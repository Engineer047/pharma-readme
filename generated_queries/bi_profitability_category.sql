CREATE OR REPLACE VIEW "PPL_LIVE"."bi_profitability_category" AS
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
      AND H."DocDate" >= '2023-01-01'
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
      AND H."DocDate" >= '2023-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"DailyCategorySales" AS (
    SELECT
        S."DocDate",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        SUM(S."Sales") AS "Sales",
        SUM(S."GP") AS "GP"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON S."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY S."DocDate", COALESCE(B."ItmsGrpNam", 'UNMAPPED')
),
"DailyTotal" AS (
    SELECT
        D."DocDate",
        SUM(D."Sales") AS "TotalDaySales"
    FROM "DailyCategorySales" D
    GROUP BY D."DocDate"
),
"GrowthMetrics" AS (
    SELECT
        S."DocDate",
        S."Category",
        S."Sales",
        S."GP",
        T."TotalDaySales",
        PM."Sales" AS "PrevMonthSales",
        PY."Sales" AS "PrevYearSales"
    FROM "DailyCategorySales" S
    INNER JOIN "DailyTotal" T
        ON S."DocDate" = T."DocDate"
    LEFT JOIN "DailyCategorySales" PM
        ON PM."Category" = S."Category"
       AND PM."DocDate" = ADD_MONTHS(S."DocDate", -1)
    LEFT JOIN "DailyCategorySales" PY
        ON PY."Category" = S."Category"
       AND PY."DocDate" = ADD_MONTHS(S."DocDate", -12)
)
SELECT
    G."DocDate" AS "ReportDate",
    G."Category",
    G."Sales" AS "Monthly Sales",
    CASE
        WHEN G."Sales" = 0 THEN 0
        ELSE CAST((G."GP" / NULLIF(G."Sales", 0)) * 100 AS DECIMAL(19,6))
    END AS "GP %",
    CASE
        WHEN G."TotalDaySales" = 0 THEN 0
        ELSE CAST((G."Sales" / G."TotalDaySales") * 100 AS DECIMAL(19,6))
    END AS "% Share",
    CAST(G."Sales" - COALESCE(G."PrevMonthSales", 0) AS DECIMAL(19,6)) AS "MoM_Change",
    CAST(G."Sales" - COALESCE(G."PrevYearSales", 0) AS DECIMAL(19,6)) AS "YoY_Change"
FROM "GrowthMetrics" G
WHERE G."DocDate" >= '2024-01-01'
ORDER BY G."DocDate" DESC, G."Category" ASC;
