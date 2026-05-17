CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_expense_tracking" AS
WITH "PettyCashAccounts" AS (
    SELECT DISTINCT
        A."AcctCode"
    FROM "PPL_LIVE"."OACT" A
    WHERE A."FatherNum" IN ('102440000', '102450000', '102460000')
),
"ExpenseLine" AS (
    SELECT
        ADD_DAYS(J."RefDate", 1 - DAYOFMONTH(J."RefDate")) AS "ReportDate",
        COALESCE(NULLIF(J."ProfitCode", ''), NULLIF(J."OcrCode2", ''), 'UNMAPPED') AS "BranchCode",
        J."Account",
        COALESCE(A."AcctName", 'UNMAPPED') AS "AccountName",
        CASE
            WHEN PCA."AcctCode" IS NOT NULL THEN 'Petty Cash'
            WHEN UPPER(COALESCE(A."AcctName", '')) LIKE '%RENT%' THEN 'Rent'
            WHEN UPPER(COALESCE(A."AcctName", '')) LIKE '%WATER%'
              OR UPPER(COALESCE(A."AcctName", '')) LIKE '%ELECTRIC%'
              OR UPPER(COALESCE(A."AcctName", '')) LIKE '%POWER%'
              OR UPPER(COALESCE(A."AcctName", '')) LIKE '%UTILITY%'
            THEN 'Utilities'
            WHEN UPPER(COALESCE(A."AcctName", '')) LIKE '%SALAR%'
              OR UPPER(COALESCE(A."AcctName", '')) LIKE '%PAYROLL%'
              OR UPPER(COALESCE(A."AcctName", '')) LIKE '%WAGE%'
              OR UPPER(COALESCE(A."AcctName", '')) LIKE '%NSSF%'
              OR UPPER(COALESCE(A."AcctName", '')) LIKE '%NHIF%'
              OR UPPER(COALESCE(A."AcctName", '')) LIKE '%PENSION%'
            THEN 'Payroll'
            ELSE 'Other Opex'
        END AS "ExpenseCategory",
        CAST(COALESCE(J."Debit", 0) - COALESCE(J."Credit", 0) AS DECIMAL(19,6)) AS "ExpenseAmount"
    FROM "PPL_LIVE"."JDT1" J
    LEFT JOIN "PPL_LIVE"."OACT" A
        ON J."Account" = A."AcctCode"
    LEFT JOIN "PPL_LIVE"."OACT" CA
        ON J."ContraAct" = CA."AcctCode"
    LEFT JOIN "PettyCashAccounts" PCA
        ON J."ContraAct" = PCA."AcctCode"
    WHERE J."RefDate" >= '2024-01-01'
      AND (
            A."GroupMask" = 5
            OR J."Account" LIKE '5%'
            OR CA."FatherNum" IN ('102440000', '102450000', '102460000')
          )
      AND UPPER(COALESCE(A."AcctName", '')) NOT LIKE '%COST OF SALES%'
      AND UPPER(COALESCE(A."AcctName", '')) NOT LIKE '%COST OF GOODS%'
      AND UPPER(COALESCE(A."AcctName", '')) NOT LIKE '%COGS%'
),
"ExpenseCategoryAgg" AS (
    SELECT
        E."ReportDate",
        E."BranchCode",
        E."ExpenseCategory",
        CAST(SUM(E."ExpenseAmount") AS DECIMAL(19,6)) AS "ExpenseAmount"
    FROM "ExpenseLine" E
    GROUP BY E."ReportDate", E."BranchCode", E."ExpenseCategory"
),
"BranchExpenseTotal" AS (
    SELECT
        E."ReportDate",
        E."BranchCode",
        CAST(SUM(E."ExpenseAmount") AS DECIMAL(19,6)) AS "BranchOperatingExpenses"
    FROM "ExpenseCategoryAgg" E
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
)
SELECT
    E."ReportDate",
    E."BranchCode",
    COALESCE(B."BranchName", 'UNMAPPED') AS "BranchName",
    COALESCE(B."Region", 'UNMAPPED') AS "Region",
    E."ExpenseCategory",
    E."ExpenseAmount",
    T."BranchOperatingExpenses",
    CASE
        WHEN COALESCE(T."BranchOperatingExpenses", 0) = 0 THEN NULL
        ELSE CAST((E."ExpenseAmount" / NULLIF(T."BranchOperatingExpenses", 0)) * 100 AS DECIMAL(19,6))
    END AS "CategorySharePct"
FROM "ExpenseCategoryAgg" E
LEFT JOIN "BranchExpenseTotal" T
    ON E."ReportDate" = T."ReportDate"
   AND E."BranchCode" = T."BranchCode"
LEFT JOIN "BranchDim" B
    ON E."BranchCode" = B."BranchCode"
WHERE E."BranchCode" NOT LIKE 'INT-%'
ORDER BY E."ReportDate" DESC, E."BranchCode", E."ExpenseCategory";

