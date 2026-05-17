CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_profit_and_loss_comparative_annually" AS
WITH "MaxYear" AS (
    SELECT
        COALESCE(MAX(YEAR(J."RefDate")), YEAR(CURRENT_DATE)) AS "Latest Year"
    FROM "PPL_LIVE"."JDT1" J
    INNER JOIN "PPL_LIVE"."OACT" A
        ON J."Account" = A."AcctCode"
    WHERE J."RefDate" <= CURRENT_DATE
      AND SUBSTRING(A."AcctCode", 1, 1) IN ('4', '5', '6', '7', '8')
),
"ComparisonYears" AS (
    SELECT
        MY."Latest Year" - 2 AS "Year 1 Label",
        MY."Latest Year" - 1 AS "Year 2 Label",
        MY."Latest Year" AS "Year 3 Label",
        TO_DATE(TO_NVARCHAR(MY."Latest Year") || '-12-31') AS "Report Date",
        TO_DATE(TO_NVARCHAR(MY."Latest Year") || '-01-01') AS "Period Start Date",
        TO_DATE(TO_NVARCHAR(MY."Latest Year") || '-12-31') AS "Period End Date",
        'Period 01 January to 31 December' AS "Period Label",
        'PHARMAPLUS LIVE' AS "Company",
        'Local Currency (KES)' AS "Currency",
        'Statement of Income' AS "Statement Name"
    FROM "MaxYear" MY
),
"AccountDim" AS (
    SELECT
        A."AcctCode" AS "G/L Account",
        A."AcctName" AS "Name",
        A."Postable",
        SUBSTRING(A."AcctCode", 1, 1) AS "Major Group",
        RTRIM(A."AcctCode", '0') AS "Account Prefix",
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
        END AS "Section Sort Base",
        CASE SUBSTRING(A."AcctCode", 1, 1)
            WHEN '4' THEN 'REVENUE'
            WHEN '5' THEN 'COST OF SALES'
            WHEN '6' THEN 'OPERATING COSTS'
            WHEN '7' THEN 'NON-OPERATING INCOME AND EXPENDITURE'
            WHEN '8' THEN 'TAXATION AND EXTRAORDINARY ITEMS'
            ELSE 'OTHER'
        END AS "Statement Section"
    FROM "PPL_LIVE"."OACT" A
    WHERE SUBSTRING(A."AcctCode", 1, 1) IN ('4', '5', '6', '7', '8')
),
"AccountYearMovements" AS (
    SELECT
        YEAR(J."RefDate") AS "Fiscal Year",
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
        YEAR(J."RefDate"),
        J."Account"
),
"AccountRollups" AS (
    SELECT
        CY."Company",
        CY."Currency",
        CY."Statement Name",
        CY."Report Date",
        CY."Period Start Date",
        CY."Period End Date",
        CY."Period Label",
        CY."Year 1 Label",
        CY."Year 2 Label",
        CY."Year 3 Label",
        D."Statement Section",
        D."G/L Account",
        D."Name",
        D."Postable",
        D."Major Group",
        D."Sort Upper Bound",
        D."Section Sort Base",
        CAST(COALESCE(SUM(CASE WHEN M."Fiscal Year" = CY."Year 1 Label" THEN M."Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(COALESCE(SUM(CASE WHEN M."Fiscal Year" = CY."Year 2 Label" THEN M."Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(COALESCE(SUM(CASE WHEN M."Fiscal Year" = CY."Year 3 Label" THEN M."Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "ComparisonYears" CY
    CROSS JOIN "AccountDim" D
    LEFT JOIN "AccountYearMovements" M
        ON M."G/L Account" LIKE D."Account Prefix" || '%'
    GROUP BY
        CY."Company",
        CY."Currency",
        CY."Statement Name",
        CY."Report Date",
        CY."Period Start Date",
        CY."Period End Date",
        CY."Period Label",
        CY."Year 1 Label",
        CY."Year 2 Label",
        CY."Year 3 Label",
        D."Statement Section",
        D."G/L Account",
        D."Name",
        D."Postable",
        D."Major Group",
        D."Sort Upper Bound",
        D."Section Sort Base"
),
"SectionTotals" AS (
    SELECT
        A."Company",
        A."Currency",
        A."Statement Name",
        A."Report Date",
        A."Period Start Date",
        A."Period End Date",
        A."Period Label",
        A."Year 1 Label",
        A."Year 2 Label",
        A."Year 3 Label",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '4' AND A."Postable" = 'Y' THEN A."Year 1 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Turnover Year 1",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '4' AND A."Postable" = 'Y' THEN A."Year 2 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Turnover Year 2",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '4' AND A."Postable" = 'Y' THEN A."Year 3 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Turnover Year 3",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '5' AND A."Postable" = 'Y' THEN A."Year 1 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Cost Of Sales Year 1",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '5' AND A."Postable" = 'Y' THEN A."Year 2 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Cost Of Sales Year 2",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '5' AND A."Postable" = 'Y' THEN A."Year 3 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Cost Of Sales Year 3",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '6' AND A."Postable" = 'Y' THEN A."Year 1 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Operating Costs Year 1",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '6' AND A."Postable" = 'Y' THEN A."Year 2 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Operating Costs Year 2",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '6' AND A."Postable" = 'Y' THEN A."Year 3 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Operating Costs Year 3",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '7' AND A."Postable" = 'Y' THEN A."Year 1 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Non Operating Year 1",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '7' AND A."Postable" = 'Y' THEN A."Year 2 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Non Operating Year 2",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '7' AND A."Postable" = 'Y' THEN A."Year 3 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Non Operating Year 3",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '8' AND A."Postable" = 'Y' THEN A."Year 1 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Taxation Year 1",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '8' AND A."Postable" = 'Y' THEN A."Year 2 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Taxation Year 2",
        CAST(COALESCE(SUM(CASE WHEN A."Major Group" = '8' AND A."Postable" = 'Y' THEN A."Year 3 Amount" ELSE 0 END), 0) AS DECIMAL(19,6)) AS "Taxation Year 3"
    FROM "AccountRollups" A
    GROUP BY
        A."Company",
        A."Currency",
        A."Statement Name",
        A."Report Date",
        A."Period Start Date",
        A."Period End Date",
        A."Period Label",
        A."Year 1 Label",
        A."Year 2 Label",
        A."Year 3 Label"
),
"StatementRows" AS (
    SELECT
        A."Company",
        A."Currency",
        A."Statement Name",
        A."Report Date",
        A."Period Start Date",
        A."Period End Date",
        A."Period Label",
        A."Year 1 Label",
        A."Year 2 Label",
        A."Year 3 Label",
        A."Statement Section",
        CAST((A."Section Sort Base" + CAST(A."G/L Account" AS DECIMAL(19,0))) * 10 AS BIGINT) AS "Sort Order",
        'ACCOUNT' AS "Row Type",
        A."G/L Account",
        A."Name",
        A."Year 1 Amount",
        A."Year 2 Amount",
        A."Year 3 Amount"
    FROM "AccountRollups" A

    UNION ALL

    SELECT
        A."Company",
        A."Currency",
        A."Statement Name",
        A."Report Date",
        A."Period Start Date",
        A."Period End Date",
        A."Period Label",
        A."Year 1 Label",
        A."Year 2 Label",
        A."Year 3 Label",
        A."Statement Section",
        CAST(((A."Section Sort Base" + CAST(A."Sort Upper Bound" AS DECIMAL(19,0))) * 10) + 5 AS BIGINT) AS "Sort Order",
        'SUBTOTAL' AS "Row Type",
        'Total ' || A."G/L Account" AS "G/L Account",
        A."Name",
        A."Year 1 Amount",
        A."Year 2 Amount",
        A."Year 3 Amount"
    FROM "AccountRollups" A
    WHERE A."Postable" = 'N'

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'REVENUE' AS "Statement Section",
        CAST(1000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'REVENUE' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'REVENUE' AS "Statement Section",
        CAST(1999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Revenue' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Turnover Year 1" AS "Year 1 Amount",
        S."Turnover Year 2" AS "Year 2 Amount",
        S."Turnover Year 3" AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'COST OF SALES' AS "Statement Section",
        CAST(2000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'COST OF SALES' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'COST OF SALES' AS "Statement Section",
        CAST(2999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Cost of Sales' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Cost Of Sales Year 1" AS "Year 1 Amount",
        S."Cost Of Sales Year 2" AS "Year 2 Amount",
        S."Cost Of Sales Year 3" AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'COST OF SALES' AS "Statement Section",
        CAST(2999999999995 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'GROSS PROFIT' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(S."Turnover Year 1" - S."Cost Of Sales Year 1" AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(S."Turnover Year 2" - S."Cost Of Sales Year 2" AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(S."Turnover Year 3" - S."Cost Of Sales Year 3" AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'OPERATING COSTS' AS "Statement Section",
        CAST(3000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'OPERATING COSTS' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'OPERATING COSTS' AS "Statement Section",
        CAST(3999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Operating Costs' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Operating Costs Year 1" AS "Year 1 Amount",
        S."Operating Costs Year 2" AS "Year 2 Amount",
        S."Operating Costs Year 3" AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'OPERATING COSTS' AS "Statement Section",
        CAST(3999999999995 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'OPERATING PROFIT' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(S."Turnover Year 1" - S."Cost Of Sales Year 1" - S."Operating Costs Year 1" AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(S."Turnover Year 2" - S."Cost Of Sales Year 2" - S."Operating Costs Year 2" AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(S."Turnover Year 3" - S."Cost Of Sales Year 3" - S."Operating Costs Year 3" AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'NON-OPERATING INCOME AND EXPENDITURE' AS "Statement Section",
        CAST(4000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'NON-OPERATING INCOME AND EXPENDITURE' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'NON-OPERATING INCOME AND EXPENDITURE' AS "Statement Section",
        CAST(4999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Non-Operating Income and Expenditure' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Non Operating Year 1" AS "Year 1 Amount",
        S."Non Operating Year 2" AS "Year 2 Amount",
        S."Non Operating Year 3" AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'NON-OPERATING INCOME AND EXPENDITURE' AS "Statement Section",
        CAST(4999999999995 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'PROFIT AFTER FINANCING EXPENSES' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(S."Turnover Year 1" - S."Cost Of Sales Year 1" - S."Operating Costs Year 1" + S."Non Operating Year 1" AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(S."Turnover Year 2" - S."Cost Of Sales Year 2" - S."Operating Costs Year 2" + S."Non Operating Year 2" AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(S."Turnover Year 3" - S."Cost Of Sales Year 3" - S."Operating Costs Year 3" + S."Non Operating Year 3" AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'TAXATION AND EXTRAORDINARY ITEMS' AS "Statement Section",
        CAST(5000000000000 AS BIGINT) AS "Sort Order",
        'HEADER' AS "Row Type",
        'TAXATION AND EXTRAORDINARY ITEMS' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(NULL AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'TAXATION AND EXTRAORDINARY ITEMS' AS "Statement Section",
        CAST(5999999999990 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'Total Taxation and Extraordinary Items' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        S."Taxation Year 1" AS "Year 1 Amount",
        S."Taxation Year 2" AS "Year 2 Amount",
        S."Taxation Year 3" AS "Year 3 Amount"
    FROM "SectionTotals" S

    UNION ALL

    SELECT
        S."Company",
        S."Currency",
        S."Statement Name",
        S."Report Date",
        S."Period Start Date",
        S."Period End Date",
        S."Period Label",
        S."Year 1 Label",
        S."Year 2 Label",
        S."Year 3 Label",
        'TAXATION AND EXTRAORDINARY ITEMS' AS "Statement Section",
        CAST(5999999999995 AS BIGINT) AS "Sort Order",
        'CALC' AS "Row Type",
        'NET PROFIT AFTER TAX' AS "G/L Account",
        CAST(NULL AS NVARCHAR(255)) AS "Name",
        CAST(S."Turnover Year 1" - S."Cost Of Sales Year 1" - S."Operating Costs Year 1" + S."Non Operating Year 1" - S."Taxation Year 1" AS DECIMAL(19,6)) AS "Year 1 Amount",
        CAST(S."Turnover Year 2" - S."Cost Of Sales Year 2" - S."Operating Costs Year 2" + S."Non Operating Year 2" - S."Taxation Year 2" AS DECIMAL(19,6)) AS "Year 2 Amount",
        CAST(S."Turnover Year 3" - S."Cost Of Sales Year 3" - S."Operating Costs Year 3" + S."Non Operating Year 3" - S."Taxation Year 3" AS DECIMAL(19,6)) AS "Year 3 Amount"
    FROM "SectionTotals" S
)
SELECT
    S."Company",
    S."Currency",
    S."Statement Name",
    S."Report Date",
    S."Period Start Date",
    S."Period End Date",
    S."Period Label",
    S."Year 1 Label",
    S."Year 2 Label",
    S."Year 3 Label",
    S."Statement Section",
    S."Sort Order",
    S."Row Type",
    S."G/L Account",
    S."Name",
    S."Year 1 Amount",
    S."Year 2 Amount",
    S."Year 3 Amount",
    CAST(
        COALESCE(S."Year 1 Amount", 0)
        + COALESCE(S."Year 2 Amount", 0)
        + COALESCE(S."Year 3 Amount", 0)
        AS DECIMAL(19,6)
    ) AS "TOTAL"
FROM "StatementRows" S
ORDER BY
    S."Sort Order";
