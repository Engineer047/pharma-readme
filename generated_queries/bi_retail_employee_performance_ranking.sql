CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_employee_performance_ranking" AS
WITH "SalesLine" AS (
    SELECT
        T0."DocDate",
        T0."SlpCode",
        T1."ItemCode",
        CAST(T1."LineTotal" AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(T1."VatSum" AS DECIMAL(19,6)) AS "SalesVat",
        CAST(T1."LineTotal" + T1."VatSum" AS DECIMAL(19,6)) AS "SalesValueTotal"
    FROM "PPL_LIVE"."OINV" T0
    INNER JOIN "PPL_LIVE"."INV1" T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE T0."DocDate" >= '2024-01-01'
      AND T0."DocDate" <= CURRENT_DATE
      AND T0."U_CXS_FRST" = 'Y'
      AND T0."CANCELED" = 'N'

    UNION ALL

    SELECT
        T0."DocDate",
        T0."SlpCode",
        T1."ItemCode",
        CAST(-1 * T1."LineTotal" AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(-1 * T1."VatSum" AS DECIMAL(19,6)) AS "SalesVat",
        CAST(-1 * (T1."LineTotal" + T1."VatSum") AS DECIMAL(19,6)) AS "SalesValueTotal"
    FROM "PPL_LIVE"."ORIN" T0
    INNER JOIN "PPL_LIVE"."RIN1" T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE T0."DocDate" >= '2024-01-01'
      AND T0."DocDate" <= CURRENT_DATE
      AND T0."U_CXS_FRST" = 'Y'
      AND T0."CANCELED" = 'N'
),
"MonthlyEmp" AS (
    SELECT
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")) AS "ReportDate",
        COALESCE(TO_VARCHAR(S."SlpCode"), 'UNASSIGNED') AS "EmployeeCode",
        COALESCE(SLP."SlpName", 'UNASSIGNED') AS "EmployeeName",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        SUM(S."SalesLineTotal") AS "SalesLineTotal",
        SUM(S."SalesVat") AS "SalesVat",
        SUM(S."SalesValueTotal") AS "SalesValueTotal"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OSLP" SLP ON S."SlpCode" = SLP."SlpCode"
    LEFT JOIN "PPL_LIVE"."OITM" I ON S."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")), COALESCE(TO_VARCHAR(S."SlpCode"), 'UNASSIGNED'), COALESCE(SLP."SlpName", 'UNASSIGNED'), COALESCE(B."ItmsGrpNam", 'UNMAPPED')
),
"WithLag" AS (
    SELECT
        M.*,
        PM."SalesValueTotal" AS "PrevMonthSalesValue"
    FROM "MonthlyEmp" M
    LEFT JOIN "MonthlyEmp" PM
        ON PM."EmployeeCode" = M."EmployeeCode"
       AND PM."Category" = M."Category"
       AND PM."ReportDate" = ADD_MONTHS(M."ReportDate", -1)
),
"Ranked" AS (
    SELECT
        W.*,
        RANK() OVER (PARTITION BY W."ReportDate", W."Category" ORDER BY W."SalesValueTotal" DESC) AS "TopSalesRank",
        RANK() OVER (PARTITION BY W."ReportDate", W."Category" ORDER BY W."SalesValueTotal" ASC) AS "BottomSalesRank",
        RANK() OVER (PARTITION BY W."ReportDate", W."Category" ORDER BY (W."SalesValueTotal" - W."SalesVat") DESC) AS "TopProfitRank",
        RANK() OVER (PARTITION BY W."ReportDate", W."Category" ORDER BY (W."SalesValueTotal" - W."SalesVat") ASC) AS "BottomProfitRank",
        RANK() OVER (PARTITION BY W."ReportDate", W."Category" ORDER BY (W."SalesValueTotal" - COALESCE(W."PrevMonthSalesValue", 0)) DESC) AS "MostImprovedRank",
        RANK() OVER (PARTITION BY W."ReportDate", W."Category" ORDER BY (W."SalesValueTotal" - COALESCE(W."PrevMonthSalesValue", 0)) ASC) AS "MostDroppedRank"
    FROM "WithLag" W
)
SELECT
    "ReportDate",
    "EmployeeCode",
    "EmployeeName",
    "Category",
    "SalesLineTotal",
    "SalesVat",
    "SalesValueTotal",
    CAST("SalesValueTotal" - "SalesVat" AS DECIMAL(19,6)) AS "NetSalesApprox",
    "PrevMonthSalesValue",
    CAST("SalesValueTotal" - COALESCE("PrevMonthSalesValue", 0) AS DECIMAL(19,6)) AS "MoMSalesValueDelta",
    "TopSalesRank",
    "BottomSalesRank",
    "TopProfitRank",
    "BottomProfitRank",
    "MostImprovedRank",
    "MostDroppedRank",
    CASE WHEN "TopSalesRank" <= 10 OR "TopProfitRank" <= 10 THEN 'Y' ELSE 'N' END AS "Top10Flag",
    CASE WHEN "BottomSalesRank" <= 10 OR "BottomProfitRank" <= 10 THEN 'Y' ELSE 'N' END AS "Bottom10Flag"
FROM "Ranked";
