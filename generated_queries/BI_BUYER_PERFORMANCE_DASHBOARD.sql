CREATE OR REPLACE VIEW "PPL_LIVE"."BI_BUYER_PERFORMANCE_DASHBOARD" AS
WITH "PurchaseActualLine" AS (
    SELECT
        ADD_DAYS(H."DocDate", 1 - DAYOFMONTH(H."DocDate")) AS "ReportDate",
        CAST(H."UserSign" AS NVARCHAR(20)) AS "BuyerCode",
        COALESCE(U."U_NAME", 'UNASSIGNED') AS "BuyerName",
        L."ItemCode",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "PurchaseSpend",
        CAST(
            (COALESCE(L."Quantity", 0) * COALESCE(L."PriceBefDi", L."Price", 0))
            -
            (COALESCE(L."Quantity", 0) * COALESCE(L."Price", 0))
            AS DECIMAL(19,6)
        ) AS "DiscountSavings",
        CAST(
            (COALESCE(L."Quantity", 0) * COALESCE(L."Price", 0)) * COALESCE(H."DiscPrcnt", 0) / 100
            AS DECIMAL(19,6)
        ) AS "RebateSavings",
        CAST(
            COALESCE(L."LineTotal", 0) * COALESCE(T."ExtraDays", 0) * 0.18 / 365
            AS DECIMAL(19,6)
        ) AS "CreditTermSavings"
    FROM "PPL_LIVE"."OPCH" H
    INNER JOIN "PPL_LIVE"."PCH1" L
        ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "PPL_LIVE"."OUSR" U
        ON H."UserSign" = U."USERID"
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON L."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    LEFT JOIN "PPL_LIVE"."OCTG" T
        ON H."GroupNum" = T."GroupNum"
    WHERE H."CANCELED" = 'N'
      AND H."DocDate" >= '2024-01-01'
),
"PurchaseActualMonthly" AS (
    SELECT
        P."ReportDate",
        P."BuyerCode",
        P."BuyerName",
        P."Category",
        CAST(SUM(P."PurchaseSpend") AS DECIMAL(19,6)) AS "ActualPurchaseSpend",
        CAST(SUM(P."DiscountSavings") AS DECIMAL(19,6)) AS "DiscountSavings",
        CAST(SUM(P."RebateSavings") AS DECIMAL(19,6)) AS "RebateSavings",
        CAST(SUM(P."CreditTermSavings") AS DECIMAL(19,6)) AS "CreditTermSavings"
    FROM "PurchaseActualLine" P
    GROUP BY P."ReportDate", P."BuyerCode", P."BuyerName", P."Category"
),
"PurchaseBudgetMonthly" AS (
    SELECT
        ADD_DAYS(H."DocDate", 1 - DAYOFMONTH(H."DocDate")) AS "ReportDate",
        CAST(H."UserSign" AS NVARCHAR(20)) AS "BuyerCode",
        COALESCE(U."U_NAME", 'UNASSIGNED') AS "BuyerName",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        CAST(SUM(L."LineTotal") AS DECIMAL(19,6)) AS "PurchaseBudget"
    FROM "PPL_LIVE"."OPOR" H
    INNER JOIN "PPL_LIVE"."POR1" L
        ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "PPL_LIVE"."OUSR" U
        ON H."UserSign" = U."USERID"
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON L."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    WHERE H."CANCELED" = 'N'
      AND H."DocDate" >= '2024-01-01'
    GROUP BY
        ADD_DAYS(H."DocDate", 1 - DAYOFMONTH(H."DocDate")),
        CAST(H."UserSign" AS NVARCHAR(20)),
        COALESCE(U."U_NAME", 'UNASSIGNED'),
        COALESCE(B."ItmsGrpNam", 'UNMAPPED')
),
"SalesCategoryMonthly" AS (
    SELECT
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")) AS "ReportDate",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        CAST(SUM(S."SalesValue") AS DECIMAL(19,6)) AS "CategorySalesValue",
        CAST(SUM(S."GrossProfit") AS DECIMAL(19,6)) AS "CategoryGrossProfit"
    FROM (
        SELECT
            H."DocDate",
            L."ItemCode",
            CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "SalesValue",
            CAST(L."GrssProfit" AS DECIMAL(19,6)) AS "GrossProfit"
        FROM "PPL_LIVE"."OINV" H
        INNER JOIN "PPL_LIVE"."INV1" L
            ON H."DocEntry" = L."DocEntry"
        WHERE H."CANCELED" = 'N'
          AND H."U_CXS_FRST" = 'Y'
          AND H."DocDate" >= '2024-01-01'

        UNION ALL

        SELECT
            H."DocDate",
            L."ItemCode",
            CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "SalesValue",
            CAST(-1 * L."GrssProfit" AS DECIMAL(19,6)) AS "GrossProfit"
        FROM "PPL_LIVE"."ORIN" H
        INNER JOIN "PPL_LIVE"."RIN1" L
            ON H."DocEntry" = L."DocEntry"
        WHERE H."CANCELED" = 'N'
          AND H."U_CXS_FRST" = 'Y'
          AND H."DocDate" >= '2024-01-01'
    ) S
    LEFT JOIN "PPL_LIVE"."OITM" I
        ON S."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY
        ADD_DAYS(S."DocDate", 1 - DAYOFMONTH(S."DocDate")),
        COALESCE(B."ItmsGrpNam", 'UNMAPPED')
),
"CategorySpendMonthly" AS (
    SELECT
        A."ReportDate",
        A."Category",
        CAST(SUM(A."ActualPurchaseSpend") AS DECIMAL(19,6)) AS "CategoryTotalPurchaseSpend"
    FROM "PurchaseActualMonthly" A
    GROUP BY A."ReportDate", A."Category"
),
"BuyerPortfolioPerf" AS (
    SELECT
        A."ReportDate",
        A."BuyerCode",
        A."BuyerName",
        A."Category",
        A."ActualPurchaseSpend",
        A."DiscountSavings",
        A."RebateSavings",
        A."CreditTermSavings",
        CAST(
            A."DiscountSavings" + A."RebateSavings" + A."CreditTermSavings"
            AS DECIMAL(19,6)
        ) AS "TotalNegotiationSavings",
        COALESCE(B."PurchaseBudget", 0) AS "PurchaseBudget",
        COALESCE(S."CategorySalesValue", 0) AS "CategorySalesValue",
        COALESCE(S."CategoryGrossProfit", 0) AS "CategoryGrossProfit",
        CASE
            WHEN COALESCE(CS."CategoryTotalPurchaseSpend", 0) = 0 THEN 0
            ELSE CAST(A."ActualPurchaseSpend" / NULLIF(CS."CategoryTotalPurchaseSpend", 0) AS DECIMAL(19,6))
        END AS "BuyerSpendShareInCategory"
    FROM "PurchaseActualMonthly" A
    LEFT JOIN "PurchaseBudgetMonthly" B
        ON A."ReportDate" = B."ReportDate"
       AND A."BuyerCode" = B."BuyerCode"
       AND A."Category" = B."Category"
    LEFT JOIN "SalesCategoryMonthly" S
        ON A."ReportDate" = S."ReportDate"
       AND A."Category" = S."Category"
    LEFT JOIN "CategorySpendMonthly" CS
        ON A."ReportDate" = CS."ReportDate"
       AND A."Category" = CS."Category"
),
"BuyerPortfolioWithAlloc" AS (
    SELECT
        P."ReportDate",
        P."BuyerCode",
        P."BuyerName",
        P."Category",
        P."ActualPurchaseSpend",
        P."PurchaseBudget",
        P."DiscountSavings",
        P."RebateSavings",
        P."CreditTermSavings",
        P."TotalNegotiationSavings",
        P."CategorySalesValue",
        P."CategoryGrossProfit",
        CAST(P."CategorySalesValue" * P."BuyerSpendShareInCategory" AS DECIMAL(19,6)) AS "BuyerAllocatedSales",
        CAST(P."CategoryGrossProfit" * P."BuyerSpendShareInCategory" AS DECIMAL(19,6)) AS "BuyerAllocatedProfit"
    FROM "BuyerPortfolioPerf" P
),
"BuyerProfitGrowth" AS (
    SELECT
        B.*,
        CAST(
            LAG(B."BuyerAllocatedProfit") OVER (
                PARTITION BY B."BuyerCode", B."Category"
                ORDER BY B."ReportDate"
            ) AS DECIMAL(19,6)
        ) AS "PrevBuyerAllocatedProfit"
    FROM "BuyerPortfolioWithAlloc" B
),
"BusinessMonthly" AS (
    SELECT
        S."ReportDate",
        CAST(SUM(S."CategorySalesValue") AS DECIMAL(19,6)) AS "OverallBusinessSales",
        CAST(SUM(S."CategoryGrossProfit") AS DECIMAL(19,6)) AS "OverallBusinessProfit"
    FROM "SalesCategoryMonthly" S
    GROUP BY S."ReportDate"
),
"FinalRows" AS (
    SELECT
        G."ReportDate",
        G."BuyerCode",
        G."BuyerName",
        G."Category",
        G."ActualPurchaseSpend",
        G."PurchaseBudget",
        G."DiscountSavings",
        G."RebateSavings",
        G."CreditTermSavings",
        G."TotalNegotiationSavings",
        G."BuyerAllocatedSales",
        G."BuyerAllocatedProfit",
        G."PrevBuyerAllocatedProfit",
        BM."OverallBusinessSales",
        BM."OverallBusinessProfit",
        ROW_NUMBER() OVER (
            PARTITION BY G."ReportDate"
            ORDER BY G."BuyerCode", G."Category"
        ) AS "RowInMonth"
    FROM "BuyerProfitGrowth" G
    LEFT JOIN "BusinessMonthly" BM
        ON G."ReportDate" = BM."ReportDate"
)
SELECT
    G."ReportDate",
    G."BuyerCode",
    G."BuyerName",
    G."Category",

    G."ActualPurchaseSpend",
    G."PurchaseBudget",
    CASE
        WHEN G."PurchaseBudget" = 0 THEN NULL
        ELSE CAST((G."ActualPurchaseSpend" / NULLIF(G."PurchaseBudget", 0)) * 100 AS DECIMAL(19,6))
    END AS "PurchaseBudgetAchievementPct",

    G."DiscountSavings",
    G."RebateSavings",
    G."CreditTermSavings",
    G."TotalNegotiationSavings",
    CASE
        WHEN G."ActualPurchaseSpend" = 0 THEN NULL
        ELSE CAST((G."TotalNegotiationSavings" / NULLIF(G."ActualPurchaseSpend", 0)) * 100 AS DECIMAL(19,6))
    END AS "NegotiationSavingsPctOfSpend",

    G."BuyerAllocatedSales",
    G."BuyerAllocatedProfit",
    G."PrevBuyerAllocatedProfit",
    CAST(G."BuyerAllocatedProfit" - COALESCE(G."PrevBuyerAllocatedProfit", 0) AS DECIMAL(19,6)) AS "CategoryProfitGrowthValue",
    CASE
        WHEN COALESCE(G."PrevBuyerAllocatedProfit", 0) = 0 THEN NULL
        ELSE CAST((G."BuyerAllocatedProfit" - G."PrevBuyerAllocatedProfit") / NULLIF(G."PrevBuyerAllocatedProfit", 0) AS DECIMAL(19,6))
    END AS "CategoryProfitGrowthPct",

    CASE
        WHEN G."RowInMonth" = 1 THEN G."OverallBusinessSales"
        ELSE NULL
    END AS "OverallBusinessSales",
    CASE
        WHEN G."RowInMonth" = 1 THEN G."OverallBusinessProfit"
        ELSE NULL
    END AS "OverallBusinessProfit",
    CAST(G."BuyerAllocatedProfit" + G."TotalNegotiationSavings" AS DECIMAL(19,6)) AS "SourcingImpactValue",
    CASE
        WHEN COALESCE(G."OverallBusinessProfit", 0) = 0 THEN NULL
        ELSE CAST(((G."BuyerAllocatedProfit" + G."TotalNegotiationSavings") / NULLIF(G."OverallBusinessProfit", 0)) * 100 AS DECIMAL(19,6))
    END AS "SourcingImpactPctOfBusinessProfit"
FROM "FinalRows" G
ORDER BY G."ReportDate" DESC, G."BuyerName", G."Category";
