CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_pending_POs_from_branches" AS
WITH "PoBranch" AS (
    SELECT
        L."DocEntry",
        CASE
            WHEN COUNT(DISTINCT L."WhsCode") = 1 THEN MAX(L."WhsCode")
            ELSE 'MULTI'
        END AS "From Store ID"
    FROM "PPL_LIVE"."POR1" L
    GROUP BY
        L."DocEntry"
)
SELECT
    H."DocDate" AS "Report Date",
    H."DocEntry" AS "Numerator",
    H."DocNum" AS "Document Number",
    H."DocDate" AS "Posting Date",
    H."CardCode" AS "Customer/Vendor Code",
    H."CardName" AS "Customer/Vendor Name",
    CAST(
        CASE
            WHEN H."DocCur" = 'KES' THEN COALESCE(H."VatSum", 0)
            ELSE COALESCE(H."VatSumFC", H."VatSum", 0)
        END AS DECIMAL(19,6)
    ) AS "Total Tax",
    CAST(
        CASE
            WHEN H."DocCur" = 'KES' THEN COALESCE(H."DocTotal", 0)
            ELSE COALESCE(H."DocTotalFC", H."DocTotal", 0)
        END AS DECIMAL(19,6)
    ) AS "Document Total",
    CAST(NULL AS NVARCHAR(50)) AS "Transaction Number",
    CAST(NULL AS NVARCHAR(50)) AS "Transaction ID",
    COALESCE(B."From Store ID", 'UNMAPPED') AS "From Store ID"
FROM "PPL_LIVE"."OPOR" H
LEFT JOIN "PoBranch" B
    ON H."DocEntry" = B."DocEntry"
WHERE H."CANCELED" = 'N'
  AND H."DocStatus" = 'O'
ORDER BY
    H."DocDate" DESC,
    H."DocNum" DESC;
