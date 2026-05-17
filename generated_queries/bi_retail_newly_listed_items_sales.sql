CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_newly_listed_items_sales" AS
WITH "NewItemsRaw" AS (
    SELECT
        I."ItemCode",
        I."ItemName",
        I."CreateDate" AS "ListDate",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        COALESCE(I."U_Brand", 'UNMAPPED') AS "Brand"
    FROM "PPL_LIVE"."OITM" I
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    WHERE I."CreateDate" >= '2024-01-01'
      AND I."CreateDate" <= CURRENT_DATE
),
"NewItems" AS (
    SELECT
        N."ItemCode",
        MAX(N."ItemName") AS "ItemName",
        MIN(N."ListDate") AS "ListDate",
        MAX(N."Category") AS "Category",
        MAX(N."Brand") AS "Brand"
    FROM "NewItemsRaw" N
    GROUP BY N."ItemCode"
),
"SalesUnion" AS (
    SELECT
        H."DocDate" AS "ReportDate",
        L."WhsCode" AS "BranchCode",
        L."ItemCode",
        CAST(L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(L."VatSum" AS DECIMAL(19,6)) AS "SalesVat",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "SalesValueTotal"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
      AND H."U_CXS_FRST" = 'Y'
      AND H."CANCELED" = 'N'

    UNION ALL

    SELECT
        H."DocDate" AS "ReportDate",
        L."WhsCode" AS "BranchCode",
        L."ItemCode",
        CAST(-1 * L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(-1 * L."LineTotal" AS DECIMAL(19,6)) AS "SalesLineTotal",
        CAST(-1 * L."VatSum" AS DECIMAL(19,6)) AS "SalesVat",
        CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "SalesValueTotal"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
      AND H."U_CXS_FRST" = 'Y'
      AND H."CANCELED" = 'N'
),
"DailyItemSales" AS (
    SELECT
        S."ReportDate",
        S."BranchCode",
        S."ItemCode",
        SUM(S."QtyBaseUoM") AS "QtyBaseUoM",
        SUM(S."SalesLineTotal") AS "SalesLineTotal",
        SUM(S."SalesVat") AS "SalesVat",
        SUM(S."SalesValueTotal") AS "SalesValueTotal"
    FROM "SalesUnion" S
    GROUP BY S."ReportDate", S."BranchCode", S."ItemCode"
),
"BranchMap" AS (
    SELECT
        W."WhsCode" AS "BranchCode",
        MAX(W."WhsName") AS "BranchName"
    FROM "PPL_LIVE"."OWHS" W
    GROUP BY W."WhsCode"
)
SELECT
    S."ReportDate",
    N."ListDate",
    DAYS_BETWEEN(N."ListDate", S."ReportDate") AS "DaysFromListing",
    CASE
        WHEN DAYS_BETWEEN(N."ListDate", S."ReportDate") < 0 THEN 'Pre-Listing'
        WHEN DAYS_BETWEEN(N."ListDate", S."ReportDate") <= 30 THEN '0-30 Days'
        WHEN DAYS_BETWEEN(N."ListDate", S."ReportDate") <= 60 THEN '31-60 Days'
        WHEN DAYS_BETWEEN(N."ListDate", S."ReportDate") <= 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS "ListingStage",
    N."ItemCode",
    N."ItemName",
    N."Category",
    N."Brand",
    S."BranchCode",
    COALESCE(B."BranchName", 'UNMAPPED') AS "BranchName",
    S."QtyBaseUoM",
    S."SalesLineTotal",
    S."SalesVat",
    S."SalesValueTotal"
FROM "DailyItemSales" S
INNER JOIN "NewItems" N
    ON S."ItemCode" = N."ItemCode"
LEFT JOIN "BranchMap" B
    ON S."BranchCode" = B."BranchCode";
