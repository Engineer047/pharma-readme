CREATE OR REPLACE VIEW "PPL_LIVE"."bi_customer_count" AS
WITH "Params" AS (
    SELECT
        DATE'2024-01-01' AS "Data_Start_Date",
        ADD_DAYS(CURRENT_DATE, 1 - DAYOFMONTH(CURRENT_DATE)) AS "MTD_Start_Date",
        CURRENT_DATE AS "MTD_As_At_Date",
        ADD_MONTHS(ADD_DAYS(CURRENT_DATE, 1 - DAYOFMONTH(CURRENT_DATE)), -1) AS "Last_MTD_Start_Date",
        ADD_MONTHS(CURRENT_DATE, -1) AS "Last_MTD_As_At_Date"
    FROM DUMMY
),
"InvoiceDocAgg" AS (
    SELECT
        H."DocDate",
        L."WhsCode",
        W."WhsName",
        H."DocEntry",
        CAST(SUM(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "DocSalesValue"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    INNER JOIN "PPL_LIVE"."OWHS" W
        ON L."WhsCode" = W."WhsCode"
    CROSS JOIN "Params" P
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= P."Data_Start_Date"
      AND H."DocDate" <= P."MTD_As_At_Date"
      AND L."WhsCode" NOT LIKE 'INT-%'
      AND L."WhsCode" NOT LIKE 'HQ-%'
    GROUP BY H."DocDate", L."WhsCode", W."WhsName", H."DocEntry"
),
"CreditDocAgg" AS (
    SELECT
        H."DocDate",
        L."WhsCode",
        W."WhsName",
        H."DocEntry",
        CAST(-SUM(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "DocSalesValue"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    INNER JOIN "PPL_LIVE"."OWHS" W
        ON L."WhsCode" = W."WhsCode"
    CROSS JOIN "Params" P
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= P."Data_Start_Date"
      AND H."DocDate" <= P."MTD_As_At_Date"
      AND L."WhsCode" NOT LIKE 'INT-%'
      AND L."WhsCode" NOT LIKE 'HQ-%'
    GROUP BY H."DocDate", L."WhsCode", W."WhsName", H."DocEntry"
),
"AllSalesDocs" AS (
    SELECT
        I."DocDate",
        I."WhsCode",
        I."WhsName",
        I."DocSalesValue"
    FROM "InvoiceDocAgg" I

    UNION ALL

    SELECT
        C."DocDate",
        C."WhsCode",
        C."WhsName",
        C."DocSalesValue"
    FROM "CreditDocAgg" C
),
"BranchBase" AS (
    SELECT
        A."WhsCode",
        MAX(A."WhsName") AS "WhsName"
    FROM "AllSalesDocs" A
    GROUP BY A."WhsCode"
),
"MTD_Transactions" AS (
    SELECT
        I."WhsCode",
        COUNT(DISTINCT I."DocEntry") AS "MTD_Transactions"
    FROM "InvoiceDocAgg" I
    CROSS JOIN "Params" P
    WHERE I."DocDate" >= P."MTD_Start_Date"
      AND I."DocDate" <= P."MTD_As_At_Date"
    GROUP BY I."WhsCode"
),
"MTD_Sales" AS (
    SELECT
        S."WhsCode",
        CAST(SUM(S."DocSalesValue") AS DECIMAL(19,6)) AS "MTD_Sales"
    FROM "AllSalesDocs" S
    CROSS JOIN "Params" P
    WHERE S."DocDate" >= P."MTD_Start_Date"
      AND S."DocDate" <= P."MTD_As_At_Date"
    GROUP BY S."WhsCode"
),
"LAST_MTD_Transactions" AS (
    SELECT
        I."WhsCode",
        COUNT(DISTINCT I."DocEntry") AS "LastMTD_Transactions"
    FROM "InvoiceDocAgg" I
    CROSS JOIN "Params" P
    WHERE I."DocDate" >= P."Last_MTD_Start_Date"
      AND I."DocDate" <= P."Last_MTD_As_At_Date"
    GROUP BY I."WhsCode"
),
"LAST_MTD_Sales" AS (
    SELECT
        S."WhsCode",
        CAST(SUM(S."DocSalesValue") AS DECIMAL(19,6)) AS "LastMTD_Sales"
    FROM "AllSalesDocs" S
    CROSS JOIN "Params" P
    WHERE S."DocDate" >= P."Last_MTD_Start_Date"
      AND S."DocDate" <= P."Last_MTD_As_At_Date"
    GROUP BY S."WhsCode"
)
SELECT
    B."WhsCode" AS "Store Code",
    B."WhsName" AS "Store Name",
    P."MTD_Start_Date" AS "MTD Start Date",
    P."MTD_As_At_Date" AS "MTD As At Date",
    COALESCE(MT."MTD_Transactions", 0) AS "MTD No. Of Customers",
    COALESCE(MS."MTD_Sales", 0) AS "MTD Sales",
    CASE
        WHEN COALESCE(MT."MTD_Transactions", 0) = 0 THEN 0
        ELSE CAST(COALESCE(MS."MTD_Sales", 0) / MT."MTD_Transactions" AS DECIMAL(19,6))
    END AS "MTD ABV",
    COALESCE(LT."LastMTD_Transactions", 0) AS "Last MTD No. Of Customers",
    COALESCE(LS."LastMTD_Sales", 0) AS "Last MTD Sales",
    CASE
        WHEN COALESCE(LT."LastMTD_Transactions", 0) = 0 THEN 0
        ELSE CAST(COALESCE(LS."LastMTD_Sales", 0) / LT."LastMTD_Transactions" AS DECIMAL(19,6))
    END AS "Last MTD ABV",
    CASE
        WHEN COALESCE(LT."LastMTD_Transactions", 0) = 0 THEN 0
        WHEN COALESCE(LS."LastMTD_Sales", 0) = 0 THEN 0
        ELSE CAST(
            (
                (COALESCE(MS."MTD_Sales", 0) / NULLIF(MT."MTD_Transactions", 0)) -
                (COALESCE(LS."LastMTD_Sales", 0) / NULLIF(LT."LastMTD_Transactions", 0))
            ) / NULLIF((COALESCE(LS."LastMTD_Sales", 0) / NULLIF(LT."LastMTD_Transactions", 0)), 0) * 100
            AS DECIMAL(19,6)
        )
    END AS "% ABV Growth"
FROM "BranchBase" B
LEFT JOIN "MTD_Transactions" MT
    ON B."WhsCode" = MT."WhsCode"
LEFT JOIN "MTD_Sales" MS
    ON B."WhsCode" = MS."WhsCode"
LEFT JOIN "LAST_MTD_Transactions" LT
    ON B."WhsCode" = LT."WhsCode"
LEFT JOIN "LAST_MTD_Sales" LS
    ON B."WhsCode" = LS."WhsCode"
CROSS JOIN "Params" P
ORDER BY B."WhsCode";
