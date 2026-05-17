CREATE OR REPLACE VIEW "PPL_LIVE"."bi_inventory_health_by_category" AS
WITH "DailySalesAgg" AS (
    SELECT
        X."DocDate",
        X."WhsCode",
        X."ItemCode",
        CAST(SUM(X."NetSalesInclVAT") AS DECIMAL(19,6)) AS "Daily_Net_Sales"
    FROM (
        SELECT
            H."DocDate",
            L."WhsCode",
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
            L."WhsCode",
            L."ItemCode",
            CAST(-(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "NetSalesInclVAT"
        FROM "PPL_LIVE"."ORIN" H
        INNER JOIN "PPL_LIVE"."RIN1" L
            ON H."DocEntry" = L."DocEntry"
        WHERE H."CANCELED" = 'N'
          AND H."U_CXS_FRST" = 'Y'
          AND H."DocDate" >= '2024-01-01'
    ) X
    GROUP BY X."DocDate", X."WhsCode", X."ItemCode"
),
"SalesMonthly" AS (
    SELECT
        LAST_DAY(D."DocDate") AS "As_At_Date",
        D."WhsCode" AS "BranchCode",
        D."ItemCode",
        CAST(SUM(D."Daily_Net_Sales") AS DECIMAL(19,6)) AS "Sales_30d_Total"
    FROM "DailySalesAgg" D
    GROUP BY LAST_DAY(D."DocDate"), D."WhsCode", D."ItemCode"
),
"SalesMonthlyWithPrev" AS (
    SELECT
        S."As_At_Date",
        S."BranchCode",
        S."ItemCode",
        S."Sales_30d_Total",
        CAST(
            LAG(S."Sales_30d_Total") OVER (
                PARTITION BY S."BranchCode", S."ItemCode"
                ORDER BY S."As_At_Date"
            )
            AS DECIMAL(19,6)
        ) AS "Sales_Prev30d_Total"
    FROM "SalesMonthly" S
),
"CurrentInventory" AS (
    SELECT
        T0."Warehouse" AS "BranchCode",
        T0."ItemCode",
        CAST(SUM(T0."InQty" - T0."OutQty") AS DECIMAL(19,6)) AS "SOH",
        CAST(SUM(T0."TransValue") / 2 AS DECIMAL(19,6)) AS "Inventory_Value"
    FROM "PPL_LIVE"."OINM" T0
    GROUP BY T0."Warehouse", T0."ItemCode"
    HAVING SUM(T0."InQty" - T0."OutQty") <> 0
       AND SUM(T0."TransValue") <> 0
),
"MonthEndDates" AS (
    SELECT DISTINCT
        S."As_At_Date"
    FROM "SalesMonthlyWithPrev" S
),
"ItemDim" AS (
    SELECT
        I."ItemCode",
        MAX(COALESCE(I."ItemName", 'UNMAPPED')) AS "ItemName",
        MAX(COALESCE(B."ItmsGrpNam", 'UNMAPPED')) AS "Category",
        MAX(COALESCE(I."U_Brand", 'UNMAPPED')) AS "Brand",
        MAX(COALESCE(I."CardCode", 'UNMAPPED')) AS "SupplierCode",
        MAX(COALESCE(S."CardName", 'UNMAPPED')) AS "SupplierName"
    FROM "PPL_LIVE"."OITM" I
    LEFT JOIN "PPL_LIVE"."OITB" B
        ON I."ItmsGrpCod" = B."ItmsGrpCod"
    LEFT JOIN "PPL_LIVE"."OCRD" S
        ON I."CardCode" = S."CardCode"
    GROUP BY I."ItemCode"
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
"ExpiryStock" AS (
    SELECT
        Q."WhsCode" AS "BranchCode",
        Q."ItemCode",
        CAST(SUM(
            CASE
                WHEN B."ExpDate" IS NOT NULL
                 AND B."ExpDate" <= CURRENT_DATE
                THEN Q."Quantity" * COALESCE(W."AvgPrice", 0)
                ELSE 0
            END
        ) AS DECIMAL(19,6)) AS "Expired_Stock_Value",
        CAST(SUM(
            CASE
                WHEN B."ExpDate" IS NOT NULL
                 AND B."ExpDate" > CURRENT_DATE
                 AND B."ExpDate" <= ADD_DAYS(CURRENT_DATE, 90)
                THEN Q."Quantity" * COALESCE(W."AvgPrice", 0)
                ELSE 0
            END
        ) AS DECIMAL(19,6)) AS "NearExpiry_Stock_Value"
    FROM "PPL_LIVE"."OBTQ" Q
    INNER JOIN "PPL_LIVE"."OBTN" B
        ON Q."MdAbsEntry" = B."AbsEntry"
       AND Q."ItemCode" = B."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITW" W
        ON Q."WhsCode" = W."WhsCode"
       AND Q."ItemCode" = W."ItemCode"
    WHERE Q."Quantity" > 0
    GROUP BY Q."WhsCode", Q."ItemCode"
),
"BaseSales" AS (
    SELECT
        S."As_At_Date",
        S."BranchCode",
        COALESCE(BD."BranchName", 'UNMAPPED') AS "BranchName",
        COALESCE(BD."Region", 'UNMAPPED') AS "Region",
        COALESCE(ID."SupplierCode", 'UNMAPPED') AS "SupplierCode",
        COALESCE(ID."SupplierName", 'UNMAPPED') AS "SupplierName",
        COALESCE(ID."Brand", 'UNMAPPED') AS "Brand",
        COALESCE(ID."Category", 'UNMAPPED') AS "Category",
        S."ItemCode",
        COALESCE(ID."ItemName", 'UNMAPPED') AS "ItemName",
        COALESCE(CI."SOH", 0) AS "SOH",
        COALESCE(CI."Inventory_Value", 0) AS "Inventory_Value",
        S."Sales_30d_Total",
        CAST(S."Sales_30d_Total" / DAYOFMONTH(S."As_At_Date") AS DECIMAL(19,6)) AS "Sales_30d_Avg_Daily",
        CAST(
            COALESCE(S."Sales_Prev30d_Total", 0)
            / DAYOFMONTH(LAST_DAY(ADD_MONTHS(S."As_At_Date", -1)))
            AS DECIMAL(19,6)
        ) AS "Sales_Prev30d_Avg_Daily",
        COALESCE(EX."Expired_Stock_Value", 0) AS "Expired_Stock_Value",
        COALESCE(EX."NearExpiry_Stock_Value", 0) AS "NearExpiry_Stock_Value"
    FROM "SalesMonthlyWithPrev" S
    LEFT JOIN "CurrentInventory" CI
        ON S."BranchCode" = CI."BranchCode"
       AND S."ItemCode" = CI."ItemCode"
    LEFT JOIN "ItemDim" ID
        ON S."ItemCode" = ID."ItemCode"
    LEFT JOIN "BranchDim" BD
        ON S."BranchCode" = BD."BranchCode"
    LEFT JOIN "ExpiryStock" EX
        ON S."BranchCode" = EX."BranchCode"
       AND S."ItemCode" = EX."ItemCode"
),
"InventoryOnly" AS (
    SELECT
        D."As_At_Date",
        CI."BranchCode",
        COALESCE(BD."BranchName", 'UNMAPPED') AS "BranchName",
        COALESCE(BD."Region", 'UNMAPPED') AS "Region",
        COALESCE(ID."SupplierCode", 'UNMAPPED') AS "SupplierCode",
        COALESCE(ID."SupplierName", 'UNMAPPED') AS "SupplierName",
        COALESCE(ID."Brand", 'UNMAPPED') AS "Brand",
        COALESCE(ID."Category", 'UNMAPPED') AS "Category",
        CI."ItemCode",
        COALESCE(ID."ItemName", 'UNMAPPED') AS "ItemName",
        CI."SOH",
        CI."Inventory_Value",
        CAST(0 AS DECIMAL(19,6)) AS "Sales_30d_Total",
        CAST(0 AS DECIMAL(19,6)) AS "Sales_30d_Avg_Daily",
        CAST(0 AS DECIMAL(19,6)) AS "Sales_Prev30d_Avg_Daily",
        COALESCE(EX."Expired_Stock_Value", 0) AS "Expired_Stock_Value",
        COALESCE(EX."NearExpiry_Stock_Value", 0) AS "NearExpiry_Stock_Value"
    FROM "MonthEndDates" D
    INNER JOIN "CurrentInventory" CI
        ON 1 = 1
    LEFT JOIN "SalesMonthlyWithPrev" S
        ON D."As_At_Date" = S."As_At_Date"
       AND CI."BranchCode" = S."BranchCode"
       AND CI."ItemCode" = S."ItemCode"
    LEFT JOIN "ItemDim" ID
        ON CI."ItemCode" = ID."ItemCode"
    LEFT JOIN "BranchDim" BD
        ON CI."BranchCode" = BD."BranchCode"
    LEFT JOIN "ExpiryStock" EX
        ON CI."BranchCode" = EX."BranchCode"
       AND CI."ItemCode" = EX."ItemCode"
    WHERE S."ItemCode" IS NULL
),
"Base" AS (
    SELECT * FROM "BaseSales"
    UNION ALL
    SELECT * FROM "InventoryOnly"
),
"CategoryAgg" AS (
    SELECT
        B."As_At_Date",
        B."BranchCode",
        B."Category",
        CAST(SUM(B."Inventory_Value") AS DECIMAL(19,6)) AS "Category_Inventory_Value",
        CAST(SUM(B."Sales_30d_Avg_Daily") AS DECIMAL(19,6)) AS "Category_Sales_30d_Avg_Daily"
    FROM "Base" B
    GROUP BY B."As_At_Date", B."BranchCode", B."Category"
)
SELECT
    B."As_At_Date",
    B."BranchCode",
    B."BranchName",
    B."Region",
    B."SupplierCode",
    B."SupplierName",
    B."Brand",
    B."Category",
    B."ItemCode",
    B."ItemName",
    B."SOH",
    B."Inventory_Value",
    B."Sales_30d_Total",
    B."Sales_30d_Avg_Daily",
    B."Sales_Prev30d_Avg_Daily",
    CASE
        WHEN B."Sales_30d_Avg_Daily" <= 0 THEN 0
        ELSE CAST(B."Inventory_Value" / NULLIF(B."Sales_30d_Avg_Daily", 0) AS DECIMAL(19,6))
    END AS "Days_of_Stock_SKU",
    CASE
        WHEN COALESCE(CA."Category_Sales_30d_Avg_Daily", 0) = 0 THEN 0
        ELSE CAST(CA."Category_Inventory_Value" / NULLIF(CA."Category_Sales_30d_Avg_Daily", 0) AS DECIMAL(19,6))
    END AS "Days_of_Stock_Category",
    CAST(B."Sales_30d_Avg_Daily" * 30 AS DECIMAL(19,6)) AS "Target_Stock_Value_30D",
    CAST(B."Inventory_Value" - (B."Sales_30d_Avg_Daily" * 30) AS DECIMAL(19,6)) AS "Excess_Stock_Value",
    CASE
        WHEN B."Sales_30d_Avg_Daily" <= 0 AND B."Inventory_Value" > 0 THEN 'OVERSTOCK_NO_SALES'
        WHEN (B."Inventory_Value" / NULLIF(B."Sales_30d_Avg_Daily", 0)) > 45 THEN 'OVERSTOCK_RISK'
        WHEN (B."Inventory_Value" / NULLIF(B."Sales_30d_Avg_Daily", 0)) < 14 THEN 'UNDERSTOCK_RISK'
        ELSE 'BALANCED'
    END AS "OverUnderStockRisk",
    B."Expired_Stock_Value",
    B."NearExpiry_Stock_Value",
    CAST(B."Expired_Stock_Value" + B."NearExpiry_Stock_Value" AS DECIMAL(19,6)) AS "ExpiryNearExpiry_Stock_Value",
    CASE
        WHEN COALESCE(CA."Category_Inventory_Value", 0) = 0 THEN 0
        ELSE CAST(((B."Expired_Stock_Value" + B."NearExpiry_Stock_Value") / CA."Category_Inventory_Value") * 100 AS DECIMAL(19,6))
    END AS "ExpiryNearExpiry_Pct_of_Category",
    CASE
        WHEN B."Sales_Prev30d_Avg_Daily" = 0 THEN NULL
        ELSE CAST((B."Sales_30d_Avg_Daily" - B."Sales_Prev30d_Avg_Daily") / NULLIF(B."Sales_Prev30d_Avg_Daily", 0) AS DECIMAL(19,6))
    END AS "Sales_Trend_Pct",
    CASE
        WHEN B."Sales_Prev30d_Avg_Daily" = 0 THEN 'NO_PRIOR_BASE'
        WHEN (B."Sales_30d_Avg_Daily" > B."Sales_Prev30d_Avg_Daily" * 1.15)
             AND (CASE WHEN B."Sales_30d_Avg_Daily" <= 0 THEN 0 ELSE B."Inventory_Value" / NULLIF(B."Sales_30d_Avg_Daily", 0) END) < 20
        THEN 'LOW_COVER_RISING_SALES'
        WHEN (B."Sales_30d_Avg_Daily" < B."Sales_Prev30d_Avg_Daily" * 0.85)
             AND (CASE WHEN B."Sales_30d_Avg_Daily" <= 0 THEN 0 ELSE B."Inventory_Value" / NULLIF(B."Sales_30d_Avg_Daily", 0) END) > 45
        THEN 'HIGH_COVER_FALLING_SALES'
        ELSE 'COVERAGE_OK_VS_TREND'
    END AS "StockCoverageVsSalesTrend"
FROM "Base" B
LEFT JOIN "CategoryAgg" CA
    ON B."As_At_Date" = CA."As_At_Date"
   AND B."BranchCode" = CA."BranchCode"
   AND B."Category" = CA."Category"
WHERE B."BranchCode" NOT LIKE 'INT-%'
ORDER BY B."As_At_Date" DESC, B."BranchName", B."Category", B."ItemCode";
