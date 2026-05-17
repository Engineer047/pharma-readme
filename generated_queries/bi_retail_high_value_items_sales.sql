CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_high_value_items_sales" AS
WITH "SalesLine" AS (
    SELECT
        T0."DocDate",
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        T1."ItemCode",
        CAST(T1."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
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
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        T1."ItemCode",
        CAST(-1 * T1."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
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
"MonthlyAgg" AS (
    SELECT
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")) AS "ReportDate",
        S."BranchCode",
        S."BranchName",
        S."ItemCode",
        COALESCE(I."ItemName", 'UNMAPPED') AS "ItemName",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        COALESCE(I."U_Brand", 'UNMAPPED') AS "Brand",
        COALESCE(I."U_Formulation", 'UNMAPPED') AS "Formulation",
        SUM(S."QtyBaseUoM") AS "QtyBaseUoM",
        SUM(S."LineTotal") AS "SalesLineTotal",
        SUM(S."VatSum") AS "SalesVat",
        SUM(S."Total") AS "SalesValueTotal"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OITM" I ON S."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")), S."BranchCode", S."BranchName", S."ItemCode", COALESCE(I."ItemName", 'UNMAPPED'), COALESCE(B."ItmsGrpNam", 'UNMAPPED'), COALESCE(I."U_Brand", 'UNMAPPED'), COALESCE(I."U_Formulation", 'UNMAPPED')
),
"Ranked" AS (
    SELECT
        M.*,
        CASE WHEN M."QtyBaseUoM" = 0 THEN NULL ELSE CAST(M."SalesValueTotal" / M."QtyBaseUoM" AS DECIMAL(19,6)) END AS "AvgSellingPrice",
        RANK() OVER (PARTITION BY M."ReportDate", M."BranchCode" ORDER BY M."SalesValueTotal" DESC) AS "TopSalesRankInBranch"
    FROM "MonthlyAgg" M
)
SELECT
    "ReportDate",
    "BranchCode",
    "BranchName",
    "ItemCode",
    "ItemName",
    "Category",
    "Brand",
    "Formulation",
    "QtyBaseUoM",
    "SalesLineTotal",
    "SalesVat",
    "SalesValueTotal",
    "AvgSellingPrice",
    CASE WHEN COALESCE("AvgSellingPrice", 0) >= 1000 THEN 'Y' ELSE 'N' END AS "HighValueFlag",
    CASE WHEN UPPER(COALESCE("Formulation", '')) LIKE '%TABLET%' AND COALESCE("AvgSellingPrice", 0) >= 50 THEN 'Y' ELSE 'N' END AS "TabletAt50Flag",
    "TopSalesRankInBranch"
FROM "Ranked";
