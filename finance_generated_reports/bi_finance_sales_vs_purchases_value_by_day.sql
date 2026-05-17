CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_sales_vs_purchases_value_by_day" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate" AS "Posting Date",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "SalesValue",
        CAST(L."GrssProfit" AS DECIMAL(19,6)) AS "GrossProfit"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE

    UNION ALL

    SELECT
        H."DocDate" AS "Posting Date",
        CAST(-1 * L."LineTotal" AS DECIMAL(19,6)) AS "SalesValue",
        CAST(-1 * L."GrssProfit" AS DECIMAL(19,6)) AS "GrossProfit"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"SalesDaily" AS (
    SELECT
        S."Posting Date",
        CAST(SUM(S."SalesValue") AS DECIMAL(19,6)) AS "Sales Value",
        CAST(SUM(S."GrossProfit") AS DECIMAL(19,6)) AS "Gross Profit"
    FROM "SalesLine" S
    GROUP BY S."Posting Date"
),
"PurchaseLine" AS (
    SELECT
        H."DocDate" AS "Posting Date",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "PurchasesValue"
    FROM "PPL_LIVE"."OPCH" H
    INNER JOIN "PPL_LIVE"."PCH1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE

    UNION ALL

    SELECT
        H."DocDate" AS "Posting Date",
        CAST(-1 * L."LineTotal" AS DECIMAL(19,6)) AS "PurchasesValue"
    FROM "PPL_LIVE"."ORPC" H
    INNER JOIN "PPL_LIVE"."RPC1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"PurchasesDaily" AS (
    SELECT
        P."Posting Date",
        CAST(SUM(P."PurchasesValue") AS DECIMAL(19,6)) AS "Purchases Value"
    FROM "PurchaseLine" P
    GROUP BY P."Posting Date"
),
"PostingDates" AS (
    SELECT "Posting Date" FROM "SalesDaily"
    UNION
    SELECT "Posting Date" FROM "PurchasesDaily"
)
SELECT
    D."Posting Date",
    COALESCE(S."Sales Value", 0) AS "Sales Value",
    COALESCE(P."Purchases Value", 0) AS "Purchases Value",
    COALESCE(S."Gross Profit", 0) AS "Gross Profit"
FROM "PostingDates" D
LEFT JOIN "SalesDaily" S
    ON D."Posting Date" = S."Posting Date"
LEFT JOIN "PurchasesDaily" P
    ON D."Posting Date" = P."Posting Date"
ORDER BY D."Posting Date" DESC;
