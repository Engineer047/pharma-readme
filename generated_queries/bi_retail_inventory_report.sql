CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_inventory_report" AS
WITH "InvoiceLines" AS (
    SELECT
        T0."DocDate",
        T2."WhsCode" AS "BranchCode",
        T2."WhsName" AS "BranchName",
        T0."DocEntry",
        T1."ItemCode"
    FROM "PPL_LIVE"."OINV" T0
    INNER JOIN "PPL_LIVE"."INV1" T1 ON T0."DocEntry" = T1."DocEntry"
    INNER JOIN "PPL_LIVE"."OWHS" T2 ON T1."WhsCode" = T2."WhsCode"
    WHERE T0."DocDate" >= '2024-01-01'
      AND T0."DocDate" <= CURRENT_DATE
      AND T0."U_CXS_FRST" = 'Y'
      AND T0."CANCELED" = 'N'
),
"DocItems" AS (
    SELECT DISTINCT
        I."DocDate",
        I."BranchCode",
        I."BranchName",
        I."DocEntry",
        I."ItemCode"
    FROM "InvoiceLines" I
),
"DocItemCount" AS (
    SELECT
        D."DocEntry",
        COUNT(*) AS "DistinctItemsInDoc"
    FROM "DocItems" D
    GROUP BY D."DocEntry"
),
"ItemDaily" AS (
    SELECT
        D."DocDate" AS "ReportDate",
        D."BranchCode",
        D."BranchName",
        D."ItemCode",
        COALESCE(I."ItemName", 'UNMAPPED') AS "ItemName",
        COALESCE(B."ItmsGrpNam", 'UNMAPPED') AS "Category",
        COUNT(*) AS "ItemDocs",
        SUM(CASE WHEN C."DistinctItemsInDoc" >= 2 THEN 1 ELSE 0 END) AS "CrossSellDocs"
    FROM "DocItems" D
    INNER JOIN "DocItemCount" C ON D."DocEntry" = C."DocEntry"
    LEFT JOIN "PPL_LIVE"."OITM" I ON D."ItemCode" = I."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" B ON I."ItmsGrpCod" = B."ItmsGrpCod"
    GROUP BY D."DocDate", D."BranchCode", D."BranchName", D."ItemCode", COALESCE(I."ItemName", 'UNMAPPED'), COALESCE(B."ItmsGrpNam", 'UNMAPPED')
),
"Periodized" AS (
    SELECT
        'DAILY' AS "PeriodType",
        I."ReportDate",
        I."BranchCode",
        I."BranchName",
        I."ItemCode",
        I."ItemName",
        I."Category",
        SUM(I."ItemDocs") AS "ItemDocs",
        SUM(I."CrossSellDocs") AS "CrossSellDocs"
    FROM "ItemDaily" I
    GROUP BY I."ReportDate", I."BranchCode", I."BranchName", I."ItemCode", I."ItemName", I."Category"

    UNION ALL

    SELECT
        'WEEKLY' AS "PeriodType",
        ADD_DAYS(I."ReportDate", -WEEKDAY(I."ReportDate")) AS "ReportDate",
        I."BranchCode",
        I."BranchName",
        I."ItemCode",
        I."ItemName",
        I."Category",
        SUM(I."ItemDocs") AS "ItemDocs",
        SUM(I."CrossSellDocs") AS "CrossSellDocs"
    FROM "ItemDaily" I
    GROUP BY ADD_DAYS(I."ReportDate", -WEEKDAY(I."ReportDate")), I."BranchCode", I."BranchName", I."ItemCode", I."ItemName", I."Category"

    UNION ALL

    SELECT
        'MONTHLY' AS "PeriodType",
        ADD_DAYS(I."ReportDate", 1 - DAYOFMONTH(I."ReportDate")) AS "ReportDate",
        I."BranchCode",
        I."BranchName",
        I."ItemCode",
        I."ItemName",
        I."Category",
        SUM(I."ItemDocs") AS "ItemDocs",
        SUM(I."CrossSellDocs") AS "CrossSellDocs"
    FROM "ItemDaily" I
    GROUP BY ADD_DAYS(I."ReportDate", 1 - DAYOFMONTH(I."ReportDate")), I."BranchCode", I."BranchName", I."ItemCode", I."ItemName", I."Category"
),
"WithLag" AS (
    SELECT
        P.*,
        LAG(CASE WHEN P."ItemDocs" = 0 THEN 0 ELSE CAST(P."CrossSellDocs" AS DECIMAL(19,6)) / P."ItemDocs" END) OVER (
            PARTITION BY P."PeriodType", P."BranchCode", P."ItemCode"
            ORDER BY P."ReportDate"
        ) AS "PrevCrossSellRate"
    FROM "Periodized" P
)
SELECT
    "PeriodType",
    "ReportDate",
    "BranchCode",
    "BranchName",
    "ItemCode",
    "ItemName",
    "Category",
    "ItemDocs",
    "CrossSellDocs",
    CASE WHEN "ItemDocs" = 0 THEN 0 ELSE CAST("CrossSellDocs" AS DECIMAL(19,6)) / "ItemDocs" END AS "CrossSellRate",
    "PrevCrossSellRate",
    CASE WHEN "PrevCrossSellRate" IS NULL OR "PrevCrossSellRate" = 0 THEN NULL ELSE CAST(((CASE WHEN "ItemDocs" = 0 THEN 0 ELSE CAST("CrossSellDocs" AS DECIMAL(19,6)) / "ItemDocs" END) - "PrevCrossSellRate") / "PrevCrossSellRate" AS DECIMAL(19,6)) END AS "CrossSellRateDeltaPct"
FROM "WithLag";
