CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_channel_sales_report" AS
WITH
"SalesLine" AS (
    SELECT
        H."DocDate",
        L."WhsCode",
        W."WhsName" AS "BranchName",
        COALESCE(R."Location", 'UNMAPPED') AS "Region",
        L."ItemCode",
        H."CardCode",
        H."CardName",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "LineTotal",
        CAST(L."VatSum" AS DECIMAL(19,6)) AS "VatSum",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "NetSalesInclVAT"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "PPL_LIVE"."OWHS" W ON L."WhsCode" = W."WhsCode"
    LEFT JOIN "PPL_LIVE"."OLCT" R ON W."Location" = R."Code"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'

    UNION ALL

    SELECT
        H."DocDate",
        L."WhsCode",
        W."WhsName" AS "BranchName",
        COALESCE(R."Location", 'UNMAPPED') AS "Region",
        L."ItemCode",
        H."CardCode",
        H."CardName",
        CAST(-1 * L."LineTotal" AS DECIMAL(19,6)) AS "LineTotal",
        CAST(-1 * L."VatSum" AS DECIMAL(19,6)) AS "VatSum",
        CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "NetSalesInclVAT"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "PPL_LIVE"."OWHS" W ON L."WhsCode" = W."WhsCode"
    LEFT JOIN "PPL_LIVE"."OLCT" R ON W."Location" = R."Code"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
),
"SalesLineTagged" AS (
    SELECT
        S."DocDate",
        S."WhsCode",
        S."BranchName",
        S."Region",
        S."ItemCode",
        CASE
            WHEN UPPER(COALESCE(C."CardName", S."CardName", '')) LIKE '%GLOVO%' THEN 'Glovo'
            WHEN UPPER(COALESCE(C."CardName", S."CardName", '')) LIKE '%UBER%' THEN 'Uber Eats'
            WHEN UPPER(COALESCE(C."CardName", S."CardName", '')) LIKE '%WHATSAPP%' THEN 'Whatsapp'
            WHEN UPPER(COALESCE(C."CardName", S."CardName", '')) LIKE '%KPA%' THEN 'KPA'
            WHEN UPPER(COALESCE(C."CardName", S."CardName", '')) LIKE '%KPC%' THEN 'KPC'
            WHEN UPPER(COALESCE(C."CardName", S."CardName", '')) LIKE '%ECOM%' THEN 'E-Commerce'
            ELSE 'Retail/Other'
        END AS "Channel",
        S."LineTotal",
        S."VatSum",
        S."NetSalesInclVAT"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OCRD" C ON S."CardCode" = C."CardCode"
),
"DailyItemSales" AS (
    SELECT
        S."DocDate",
        S."WhsCode",
        S."ItemCode",
        SUM(S."NetSalesInclVAT") AS "ItemDailyNetSales"
    FROM "SalesLine" S
    GROUP BY S."DocDate", S."WhsCode", S."ItemCode"
),
"CurrentInventory" AS (
    SELECT
        T0."Warehouse" AS "WhsCode",
        T0."ItemCode",
        SUM(T0."TransValue") / 2 AS "Inventory_Value"
    FROM "PPL_LIVE"."OINM" T0
    GROUP BY T0."Warehouse", T0."ItemCode"
    HAVING SUM(T0."InQty" - T0."OutQty") <> 0
       AND SUM(T0."TransValue") <> 0
),
"DailyItemSnapshot" AS (
    SELECT
        D."DocDate",
        D."WhsCode",
        D."ItemCode",
        D."ItemDailyNetSales",
        COALESCE(I."Inventory_Value", 0) AS "Inventory_Value"
    FROM "DailyItemSales" D
    LEFT JOIN "CurrentInventory" I
        ON D."WhsCode" = I."WhsCode"
       AND D."ItemCode" = I."ItemCode"
),
"Allocated" AS (
    SELECT
        C."DocDate",
        C."WhsCode",
        C."BranchName",
        C."Region",
        C."Channel",
        C."LineTotal",
        C."VatSum",
        C."NetSalesInclVAT",
        CASE
            WHEN S."ItemDailyNetSales" = 0 THEN 0
            ELSE S."Inventory_Value" * (C."NetSalesInclVAT" / S."ItemDailyNetSales")
        END AS "InventoryValue"
    FROM "SalesLineTagged" C
    INNER JOIN "DailyItemSnapshot" S
        ON C."DocDate"  = S."DocDate"
       AND C."WhsCode"  = S."WhsCode"
       AND C."ItemCode" = S."ItemCode"
),
"DailyChannel" AS (
    SELECT
        A."DocDate" AS "ReportDate",
        A."WhsCode" AS "BranchCode",
        A."BranchName",
        A."Region",
        A."Channel",
        SUM(A."LineTotal") AS "SalesLineTotal",
        SUM(A."VatSum") AS "SalesVat",
        SUM(A."NetSalesInclVAT") AS "SalesValueTotal",
        SUM(A."InventoryValue") AS "InventoryValue"
    FROM "Allocated" A
    GROUP BY A."DocDate", A."WhsCode", A."BranchName", A."Region", A."Channel"
),
"WithLag" AS (
    SELECT
        D.*,
        LAG(D."SalesValueTotal") OVER (
            PARTITION BY D."BranchCode", D."Channel"
            ORDER BY D."ReportDate"
        ) AS "PrevSalesValue"
    FROM "DailyChannel" D
)
SELECT
    "ReportDate",
    "BranchCode",
    "BranchName",
    "Region",
    "Channel",
    "SalesLineTotal",
    "SalesVat",
    "SalesValueTotal",
    "InventoryValue",
    "PrevSalesValue",
    CAST("SalesValueTotal" - COALESCE("PrevSalesValue", 0) AS DECIMAL(19,6)) AS "SalesValueDelta",
    CASE WHEN COALESCE("PrevSalesValue", 0) = 0 THEN NULL ELSE CAST(("SalesValueTotal" - "PrevSalesValue") / "PrevSalesValue" AS DECIMAL(19,6)) END AS "SalesValueDeltaPct"
FROM "WithLag";
