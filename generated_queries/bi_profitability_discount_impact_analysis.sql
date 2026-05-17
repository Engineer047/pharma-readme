CREATE OR REPLACE VIEW "PPL_LIVE"."bi_profitability_discount_impact_analysis" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "Sales",
        CAST((COALESCE(L."Quantity", 0) * COALESCE(L."PriceBefDi", 0)) - COALESCE(L."LineTotal", 0) AS DECIMAL(19,6)) AS "PromoAmount",
        CAST(L."GrssProfit" AS DECIMAL(19,6)) AS "GP_With_Promo"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON L."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE

    UNION ALL

    SELECT
        H."DocDate",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        CAST(-1 * L."LineTotal" AS DECIMAL(19,6)) AS "Sales",
        CAST(-1 * ((COALESCE(L."Quantity", 0) * COALESCE(L."PriceBefDi", 0)) - COALESCE(L."LineTotal", 0)) AS DECIMAL(19,6)) AS "PromoAmount",
        CAST(-1 * L."GrssProfit" AS DECIMAL(19,6)) AS "GP_With_Promo"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON L."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"DailyDiscountSales" AS (
    SELECT
        S."DocDate",
        S."Category",
        SUM(S."Sales") AS "Sales",
        SUM(S."PromoAmount") AS "PromoAmount",
        SUM(S."GP_With_Promo") AS "GP_With_Promo"
    FROM "SalesLine" S
    GROUP BY S."DocDate", S."Category"
)
SELECT
    D."DocDate" AS "ReportDate",
    D."Category",
    D."Sales",
    D."PromoAmount" AS "Promo",
    CASE
        WHEN (D."Sales" + D."PromoAmount") = 0 THEN 0
        ELSE CAST((D."PromoAmount" / (D."Sales" + D."PromoAmount")) * 100 AS DECIMAL(19,6))
    END AS "Discount %",
    D."GP_With_Promo",
    CAST(D."GP_With_Promo" + D."PromoAmount" AS DECIMAL(19,6)) AS "GP_Without_Promo",
    CASE
        WHEN (D."GP_With_Promo" + D."PromoAmount") = 0 THEN 0
        ELSE CAST((D."PromoAmount" / NULLIF(D."GP_With_Promo" + D."PromoAmount", 0)) * 100 AS DECIMAL(19,6))
    END AS "% lost to Discount"
FROM "DailyDiscountSales" D
ORDER BY D."DocDate" DESC, D."Category" ASC;
