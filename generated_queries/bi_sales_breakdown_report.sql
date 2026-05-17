CREATE OR REPLACE VIEW "PPL_LIVE"."bi_sales_breakdown_report" AS
WITH "SalesLineLevel" AS (
    SELECT
        H."DocDate",
        L."WhsCode",
        L."ItemCode",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "NetSales"
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
        L."WhsCode",
        L."ItemCode",
        CAST(-(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "NetSales"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"SalesDailyItem" AS (
    SELECT
        S."DocDate",
        S."WhsCode",
        S."ItemCode",
        SUM(S."NetSales") AS "Item_Daily_Sales"
    FROM "SalesLineLevel" S
    GROUP BY S."DocDate", S."WhsCode", S."ItemCode"
),
"DailySalesAgg" AS (
    SELECT
        S."DocDate",
        S."WhsCode",
        SUM(S."Item_Daily_Sales") AS "Daily_Actual"
    FROM "SalesDailyItem" S
    GROUP BY S."DocDate", S."WhsCode"
),
"TargetMap" AS (
    SELECT
        UPPER(TRIM(T."Code")) AS "CodeNorm",
        MAX(COALESCE(T."U_SalesTarget", 0)) AS "Monthly_Sales_Target"
    FROM "PPL_LIVE"."@BRANCHTARGET" T
    GROUP BY UPPER(TRIM(T."Code"))
),
"DailyWithBudget" AS (
    SELECT
        D."DocDate",
        D."WhsCode",
        D."Daily_Actual",
        CAST(
            COALESCE(T."Monthly_Sales_Target", 0) / DAYOFMONTH(LAST_DAY(D."DocDate"))
            AS DECIMAL(19,6)
        ) AS "Daily_Budget"
    FROM "DailySalesAgg" D
    LEFT JOIN "TargetMap" T
        ON UPPER(TRIM(D."WhsCode")) = T."CodeNorm"
),
"WithTotals" AS (
    SELECT
        D."DocDate",
        D."WhsCode",
        D."Daily_Budget",
        D."Daily_Actual",
        SUM(D."Daily_Budget") OVER (
            PARTITION BY D."WhsCode", YEAR(D."DocDate"), MONTH(D."DocDate")
            ORDER BY D."DocDate"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "Mtd_Budget_Run",
        SUM(D."Daily_Actual") OVER (
            PARTITION BY D."WhsCode", YEAR(D."DocDate"), MONTH(D."DocDate")
            ORDER BY D."DocDate"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "Mtd_Actual_Run",
        SUM(D."Daily_Budget") OVER (
            PARTITION BY D."WhsCode", YEAR(D."DocDate")
            ORDER BY D."DocDate"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "Ytd_Budget_Run",
        SUM(D."Daily_Actual") OVER (
            PARTITION BY D."WhsCode", YEAR(D."DocDate")
            ORDER BY D."DocDate"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "Ytd_Actual_Run",
        MAX(D."DocDate") OVER (
            PARTITION BY D."WhsCode", YEAR(D."DocDate"), MONTH(D."DocDate")
        ) AS "Last_DocDate_In_Month"
    FROM "DailyWithBudget" D
),
"BranchMap" AS (
    SELECT
        W."WhsCode",
        MAX(W."WhsName") AS "Business",
        MAX(COALESCE(L."Location", 'UNMAPPED')) AS "Region"
    FROM "PPL_LIVE"."OWHS" W
    LEFT JOIN "PPL_LIVE"."OLCT" L
        ON W."Location" = L."Code"
    WHERE W."WhsCode" NOT LIKE 'INT-%'
    GROUP BY W."WhsCode"
)
SELECT
    W."DocDate",
    W."WhsCode",
    B."Business",
    B."Region",
    W."Daily_Budget",
    W."Daily_Actual",
    W."Mtd_Budget_Run" AS "Mtd_Budget_Run",
    CASE
        WHEN W."DocDate" = W."Last_DocDate_In_Month" THEN W."Mtd_Actual_Run"
        ELSE 0
    END AS "Mtd_Actual_Run",
    W."Ytd_Budget_Run" AS "Ytd_Budget_Run",
    CASE
        WHEN W."DocDate" = W."Last_DocDate_In_Month" THEN W."Ytd_Actual_Run"
        ELSE 0
    END AS "Ytd_Actual_Run"
FROM "WithTotals" W
INNER JOIN "BranchMap" B
    ON W."WhsCode" = B."WhsCode"
ORDER BY W."DocDate" DESC, B."Business";
