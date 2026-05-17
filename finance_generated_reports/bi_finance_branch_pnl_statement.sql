CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_branch_pnl_statement" AS
WITH "SalesLine" AS (
    SELECT
        ADD_DAYS(H."DocDate", 1 - DAYOFMONTH(H."DocDate")) AS "ReportDate",
        L."WhsCode" AS "BranchCode",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "Revenue",
        CAST(L."GrssProfit" AS DECIMAL(19,6)) AS "GrossMargin"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'

    UNION ALL

    SELECT
        ADD_DAYS(H."DocDate", 1 - DAYOFMONTH(H."DocDate")) AS "ReportDate",
        L."WhsCode" AS "BranchCode",
        CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "Revenue",
        CAST(-1 * L."GrssProfit" AS DECIMAL(19,6)) AS "GrossMargin"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
),
"SalesAgg" AS (
    SELECT
        S."ReportDate",
        S."BranchCode",
        CAST(SUM(S."Revenue") AS DECIMAL(19,6)) AS "Revenue",
        CAST(SUM(S."GrossMargin") AS DECIMAL(19,6)) AS "GrossMargin"
    FROM "SalesLine" S
    GROUP BY S."ReportDate", S."BranchCode"
),
"ExpenseLine" AS (
    SELECT
        ADD_DAYS(J."RefDate", 1 - DAYOFMONTH(J."RefDate")) AS "ReportDate",
        COALESCE(NULLIF(J."ProfitCode", ''), NULLIF(J."OcrCode2", ''), 'UNMAPPED') AS "BranchCode",
        CAST(COALESCE(J."Debit", 0) - COALESCE(J."Credit", 0) AS DECIMAL(19,6)) AS "ExpenseAmount"
    FROM "PPL_LIVE"."JDT1" J
    LEFT JOIN "PPL_LIVE"."OACT" A
        ON J."Account" = A."AcctCode"
    WHERE J."RefDate" >= '2024-01-01'
      AND (
            A."GroupMask" = 5
            OR J."Account" LIKE '5%'
          )
      AND UPPER(COALESCE(A."AcctName", '')) NOT LIKE '%COST OF SALES%'
      AND UPPER(COALESCE(A."AcctName", '')) NOT LIKE '%COST OF GOODS%'
      AND UPPER(COALESCE(A."AcctName", '')) NOT LIKE '%COGS%'
),
"ExpenseAgg" AS (
    SELECT
        E."ReportDate",
        E."BranchCode",
        CAST(SUM(E."ExpenseAmount") AS DECIMAL(19,6)) AS "OperatingExpenses"
    FROM "ExpenseLine" E
    GROUP BY E."ReportDate", E."BranchCode"
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
"Keys" AS (
    SELECT "ReportDate", "BranchCode" FROM "SalesAgg"
    UNION
    SELECT "ReportDate", "BranchCode" FROM "ExpenseAgg"
)
SELECT
    K."ReportDate",
    K."BranchCode",
    COALESCE(B."BranchName", 'UNMAPPED') AS "BranchName",
    COALESCE(B."Region", 'UNMAPPED') AS "Region",
    COALESCE(S."Revenue", 0) AS "Revenue",
    CAST(COALESCE(S."Revenue", 0) - COALESCE(S."GrossMargin", 0) AS DECIMAL(19,6)) AS "COGS",
    COALESCE(S."GrossMargin", 0) AS "Gross Margin",
    COALESCE(E."OperatingExpenses", 0) AS "Operating Expenses",
    CAST(COALESCE(S."GrossMargin", 0) - COALESCE(E."OperatingExpenses", 0) AS DECIMAL(19,6)) AS "Net Profit"
FROM "Keys" K
LEFT JOIN "SalesAgg" S
    ON K."ReportDate" = S."ReportDate"
   AND K."BranchCode" = S."BranchCode"
LEFT JOIN "ExpenseAgg" E
    ON K."ReportDate" = E."ReportDate"
   AND K."BranchCode" = E."BranchCode"
LEFT JOIN "BranchDim" B
    ON K."BranchCode" = B."BranchCode"
WHERE K."BranchCode" NOT LIKE 'INT-%'
ORDER BY K."ReportDate" DESC, K."BranchCode";

