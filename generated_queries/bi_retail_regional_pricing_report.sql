CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_regional_pricing_report" AS
WITH "SalesLine" AS (
    SELECT
        T0."DocDate",
        T1."ItemCode",
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        CAST(T1."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
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
        T1."ItemCode",
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        CAST(-1 * T1."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
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
"RegionalMonthly" AS (
    SELECT
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")) AS "ReportDate",
        COALESCE(L."Location", 'UNMAPPED') AS "Region",
        S."ItemCode",
        COALESCE(I."ItemName", 'UNMAPPED') AS "ItemName",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        COALESCE(I."U_Brand", 'UNMAPPED') AS "Brand",
        SUM(S."QtyBaseUoM") AS "QtyBaseUoM",
        SUM(S."SalesLineTotal") AS "SalesLineTotal",
        SUM(S."SalesVat") AS "SalesVat",
        SUM(S."SalesValueTotal") AS "SalesValueTotal"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OWHS" W ON S."BranchCode" = W."WhsCode"
    LEFT JOIN "PPL_LIVE"."OLCT" L ON W."Location" = L."Code"
    LEFT JOIN "PPL_LIVE"."OITM" I ON S."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")), COALESCE(L."Location", 'UNMAPPED'), S."ItemCode", COALESCE(I."ItemName", 'UNMAPPED'), COALESCE(B."ItmsGrpNam", 'UNMAPPED'), COALESCE(I."U_Brand", 'UNMAPPED')
),
"CompanyMonthly" AS (
    SELECT
        R."ReportDate",
        R."ItemCode",
        SUM(R."QtyBaseUoM") AS "CompanyQty",
        SUM(R."SalesValueTotal") AS "CompanySalesValue"
    FROM "RegionalMonthly" R
    GROUP BY R."ReportDate", R."ItemCode"
),
"WithLag" AS (
    SELECT
        R.*,
        LAG(CASE WHEN R."QtyBaseUoM" = 0 THEN NULL ELSE R."SalesValueTotal" / R."QtyBaseUoM" END) OVER (
            PARTITION BY R."Region", R."ItemCode"
            ORDER BY R."ReportDate"
        ) AS "PrevMonthAvgPrice"
    FROM "RegionalMonthly" R
)
SELECT
    W."ReportDate",
    W."Region",
    W."ItemCode",
    W."ItemName",
    W."Category",
    W."Brand",
    W."QtyBaseUoM",
    W."SalesLineTotal",
    W."SalesVat",
    W."SalesValueTotal",
    CASE WHEN W."QtyBaseUoM" = 0 THEN NULL ELSE CAST(W."SalesValueTotal" / W."QtyBaseUoM" AS DECIMAL(19,6)) END AS "RegionalAvgPrice",
    CASE WHEN C."CompanyQty" = 0 THEN NULL ELSE CAST(C."CompanySalesValue" / C."CompanyQty" AS DECIMAL(19,6)) END AS "CompanyAvgPrice",
    CASE WHEN C."CompanyQty" = 0 OR (C."CompanySalesValue" / C."CompanyQty") = 0 THEN NULL ELSE CAST((W."SalesValueTotal" / NULLIF(W."QtyBaseUoM", 0)) / (C."CompanySalesValue" / C."CompanyQty") AS DECIMAL(19,6)) END AS "RegionalPriceIndex",
    "PrevMonthAvgPrice",
    CASE WHEN "PrevMonthAvgPrice" IS NULL OR "PrevMonthAvgPrice" = 0 THEN NULL ELSE CAST(((W."SalesValueTotal" / NULLIF(W."QtyBaseUoM", 0)) - "PrevMonthAvgPrice") / "PrevMonthAvgPrice" AS DECIMAL(19,6)) END AS "MoMPriceDeltaPct"
FROM "WithLag" W
LEFT JOIN "CompanyMonthly" C
    ON W."ReportDate" = C."ReportDate"
   AND W."ItemCode" = C."ItemCode";
