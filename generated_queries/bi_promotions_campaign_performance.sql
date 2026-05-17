CREATE OR REPLACE VIEW "PPL_LIVE"."bi_promotions_campaign_performance" AS
WITH "BaseInvLine" AS (
    SELECT
        L."DocEntry",
        L."LineNum",
        COALESCE(NULLIF(TRIM(L."Project"), ''), NULLIF(TRIM(H."Project"), ''), '') AS "ProjectCodeRaw",
        COALESCE(L."DiscPrcnt", 0) AS "LineDiscPct"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"SalesLine" AS (
    SELECT
        H."DocDate",
        L."WhsCode",
        L."ItemCode",
        COALESCE(NULLIF(TRIM(L."Project"), ''), NULLIF(TRIM(H."Project"), ''), '') AS "ProjectCodeRaw",
        CAST(L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "NetSales",
        CAST(L."Quantity" * L."PriceBefDi" AS DECIMAL(19,6)) AS "GrossBeforeDiscount",
        CAST((L."Quantity" * L."PriceBefDi") - L."LineTotal" AS DECIMAL(19,6)) AS "DiscountAmount",
        CASE
            WHEN COALESCE(NULLIF(TRIM(L."Project"), ''), NULLIF(TRIM(H."Project"), ''), '') <> '' THEN 1
            WHEN COALESCE(L."DiscPrcnt", 0) <> 0 THEN 1
            ELSE 0
        END AS "IsPromoLine"
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
        L."WhsCode",
        L."ItemCode",
        COALESCE(
            NULLIF(TRIM(L."Project"), ''),
            NULLIF(TRIM(H."Project"), ''),
            B."ProjectCodeRaw",
            ''
        ) AS "ProjectCodeRaw",
        CAST(-1 * L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "NetSales",
        CAST(-1 * (L."Quantity" * L."PriceBefDi") AS DECIMAL(19,6)) AS "GrossBeforeDiscount",
        CAST(-1 * ((L."Quantity" * L."PriceBefDi") - L."LineTotal") AS DECIMAL(19,6)) AS "DiscountAmount",
        CASE
            WHEN COALESCE(
                NULLIF(TRIM(L."Project"), ''),
                NULLIF(TRIM(H."Project"), ''),
                B."ProjectCodeRaw",
                ''
            ) <> '' THEN 1
            WHEN COALESCE(L."DiscPrcnt", 0) <> 0 THEN 1
            WHEN COALESCE(B."LineDiscPct", 0) <> 0 THEN 1
            ELSE 0
        END AS "IsPromoLine"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "BaseInvLine" B
        ON L."BaseType" = 13
       AND L."BaseEntry" = B."DocEntry"
       AND L."BaseLine" = B."LineNum"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"TaggedLine" AS (
    SELECT
        S."DocDate",
        S."WhsCode",
        S."ItemCode",
        CASE
            WHEN S."ProjectCodeRaw" <> '' THEN S."ProjectCodeRaw"
            WHEN S."IsPromoLine" = 1 THEN 'DISCOUNT_ONLY'
            ELSE 'NO_PROMO'
        END AS "CampaignCode",
        CASE
            WHEN S."ProjectCodeRaw" = '' AND S."IsPromoLine" = 0 THEN 'NO_PROMO'
            WHEN UPPER(S."ProjectCodeRaw") LIKE 'SUP%'
              OR UPPER(S."ProjectCodeRaw") LIKE '%SUPPLIER%'
              OR UPPER(S."ProjectCodeRaw") LIKE '%VENDOR%'
            THEN 'SUPPLIER_FUNDED'
            ELSE 'RETAILER_FUNDED'
        END AS "FundingType",
        S."QtyBaseUoM",
        S."NetSales",
        S."GrossBeforeDiscount",
        S."DiscountAmount",
        S."IsPromoLine"
    FROM "SalesLine" S
),
"PromoCampaignDaily" AS (
    SELECT
        T."DocDate" AS "ReportDate",
        T."WhsCode",
        T."ItemCode",
        T."CampaignCode",
        T."FundingType",
        CAST(SUM(T."QtyBaseUoM") AS DECIMAL(19,6)) AS "PromoQty",
        CAST(SUM(T."NetSales") AS DECIMAL(19,6)) AS "PromoSales",
        CAST(SUM(T."GrossBeforeDiscount") AS DECIMAL(19,6)) AS "PromoGrossBeforeDiscount",
        CAST(SUM(T."DiscountAmount") AS DECIMAL(19,6)) AS "PromoDiscount"
    FROM "TaggedLine" T
    WHERE T."IsPromoLine" = 1
    GROUP BY
        T."DocDate",
        T."WhsCode",
        T."ItemCode",
        T."CampaignCode",
        T."FundingType"
),
"DailyNonPromo" AS (
    SELECT
        T."DocDate",
        T."WhsCode",
        T."ItemCode",
        CAST(SUM(T."QtyBaseUoM") AS DECIMAL(19,6)) AS "NonPromoQty",
        CAST(SUM(T."NetSales") AS DECIMAL(19,6)) AS "NonPromoSales"
    FROM "TaggedLine" T
    WHERE T."IsPromoLine" = 0
    GROUP BY T."DocDate", T."WhsCode", T."ItemCode"
),
"Baseline30" AS (
    SELECT
        K."ReportDate",
        K."WhsCode",
        K."ItemCode",
        CAST(COALESCE(SUM(N."NonPromoQty"), 0) / 30 AS DECIMAL(19,6)) AS "BaselineQty",
        CAST(COALESCE(SUM(N."NonPromoSales"), 0) / 30 AS DECIMAL(19,6)) AS "BaselineSales"
    FROM (
        SELECT DISTINCT
            P."ReportDate",
            P."WhsCode",
            P."ItemCode"
        FROM "PromoCampaignDaily" P
    ) K
    LEFT JOIN "DailyNonPromo" N
        ON N."WhsCode" = K."WhsCode"
       AND N."ItemCode" = K."ItemCode"
       AND N."DocDate" >= ADD_DAYS(K."ReportDate", -30)
       AND N."DocDate" < K."ReportDate"
    GROUP BY K."ReportDate", K."WhsCode", K."ItemCode"
),
"BranchDim" AS (
    SELECT
        W."WhsCode",
        MAX(W."WhsName") AS "BranchName",
        MAX(COALESCE(L."Location", 'UNMAPPED')) AS "Region"
    FROM "PPL_LIVE"."OWHS" W
    LEFT JOIN "PPL_LIVE"."OLCT" L
        ON W."Location" = L."Code"
    GROUP BY W."WhsCode"
),
"ItemDim" AS (
    SELECT
        I."ItemCode",
        MAX(COALESCE(I."ItemName", 'UNMAPPED')) AS "ItemName",
        MAX(COALESCE(B."ItmsGrpNam", 'UNMAPPED')) AS "Category",
        MAX(COALESCE(I."CardCode", 'UNMAPPED')) AS "SupplierCode",
        MAX(COALESCE(S."CardName", 'UNMAPPED')) AS "SupplierName"
    FROM "PPL_LIVE"."OITM" I
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    LEFT JOIN "PPL_LIVE"."OCRD" S
        ON I."CardCode" = S."CardCode"
    GROUP BY I."ItemCode"
)
SELECT
    P."ReportDate",
    P."CampaignCode",
    P."FundingType",
    P."WhsCode" AS "BranchCode",
    COALESCE(BD."BranchName", 'UNMAPPED') AS "BranchName",
    COALESCE(BD."Region", 'UNMAPPED') AS "Region",
    P."ItemCode",
    COALESCE(ID."ItemName", 'UNMAPPED') AS "ItemName",
    COALESCE(ID."Category", 'UNMAPPED') AS "Category",
    COALESCE(ID."SupplierCode", 'UNMAPPED') AS "SupplierCode",
    COALESCE(ID."SupplierName", 'UNMAPPED') AS "SupplierName",

    P."PromoQty",
    COALESCE(BL."BaselineQty", 0) AS "BaselineQty",
    CAST(P."PromoQty" - COALESCE(BL."BaselineQty", 0) AS DECIMAL(19,6)) AS "UpliftQty",
    CASE
        WHEN COALESCE(BL."BaselineQty", 0) = 0 THEN NULL
        ELSE CAST((P."PromoQty" - BL."BaselineQty") / BL."BaselineQty" AS DECIMAL(19,6))
    END AS "UpliftQtyPct",

    P."PromoSales",
    COALESCE(BL."BaselineSales", 0) AS "BaselineSales",
    CAST(P."PromoSales" - COALESCE(BL."BaselineSales", 0) AS DECIMAL(19,6)) AS "UpliftSales",
    CASE
        WHEN COALESCE(BL."BaselineSales", 0) = 0 THEN NULL
        ELSE CAST((P."PromoSales" - BL."BaselineSales") / BL."BaselineSales" AS DECIMAL(19,6))
    END AS "UpliftSalesPct",

    P."PromoGrossBeforeDiscount",
    P."PromoDiscount" AS "PromoCost",
    CASE
        WHEN P."PromoDiscount" = 0 THEN NULL
        ELSE CAST(((P."PromoSales" - COALESCE(BL."BaselineSales", 0)) - P."PromoDiscount") / P."PromoDiscount" AS DECIMAL(19,6))
    END AS "PromoROI",

    CASE WHEN P."FundingType" = 'SUPPLIER_FUNDED' THEN P."PromoSales" ELSE 0 END AS "SupplierFundedPromoSales",
    CASE WHEN P."FundingType" = 'SUPPLIER_FUNDED' THEN P."PromoDiscount" ELSE 0 END AS "SupplierFundedPromoCost",
    CASE WHEN P."FundingType" = 'RETAILER_FUNDED' THEN P."PromoSales" ELSE 0 END AS "RetailerFundedPromoSales",
    CASE WHEN P."FundingType" = 'RETAILER_FUNDED' THEN P."PromoDiscount" ELSE 0 END AS "RetailerFundedPromoCost"

FROM "PromoCampaignDaily" P
LEFT JOIN "Baseline30" BL
    ON P."ReportDate" = BL."ReportDate"
   AND P."WhsCode" = BL."WhsCode"
   AND P."ItemCode" = BL."ItemCode"
LEFT JOIN "BranchDim" BD
    ON P."WhsCode" = BD."WhsCode"
LEFT JOIN "ItemDim" ID
    ON P."ItemCode" = ID."ItemCode"
WHERE P."CampaignCode" <> 'NO_PROMO'
  AND P."WhsCode" NOT LIKE 'INT-%'
  AND P."WhsCode" NOT LIKE 'HQ-%'
ORDER BY P."ReportDate" DESC, P."CampaignCode", P."WhsCode", P."ItemCode";
