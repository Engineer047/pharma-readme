CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_branch_performance_ranking" AS
WITH "SalesLine" AS (
    SELECT
        T0."DocDate",
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        T1."ItemCode",
        CAST(T1."LineTotal" AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(T1."VatSum" AS DECIMAL(19,6)) AS "SalesVat",
        CAST(T1."LineTotal" + T1."VatSum" AS DECIMAL(19,6)) AS "SalesValueTotal"
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
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        T1."ItemCode",
        CAST(-1 * T1."LineTotal" AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(-1 * T1."VatSum" AS DECIMAL(19,6)) AS "SalesVat",
        CAST(-1 * (T1."LineTotal" + T1."VatSum") AS DECIMAL(19,6)) AS "SalesValueTotal"
    FROM "PPL_LIVE"."ORIN" T0
    INNER JOIN "PPL_LIVE"."RIN1" T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN "PPL_LIVE"."OWHS" T2 ON T1."WhsCode" = T2."WhsCode"
    WHERE T0."DocDate" >= '2024-01-01'
      AND T0."DocDate" <= CURRENT_DATE
      AND T0."U_CXS_FRST" = 'Y'
      AND T0."CANCELED" = 'N'
),
"MonthlyBranch" AS (
    SELECT
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")) AS "ReportDate",
        S."BranchCode",
        S."BranchName",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        SUM(S."SalesLineTotal") AS "SalesLineTotal",
        SUM(S."SalesVat") AS "SalesVat",
        SUM(S."SalesValueTotal") AS "SalesValueTotal"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OITM" I ON S."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")), S."BranchCode", S."BranchName", COALESCE(B."ItmsGrpNam", 'UNMAPPED')
),
"Ranked" AS (
    SELECT
        M.*,
        RANK() OVER (PARTITION BY M."ReportDate", M."Category" ORDER BY M."SalesValueTotal" DESC) AS "TopSalesRank",
        RANK() OVER (PARTITION BY M."ReportDate", M."Category" ORDER BY M."SalesValueTotal" ASC) AS "BottomSalesRank",
        RANK() OVER (PARTITION BY M."ReportDate", M."Category" ORDER BY (M."SalesValueTotal" - M."SalesVat") DESC) AS "TopProfitRank",
        RANK() OVER (PARTITION BY M."ReportDate", M."Category" ORDER BY (M."SalesValueTotal" - M."SalesVat") ASC) AS "BottomProfitRank"
    FROM "MonthlyBranch" M
)
SELECT
    "ReportDate",
    "BranchCode",
    "BranchName",
    "Category",
    "SalesLineTotal",
    "SalesVat",
    "SalesValueTotal",
    CAST("SalesValueTotal" - "SalesVat" AS DECIMAL(19,6)) AS "NetSalesApprox",
    "TopSalesRank",
    "BottomSalesRank",
    "TopProfitRank",
    "BottomProfitRank",
    CASE WHEN "TopSalesRank" <= 10 OR "TopProfitRank" <= 10 THEN 'Y' ELSE 'N' END AS "Top10Flag",
    CASE WHEN "BottomSalesRank" <= 10 OR "BottomProfitRank" <= 10 THEN 'Y' ELSE 'N' END AS "Bottom10Flag"
FROM "Ranked";
