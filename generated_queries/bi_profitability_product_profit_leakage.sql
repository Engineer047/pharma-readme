CREATE OR REPLACE VIEW "PPL_LIVE"."bi_profitability_product_profit_leakage" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate",
        L."ItemCode",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "Sales",
        CAST(L."GrssProfit" AS DECIMAL(19,6)) AS "GP"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE

    UNION ALL

    SELECT
        H."DocDate",
        L."ItemCode",
        CAST(-1 * L."LineTotal" AS DECIMAL(19,6)) AS "Sales",
        CAST(-1 * L."GrssProfit" AS DECIMAL(19,6)) AS "GP"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"DailyProductSales" AS (
    SELECT
        S."DocDate",
        S."ItemCode",
        COALESCE(I."ItemName", 'UNMAPPED') AS "Description",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        SUM(S."Sales") AS "Sales",
        SUM(S."GP") AS "GP"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON S."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY
        S."DocDate",
        S."ItemCode",
        COALESCE(I."ItemName", 'UNMAPPED'),
        COALESCE(B."ItmsGrpNam", 'UNMAPPED')
)
SELECT
    D."DocDate" AS "ReportDate",
    D."Description",
    D."Category",
    D."Sales",
    D."GP",
    CASE
        WHEN D."Sales" = 0 THEN 0
        ELSE CAST((D."GP" / NULLIF(D."Sales", 0)) * 100 AS DECIMAL(19,6))
    END AS "GP %"
FROM "DailyProductSales" D
ORDER BY D."DocDate" DESC, "GP %" ASC;
