CREATE OR REPLACE VIEW "PPL_LIVE"."bi_availability_report" AS
WITH "ItemBase" AS (
    SELECT
        I."ItemCode",
        I."ItemName",
        I."UgpEntry",
        COALESCE(NULLIF(I."NumInBuy", 0), 1) AS "NumInBuy",
        I."CardCode" AS "PreferredVendorCode"
    FROM "PPL_LIVE"."OITM" I
),
"SalesLines" AS (
    SELECT
        H."DocDate",
        L."ItemCode",
        CAST(L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseSigned"
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
        L."ItemCode",
        CAST(-1 * L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseSigned"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"SalesNormalized" AS (
    SELECT
        S."DocDate",
        S."ItemCode",
        CAST(S."QtyBaseSigned" AS DECIMAL(19,6)) AS "Qty Pieces",
        CAST(S."QtyBaseSigned" / COALESCE(NULLIF(I."NumInBuy", 0), 1) AS DECIMAL(19,6)) AS "Qty Whole"
    FROM "SalesLines" S
    INNER JOIN "ItemBase" I
        ON S."ItemCode" = I."ItemCode"
),
"SalesDailyItem" AS (
    SELECT
        N."DocDate",
        N."ItemCode",
        SUM(N."Qty Whole") AS "Qty Whole Sales",
        SUM(N."Qty Pieces") AS "Qty Pieces Sales"
    FROM "SalesNormalized" N
    GROUP BY N."DocDate", N."ItemCode"
),
"HQStock" AS (
    SELECT
        W."ItemCode",
        CAST(SUM(W."OnHand") / NULLIF(MAX(I."NumInBuy"), 0) AS DECIMAL(19,6)) AS "Qty Whole Whs"
    FROM "PPL_LIVE"."OITW" W
    INNER JOIN "ItemBase" I
        ON W."ItemCode" = I."ItemCode"
    WHERE W."WhsCode" = 'HQ-MAIN'
    GROUP BY W."ItemCode"
),
"UomGroup" AS (
    SELECT
        G."UgpEntry",
        MAX(G."UgpName") AS "UOM Group"
    FROM "PPL_LIVE"."OUGP" G
    GROUP BY G."UgpEntry"
)
SELECT
    'COMPANYWISE' AS "WhsCode",
    S."DocDate",
    S."ItemCode",
    I."ItemName",
    COALESCE(U."UOM Group", 'UNMAPPED') AS "UOM Group",
    S."Qty Whole Sales",
    S."Qty Pieces Sales",
    COALESCE(H."Qty Whole Whs", 0) AS "Qty Whole Whs",
    CAST(COALESCE(H."Qty Whole Whs", 0) - S."Qty Whole Sales" AS DECIMAL(19,6)) AS "Difference",
    COALESCE(V."CardCode", 'UNMAPPED') AS "Preferred Vendor Code",
    COALESCE(V."CardName", 'UNMAPPED') AS "Preferred Vendor Name"
FROM "SalesDailyItem" S
INNER JOIN "ItemBase" I
    ON S."ItemCode" = I."ItemCode"
LEFT JOIN "UomGroup" U
    ON I."UgpEntry" = U."UgpEntry"
LEFT JOIN "HQStock" H
    ON S."ItemCode" = H."ItemCode"
LEFT JOIN "PPL_LIVE"."OCRD" V
    ON I."PreferredVendorCode" = V."CardCode"
ORDER BY "Qty Pieces Sales" DESC;
