CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_branch_cash_bank_recon" AS
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
"InvoiceHeader" AS (
    SELECT
        H."DocEntry",
        H."DocDate",
        H."DocTotal",
        H."GroupNum",
        H."Comments"
    FROM "PPL_LIVE"."OINV" H
    WHERE H."CANCELED" = 'N'
      AND H."DocDate" >= '2024-01-01'
),
"TenderDaily" AS (
    SELECT
        H."DocDate" AS "ReportDate",
        S."BranchCode",
        CAST(SUM(
            CASE
                WHEN UPPER(COALESCE(H."Comments", '')) LIKE '%MPESA%'
                  OR UPPER(COALESCE(H."Comments", '')) LIKE '%M-PESA%'
                  OR UPPER(COALESCE(H."Comments", '')) LIKE '%CARD%'
                  OR UPPER(COALESCE(H."Comments", '')) LIKE '%VISA%'
                  OR UPPER(COALESCE(H."Comments", '')) LIKE '%MASTERCARD%'
                THEN 0
                WHEN COALESCE(H."GroupNum", -1) = -1 THEN COALESCE(H."DocTotal", 0) * S."BranchSharePct"
                ELSE 0
            END
        ) AS DECIMAL(19,6)) AS "CashTender",
        CAST(SUM(
            CASE
                WHEN UPPER(COALESCE(H."Comments", '')) LIKE '%MPESA%'
                  OR UPPER(COALESCE(H."Comments", '')) LIKE '%M-PESA%'
                THEN COALESCE(H."DocTotal", 0) * S."BranchSharePct"
                ELSE 0
            END
        ) AS DECIMAL(19,6)) AS "MpesaTender",
        CAST(SUM(
            CASE
                WHEN UPPER(COALESCE(H."Comments", '')) LIKE '%CARD%'
                  OR UPPER(COALESCE(H."Comments", '')) LIKE '%VISA%'
                  OR UPPER(COALESCE(H."Comments", '')) LIKE '%MASTERCARD%'
                THEN COALESCE(H."DocTotal", 0) * S."BranchSharePct"
                WHEN COALESCE(H."GroupNum", -1) <> -1
                     AND UPPER(COALESCE(H."Comments", '')) NOT LIKE '%MPESA%'
                     AND UPPER(COALESCE(H."Comments", '')) NOT LIKE '%M-PESA%'
                THEN COALESCE(H."DocTotal", 0) * S."BranchSharePct"
                ELSE 0
            END
        ) AS DECIMAL(19,6)) AS "CardTender"
    FROM "InvoiceHeader" H
    INNER JOIN "InvBranchShare" S
        ON H."DocEntry" = S."DocEntry"
    GROUP BY H."DocDate", S."BranchCode"
),
"SalesDaily" AS (
    SELECT
        H."DocDate" AS "ReportDate",
        L."WhsCode" AS "BranchCode",
        CAST(SUM(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "NetInvoiceSales"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
    GROUP BY H."DocDate", L."WhsCode"

    UNION ALL

    SELECT
        H."DocDate" AS "ReportDate",
        L."WhsCode" AS "BranchCode",
        CAST(SUM(-1 * (L."LineTotal" + L."VatSum")) AS DECIMAL(19,6)) AS "NetInvoiceSales"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
    GROUP BY H."DocDate", L."WhsCode"
),
"SalesDailyAgg" AS (
    SELECT
        S."ReportDate",
        S."BranchCode",
        CAST(SUM(S."NetInvoiceSales") AS DECIMAL(19,6)) AS "NetSales"
    FROM "SalesDaily" S
    GROUP BY S."ReportDate", S."BranchCode"
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
),
"Keys" AS (
    SELECT "ReportDate", "BranchCode" FROM "TenderDaily"
    UNION
    SELECT "ReportDate", "BranchCode" FROM "SalesDailyAgg"
)
SELECT
    K."ReportDate",
    K."BranchCode",
    COALESCE(B."BranchName", 'UNMAPPED') AS "BranchName",
    COALESCE(B."Region", 'UNMAPPED') AS "Region",
    COALESCE(T."CashTender", 0) AS "Cash",
    COALESCE(T."MpesaTender", 0) AS "M-Pesa",
    COALESCE(T."CardTender", 0) AS "Card",
    CAST(COALESCE(T."CashTender", 0) + COALESCE(T."MpesaTender", 0) + COALESCE(T."CardTender", 0) AS DECIMAL(19,6)) AS "TotalTender",
    COALESCE(S."NetSales", 0) AS "NetSales",
    CAST((COALESCE(T."CashTender", 0) + COALESCE(T."MpesaTender", 0) + COALESCE(T."CardTender", 0)) - COALESCE(S."NetSales", 0) AS DECIMAL(19,6)) AS "ReconciliationVariance",
    CASE
        WHEN ABS((COALESCE(T."CashTender", 0) + COALESCE(T."MpesaTender", 0) + COALESCE(T."CardTender", 0)) - COALESCE(S."NetSales", 0)) <= 1 THEN 'RECONCILED'
        WHEN ABS((COALESCE(T."CashTender", 0) + COALESCE(T."MpesaTender", 0) + COALESCE(T."CardTender", 0)) - COALESCE(S."NetSales", 0)) <= 100 THEN 'MINOR_GAP'
        ELSE 'UNRECONCILED'
    END AS "ReconciliationStatus"
FROM "Keys" K
LEFT JOIN "TenderDaily" T
    ON K."ReportDate" = T."ReportDate"
   AND K."BranchCode" = T."BranchCode"
LEFT JOIN "SalesDailyAgg" S
    ON K."ReportDate" = S."ReportDate"
   AND K."BranchCode" = S."BranchCode"
LEFT JOIN "BranchDim" B
    ON K."BranchCode" = B."BranchCode"
WHERE K."BranchCode" NOT LIKE 'INT-%'
ORDER BY K."ReportDate" DESC, K."BranchCode";

