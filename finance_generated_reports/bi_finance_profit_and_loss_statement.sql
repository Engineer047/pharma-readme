CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_profit_and_loss_statement" AS
WITH "ReportMonths" AS (
    SELECT DISTINCT
        ADD_DAYS(J."RefDate", 1 - DAYOFMONTH(J."RefDate")) AS "Period Start Date",
        LAST_DAY(J."RefDate") AS "Period End Date",
        LAST_DAY(J."RefDate") AS "Report Date",
        CAST(TO_VARCHAR(LAST_DAY(J."RefDate"), 'YYYY-MM') AS NVARCHAR(7)) AS "Month/Year"
    FROM "PPL_LIVE"."JDT1" J
    INNER JOIN "PPL_LIVE"."OACT" A
        ON J."Account" = A."AcctCode"
    WHERE J."RefDate" <= CURRENT_DATE
      AND SUBSTRING(A."AcctCode", 1, 1) IN ('4', '5', '6', '7', '8')
),
"AccountDim" AS (
    SELECT
        A."AcctCode" AS "G/L Account",
        A."AcctName" AS "Name",
        A."Postable",
        SUBSTRING(A."AcctCode", 1, 1) AS "Major Group",
        RTRIM(A."AcctCode", '0') AS "Account Prefix",
        CAST(RTRIM(A."AcctCode", '0') AS DECIMAL(19,0)) AS "Prefix Number",
        CAST(POWER(10, 10 - LENGTH(RTRIM(A."AcctCode", '0'))) AS DECIMAL(19,0)) AS "Prefix Factor",
        CAST(
            CAST(RTRIM(A."AcctCode", '0') AS DECIMAL(19,0))
            * CAST(POWER(10, 10 - LENGTH(RTRIM(A."AcctCode", '0'))) AS DECIMAL(19,0))
            + CAST(POWER(10, 10 - LENGTH(RTRIM(A."AcctCode", '0'))) AS DECIMAL(19,0))
            - 1
            AS DECIMAL(19,0)
        ) AS "Sort Upper Bound",
        CASE SUBSTRING(A."AcctCode", 1, 1)
            WHEN '4' THEN CAST(100000000000 AS DECIMAL(21,6))
            WHEN '5' THEN CAST(200000000000 AS DECIMAL(21,6))
            WHEN '6' THEN CAST(300000000000 AS DECIMAL(21,6))
            WHEN '7' THEN CAST(400000000000 AS DECIMAL(21,6))
            WHEN '8' THEN CAST(500000000000 AS DECIMAL(21,6))
            ELSE CAST(900000000000 AS DECIMAL(21,6))
        END AS "Section Sort Base"
    FROM "PPL_LIVE"."OACT" A
    WHERE SUBSTRING(A."AcctCode", 1, 1) IN ('4', '5', '6', '7', '8')
),
"AccountMovements" AS (
    SELECT
        LAST_DAY(J."RefDate") AS "Report Date",
        J."Account" AS "G/L Account",
        CAST(
            SUM(
                CASE
                    WHEN SUBSTRING(J."Account", 1, 1) IN ('4', '7')
                        THEN COALESCE(J."Credit", 0) - COALESCE(J."Debit", 0)
                    WHEN SUBSTRING(J."Account", 1, 1) IN ('5', '6', '8')
                        THEN COALESCE(J."Debit", 0) - COALESCE(J."Credit", 0)
                    ELSE COALESCE(J."Debit", 0) - COALESCE(J."Credit", 0)
                END
            ) AS DECIMAL(19,6)
        ) AS "Amount"
    FROM "PPL_LIVE"."JDT1" J
    INNER JOIN "PPL_LIVE"."OACT" A
        ON J."Account" = A."AcctCode"
    WHERE J."RefDate" <= CURRENT_DATE
      AND SUBSTRING(A."AcctCode", 1, 1) IN ('4', '5', '6', '7', '8')
    GROUP BY
        LAST_DAY(J."RefDate"),
        J."Account"
),
"AccountRollups" AS (
    SELECT
        RM."Report Date",
        RM."Period Start Date",
        RM."Period End Date",
        RM."Month/Year",
        D."G/L Account",
        D."Name",
        D."Postable",
        D."Major Group",
        D."Account Prefix",
        D."Sort Upper Bound",
        D."Section Sort Base",
        CAST(COALESCE(SUM(M."Amount"), 0) AS DECIMAL(19,6)) AS "Amount"
    FROM "ReportMonths" RM
    CROSS JOIN "AccountDim" D
    LEFT JOIN "AccountMovements" M
        ON M."Report Date" = RM."Report Date"
       AND M."G/L Account" LIKE D."Account Prefix" || '%'
    GROUP BY
        RM."Report Date",
        RM."Period Start Date",
        RM."Period End Date",
        RM."Month/Year",
        D."G/L Account",
        D."Name",
        D."Postable",
        D."Major Group",
        D."Account Prefix",
        D."Sort Upper Bound",
        D."Section Sort Base"
),
"SectionTotals" AS (
    SELECT
        RM."Report Date",
        RM."Period Start Date",
        RM."Period End Date",
        RM."Month/Year",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '4' AND A."Postable" = 'Y' THEN A."Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Turnover Amount",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '5' AND A."Postable" = 'Y' THEN A."Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Cost Of Sales Amount",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '6' AND A."Postable" = 'Y' THEN A."Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Operating Costs Amount",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '7' AND A."Postable" = 'Y' THEN A."Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Non Operating Amount",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '8' AND A."Postable" = 'Y' THEN A."Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Taxation Amount"
    FROM "ReportMonths" RM
    LEFT JOIN "AccountRollups" A
        ON RM."Report Date" = A."Report Date"
    GROUP BY
        RM."Report Date",
        RM."Period Start Date",
        RM."Period End Date",
        RM."Month/Year"
),
"StatementRows" AS (
    SELECT
        A."Report Date",
        A."Period Start Date",
        A."Period End Date",
        A."Month/Year",
        CAST((A."Section Sort Base" + CAST(A."G/L Account" AS DECIMAL(19,0))) * 10 AS BIGINT) AS "Sort Order",
        'ACCOUNT' AS "Row Type",
        A."G/L Account",
        A."Name",
        A."Amount"
    FROM "AccountRollups" A

    UNION ALL

    SELECT
        A."Report Date",
        A."Period Start Date",
        A."Period End Date",
        A."Month/Year",
        CAST(((A."Section Sort Base" + CAST(A."Sort Upper Bound" AS DECIMAL(19,0))) * 10) + 5 AS BIGINT) AS "Sort Order",
        'SUBTOTAL' AS "Row Type",
        'Total ' || A."G/L Account" AS "G/L Account",
        A."Name",
        A."Amount"
    FROM "AccountRollups" A
    WHERE A."Postable" = 'N'

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(1000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'Turnover' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(1999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Turnover' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Turnover Amount" AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(2000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'Cost of Sales' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(2999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Cost of Sales' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Cost Of Sales Amount" AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(2999999999995 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Gross Profit' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(S."Turnover Amount" - S."Cost Of Sales Amount" AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(3000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'Operating Costs' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(3999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Operating Costs' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Operating Costs Amount" AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(3999999999995 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Operating Profit' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(S."Turnover Amount" - S."Cost Of Sales Amount" - S."Operating Costs Amount" AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(4000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'Non-Operating Income and Expenditure' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(4999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Non-Operating Income and Expenditure' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Non Operating Amount" AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(4999999999995 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Profit After Financing Expenses' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(
            S."Turnover Amount"
            - S."Cost Of Sales Amount"
            - S."Operating Costs Amount"
            + S."Non Operating Amount"
            AS DECIMAL(19,6)
        ) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(5000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'Taxation and Extraordinary Items' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(5999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Taxation and Extraordinary Items' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Taxation Amount" AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(5999999999995 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Profit Period' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(
            S."Turnover Amount"
            - S."Cost Of Sales Amount"
            - S."Operating Costs Amount"
            + S."Non Operating Amount"
            - S."Taxation Amount"
            AS DECIMAL(19,6)
        ) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(6000000000000 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        '#9' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(0 AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(6000000000010 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total #9' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(0 AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(6000000000020 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        '#10' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(0 AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(6000000000030 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total #10' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(0 AS DECIMAL(19,6)) AS "Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Month/Year",
        CAST(6000000000040 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Net Profit' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(
            S."Turnover Amount"
            - S."Cost Of Sales Amount"
            - S."Operating Costs Amount"
            + S."Non Operating Amount"
            - S."Taxation Amount"
            AS DECIMAL(19,6)
        ) AS "Amount"
    FROM "SectionTotals" S
)
SELECT
    S."Report Date",
    S."Period Start Date",
    S."Period End Date",
    S."Month/Year",
    S."Sort Order",
    S."Row Type",
    S."G/L Account",
    S."Name",
    S."Amount"
FROM "StatementRows" S
ORDER BY
    S."Report Date" DESC,
    S."Sort Order";
