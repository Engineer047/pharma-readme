CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_open_item_list" AS
WITH "DocBranch" AS (
    SELECT
        L."DocEntry",
        CASE
            WHEN COUNT(DISTINCT L."WhsCode") = 1 THEN MAX(L."WhsCode")
            ELSE 'MULTI'
        END AS "BRANCH"
    FROM "PPL_LIVE"."PDN1" L
    GROUP BY
        L."DocEntry"
)
SELECT
    H."DocDate" AS "Report Date",
    COALESCE(S."SeriesName", 'Primary') AS "Doc. Series",
    H."DocNum" AS "Doc. No.",
    H."CardCode" AS "Vendor Code",
    H."CardName" AS "Vendor Name",
    H."NumAtCard" AS "Vendor Ref. No.",
    H."DocDueDate" AS "Due Date",
    CAST(
        CASE
            WHEN H."DocCur" = 'KES' THEN COALESCE(H."DocTotal", 0)
            ELSE COALESCE(H."DocTotalFC", H."DocTotal", 0)
        END AS DECIMAL(19,6)
    ) AS "Amount",
    CAST(
        CASE
            WHEN H."DocCur" = 'KES' THEN COALESCE(H."DocTotal", 0) - COALESCE(H."VatSum", 0)
            ELSE COALESCE(H."DocTotalFC", H."DocTotal", 0) - COALESCE(H."VatSumFC", H."VatSum", 0)
        END AS DECIMAL(19,6)
    ) AS "Net",
    CAST(
        CASE
            WHEN H."DocCur" = 'KES' THEN COALESCE(H."VatSum", 0)
            ELSE COALESCE(H."VatSumFC", H."VatSum", 0)
        END AS DECIMAL(19,6)
    ) AS "Tax",
    CAST(
        CASE
            WHEN H."DocCur" = 'KES' THEN COALESCE(H."DocTotal", 0)
            ELSE COALESCE(H."DocTotalFC", H."DocTotal", 0)
        END AS DECIMAL(19,6)
    ) AS "Original Amount",
    H."DocDate" AS "Posting Date",
    COALESCE(H."TaxDate", H."DocDate") AS "Document Date",
    COALESCE(B."BRANCH", 'UNMAPPED') AS "BRANCH",
    'Goods Receipt PO' AS "Document Type",
    '' AS "Blanket Agreement",
    COALESCE(NULLIF(H."Comments", ''), 'Received') AS "Remarks",
    'Yes' AS "From Store",
    'No' AS "For Store"
FROM "PPL_LIVE"."OPDN" H
LEFT JOIN "PPL_LIVE"."NNM1" S
    ON H."Series" = S."Series"
   AND S."ObjectCode" = '20'
LEFT JOIN "DocBranch" B
    ON H."DocEntry" = B."DocEntry"
WHERE H."CANCELED" = 'N'
  AND H."DocStatus" = 'O'
ORDER BY
    H."DocDate" DESC,
    H."DocNum" DESC;
