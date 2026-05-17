CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_DOC" AS
WITH "DocRows" AS (
    SELECT 10 AS "SortOrder", '1' AS "No", 'PROFIT AND LOSS STATEMENT' AS "Reports", '' AS "Comments", '1' AS "Priority", '' AS "Status" FROM DUMMY
    UNION ALL
    SELECT 20, 'A.', 'CONSOLIDATED (Cummulative for entire Company Branches and head office)', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 30, '1', 'Consolidated Annually', 'If Selected more Period Monthly or annually should show distribution for comparison', '', '' FROM DUMMY
    UNION ALL
    SELECT 40, '2', 'Consolidated Monthly', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 50, '3', 'Comparative Annually', 'P AND L Comparison Annually', '', '' FROM DUMMY
    UNION ALL
    SELECT 60, '4', 'Comparative Monthly', 'P AND L Comparison Monthly', '', '' FROM DUMMY
    UNION ALL
    SELECT 70, 'B.', 'P & L PER cost centre', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 80, '', 'Show Distibution for all branches, Head Office and Total', '', '', '' FROM DUMMY

    UNION ALL

    SELECT 90, '2', 'BALANCE SHEET', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 100, '', 'As at a given Period', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 110, '', 'As per;', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 120, '1', 'Annually', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 130, '2', 'Monthly', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 140, '3', 'Quartley', '', '', '' FROM DUMMY

    UNION ALL

    SELECT 150, '3', 'SALES AND PURCHASES REPORT', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 160, '1', 'Purchases Per vendor', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 170, '2', 'Sales Vs Local and Vincare Purchases', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 180, '3', 'Sales per Partner per branch', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 190, '4', 'PRODUCT SOLD PER PERSON SAMPLE', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 200, '5', 'SAMPLE SALES PER BRANCH', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 210, '6', 'Sales Value VS Purchases Value per day Sample', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 220, '7', 'Sales vs Transfer', '', '', '' FROM DUMMY

    UNION ALL

    SELECT 230, '4', 'AGING REPORT AND OTHER REPORTS', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 240, '', 'AGEING format-payables', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 250, '', 'AGEING format.xlsx-receivables Sample', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 260, '', 'PENDING POs from Branches', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 270, '', 'OPEN ITEM LIST', '', '', '' FROM DUMMY
    UNION ALL
    SELECT 280, '', 'AGEING format', '', '', '' FROM DUMMY
)
SELECT
    D."No",
    D."Reports",
    D."Comments",
    D."Priority",
    D."Status"
FROM "DocRows" D
ORDER BY D."SortOrder";
