CREATE OR REPLACE VIEW "PPL_LIVE"."bi_sales_profitability" AS
WITH "SalesLine" AS (
    SELECT
        H."DocDate",
        L."WhsCode" AS "Warehouse",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "SalesValue"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2023-01-01'
      AND H."DocDate" <= CURRENT_DATE

    UNION ALL

    SELECT
        H."DocDate",
        L."WhsCode" AS "Warehouse",
        CAST(-(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "SalesValue"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2023-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"SalesDaily" AS (
    SELECT
        S."DocDate",
        S."Warehouse",
        SUM(S."SalesValue") AS "Sales Value"
    FROM "SalesLine" S
    GROUP BY S."DocDate", S."Warehouse"
),
"TransfersDaily" AS (
    SELECT
        N1."DocDate",
        N1."Warehouse",
        SUM(CASE WHEN N1."TransValue" > 0 THEN N1."TransValue" ELSE 0 END) AS "Transfers In Value",
        SUM(CASE WHEN N1."TransValue" < 0 THEN -N1."TransValue" ELSE 0 END) AS "Transfers Out Value"
    FROM "PPL_LIVE"."OINM" N1
    WHERE N1."DocDate" >= '2023-01-01'
      AND N1."DocDate" <= CURRENT_DATE
      AND N1."TransType" = '67'
    GROUP BY N1."DocDate", N1."Warehouse"
),
"Combined" AS (
    SELECT
        X."DocDate",
        X."Warehouse",
        SUM(X."Sales Value") AS "Sales Value",
        SUM(X."Transfers In Value") AS "Transfers In Value",
        SUM(X."Transfers Out Value") AS "Transfers Out Value"
    FROM (
        SELECT
            S."DocDate",
            S."Warehouse",
            S."Sales Value",
            CAST(0 AS DECIMAL(19,6)) AS "Transfers In Value",
            CAST(0 AS DECIMAL(19,6)) AS "Transfers Out Value"
        FROM "SalesDaily" S

        UNION ALL

        SELECT
            T."DocDate",
            T."Warehouse",
            CAST(0 AS DECIMAL(19,6)) AS "Sales Value",
            T."Transfers In Value",
            T."Transfers Out Value"
        FROM "TransfersDaily" T
    ) X
    GROUP BY X."DocDate", X."Warehouse"
)
SELECT
    C."DocDate",
    C."Warehouse",
    W."WhsName" AS "Branch Name",
    COALESCE(L."Location", 'UNMAPPED') AS "Branch Region",
    C."Sales Value",
    C."Transfers In Value",
    C."Transfers Out Value",
    CAST(C."Transfers In Value" - C."Transfers Out Value" AS DECIMAL(19,6)) AS "Transfers In - Out Value",
    CAST(C."Sales Value" - (C."Transfers In Value" - C."Transfers Out Value") AS DECIMAL(19,6)) AS "Variance",
    CASE
        WHEN C."Sales Value" = 0 THEN 0
        ELSE CAST(
            ((C."Sales Value" - (C."Transfers In Value" - C."Transfers Out Value")) / C."Sales Value") * 100
            AS DECIMAL(19,6)
        )
    END AS "GP %"
FROM "Combined" C
INNER JOIN "PPL_LIVE"."OWHS" W
    ON C."Warehouse" = W."WhsCode"
LEFT JOIN "PPL_LIVE"."OLCT" L
    ON W."Location" = L."Code"
WHERE C."Warehouse" NOT LIKE 'INT-%'
  AND C."Warehouse" NOT LIKE 'HQ-%'
ORDER BY C."DocDate" DESC, C."Warehouse" ASC;
