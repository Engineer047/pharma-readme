CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_branch_level_report" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate" AS "ReportDate",
        L."WhsCode" AS "BranchCode",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "SalesValue",
        CAST(L."GrssProfit" AS DECIMAL(19,6)) AS "GrossProfit"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'

    UNION ALL

    SELECT
        H."DocDate" AS "ReportDate",
        L."WhsCode" AS "BranchCode",
        CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "SalesValue",
        CAST(-1 * L."GrssProfit" AS DECIMAL(19,6)) AS "GrossProfit"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
),
"SalesDaily" AS (
    SELECT
        S."ReportDate",
        S."BranchCode",
        CAST(SUM(S."SalesValue") AS DECIMAL(19,6)) AS "SalesValueTotal",
        CAST(SUM(S."GrossProfit") AS DECIMAL(19,6)) AS "GrossProfitTotal"
    FROM "SalesLine" S
    GROUP BY S."ReportDate", S."BranchCode"
),
"TransferDaily" AS (
    SELECT
        N."DocDate" AS "ReportDate",
        N."Warehouse" AS "BranchCode",
        CAST(SUM(CASE WHEN N."TransValue" > 0 THEN N."TransValue" ELSE 0 END) AS DECIMAL(19,6)) AS "TransfersInValue",
        CAST(SUM(CASE WHEN N."TransValue" < 0 THEN -N."TransValue" ELSE 0 END) AS DECIMAL(19,6)) AS "TransfersOutValue"
    FROM "PPL_LIVE"."OINM" N
    WHERE N."DocDate" >= '2024-01-01'
      AND N."TransType" = '67'
    GROUP BY N."DocDate", N."Warehouse"
),
"InvDocTotals" AS (
    SELECT
        L."DocEntry",
        CAST(SUM(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "DocTotalLines"
    FROM "PPL_LIVE"."INV1" L
    GROUP BY L."DocEntry"
),
"InvBranchShare" AS (
    SELECT
        L."DocEntry",
        L."WhsCode" AS "BranchCode",
        CAST(SUM(L."LineTotal" + L."VatSum") / NULLIF(T."DocTotalLines", 0) AS DECIMAL(19,6)) AS "BranchSharePct"
    FROM "PPL_LIVE"."INV1" L
    INNER JOIN "InvDocTotals" T
        ON L."DocEntry" = T."DocEntry"
    GROUP BY L."DocEntry", L."WhsCode", T."DocTotalLines"
),
"ReceivableDocOpen" AS (
    SELECT
        H."DocEntry",
        H."DocDate" AS "ReportDate",
        H."DocDueDate",
        CAST(
            CASE
                WHEN COALESCE(H."DocTotal", 0) - COALESCE(H."PaidToDate", 0) > 0
                THEN COALESCE(H."DocTotal", 0) - COALESCE(H."PaidToDate", 0)
                ELSE 0
            END AS DECIMAL(19,6)
        ) AS "OpenAmount"
    FROM "PPL_LIVE"."OINV" H
    WHERE H."CANCELED" = 'N'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocStatus" = 'O'
),
"ReceivableDaily" AS (
    SELECT
        R."ReportDate",
        S."BranchCode",
        CAST(SUM(R."OpenAmount" * S."BranchSharePct") AS DECIMAL(19,6)) AS "OpenReceivableValue",
        CAST(SUM(CASE WHEN R."DocDueDate" < CURRENT_DATE THEN R."OpenAmount" * S."BranchSharePct" ELSE 0 END) AS DECIMAL(19,6)) AS "OverdueReceivableValue",
        COUNT(DISTINCT CASE WHEN R."OpenAmount" > 0 THEN R."DocEntry" END) AS "OpenInvoiceCount",
        COUNT(DISTINCT CASE WHEN R."OpenAmount" > 0 AND R."DocDueDate" < CURRENT_DATE THEN R."DocEntry" END) AS "OverdueInvoiceCount"
    FROM "ReceivableDocOpen" R
    INNER JOIN "InvBranchShare" S
        ON R."DocEntry" = S."DocEntry"
    GROUP BY R."ReportDate", S."BranchCode"
),
"ReportKeys" AS (
    SELECT "ReportDate", "BranchCode" FROM "SalesDaily"
    UNION
    SELECT "ReportDate", "BranchCode" FROM "TransferDaily"
    UNION
    SELECT "ReportDate", "BranchCode" FROM "ReceivableDaily"
),
"BranchDim" AS (
    SELECT
        W."WhsCode" AS "BranchCode",
        MAX(W."WhsName") AS "BranchName",
        MAX(COALESCE(L."Location", 'UNMAPPED')) AS "Region"
    FROM "PPL_LIVE"."OWHS" W
    LEFT JOIN "PPL_LIVE"."OLCT" L
        ON W."Location" = L."Code"
    GROUP BY W."WhsCode"
)
SELECT
    K."ReportDate",
    K."BranchCode",
    COALESCE(B."BranchName", 'UNMAPPED') AS "BranchName",
    COALESCE(B."Region", 'UNMAPPED') AS "Region",

    COALESCE(S."SalesValueTotal", 0) AS "SalesValueTotal",
    COALESCE(S."GrossProfitTotal", 0) AS "GrossProfitTotal",
    CASE
        WHEN COALESCE(S."SalesValueTotal", 0) = 0 THEN NULL
        ELSE CAST((S."GrossProfitTotal" / NULLIF(S."SalesValueTotal", 0)) * 100 AS DECIMAL(19,6))
    END AS "GrossMarginPct",

    COALESCE(T."TransfersInValue", 0) AS "TransfersInValue",
    COALESCE(T."TransfersOutValue", 0) AS "TransfersOutValue",
    CAST(COALESCE(T."TransfersInValue", 0) - COALESCE(T."TransfersOutValue", 0) AS DECIMAL(19,6)) AS "NetTransferFlow",

    COALESCE(R."OpenReceivableValue", 0) AS "OpenReceivableValue",
    COALESCE(R."OverdueReceivableValue", 0) AS "OverdueReceivableValue",
    COALESCE(R."OpenInvoiceCount", 0) AS "OpenInvoiceCount",
    COALESCE(R."OverdueInvoiceCount", 0) AS "OverdueInvoiceCount",
    CASE
        WHEN COALESCE(R."OpenReceivableValue", 0) = 0 THEN NULL
        ELSE CAST((R."OverdueReceivableValue" / NULLIF(R."OpenReceivableValue", 0)) * 100 AS DECIMAL(19,6))
    END AS "OverdueReceivablePct",

    CASE
        WHEN COALESCE(R."OpenReceivableValue", 0) = 0 THEN 'OK'
        WHEN (COALESCE(R."OverdueReceivableValue", 0) / NULLIF(R."OpenReceivableValue", 0)) > 0.5 THEN 'HIGH_RISK'
        WHEN (COALESCE(R."OverdueReceivableValue", 0) / NULLIF(R."OpenReceivableValue", 0)) > 0.2 THEN 'MEDIUM_RISK'
        ELSE 'OK'
    END AS "ComplianceStatus"
FROM "ReportKeys" K
LEFT JOIN "SalesDaily" S
    ON K."ReportDate" = S."ReportDate"
   AND K."BranchCode" = S."BranchCode"
LEFT JOIN "TransferDaily" T
    ON K."ReportDate" = T."ReportDate"
   AND K."BranchCode" = T."BranchCode"
LEFT JOIN "ReceivableDaily" R
    ON K."ReportDate" = R."ReportDate"
   AND K."BranchCode" = R."BranchCode"
LEFT JOIN "BranchDim" B
    ON K."BranchCode" = B."BranchCode"
WHERE K."BranchCode" NOT LIKE 'INT-%'
ORDER BY K."ReportDate" DESC, K."BranchCode";

