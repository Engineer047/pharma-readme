CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_profit_&_loss_per_cost_centre" AS
WITH "SalesLine" AS (
    SELECT
        ADD_DAYS(H."DocDate", 1 - DAYOFMONTH(H."DocDate")) AS "Report Date",
        L."WhsCode" AS "BranchCode",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "Revenue",
        CAST(L."GrssProfit" AS DECIMAL(19,6)) AS "Gross Margin"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'

    UNION ALL

    SELECT
        ADD_DAYS(H."DocDate", 1 - DAYOFMONTH(H."DocDate")) AS "Report Date",
        L."WhsCode" AS "BranchCode",
        CAST(-1 * (L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "Revenue",
        CAST(-1 * L."GrssProfit" AS DECIMAL(19,6)) AS "Gross Margin"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2024-01-01'
),
"SalesAgg" AS (
    SELECT
        S."Report Date",
        S."BranchCode",
        CAST(SUM(S."Revenue") AS DECIMAL(19,6)) AS "Revenue",
        CAST(SUM(S."Gross Margin") AS DECIMAL(19,6)) AS "Gross Margin"
    FROM "SalesLine" S
    GROUP BY
        S."Report Date",
        S."BranchCode"
),
"ExpenseLine" AS (
    SELECT
        ADD_DAYS(J."RefDate", 1 - DAYOFMONTH(J."RefDate")) AS "Report Date",
        COALESCE(NULLIF(J."ProfitCode", ''), NULLIF(J."OcrCode2", ''), 'UNMAPPED') AS "BranchCode",
        CAST(COALESCE(J."Debit", 0) - COALESCE(J."Credit", 0) AS DECIMAL(19,6)) AS "Operating Expenses"
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
        E."Report Date",
        E."BranchCode",
        CAST(SUM(E."Operating Expenses") AS DECIMAL(19,6)) AS "Operating Expenses"
    FROM "ExpenseLine" E
    GROUP BY
        E."Report Date",
        E."BranchCode"
),
"BranchDim" AS (
    SELECT
        W."WhsCode" AS "BranchCode",
        MAX(W."WhsName") AS "BranchName",
        MAX(COALESCE(L."Location", 'UNMAPPED')) AS "Region"
    FROM "PPL_LIVE"."OWHS" W
    LEFT JOIN "PPL_LIVE"."OLCT" L
        ON W."Location" = L."Code"
    GROUP BY
        W."WhsCode"
),
"Keys" AS (
    SELECT
        S."Report Date",
        S."BranchCode"
    FROM "SalesAgg" S

    UNION

    SELECT
        E."Report Date",
        E."BranchCode"
    FROM "ExpenseAgg" E
),
"BasePnL" AS (
    SELECT
        K."Report Date",
        CASE
            WHEN K."BranchCode" = 'UNMAPPED' THEN 'HEAD_OFFICE'
            ELSE K."BranchCode"
        END AS "Cost Centre Code",
        CASE
            WHEN K."BranchCode" = 'UNMAPPED' THEN 'HEAD OFFICE'
            ELSE COALESCE(B."BranchName", 'UNMAPPED')
        END AS "Cost Centre Name",
        CASE
            WHEN K."BranchCode" = 'UNMAPPED' THEN 'HEAD OFFICE'
            ELSE COALESCE(B."Region", 'UNMAPPED')
        END AS "Region",
        COALESCE(S."Revenue", 0) AS "Revenue",
        CAST(COALESCE(S."Revenue", 0) - COALESCE(S."Gross Margin", 0) AS DECIMAL(19,6)) AS "COGS",
        COALESCE(S."Gross Margin", 0) AS "Gross Margin",
        COALESCE(E."Operating Expenses", 0) AS "Operating Expenses",
        CAST(COALESCE(S."Gross Margin", 0) - COALESCE(E."Operating Expenses", 0) AS DECIMAL(19,6)) AS "Net Profit"
    FROM "Keys" K
    LEFT JOIN "SalesAgg" S
        ON K."Report Date" = S."Report Date"
       AND K."BranchCode" = S."BranchCode"
    LEFT JOIN "ExpenseAgg" E
        ON K."Report Date" = E."Report Date"
       AND K."BranchCode" = E."BranchCode"
    LEFT JOIN "BranchDim" B
        ON K."BranchCode" = B."BranchCode"
    WHERE K."BranchCode" NOT LIKE 'INT-%'
),
"PnLRows" AS (
    SELECT
        B."Report Date",
        B."Cost Centre Code",
        B."Cost Centre Name",
        B."Region",
        10 AS "Line Sort",
        'Revenue' AS "PnL Line",
        CAST(B."Revenue" AS DECIMAL(19,6)) AS "Amount"
    FROM "BasePnL" B

    UNION ALL

    SELECT
        B."Report Date",
        B."Cost Centre Code",
        B."Cost Centre Name",
        B."Region",
        20 AS "Line Sort",
        'COGS' AS "PnL Line",
        CAST(B."COGS" AS DECIMAL(19,6)) AS "Amount"
    FROM "BasePnL" B

    UNION ALL

    SELECT
        B."Report Date",
        B."Cost Centre Code",
        B."Cost Centre Name",
        B."Region",
        30 AS "Line Sort",
        'Gross Margin' AS "PnL Line",
        CAST(B."Gross Margin" AS DECIMAL(19,6)) AS "Amount"
    FROM "BasePnL" B

    UNION ALL

    SELECT
        B."Report Date",
        B."Cost Centre Code",
        B."Cost Centre Name",
        B."Region",
        40 AS "Line Sort",
        'Operating Expenses' AS "PnL Line",
        CAST(B."Operating Expenses" AS DECIMAL(19,6)) AS "Amount"
    FROM "BasePnL" B

    UNION ALL

    SELECT
        B."Report Date",
        B."Cost Centre Code",
        B."Cost Centre Name",
        B."Region",
        50 AS "Line Sort",
        'Net Profit' AS "PnL Line",
        CAST(B."Net Profit" AS DECIMAL(19,6)) AS "Amount"
    FROM "BasePnL" B
),
"TotalCompany" AS (
    SELECT
        R."Report Date",
        'TOTAL_COMPANY' AS "Cost Centre Code",
        'TOTAL COMPANY' AS "Cost Centre Name",
        'ALL' AS "Region",
        R."Line Sort",
        R."PnL Line",
        CAST(SUM(R."Amount") AS DECIMAL(19,6)) AS "Amount"
    FROM "PnLRows" R
    GROUP BY
        R."Report Date",
        R."Line Sort",
        R."PnL Line"
)
SELECT
    R."Report Date",
    YEAR(R."Report Date") AS "Report Year",
    MONTH(R."Report Date") AS "Report Month Number",
    MONTHNAME(R."Report Date") AS "Report Month Name",
    R."Cost Centre Code",
    R."Cost Centre Name",
    R."Region",
    R."Line Sort",
    R."PnL Line",
    R."Amount"
FROM (
    SELECT
        P."Report Date",
        P."Cost Centre Code",
        P."Cost Centre Name",
        P."Region",
        P."Line Sort",
        P."PnL Line",
        P."Amount"
    FROM "PnLRows" P

    UNION ALL

    SELECT
        T."Report Date",
        T."Cost Centre Code",
        T."Cost Centre Name",
        T."Region",
        T."Line Sort",
        T."PnL Line",
        T."Amount"
    FROM "TotalCompany" T
) R
ORDER BY
    R."Report Date" DESC,
    R."Line Sort",
    R."Cost Centre Name";
