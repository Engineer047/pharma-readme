CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_branch_sales_performance" AS
WITH "SalesLine" AS (
    SELECT
        T0."DocDate",
        COALESCE(T0."DocTime", 0) AS "DocTime",
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        T0."CardCode",
        CAST(T1."LineTotal" AS DECIMAL(19,6)) AS "LineTotal",
        CAST(T1."VatSum" AS DECIMAL(19,6)) AS "VatSum",
        CAST(T1."LineTotal" + T1."VatSum" AS DECIMAL(19,6)) AS "Total"
    FROM "PPL_LIVE"."OINV" T0
    INNER JOIN "PPL_LIVE"."INV1" T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN "PPL_LIVE"."OWHS" T2 ON T1."WhsCode" = T2."WhsCode"
    WHERE T0."DocDate" >= '2024-01-01'
      AND T0."DocDate" <= CURRENT_DATE
      AND T0."U_CXS_FRST" = 'Y'
      AND T0."CANCELED" = 'N'

    UNION ALL

    SELECT
        T0."DocDate",
        COALESCE(T0."DocTime", 0) AS "DocTime",
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        T0."CardCode",
        CAST(-1 * T1."LineTotal" AS DECIMAL(19,6)) AS "LineTotal",
        CAST(-1 * T1."VatSum" AS DECIMAL(19,6)) AS "VatSum",
        CAST(-1 * (T1."LineTotal" + T1."VatSum") AS DECIMAL(19,6)) AS "Total"
    FROM "PPL_LIVE"."ORIN" T0
    INNER JOIN "PPL_LIVE"."RIN1" T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN "PPL_LIVE"."OWHS" T2 ON T1."WhsCode" = T2."WhsCode"
    WHERE T0."DocDate" >= '2024-01-01'
      AND T0."DocDate" <= CURRENT_DATE
      AND T0."U_CXS_FRST" = 'Y'
      AND T0."CANCELED" = 'N'
),
"Tagged" AS (
    SELECT
        S."DocDate",
        CAST(SUBSTRING(LPAD(TO_VARCHAR(S."DocTime"), 4, '0'), 1, 2) AS INTEGER) AS "HourNo",
        S."BranchCode",
        S."BranchName",
        COALESCE(L."Location", 'UNMAPPED') AS "Region",
        CASE
            WHEN UPPER(COALESCE(L."Location", S."BranchName", '')) LIKE '%TIER 1%' OR UPPER(COALESCE(L."Location", S."BranchName", '')) LIKE '%T1%' THEN 'T1'
            WHEN UPPER(COALESCE(L."Location", S."BranchName", '')) LIKE '%TIER 2%' OR UPPER(COALESCE(L."Location", S."BranchName", '')) LIKE '%T2%' THEN 'T2'
            WHEN UPPER(COALESCE(L."Location", S."BranchName", '')) LIKE '%TIER 3%' OR UPPER(COALESCE(L."Location", S."BranchName", '')) LIKE '%T3%' THEN 'T3'
            WHEN UPPER(COALESCE(L."Location", S."BranchName", '')) LIKE '%TIER 4%' OR UPPER(COALESCE(L."Location", S."BranchName", '')) LIKE '%T4%' THEN 'T4'
            ELSE 'UNCLASSIFIED'
        END AS "BranchTier",
        S."CardCode",
        S."LineTotal",
        S."VatSum",
        S."Total"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OWHS" W ON S."BranchCode" = W."WhsCode"
    LEFT JOIN "PPL_LIVE"."OLCT" L ON W."Location" = L."Code"
),
"HourlyAgg" AS (
    SELECT
        T."DocDate" AS "ReportDate",
        T."HourNo",
        T."BranchCode",
        T."BranchName",
        T."Region",
        COUNT(DISTINCT T."CardCode") AS "CustomerCount",
        SUM(T."LineTotal") AS "SalesLineTotal",
        SUM(T."VatSum") AS "SalesVat",
        SUM(T."Total") AS "SalesValueTotal"
    FROM "Tagged" T
    GROUP BY T."DocDate", T."HourNo", T."BranchCode", T."BranchName", T."Region"
),
"DailyAgg" AS (
    SELECT
        T."DocDate" AS "ReportDate",
        T."BranchCode",
        T."BranchName",
        T."Region",
        COUNT(DISTINCT T."CardCode") AS "CustomerCount",
        COUNT(DISTINCT CASE WHEN T."Total" <> 0 THEN T."HourNo" END) AS "ActiveHours",
        SUM(T."LineTotal") AS "SalesLineTotal",
        SUM(T."VatSum") AS "SalesVat",
        SUM(T."Total") AS "SalesValueTotal"
    FROM "Tagged" T
    GROUP BY T."DocDate", T."BranchCode", T."BranchName", T."Region"
),
"DailyLag" AS (
    SELECT
        D.*,
        LAG(D."SalesValueTotal") OVER (PARTITION BY D."BranchCode" ORDER BY D."ReportDate") AS "PrevDaySalesValue",
        LAG(D."SalesValueTotal", 7) OVER (PARTITION BY D."BranchCode" ORDER BY D."ReportDate") AS "PrevWeekSalesValue"
    FROM "DailyAgg" D
),
"MonthlyAgg" AS (
    SELECT
        ADD_DAYS(D."ReportDate", 1 - DAYOFMONTH(D."ReportDate")) AS "MonthStart",
        D."BranchCode",
        SUM(D."SalesValueTotal") AS "MonthSalesValue"
    FROM "DailyAgg" D
    GROUP BY ADD_DAYS(D."ReportDate", 1 - DAYOFMONTH(D."ReportDate")), D."BranchCode"
),
"MonthlyLag" AS (
    SELECT
        M.*,
        LAG(M."MonthSalesValue") OVER (PARTITION BY M."BranchCode" ORDER BY M."MonthStart") AS "PrevMonthSalesValue"
    FROM "MonthlyAgg" M
)
SELECT
    'HOURLY' AS "GrainType",
    H."ReportDate",
    H."HourNo",
    H."BranchCode",
    H."BranchName",
    H."Region",
    CAST(NULL AS NVARCHAR(120)) AS "EmployeeName",
    CAST(NULL AS NVARCHAR(60)) AS "ItemCode",
    CAST(NULL AS NVARCHAR(255)) AS "ItemName",
    H."CustomerCount",
    H."SalesLineTotal",
    H."SalesVat",
    H."SalesValueTotal",
    CASE WHEN H."SalesValueTotal" = 0 THEN 0 ELSE CAST((H."SalesValueTotal" - H."SalesVat") / H."SalesValueTotal" AS DECIMAL(19,6)) END AS "NetSalesRatio",
    CAST(NULL AS INTEGER) AS "ActiveHours",
    CAST(NULL AS NVARCHAR(1)) AS "Branch24HFlag",
    CAST(NULL AS DECIMAL(19,6)) AS "PrevDaySalesValue",
    CAST(NULL AS DECIMAL(19,6)) AS "PrevWeekSalesValue",
    CAST(NULL AS DECIMAL(19,6)) AS "PrevMonthSalesValue",
    CAST(NULL AS DECIMAL(19,6)) AS "DoDDeltaPct",
    CAST(NULL AS DECIMAL(19,6)) AS "WoWDeltaPct",
    CAST(NULL AS DECIMAL(19,6)) AS "MoMDeltaPct"
FROM "HourlyAgg" H

UNION ALL

SELECT
    'DAILY' AS "GrainType",
    D."ReportDate",
    CAST(NULL AS INTEGER) AS "HourNo",
    D."BranchCode",
    D."BranchName",
    D."Region",
    CAST(NULL AS NVARCHAR(120)) AS "EmployeeName",
    CAST(NULL AS NVARCHAR(60)) AS "ItemCode",
    CAST(NULL AS NVARCHAR(255)) AS "ItemName",
    D."CustomerCount",
    D."SalesLineTotal",
    D."SalesVat",
    D."SalesValueTotal",
    CASE WHEN D."SalesValueTotal" = 0 THEN 0 ELSE CAST((D."SalesValueTotal" - D."SalesVat") / D."SalesValueTotal" AS DECIMAL(19,6)) END AS "NetSalesRatio",
    D."ActiveHours",
    CASE WHEN D."ActiveHours" >= 20 THEN 'Y' ELSE 'N' END AS "Branch24HFlag",
    D."PrevDaySalesValue",
    D."PrevWeekSalesValue",
    ML."PrevMonthSalesValue",
    CASE WHEN COALESCE(D."PrevDaySalesValue", 0) = 0 THEN NULL ELSE CAST((D."SalesValueTotal" - D."PrevDaySalesValue") / D."PrevDaySalesValue" AS DECIMAL(19,6)) END AS "DoDDeltaPct",
    CASE WHEN COALESCE(D."PrevWeekSalesValue", 0) = 0 THEN NULL ELSE CAST((D."SalesValueTotal" - D."PrevWeekSalesValue") / D."PrevWeekSalesValue" AS DECIMAL(19,6)) END AS "WoWDeltaPct",
    CASE WHEN COALESCE(ML."PrevMonthSalesValue", 0) = 0 THEN NULL ELSE CAST((M."MonthSalesValue" - ML."PrevMonthSalesValue") / ML."PrevMonthSalesValue" AS DECIMAL(19,6)) END AS "MoMDeltaPct"
FROM "DailyLag" D
LEFT JOIN "MonthlyAgg" M
    ON ADD_DAYS(D."ReportDate", 1 - DAYOFMONTH(D."ReportDate")) = M."MonthStart"
   AND D."BranchCode" = M."BranchCode"
LEFT JOIN "MonthlyLag" ML
    ON M."MonthStart" = ML."MonthStart"
   AND M."BranchCode" = ML."BranchCode";
