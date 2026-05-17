CREATE OR REPLACE VIEW "PPL_LIVE"."bi_finance_ageing" AS
WITH "ReconApplied" AS (
    SELECT
        R1."ShortName",
        R1."TransId",
        R1."TransRowId",
        SUM(
            R1."ReconSum"
            * CASE
                WHEN R1."IsCredit" = 'D' THEN 1
                ELSE -1
              END
        ) AS "ReconSum"
    FROM "PPL_LIVE"."OITR" R0
    INNER JOIN "PPL_LIVE"."ITR1" R1
        ON R0."ReconNum" = R1."ReconNum"
    WHERE R0."ReconDate" <= CURRENT_DATE
    GROUP BY
        R1."ShortName",
        R1."TransId",
        R1."TransRowId"
),
"VendorOpenBase" AS (
    SELECT
        BP."CardCode" AS "Vendor Code",
        J."RefDate" AS "Posting Date",
        ADD_DAYS(J."RefDate", 1 - DAYOFMONTH(J."RefDate")) AS "Posting Month Start",
        CAST(
            -1 * (
                COALESCE(J."Debit", 0)
                - COALESCE(J."Credit", 0)
                - COALESCE(R."ReconSum", 0)
            ) AS DECIMAL(19,6)
        ) AS "Balance Due",
        COALESCE(NULLIF(BP."FatherCard", ''), BP."CardCode") AS "Consolidated BP Code",
        COALESCE(PBP."CardName", BP."CardName") AS "Consolidated BP Name"
    FROM "PPL_LIVE"."JDT1" J
    INNER JOIN "PPL_LIVE"."OCRD" BP
        ON J."ShortName" = BP."CardCode"
    LEFT JOIN "ReconApplied" R
        ON J."TransId" = R."TransId"
       AND J."Line_ID" = R."TransRowId"
       AND J."ShortName" = R."ShortName"
    LEFT JOIN "PPL_LIVE"."OCRD" PBP
        ON BP."FatherCard" = PBP."CardCode"
    WHERE J."RefDate" <= CURRENT_DATE
      AND J."IntrnMatch" = 0
      AND BP."CardType" = 'S'
),
"VendorOpenPayables" AS (
    SELECT
        V."Vendor Code",
        V."Posting Date",
        V."Posting Month Start",
        V."Balance Due",
        V."Consolidated BP Code",
        V."Consolidated BP Name"
    FROM "VendorOpenBase" V
    WHERE V."Balance Due" > 0
),
"VendorMonthly" AS (
    SELECT
        V."Vendor Code",
        YEAR(V."Posting Month Start") AS "Year",
        MONTH(V."Posting Month Start") AS "Month Number",
        MONTHNAME(V."Posting Month Start") AS "MonthName",
        CAST(SUM(V."Balance Due") AS DECIMAL(19,6)) AS "Balance Due",
        V."Consolidated BP Code",
        V."Consolidated BP Name"
    FROM "VendorOpenPayables" V
    GROUP BY
        V."Vendor Code",
        YEAR(V."Posting Month Start"),
        MONTH(V."Posting Month Start"),
        MONTHNAME(V."Posting Month Start"),
        V."Consolidated BP Code",
        V."Consolidated BP Name"
)
SELECT
    V."Vendor Code",
    V."Year",
    V."Month Number" AS "monthno",
    V."MonthName",
    V."Balance Due",
    V."Consolidated BP Code",
    V."Consolidated BP Name"
FROM "VendorMonthly" V
ORDER BY
    V."Vendor Code",
    V."Year" DESC,
    V."Month Number" DESC;
