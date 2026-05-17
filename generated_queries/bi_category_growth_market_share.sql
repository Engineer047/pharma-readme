CREATE OR REPLACE VIEW "PPL_LIVE"."bi_category_growth_market_share" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate",
        L."WhsCode" AS "BranchCode",
        L."ItemCode",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "NetSalesInclVAT"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'

    UNION ALL

    SELECT
        H."DocDate",
        L."WhsCode" AS "BranchCode",
        L."ItemCode",
        CAST(-(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "NetSalesInclVAT"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
),
"MonthlyItemSales" AS (
    SELECT
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")) AS "ReportDate",
        S."BranchCode",
        S."ItemCode",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        CAST(SUM(S."NetSalesInclVAT") AS DECIMAL(19,6)) AS "ItemSales"
    FROM "SalesLine" S
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON S."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")),
        S."BranchCode",
        S."ItemCode",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED')
),
"MonthlyCategorySales" AS (
    SELECT
        M."ReportDate",
        M."BranchCode",
        M."Category",
        CAST(SUM(M."ItemSales") AS DECIMAL(19,6)) AS "CategorySales"
    FROM "MonthlyItemSales" M
    GROUP BY M."ReportDate", M."BranchCode", M."Category"
),
"MonthlyBranchSales" AS (
    SELECT
        M."ReportDate",
        M."BranchCode",
        CAST(SUM(M."CategorySales") AS DECIMAL(19,6)) AS "BranchSales"
    FROM "MonthlyCategorySales" M
    GROUP BY M."ReportDate", M."BranchCode"
),
"CategoryGrowth" AS (
    SELECT
        C."ReportDate",
        C."BranchCode",
        C."Category",
        C."CategorySales",
        CAST(
            LAG(C."CategorySales") OVER (
                PARTITION BY C."BranchCode", C."Category"
                ORDER BY C."ReportDate"
            ) AS DECIMAL(19,6)
        ) AS "PrevCategorySales"
    FROM "MonthlyCategorySales" C
),
"BranchGrowth" AS (
    SELECT
        B."ReportDate",
        B."BranchCode",
        B."BranchSales",
        CAST(
            LAG(B."BranchSales") OVER (
                PARTITION BY B."BranchCode"
                ORDER BY B."ReportDate"
            ) AS DECIMAL(19,6)
        ) AS "PrevBranchSales"
    FROM "MonthlyBranchSales" B
),
"NewProductContribution" AS (
    SELECT
        M."ReportDate",
        M."BranchCode",
        M."Category",
        CAST(SUM(
            CASE
                WHEN I."CreateDate" IS NOT NULL
                 AND I."CreateDate" >= ADD_DAYS(LAST_DAY(M."ReportDate"), -90)
                 AND I."CreateDate" <= LAST_DAY(M."ReportDate")
                THEN M."ItemSales"
                ELSE 0
            END
        ) AS DECIMAL(19,6)) AS "NewProductSales"
    FROM "MonthlyItemSales" M
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON M."ItemCode" = I."ItemCode"
    GROUP BY M."ReportDate", M."BranchCode", M."Category"
),
"BranchDim" AS (
    SELECT
        W."WhsCode" AS "BranchCode",
        MAX(W."WhsName") AS "BranchName",
        MAX(COALESCE(L."Location", 'UNMAPPED')) AS "Region"
    FROM "PPL_LIVE"."OWHS" W
    LEFT JOIN "PPL_LIVE"."OLCT" L
        ON W."Location" = L."Code"
    GROUP BY W."WhsCode"
),
"CompetitorBenchmark" AS (
    SELECT
        CAST(NULL AS DATE) AS "ReportDate",
        CAST(NULL AS NVARCHAR(20)) AS "BranchCode",
        CAST(NULL AS NVARCHAR(100)) AS "Category",
        CAST(NULL AS DECIMAL(19,6)) AS "CompetitorSales"
    FROM DUMMY
    WHERE 1 = 0
)
SELECT
    C."ReportDate",
    C."BranchCode",
    COALESCE(BD."BranchName", 'UNMAPPED') AS "BranchName",
    COALESCE(BD."Region", 'UNMAPPED') AS "Region",
    C."Category",

    C."CategorySales",
    B."BranchSales",

    C."PrevCategorySales",
    CAST(C."CategorySales" - COALESCE(C."PrevCategorySales", 0) AS DECIMAL(19,6)) AS "CategoryGrowthValue",
    CASE
        WHEN COALESCE(C."PrevCategorySales", 0) = 0 THEN NULL
        ELSE CAST((C."CategorySales" - C."PrevCategorySales") / NULLIF(C."PrevCategorySales", 0) AS DECIMAL(19,6))
    END AS "CategoryGrowthPct",

    B."PrevBranchSales",
    CAST(B."BranchSales" - COALESCE(B."PrevBranchSales", 0) AS DECIMAL(19,6)) AS "BranchGrowthValue",
    CASE
        WHEN COALESCE(B."PrevBranchSales", 0) = 0 THEN NULL
        ELSE CAST((B."BranchSales" - B."PrevBranchSales") / NULLIF(B."PrevBranchSales", 0) AS DECIMAL(19,6))
    END AS "BranchGrowthPct",

    CASE
        WHEN COALESCE(B."PrevBranchSales", 0) = 0 THEN NULL
        WHEN COALESCE(C."PrevCategorySales", 0) = 0 THEN NULL
        ELSE CAST(
            ((C."CategorySales" - C."PrevCategorySales") / NULLIF(C."PrevCategorySales", 0))
            -
            ((B."BranchSales" - B."PrevBranchSales") / NULLIF(B."PrevBranchSales", 0))
            AS DECIMAL(19,6)
        )
    END AS "InternalCategoryVsBranchGrowthPct",

    CASE
        WHEN B."BranchSales" = 0 THEN 0
        ELSE CAST((C."CategorySales" / NULLIF(B."BranchSales", 0)) * 100 AS DECIMAL(19,6))
    END AS "CategorySharePct",

    COALESCE(N."NewProductSales", 0) AS "NewProductSales",
    CASE
        WHEN C."CategorySales" = 0 THEN 0
        ELSE CAST((COALESCE(N."NewProductSales", 0) / NULLIF(C."CategorySales", 0)) * 100 AS DECIMAL(19,6))
    END AS "NewProductContributionPct",
    CASE
        WHEN (C."CategorySales" - COALESCE(C."PrevCategorySales", 0)) = 0 THEN NULL
        ELSE CAST(
            COALESCE(N."NewProductSales", 0)
            / NULLIF((C."CategorySales" - COALESCE(C."PrevCategorySales", 0)), 0)
            AS DECIMAL(19,6)
        )
    END AS "NewProductContributionToGrowthRatio",

    CB."CompetitorSales",
    CASE
        WHEN COALESCE(CB."CompetitorSales", 0) = 0 AND C."CategorySales" = 0 THEN NULL
        ELSE CAST(
            (C."CategorySales" / NULLIF(C."CategorySales" + COALESCE(CB."CompetitorSales", 0), 0)) * 100
            AS DECIMAL(19,6)
        )
    END AS "InternalVsCompetitorSharePct",
    CASE
        WHEN B."BranchSales" = 0 THEN NULL
        WHEN COALESCE(CB."CompetitorSales", 0) = 0 AND C."CategorySales" = 0 THEN NULL
        ELSE CAST(
            ((C."CategorySales" / NULLIF(B."BranchSales", 0)) * 100)
            -
            ((C."CategorySales" / NULLIF(C."CategorySales" + COALESCE(CB."CompetitorSales", 0), 0)) * 100)
            AS DECIMAL(19,6)
        )
    END AS "CategoryShareBenchmarkGapPct"
FROM "CategoryGrowth" C
INNER JOIN "BranchGrowth" B
    ON C."ReportDate" = B."ReportDate"
   AND C."BranchCode" = B."BranchCode"
LEFT JOIN "NewProductContribution" N
    ON C."ReportDate" = N."ReportDate"
   AND C."BranchCode" = N."BranchCode"
   AND C."Category" = N."Category"
LEFT JOIN "BranchDim" BD
    ON C."BranchCode" = BD."BranchCode"
LEFT JOIN "CompetitorBenchmark" CB
    ON C."ReportDate" = CB."ReportDate"
   AND C."BranchCode" = CB."BranchCode"
   AND C."Category" = CB."Category"
WHERE C."BranchCode" NOT LIKE 'INT-%'
ORDER BY C."ReportDate" DESC, C."BranchCode", C."Category";

