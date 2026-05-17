CREATE OR REPLACE VIEW "PPL_LIVE"."bi_retail_sales_report" AS
WITH "SalesUnion" AS (
    SELECT
        'INVOICE' AS "DocType",
        H."DocEntry",
        H."DocNum",
        L."LineNum",
        H."DocDate",
        COALESCE(H."DocTime", 0) AS "DocTime",
        H."CardCode",
        H."CardName",
        H."SlpCode",
        L."ItemCode",
        L."WhsCode",
        L."Project",
        CAST(L."Quantity" AS DECIMAL(19,6)) AS "QtySalesUoM",
        CAST(L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(L."Quantity" * L."PriceBefDi" AS DECIMAL(19,6)) AS "GrossBeforeDiscount",
        CAST(L."LineTotal" AS DECIMAL(19,6)) AS "NetSales",
        CAST(L."GrssProfit" AS DECIMAL(19,6)) AS "GrossProfit"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE

    UNION ALL

    SELECT
        'CREDIT_NOTE' AS "DocType",
        H."DocEntry",
        H."DocNum",
        L."LineNum",
        H."DocDate",
        COALESCE(H."DocTime", 0) AS "DocTime",
        H."CardCode",
        H."CardName",
        H."SlpCode",
        L."ItemCode",
        L."WhsCode",
        L."Project",
        CAST(-1 * L."Quantity" AS DECIMAL(19,6)) AS "QtySalesUoM",
        CAST(-1 * L."InvQty" AS DECIMAL(19,6)) AS "QtyBaseUoM",
        CAST(-1 * (L."Quantity" * L."PriceBefDi") AS DECIMAL(19,6)) AS "GrossBeforeDiscount",
        CAST(-1 * L."LineTotal" AS DECIMAL(19,6)) AS "NetSales",
        CAST(-1 * L."GrssProfit" AS DECIMAL(19,6)) AS "GrossProfit"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."DocDate" >= '2024-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"Enriched" AS (
    SELECT
        S."DocType",
        S."DocEntry",
        S."DocNum",
        S."LineNum",
        S."DocDate",
        YEAR(S."DocDate") AS "YearNo",
        MONTH(S."DocDate") AS "MonthNo",
        TO_VARCHAR(S."DocDate", 'YYYY-MM') AS "MonthKey",
        TO_VARCHAR(YEAR(S."DocDate")) || '-W' || LPAD(TO_VARCHAR(WEEK(S."DocDate")), 2, '0') AS "WeekKey",
        CAST(SUBSTRING(LPAD(TO_VARCHAR(S."DocTime"), 4, '0'), 1, 2) AS INTEGER) AS "DocHour",
        CASE
            WHEN CAST(SUBSTRING(LPAD(TO_VARCHAR(S."DocTime"), 4, '0'), 1, 2) AS INTEGER) BETWEEN 0 AND 7 THEN 'Night'
            WHEN CAST(SUBSTRING(LPAD(TO_VARCHAR(S."DocTime"), 4, '0'), 1, 2) AS INTEGER) BETWEEN 8 AND 15 THEN 'Day'
            ELSE 'Evening'
        END AS "ShiftName",
        S."CardCode" AS "CustomerCode",
        S."CardName" AS "CustomerName",
        COALESCE(SLP."SlpName", 'UNASSIGNED') AS "SalespersonName",
        COALESCE(TO_VARCHAR(S."SlpCode"), 'UNASSIGNED') AS "SalespersonCode",
        S."ItemCode",
        ITM."ItemName",
        COALESCE(ITB."ItmsGrpNam", 'UNMAPPED') AS "Category",
        COALESCE(ITM."U_Brand", 'UNMAPPED') AS "Brand",
        COALESCE(ITM."U_SubCat1", 'UNMAPPED') AS "SubCategory1",
        COALESCE(ITM."U_SubCat2", 'UNMAPPED') AS "SubCategory2",
        COALESCE(ITM."U_SubCat3", 'UNMAPPED') AS "SubCategory3",
        COALESCE(ITM."U_Formulation", 'UNMAPPED') AS "Formulation",
        COALESCE(ITM."U_ActiveIngredient", 'UNMAPPED') AS "Molecule",
        COALESCE(ITM."CardCode", 'UNMAPPED') AS "SupplierCode",
        COALESCE(SUP."CardName", 'UNMAPPED') AS "SupplierName",
        S."WhsCode" AS "BranchCode",
        COALESCE(WHS."WhsName", 'UNMAPPED') AS "BranchName",
        COALESCE(LCT."Location", 'UNMAPPED') AS "Region",
        CASE
            WHEN UPPER(COALESCE(LCT."Location", WHS."WhsName", '')) LIKE '%TIER 1%' OR UPPER(COALESCE(LCT."Location", WHS."WhsName", '')) LIKE '%T1%' THEN 'T1'
            WHEN UPPER(COALESCE(LCT."Location", WHS."WhsName", '')) LIKE '%TIER 2%' OR UPPER(COALESCE(LCT."Location", WHS."WhsName", '')) LIKE '%T2%' THEN 'T2'
            WHEN UPPER(COALESCE(LCT."Location", WHS."WhsName", '')) LIKE '%TIER 3%' OR UPPER(COALESCE(LCT."Location", WHS."WhsName", '')) LIKE '%T3%' THEN 'T3'
            WHEN UPPER(COALESCE(LCT."Location", WHS."WhsName", '')) LIKE '%TIER 4%' OR UPPER(COALESCE(LCT."Location", WHS."WhsName", '')) LIKE '%T4%' THEN 'T4'
            ELSE 'UNCLASSIFIED'
        END AS "BranchTier",
        'UNMAPPED' AS "BM",
        'UNMAPPED' AS "RM",
        'UNMAPPED' AS "HOR",
        CASE
            WHEN UPPER(COALESCE(CUST."CardName", S."CardName", '')) LIKE '%GLOVO%' OR UPPER(COALESCE(CUST."CardCode", S."CardCode", '')) LIKE '%GLOVO%' THEN 'Glovo'
            WHEN UPPER(COALESCE(CUST."CardName", S."CardName", '')) LIKE '%UBER%' OR UPPER(COALESCE(CUST."CardCode", S."CardCode", '')) LIKE '%UBER%' THEN 'Uber Eats'
            WHEN UPPER(COALESCE(CUST."CardName", S."CardName", '')) LIKE '%WHATSAPP%' OR UPPER(COALESCE(CUST."CardCode", S."CardCode", '')) LIKE '%WHATSAPP%' THEN 'Whatsapp'
            WHEN UPPER(COALESCE(CUST."CardName", S."CardName", '')) LIKE '%KPA%' OR UPPER(COALESCE(CUST."CardCode", S."CardCode", '')) LIKE '%KPA%' THEN 'KPA'
            WHEN UPPER(COALESCE(CUST."CardName", S."CardName", '')) LIKE '%KPC%' OR UPPER(COALESCE(CUST."CardCode", S."CardCode", '')) LIKE '%KPC%' THEN 'KPC'
            WHEN UPPER(COALESCE(CUST."CardName", S."CardName", '')) LIKE '%ECOM%' OR UPPER(COALESCE(CUST."CardCode", S."CardCode", '')) LIKE '%ECOM%' THEN 'E-Commerce'
            ELSE 'Retail/Other'
        END AS "Channel",
        S."Project",
        S."QtySalesUoM",
        S."QtyBaseUoM",
        S."GrossBeforeDiscount",
        S."NetSales",
        S."GrossProfit"
    FROM "SalesUnion" S
    LEFT JOIN "PPL_LIVE"."OCRD" CUST
        ON S."CardCode" = CUST."CardCode"
    LEFT JOIN "PPL_LIVE"."OSLP" SLP
        ON S."SlpCode" = SLP."SlpCode"
    LEFT JOIN "PPL_LIVE"."OITM" ITM
        ON S."ItemCode" = ITM."ItemCode"
    LEFT JOIN "PPL_LIVE"."OITB" ITB
        ON ITM."ItmsGrpCod" = ITB."ItmsGrpCod"
    LEFT JOIN "PPL_LIVE"."OCRD" SUP
        ON ITM."CardCode" = SUP."CardCode"
    LEFT JOIN "PPL_LIVE"."OWHS" WHS
        ON S."WhsCode" = WHS."WhsCode"
    LEFT JOIN "PPL_LIVE"."OLCT" LCT
        ON WHS."Location" = LCT."Code"
)
SELECT
    "DocType",
    "DocEntry",
    "DocNum",
    "LineNum",
    "DocDate",
    "YearNo",
    "MonthNo",
    "MonthKey",
    "WeekKey",
    "DocHour",
    "ShiftName",
    "CustomerCode",
    "CustomerName",
    "SalespersonCode",
    "SalespersonName",
    "ItemCode",
    "ItemName",
    "Category",
    "Brand",
    "SubCategory1",
    "SubCategory2",
    "SubCategory3",
    "Formulation",
    "Molecule",
    "SupplierCode",
    "SupplierName",
    "BranchCode",
    "BranchName",
    "Region",
    "BranchTier",
    "BM",
    "RM",
    "HOR",
    "Channel",
    "Project",
    "QtySalesUoM",
    "QtyBaseUoM",
    "GrossBeforeDiscount",
    CAST("GrossBeforeDiscount" - "NetSales" AS DECIMAL(19,6)) AS "DiscountAmount",
    "NetSales",
    "GrossProfit",
    CAST("NetSales" - "GrossProfit" AS DECIMAL(19,6)) AS "CostAmount",
    CASE WHEN "NetSales" = 0 THEN 0 ELSE CAST("GrossProfit" / "NetSales" AS DECIMAL(19,6)) END AS "GPMarginPct",
    CASE WHEN ("NetSales" - "GrossProfit") = 0 THEN 0 ELSE CAST("GrossProfit" / ("NetSales" - "GrossProfit") AS DECIMAL(19,6)) END AS "MarkupPct"
FROM "Enriched";
