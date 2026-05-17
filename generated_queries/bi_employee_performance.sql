CREATE OR REPLACE VIEW "PPL_LIVE"."bi_employee_performance" AS
WITH "SalesUnion" AS (
    SELECT
        YEAR(H."DocDate") AS "Year",
        MONTH(H."DocDate") AS "MonthNo",
        COALESCE(SLP."SlpName", 'UNASSIGNED') AS "SlpName",
        CAST(L."LineTotal" + L."VatSum" AS DECIMAL(19,6)) AS "SalesValue"
    FROM "PPL_LIVE"."OINV" H
    INNER JOIN "PPL_LIVE"."INV1" L
        ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "PPL_LIVE"."OSLP" SLP
        ON H."SlpCode" = SLP."SlpCode"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2023-01-01'
      AND H."DocDate" <= CURRENT_DATE

    UNION ALL

    SELECT
        YEAR(H."DocDate") AS "Year",
        MONTH(H."DocDate") AS "MonthNo",
        COALESCE(SLP."SlpName", 'UNASSIGNED') AS "SlpName",
        CAST(-(L."LineTotal" + L."VatSum") AS DECIMAL(19,6)) AS "SalesValue"
    FROM "PPL_LIVE"."ORIN" H
    INNER JOIN "PPL_LIVE"."RIN1" L
        ON H."DocEntry" = L."DocEntry"
    LEFT JOIN "PPL_LIVE"."OSLP" SLP
        ON H."SlpCode" = SLP."SlpCode"
    WHERE H."CANCELED" = 'N'
      AND H."U_CXS_FRST" = 'Y'
      AND H."DocDate" >= '2023-01-01'
      AND H."DocDate" <= CURRENT_DATE
),
"MonthlySales" AS (
    SELECT
        S."Year",
        S."MonthNo",
        S."SlpName",
        SUM(S."SalesValue") AS "MonthSales"
    FROM "SalesUnion" S
    GROUP BY S."Year", S."MonthNo", S."SlpName"
)
SELECT
    M."Year",
    M."SlpName",
    SUM(CASE WHEN M."MonthNo" = 1 THEN M."MonthSales" ELSE 0 END) AS "January",
    SUM(CASE WHEN M."MonthNo" = 2 THEN M."MonthSales" ELSE 0 END) AS "February",
    SUM(CASE WHEN M."MonthNo" = 3 THEN M."MonthSales" ELSE 0 END) AS "March",
    SUM(CASE WHEN M."MonthNo" = 4 THEN M."MonthSales" ELSE 0 END) AS "April",
    SUM(CASE WHEN M."MonthNo" = 5 THEN M."MonthSales" ELSE 0 END) AS "May",
    SUM(CASE WHEN M."MonthNo" = 6 THEN M."MonthSales" ELSE 0 END) AS "June",
    SUM(CASE WHEN M."MonthNo" = 7 THEN M."MonthSales" ELSE 0 END) AS "July",
    SUM(CASE WHEN M."MonthNo" = 8 THEN M."MonthSales" ELSE 0 END) AS "August",
    SUM(CASE WHEN M."MonthNo" = 9 THEN M."MonthSales" ELSE 0 END) AS "September",
    SUM(CASE WHEN M."MonthNo" = 10 THEN M."MonthSales" ELSE 0 END) AS "October",
    SUM(CASE WHEN M."MonthNo" = 11 THEN M."MonthSales" ELSE 0 END) AS "November",
    SUM(CASE WHEN M."MonthNo" = 12 THEN M."MonthSales" ELSE 0 END) AS "December",
    SUM(M."MonthSales") AS "Total"
FROM "MonthlySales" M
GROUP BY M."Year", M."SlpName"
ORDER BY M."Year" DESC, M."SlpName" ASC;
