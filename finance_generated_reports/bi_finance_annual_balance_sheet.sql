CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_annual_balance_sheet" AS
WITH "AccountDim" AS (
    SELECT
        A."AcctCode" AS "Account Code",
        A."AcctName" AS "Account Name",
        A."FatherNum" AS "Parent Account Code",
        P."AcctName" AS "Parent Account Name",
        A."GroupMask" AS "Section Sort",
        CASE
            WHEN A."GroupMask" = 1 THEN 'Assets'
            WHEN A."GroupMask" = 2 THEN 'Liabilities'
            WHEN A."GroupMask" = 3 THEN 'Equity'
            ELSE 'Other'
        END AS "Statement Section"
    FROM "PPL_LIVE"."OACT" A
    LEFT JOIN "PPL_LIVE"."OACT" P
        ON A."FatherNum" = P."AcctCode"
    WHERE A."GroupMask" IN (1, 2, 3)
      AND A."Postable" = 'Y'
),
"ReportYears" AS (
    SELECT DISTINCT
        YEAR(J."RefDate") AS "Balance Year",
        ADD_DAYS(
            ADD_YEARS(TO_DATE(TO_NVARCHAR(YEAR(J."RefDate")) || '-01-01'), 1),
            -1
        ) AS "Report Date"
    FROM "PPL_LIVE"."JDT1" J
    INNER JOIN "PPL_LIVE"."OACT" A
        ON J."Account" = A."AcctCode"
    WHERE A."GroupMask" IN (1, 2, 3)
),
"YearlyMovements" AS (
    SELECT
        YEAR(J."RefDate") AS "Balance Year",
        J."Account" AS "Account Code",
        CAST(
            SUM(
                CASE
                    WHEN A."GroupMask" = 1
                        THEN COALESCE(J."Debit", 0) - COALESCE(J."Credit", 0)
                    ELSE COALESCE(J."Credit", 0) - COALESCE(J."Debit", 0)
                END
            ) AS DECIMAL(19,6)
        ) AS "Year Movement"
    FROM "PPL_LIVE"."JDT1" J
    INNER JOIN "PPL_LIVE"."OACT" A
        ON J."Account" = A."AcctCode"
    WHERE A."GroupMask" IN (1, 2, 3)
    GROUP BY
        YEAR(J."RefDate"),
        J."Account"
),
"AccountYearBase" AS (
    SELECT
        Y."Report Date",
        Y."Balance Year",
        A."Section Sort",
        A."Statement Section",
        A."Account Code",
        A."Account Name",
        A."Parent Account Code",
        A."Parent Account Name"
    FROM "ReportYears" Y
    CROSS JOIN "AccountDim" A
),
"AnnualBalances" AS (
    SELECT
        B."Report Date",
        B."Balance Year",
        B."Section Sort",
        B."Statement Section",
        B."Account Code",
        B."Account Name",
        B."Parent Account Code",
        B."Parent Account Name",
        CAST(
            SUM(COALESCE(M."Year Movement", 0)) OVER (
                PARTITION BY B."Account Code"
                ORDER BY B."Balance Year"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS DECIMAL(19,6)
        ) AS "Closing Balance"
    FROM "AccountYearBase" B
    LEFT JOIN "YearlyMovements" M
        ON B."Balance Year" = M."Balance Year"
       AND B."Account Code" = M."Account Code"
)
SELECT
    A."Report Date",
    A."Balance Year",
    A."Section Sort",
    A."Statement Section",
    A."Parent Account Code",
    A."Parent Account Name",
    A."Account Code",
    A."Account Name",
    A."Closing Balance"
FROM "AnnualBalances" A
WHERE A."Closing Balance" <> 0
ORDER BY
    A."Report Date" DESC,
    A."Section Sort",
    A."Parent Account Code",
    A."Account Code";
