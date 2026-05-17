CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_top_1000_selling_items" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate",
        L."WhsCode" AS "BranchCode",
        L."ItemCode",
        CAST(L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(L."VatSum" AS DECIMAL(19,6)) AS "SalesVat",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "SalesValueTotal"
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
        L."WhsCode" AS "BranchCode",
        L."ItemCode",
        CAST(-1 * L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(-1 * L."LineTotal" AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(-1 * L."VatSum" AS DECIMAL(19,6)) AS "SalesVat",
        CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "SalesValueTotal"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"DailyItemSales" AS (
    SELECT
        S."DocDate" AS "ReportDate",
        S."ItemCode",
        CAST(SUM(S."QtyBaseUoM") AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(SUM(S."SalesLineTotal") AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(SUM(S."SalesVat") AS DECIMAL(19,6)) AS "SalesVat",
        CAST(SUM(S."SalesValueTotal") AS DECIMAL(19,6)) AS "SalesValueTotal"
    FROM "SalesLine" S
    GROUP BY
        S."DocDate",
        S."ItemCode"
),
"MonthlyItemSales" AS (
    SELECT
        ADD_DAYS(D."ReportDate", 1 - DAYOFMONTH(D."ReportDate")) AS "ReportDate",
        D."ItemCode",
        CAST(SUM(D."QtyBaseUoM") AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(SUM(D."SalesLineTotal") AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(SUM(D."SalesVat") AS DECIMAL(19,6)) AS "SalesVat",
        CAST(SUM(D."SalesValueTotal") AS DECIMAL(19,6)) AS "SalesValueTotal"
    FROM "DailyItemSales" D
    GROUP BY
        ADD_DAYS(D."ReportDate", 1 - DAYOFMONTH(D."ReportDate")),
        D."ItemCode"
),
"ItemDim" AS (
    SELECT
        I."ItemCode",
        MAX(COALESCE(I."ItemName", 'UNMAPPED')) AS "ItemName",
        MAX(COALESCE(B."ItmsGrpNam", 'UNMAPPED')) AS "Category",
        MAX(COALESCE(I."U_Brand", 'UNMAPPED')) AS "Brand"
    FROM "PPL_LIVE"."OITM" I
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY I."ItemCode"
),
"Ranked" AS (
    SELECT
        M."ReportDate",
        CAST(NULL AS NVARCHAR(50)) AS "BranchCode",
        CAST(NULL AS NVARCHAR(255)) AS "BranchName",
        'COMPANY' AS "Region",
        M."ItemCode",
        COALESCE(I."ItemName", 'UNMAPPED') AS "ItemName",
        COALESCE(I."Category", 'UNMAPPED') AS "Category",
        COALESCE(I."Brand", 'UNMAPPED') AS "Brand",
        M."QtyBaseUoM",
        M."SalesLineTotal",
        M."SalesVat",
        M."SalesValueTotal",
        RANK() OVER (
            PARTITION BY M."ReportDate"
            ORDER BY M."SalesValueTotal" DESC
        ) AS "SalesRank"
    FROM "MonthlyItemSales" M
    LEFT JOIN "ItemDim" I
        ON M."ItemCode" = I."ItemCode"
)
SELECT
    'COMPANY' AS "GrainType",
    R."ReportDate",
    R."BranchCode",
    R."BranchName",
    R."Region",
    R."ItemCode",
    R."ItemName",
    R."Category",
    R."Brand",
    R."QtyBaseUoM",
    R."SalesLineTotal",
    R."SalesVat",
    R."SalesValueTotal",
    R."SalesRank",
    'Y' AS "Top1000Flag",
    CAST(NULL AS DECIMAL(19,6)) AS "RegionSalesValueTotal",
    CAST(NULL AS INTEGER) AS "RegionSalesRank",
    CAST(NULL AS NVARCHAR(1)) AS "Top1000RegionFlag",
    R."SalesValueTotal" AS "CompanySalesValueTotal",
    R."SalesRank" AS "CompanySalesRank",
    'Y' AS "Top1000CompanyFlag"
FROM "Ranked" R
WHERE R."SalesRank" <= 1000
ORDER BY
    R."ReportDate" DESC,
    R."SalesRank",
    R."ItemCode";
