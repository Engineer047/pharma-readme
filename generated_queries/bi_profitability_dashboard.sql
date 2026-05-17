CREATE OR REPLACE VIEW "PPL_LIVE"."bi_profitability_dashboard" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate",
        L."WhsCode",
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
        L."WhsCode",
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
"DailySales" AS (
    SELECT
        S."DocDate",
        S."WhsCode",
        MAX(W."WhsName") AS "Store",
        MAX(COALESCE(L."Location", 'UNMAPPED')) AS "Region",
        SUM(S."Sales") AS "Sales",
        SUM(S."GP") AS "GP"
    FROM "SalesLine" S
    INNER JOIN "PPL_LIVE"."OWHS" W
        ON S."WhsCode" = W."WhsCode"
    LEFT JOIN "PPL_LIVE"."OLCT" L
        ON W."Location" = L."Code"
    GROUP BY S."DocDate", S."WhsCode"
),
"TargetMap" AS (
    SELECT
        UPPER(TRIM(T."Code")) AS "CodeNorm",
        MAX(COALESCE(T."U_SalesTarget", 0)) AS "MonthlyTarget"
    FROM "PPL_LIVE"."@BRANCHTARGET" T
    GROUP BY UPPER(TRIM(T."Code"))
),
"DailyBudget" AS (
    SELECT
        D."DocDate",
        D."WhsCode",
        CAST(
            COALESCE(T."MonthlyTarget", 0) / DAYOFMONTH(LAST_DAY(D."DocDate"))
            AS DECIMAL(19,6)
        ) AS "DailyBudgetAmount"
    FROM (
        SELECT DISTINCT
            S."DocDate",
            S."WhsCode"
        FROM "DailySales" S
    ) D
    LEFT JOIN "TargetMap" T
        ON UPPER(TRIM(D."WhsCode")) = T."CodeNorm"
),
"FinalMetrics" AS (
    SELECT
        S."DocDate",
        S."WhsCode",
        S."Store",
        S."Region",
        S."Sales",
        S."GP",
        COALESCE(B."DailyBudgetAmount", CAST(0 AS DECIMAL(19,6))) AS "Budget"
    FROM "DailySales" S
    LEFT JOIN "DailyBudget" B
        ON S."DocDate" = B."DocDate"
       AND S."WhsCode" = B."WhsCode"
),
"WithComparisons" AS (
    SELECT
        F."DocDate",
        F."WhsCode",
        F."Store",
        F."Region",
        F."Sales",
        F."GP",
        F."Budget",
        PM."Sales" AS "PrevMonthSales",
        PY."Sales" AS "PrevYearSales"
    FROM "FinalMetrics" F
    LEFT JOIN "FinalMetrics" PM
        ON PM."WhsCode" = F."WhsCode"
       AND PM."DocDate" = ADD_MONTHS(F."DocDate", -1)
    LEFT JOIN "FinalMetrics" PY
        ON PY."WhsCode" = F."WhsCode"
       AND PY."DocDate" = ADD_MONTHS(F."DocDate", -12)
)
SELECT
    C."DocDate" AS "ReportDate",
    C."Store",
    C."Region",
    C."Sales" AS "Daily Sales",
    C."GP" AS "Daily GP",
    C."Budget" AS "Daily Budget",
    CASE
        WHEN C."Sales" = 0 THEN 0
        ELSE CAST((C."GP" / NULLIF(C."Sales", 0)) * 100 AS DECIMAL(19,6))
    END AS "GP %",
    CAST(C."Sales" - C."Budget" AS DECIMAL(19,6)) AS "Budget_Variance",
    CAST(C."Sales" - COALESCE(C."PrevMonthSales", 0) AS DECIMAL(19,6)) AS "MoM_Change",
    CAST(C."Sales" - COALESCE(C."PrevYearSales", 0) AS DECIMAL(19,6)) AS "YoY_Change"
FROM "WithComparisons" C
WHERE C."DocDate" >= '2024-01-01'
ORDER BY C."DocDate" DESC, C."Store" ASC;
