CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_receivables_branch_level" AS
WITH "InvDocTotals" AS (
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
        CAST(
            SUM(L."LineTotal" + L."VatSum") / NULLIF(T."DocTotalLines", 0)
            AS DECIMAL(19,6)
        ) AS "BranchSharePct"
    FROM "PPL_LIVE"."INV1" L
    INNER JOIN "InvDocTotals" T
        ON L."DocEntry" = T."DocEntry"
    GROUP BY L."DocEntry", L."WhsCode", T."DocTotalLines"
),
"ReceivableBase" AS (
    SELECT
        H."DocEntry",
        H."DocNum",
        H."DocDate" AS "ReportDate",
        H."DocDueDate",
        H."CardCode",
        H."CardName",
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
"ReceivableTagged" AS (
    SELECT
        R."DocEntry",
        R."DocNum",
        R."ReportDate",
        R."DocDueDate",
        R."CardCode",
        R."CardName",
        R."OpenAmount",
        CASE
            WHEN UPPER(COALESCE(R."CardName", R."CardCode", '')) LIKE '%GLOVO%' THEN 'Glovo'
            WHEN UPPER(COALESCE(R."CardName", R."CardCode", '')) LIKE '%UBER%' THEN 'UberEats'
            WHEN UPPER(COALESCE(R."CardName", R."CardCode", '')) LIKE '%SUKHIBA%' THEN 'Sukhiba'
            WHEN UPPER(COALESCE(R."CardName", R."CardCode", '')) LIKE '%SAP%' THEN 'SAP'
            WHEN UPPER(COALESCE(R."CardName", R."CardCode", '')) LIKE '%KENYA PIPELINE%'
              OR UPPER(COALESCE(R."CardName", R."CardCode", '')) LIKE '%KPC%'
            THEN 'Partnerships - Kenya Pipeline Corporation'
            WHEN UPPER(COALESCE(R."CardName", R."CardCode", '')) LIKE '%KENYA PORTS%'
              OR UPPER(COALESCE(R."CardName", R."CardCode", '')) LIKE '%KPA%'
            THEN 'Partnerships - Kenya Ports Authority'
            ELSE 'Pending Reconciliations'
        END AS "ReceivableType"
    FROM "ReceivableBase" R
),
"ReceivableAllocated" AS (
    SELECT
        T."ReportDate",
        S."BranchCode",
        T."ReceivableType",
        CAST(SUM(T."OpenAmount" * S."BranchSharePct") AS DECIMAL(19,6)) AS "OpenReceivableValue",
        CAST(SUM(
            CASE
                WHEN T."DocDueDate" < CURRENT_DATE THEN T."OpenAmount" * S."BranchSharePct"
                ELSE 0
            END
        ) AS DECIMAL(19,6)) AS "OverdueReceivableValue",
        COUNT(DISTINCT CASE WHEN T."OpenAmount" > 0 THEN T."DocEntry" END) AS "OpenInvoiceCount",
        COUNT(DISTINCT CASE WHEN T."DocDueDate" < CURRENT_DATE AND T."OpenAmount" > 0 THEN T."DocEntry" END) AS "OverdueInvoiceCount"
    FROM "ReceivableTagged" T
    INNER JOIN "InvBranchShare" S
        ON T."DocEntry" = S."DocEntry"
    GROUP BY T."ReportDate", S."BranchCode", T."ReceivableType"
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
    R."ReportDate",
    R."BranchCode",
    COALESCE(B."BranchName", 'UNMAPPED') AS "BranchName",
    COALESCE(B."Region", 'UNMAPPED') AS "Region",
    R."ReceivableType",
    R."OpenReceivableValue",
    R."OverdueReceivableValue",
    R."OpenInvoiceCount",
    R."OverdueInvoiceCount",
    CASE
        WHEN COALESCE(R."OpenReceivableValue", 0) = 0 THEN NULL
        ELSE CAST((R."OverdueReceivableValue" / NULLIF(R."OpenReceivableValue", 0)) * 100 AS DECIMAL(19,6))
    END AS "OverduePct"
FROM "ReceivableAllocated" R
LEFT JOIN "BranchDim" B
    ON R."BranchCode" = B."BranchCode"
WHERE R."BranchCode" NOT LIKE 'INT-%'
ORDER BY R."ReportDate" DESC, R."BranchCode", R."ReceivableType";

