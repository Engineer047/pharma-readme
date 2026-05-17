CREATE OR REPLACE VIEW "PPL_LIVE"."bi_inventory_stock_health" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate",
        L."WhsCode",
        L."ItemCode",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "SalesValue"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2025-01-01'
      AND H."DocDate" <= CURRENT_DATE

    UNION ALL

    SELECT
        H."DocDate",
        L."WhsCode",
        L."ItemCode",
        CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "SalesValue"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2025-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"DailySales" AS (
    SELECT
        S."DocDate" AS "As_At_Date",
        S."WhsCode",
        S."ItemCode",
        CAST(SUM(S."SalesValue") AS DECIMAL(19,6)) AS "Sales_Value"
    FROM "SalesLine" S
    GROUP BY S."DocDate", S."WhsCode", S."ItemCode"
),
"CurrentInventory" AS (
    SELECT
        T0."Warehouse" AS "WhsCode",
        T0."ItemCode",
        CAST(SUM(T0."InQty" - T0."OutQty") AS DECIMAL(19,6)) AS "SOH",
        CAST(SUM(T0."TransValue") AS DECIMAL(19,6)) AS "Inventory_Value"
    FROM "PPL_LIVE"."OINM" T0
    WHERE T0."DocDate" <= CURRENT_DATE
    GROUP BY T0."Warehouse", T0."ItemCode"
    HAVING SUM(T0."InQty" - T0."OutQty") <> 0
       AND SUM(T0."TransValue") <> 0
),
"ItemDaily" AS (
    SELECT
        D."As_At_Date",
        D."WhsCode",
        D."ItemCode",
        D."Sales_Value",
        COALESCE(I."SOH", 0) AS "SOH",
        COALESCE(I."Inventory_Value", 0) AS "Inventory_Value"
    FROM "DailySales" D
    LEFT JOIN "CurrentInventory" I
        ON D."WhsCode" = I."WhsCode"
       AND D."ItemCode" = I."ItemCode"
)
SELECT
    D."As_At_Date",
    W."WhsCode",
    W."WhsName" AS "Branch",
    D."ItemCode",
    COALESCE(I."ItemName", 'UNMAPPED') AS "ItemName",
    COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
    COALESCE(I."U_ActiveIngredient", 'UNMAPPED') AS "Molecule",
    D."Sales_Value",
    D."SOH",
    D."Inventory_Value",
    CASE
        WHEN D."Sales_Value" <= 0 THEN 0
        ELSE CAST(D."Inventory_Value" / NULLIF(D."Sales_Value", 0) AS DECIMAL(19,6))
    END AS "Days_of_Stock",
    CASE
        WHEN D."Sales_Value" <= 0 AND D."Inventory_Value" > 0 THEN 'GREEN'
        WHEN D."Inventory_Value" <= (D."Sales_Value" * 7) THEN 'RED'
        WHEN D."Inventory_Value" <= (D."Sales_Value" * 14) THEN 'AMBER'
        ELSE 'GREEN'
    END AS "Stock_Status",
    CASE
        WHEN I."U_Essentials" = 'Y' AND D."SOH" > 0 THEN 'AVAILABLE'
        WHEN I."U_Essentials" = 'Y' AND D."SOH" <= 0 THEN 'NOT AVAILABLE'
        ELSE NULL
    END AS "Essential_Molecule_Status"
FROM "ItemDaily" D
INNER JOIN "PPL_LIVE"."OWHS" W
    ON D."WhsCode" = W."WhsCode"
LEFT JOIN "PPL_LIVE"."OITM" I
    ON D."ItemCode" = I."ItemCode"
LEFT JOIN "PPL_LIVE"."OITB" B
    ON I."ItmsGrpCod" = B."ItmsGrpCod"
WHERE W."WhsCode" NOT LIKE 'INT-%'
  AND D."As_At_Date" >= '2025-01-01'
ORDER BY D."As_At_Date" DESC, "Branch", D."ItemCode";
