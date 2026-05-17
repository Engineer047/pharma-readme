CREATE OR REPLACE VIEW "PPL_LIVE"."bi_product_mix_pricing_analysis" AS
WITH "SalesLine" AS (
    SELECT
        T0."DocDate",
        T1."ItemCode",
        T1."WhsCode" AS "BranchCode",
        CAST(T1."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(T1."LineTotal" AS DECIMAL(19,6)) AS "LineTotal",
        CAST(T1."VatSum" AS DECIMAL(19,6)) AS "VatSum",
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
        T1."ItemCode",
        T1."WhsCode",
        -1 * CAST(T1."InvQty" AS DECIMAL(19,6)),
        -1 * CAST(T1."LineTotal" AS DECIMAL(19,6)),
        -1 * CAST(T1."VatSum" AS DECIMAL(19,6)),
        -1 * CAST(T1."LineTotal" + T1."VatSum" AS DECIMAL(19,6))
    FROM "PPL_LIVE"."ORIN" T0
    INNER JOIN "PPL_LIVE"."RIN1" T1 ON T0."DocEntry" = T1."DocEntry"
    WHERE T0."DocDate" >= '2024-01-01'
      AND T0."DocDate" <= CURRENT_DATE
      AND T0."U_CXS_FRST" = 'Y'
      AND T0."CANCELED" = 'N'
),

/* DAILY SALES - SINGLE SOURCE OF TRUTH */
"DailySales" AS (
    SELECT
        S."DocDate",
        S."BranchCode",
        S."ItemCode",
        SUM(S."QtyBaseUoM") AS "QtyBaseUoM",
        SUM(S."LineTotal") AS "SalesLineTotal",
        SUM(S."VatSum") AS "SalesVat",
        SUM(S."SalesValueTotal") AS "SalesValueTotal"
    FROM "SalesLine" S
    GROUP BY
        S."DocDate",
        S."BranchCode",
        S."ItemCode"
),

/* INVENTORY - ONE ROW PER BRANCH + ITEM */
"InventoryCurrent" AS (
    SELECT
        T0."Warehouse" AS "BranchCode",
        T0."ItemCode",
        SUM(T0."InQty" - T0."OutQty") AS "OnHandQty",
        SUM(T0."TransValue") / 2 AS "StockValue"
    FROM "PPL_LIVE"."OINM" T0
    GROUP BY
        T0."Warehouse",
        T0."ItemCode"
    HAVING
        SUM(T0."InQty" - T0."OutQty") <> 0
        AND SUM(T0."TransValue") <> 0
)

SELECT
    D."DocDate",
    D."BranchCode",
    W."WhsName" AS "BranchName",
    COALESCE(L."Location", 'UNMAPPED') AS "Region",
    D."ItemCode",
    I."ItemName",
    B."ItmsGrpNam" AS "Category",
    I."U_Brand" AS "Brand",
    I."U_SubCat1" AS "SubCategory1",
    I."U_SubCat2" AS "SubCategory2",
    I."U_SubCat3" AS "SubCategory3",
    I."U_Formulation" AS "Formulation",
    D."QtyBaseUoM",
    D."SalesLineTotal",
    D."SalesVat",
    D."SalesValueTotal",
    CASE
        WHEN D."QtyBaseUoM" = 0 THEN NULL
        ELSE D."SalesValueTotal" / D."QtyBaseUoM"
    END AS "AvgSellingPrice",
    IC."OnHandQty",
    IC."StockValue",
    CASE
        WHEN COALESCE(IC."StockValue", 0) = 0 THEN NULL
        ELSE D."SalesValueTotal" / IC."StockValue"
    END AS "SalesVsHoldingValue",
    CASE
        WHEN COALESCE(IC."OnHandQty", 0) = 0 THEN NULL
        ELSE D."QtyBaseUoM" / IC."OnHandQty"
    END AS "SalesVsHoldingQty"
FROM "DailySales" D
LEFT JOIN "InventoryCurrent" IC
    ON D."BranchCode" = IC."BranchCode"
   AND D."ItemCode" = IC."ItemCode"
LEFT JOIN "PPL_LIVE"."OWHS" W ON D."BranchCode" = W."WhsCode"
LEFT JOIN "PPL_LIVE"."OLCT" L ON W."Location" = L."Code"
LEFT JOIN "PPL_LIVE"."OITM" I ON D."ItemCode" = I."ItemCode"
LEFT JOIN "PPL_LIVE"."OITB" B ON I."ItmsGrpCod" = B."ItmsGrpCod";
