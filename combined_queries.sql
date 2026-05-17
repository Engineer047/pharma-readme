-- ===============================================
-- Source: BI_AP_INVOICE.txt
-- ===============================================
BI_AP_INVOICE

CREATE VIEW "PPL_LIVE"."BI_AP_INVOICE" ( "Invoice No",
	 "Invoice Date",
	 "Supplier Invoice No",
	 "CardCode",
	 "DocCur",
	 "GRN No",
	 "PO No",
	 "ItemCode",
	 "Invoice Qty",
	 "Invoice Price",
	 "Invoice Line Total",
	 "Invoice Tax Amount",
	 "GRN Qty",
	 "GRN Price",
	 "GRN Line Total",
	 "GRN Tax Amount" ) AS ((select
	 T0."DocNum" "Invoice No",
	T0."DocDate" "Invoice Date",
	T0."NumAtCard" "Supplier Invoice No",
	T0."CardCode",
	T0."DocCur",
	 T3."DocNum" "GRN No",
	T5."DocNum" "PO No",
	T1."ItemCode",
	T1."Quantity" "Invoice Qty",
	T1."Price" "Invoice Price",
	 CASE WHEN T0."DocCur"='KES' 
		then T1."LineTotal" 
		ELSE T1."TotalFrgn" 
		end "Invoice Line Total",
	 CASE WHEN T0."DocCur"='KES' 
		then T1."VatSum" 
		ELSE T1."VatSumFrgn" 
		END "Invoice Tax Amount",
	 T2."Quantity" "GRN Qty",
	T2."Price" "GRN Price",
	 CASE WHEN T0."DocCur"='KES' 
		then T2."LineTotal" 
		ELSE T2."TotalFrgn" 
		end "GRN Line Total",
	 CASE WHEN T0."DocCur"='KES' 
		then T2."VatSum" 
		ELSE T2."VatSumFrgn" 
		END "GRN Tax Amount" 
		from OPCH T0 
		INNER JOIN PCH1 T1 ON T0."DocEntry"=T1."DocEntry" 
		and T0."DocType"='I' 
		INNER JOIN PDN1 T2 ON T1."BaseEntry"=T2."DocEntry" 
		and T1."BaseLine"=T2."LineNum" 
		INNER JOIN OPDN T3 ON T2."DocEntry"=T3."DocEntry" 
		LEFT JOIN POR1 T4 ON T4."DocEntry"=T2."BaseEntry" 
		and T2."BaseLine"=T4."LineNum" 
		LEFT JOIN OPOR T5 ON T5."DocEntry"=T4."DocEntry") 
	UNION ALL (select
	 T0."DocNum" "Invoice No",
	T0."DocDate" "Invoice Date",
	T0."NumAtCard" "Supplier Invoice No",
	T0."CardCode",
	T0."DocCur",
	 '0' "GRN No",
	'0' "PO No",
	T1."ItemCode",
	T1."Quantity" "Invoice Qty",
	T1."Price" "Invoice Price",
	 CASE WHEN T0."DocCur"='KES' 
		then T1."LineTotal" 
		ELSE T1."TotalFrgn" 
		end "Invoice Line Total",
	 CASE WHEN T0."DocCur"='KES' 
		then T1."VatSum" 
		ELSE T1."VatSumFrgn" 
		END "Invoice Tax Amount",
	 '0' "GRN Qty",
	'0' "GRN Price",
	 '0' "GRN Line Total",
	 '0' "GRN Tax Amount" 
		from OPCH T0 
		INNER JOIN PCH1 T1 ON T0."DocEntry"=T1."DocEntry" 
		and T0."DocType"='I' 
		AND T1."BaseType"='-1') 
	order by "Invoice No",
	"Invoice Date") WITH READ ONLY

GO

-- ===============================================
-- Source: BI_BP_MASTER_NEW.txt
-- ===============================================
BI_BP_MASTER_NEW

CREATE VIEW "PPL_LIVE"."BI_BP_MASTER_NEW" ( "CardCode",
	 "CardName",
	 "Foreign Name",
	 "GroupName",
	 "CardType",
	 "Phone1",
	 "Phone2",
	 "CntctPrsn",
	 "Payterm",
	 "CreditLine",
	 "LicTradNum",
	 "ListName",
	 "SlpName",
	 "Currency",
	 "Cellular",
	 "City",
	 "County",
	 "Country",
	 "E_Mail",
	 "Category",
	 "Territory",
	 "CreateDate" ) AS SELECT
	 T0."CardCode",
	 T0."CardName",
	 T0."CardFName" "Foreign Name",
	 T5."GroupName",
	 T0."CardType",
	 T0."Phone1",
	 T0."Phone2",
	 T0."CntctPrsn",
	 T4."PymntGroup" "Payterm",
	 T0."CreditLine",
	 T0."LicTradNum",
	 T2."ListName",
	 T1."SlpName",
	 T0."Currency",
	 T0."Cellular",
	 T0."City",
	 T0."County",
	 T0."Country",
	 T0."E_Mail",
	 CASE WHEN T0."QryGroup1"='Y' 
THEN 'STOCK SUPPLIERS' WHEN T0."QryGroup2"='Y' 
THEN 'SERVICE SUPPLIERS' WHEN T0."QryGroup3"='Y' 
THEN 'CASH CUSTOMER' WHEN T0."QryGroup4"='Y' 
THEN 'CREDIT CUSTOMER' WHEN T0."QryGroup5"='Y' 
THEN 'PARTNERSHIPS' WHEN T0."QryGroup6"='Y' 
END "Groups"
	 T3."descript" "Territory",
	 T0."CreateDate" 
FROM OCRD T0 
LEFT JOIN OSLP T1 ON T0."SlpCode" = T1."SlpCode" 
LEFT JOIN OPLN T2 ON T0."ListNum" = T2."ListNum" 
LEFT JOIN OTER T3 ON T0."Territory" = T3."territryID" 
LEFT JOIN OCTG T4 ON T0."GroupNum" = T4."GroupNum" 
LEFT JOIN OCRG T5 ON T0."GroupCode" = T5."GroupCode" 
ORDER BY T0."CardType",
	 T0."CardCode" WITH READ ONLY

GO

-- ===============================================
-- Source: BI_CASH_CUSTOMER_AGING.txt
-- ===============================================
BI_CASH_CUSTOMER_AGING

CREATE VIEW "PPL_LIVE"."BI_CASH_CUSTOMER_AGING" ( "CardCode",
	 "CardName",
	 "PAYTERM",
	 "SALESREP",
	 "CREDITTERM",
	 "DOCNUM",
	 "CURRENCY",
	 "POSTINGDATE",
	 "DOCUMENTDATE",
	 "LC_BALANCE",
	 "LC_FUTURE",
	 "LC_CURRENT",
	 "LC_31_60_DAYS",
	 "LC_61_90_DAYS",
	 "LC_91_120_DAYS",
	 "LC_120_150_DAYS",
	 "LC_150_180_DAYS",
	 "LC_180_DAYS" ) AS SELECT
	 T1."CardCode",
	 T1."CardName" ,
	 T6."PymntGroup" "PAYTERM",
	 T5."SlpName" "SALESREP",
	 T1."CreditLine" "CREDITTERM",
	 T3."DocNum" "DOCNUM",
	 CASE WHEN T0."FCCurrency" IS NULL 
THEN 'KES' WHEN T0."FCCurrency" = 'USD' 
THEN 'USD' -- WHEN T0."FCCurrency" = 'KES' THEN 'KES'
 WHEN T0."FCCurrency" = 'EUR' 
THEN 'EUR' WHEN T0."FCCurrency" = 'GBP' 
THEN 'GBP' WHEN T0."FCCurrency" = 'TZS' 
THEN 'TZS' 
END as Currency ,
	 T0."RefDate" "POSTINGDATE",
	 T0."TaxDate" "DOCUMENTDATE",
	 (T0."Debit"-T0."Credit"-COALESCE(T7."ReconSum",
	 0)) "LC_BALANCE" ,
	 IFNULL((SELECT
	 T0."Debit"-T0."Credit" -COALESCE(T7."ReconSum",
	 0) 
		FROM DUMMY 
		WHERE (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
					FROM DUMMY ))<=-1)),
	 0) "LC_FUTURE" ,
	 IFNULL((SELECT
	 T0."Debit"-T0."Credit" -COALESCE(T7."ReconSum",
	 0) 
		FROM DUMMY 
		WHERE (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
					FROM DUMMY))>=0 
			and (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
						FROM DUMMY))<=30))),
	 0) "LC_CURRENT" ,
	 IFNULL((SELECT
	 T0."Debit"-T0."Credit" -COALESCE(T7."ReconSum",
	 0) 
		FROM DUMMY 
		WHERE (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
					FROM DUMMY))>30 
			and (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
						FROM DUMMY))<=60))),
	 0) "LC_31_60_DAYS" ,
	 IFNULL((SELECT
	 T0."Debit"-T0."Credit" -COALESCE(T7."ReconSum",
	 0) 
		FROM DUMMY 
		WHERE (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
					FROM DUMMY))>60 
			and (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
						FROM DUMMY))<=90))),
	 0) "LC_61_90_DAYS" ,
	 IFNULL((SELECT
	 T0."Debit"-T0."Credit" -COALESCE(T7."ReconSum",
	 0) 
		FROM DUMMY 
		WHERE (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
					FROM DUMMY ))>90 
			and (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
						FROM DUMMY))<=120))),
	 0) "LC_91_120_DAYS" ,
	 IFNULL((SELECT
	 T0."Debit"-T0."Credit" -COALESCE(T7."ReconSum",
	 0) 
		FROM DUMMY 
		WHERE (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
					FROM DUMMY))>120 
			and (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
						FROM DUMMY))<=150))),
	 0) "LC_120_150_DAYS" ,
	 IFNULL((SELECT
	 T0."Debit"-T0."Credit" -COALESCE(T7."ReconSum",
	 0) 
		FROM DUMMY 
		WHERE (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
					FROM DUMMY))>150 
			and (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
						FROM DUMMY))<=180))),
	 0) "LC_150_180_DAYS" ,
	 IFNULL((SELECT
	 T0."Debit"-T0."Credit" -COALESCE(T7."ReconSum",
	 0) 
		FROM DUMMY 
		WHERE (DAYS_BETWEEN(T0."RefDate" ,
	 (SELECT
	 CURRENT_DATE 
					FROM DUMMY))>=181)),
	 0) "LC_180_DAYS" ---------------------------------------------------------------------------------------------------------------------------
 
FROM "PPL_LIVE"."JDT1" T0 
INNER JOIN "PPL_LIVE"."OCRD" T1 ON T0."ShortName" = T1."CardCode" 
left join "PPL_LIVE"."OCTG" T6 on T6."GroupNum"=T1."GroupNum" 
left join "PPL_LIVE"."OSLP" T5 on T5."SlpCode"=T1."SlpCode" 
LEFT OUTER JOIN "PPL_LIVE"."OINV" T3 ON T0."TransType" = T3."ObjType" 
AND T0."TransId" = T3."TransId" 
LEFT OUTER JOIN "PPL_LIVE"."ORIN" T4 ON T0."TransType" = T4."ObjType" 
AND T0."TransId" = T4."TransId" 
LEFT JOIN ( SELECT
	 T4."ShortName",
	 T4."TransId",
	 T4."TransRowId",
	 SUM( T4."ReconSum" * CASE WHEN T4."IsCredit" = 'D' 
		THEN 1 
		ELSE -1 
		END ) AS "ReconSum" 
	FROM "PPL_LIVE"."OITR" T3 
	INNER JOIN "PPL_LIVE"."ITR1" T4 ON T3."ReconNum" = T4."ReconNum" 
	WHERE T3."ReconDate" <= (SELECT
	 CURRENT_DATE 
		FROM DUMMY) 
	GROUP BY T4."ShortName",
	 T4."TransRowId",
	 T4."TransId" ) T7 ON T0."TransId" = T7."TransId" 
AND T7."TransRowId" = T0."Line_ID" 
AND T0."ShortName" = T7."ShortName" 
WHERE T0."RefDate" <= (SELECT
	 CURRENT_DATE 
	FROM DUMMY) 
and T0."IntrnMatch" = 0 
AND T1."CardType" = 'C' 
AND (T0."Debit"-T0."Credit"-COALESCE(T7."ReconSum",
	 0)) <> 0 
ORDER BY T1."CardCode" WITH READ ONLY

GO

-- ===============================================
-- Source: BI_COA.txt
-- ===============================================
BI_COA

CREATE VIEW "PPL_LIVE"."BI_COA" ( "AcctCode",
	 "AcctName",
	 "CurrTotal",
	 "FatherNum",
	 "GroupMask",
	 "Postable" ) AS SELECT
	 T0."AcctCode",
	T0."AcctName",
	T0."CurrTotal",
	T0."FatherNum",
	T0."GroupMask",
	T0."Postable" 
FROM OACT T0

GO

-- ===============================================
-- Source: BI_CURRENT_INVENTORY_FINAL.txt
-- ===============================================
BI_CURRENT_INVENTORY_FINAL

CREATE VIEW "PPL_LIVE"."BI_CURRENT_INVENTORY_FINAL" ( "Warehouse",
	 "ItemCode",
	 "SUM(InQty-OutQty)",
	 "Stock Value" ) AS SELECT
	 T0."Warehouse",
	 T0."ItemCode",
	 sum(T0."InQty"-T0."OutQty"),
	 sum(T0."TransValue") "Stock Value" 
FROM OINM T0 
GROUP BY T0."Warehouse",
	 T0."ItemCode" HAVING sum(T0."InQty"-T0."OutQty")<>0 
and sum(T0."TransValue") <>'0' WITH READ ONLY

GO

-- ===============================================
-- Source: BI_CUSTOMER_OUTSTANDING.txt
-- ===============================================
BI_CUSTOMER_OUTSTANDING

CREATE VIEW "PPL_LIVE"."BI_CUSTOMER_OUTSTANDING" ( "Customer Code",
	 "TransType",
	 "DocNum",
	 "Doc Date",
	 "Due Date",
	 "Balance" ) AS select
	 T1."ShortName" "Customer Code",
	T1."TransType",
	T0."BaseRef" "DocNum",
	 TO_VARCHAR(T1."RefDate",
	'YYYY-MM-DD') "Doc Date",
	 TO_VARCHAR(T1."DueDate",
	'YYYY-MM-DD') "Due Date",
	 (T1."BalDueDeb"-T1."BalDueCred")"Balance" 
FROM OJDT T0 
INNER JOIN JDT1 T1 ON T0."TransId" = T1."TransId" 
INNER JOIN OCRD T2 ON T1."ShortName" = T2."CardCode" 
AND T2."CardType"='C' 
where (T1."BalDueDeb"<>0 
	or T1."BalDueCred"<>0) WITH READ ONLY

GO

-- ===============================================
-- Source: BI_GL_TRANSACTIONS.txt
-- ===============================================
BI_GL_TRANSACTIONS

CREATE VIEW "PPL_LIVE"."BI_GL_TRANSACTIONS" ( "TransId",
	 "ProfitCode",
	 "OcrCode2",
	 "RefDate",
	 "Account",
	 "Debit",
	 "Credit" ) AS select
	 T0."TransId",
	 T0."ProfitCode",
	 T0."OcrCode2",
	 T0."RefDate",
	 T0."Account",
	 T0."Debit",
	 T0."Credit" 
from JDT1 T0

GO

-- ===============================================
-- Source: BI_GRN_FINAL.txt
-- ===============================================
BI_GRN_FINAL

CREATE VIEW "PPL_LIVE"."BI_GRN_FINAL" ( "DocType",
	 "DocNum",
	 "DocDate",
	 "CardCode",
	 "ItemCode",
	 "Purchase UoM",
	 "Quantity",
	 "DocDueDate",
	 "GRN STATUS",
	 "DocCur",
	 "PO NO",
	 "Supplier Inv. No",
	 "Line Total",
	 "Tax Amount",
	 "DiscPrcnt",
	 "Base Qty",
	 "Base UoM",
	 "LineTotal",
	 "GRN CREATER" ) AS SELECT
	 T0."DocType",
	 T0."DocNum",
	 T0."DocDate",
	 T0."CardCode",
	 T3."ItemCode",
	 T3."unitMsr" "Purchase UoM",
	 T3."Quantity",
	 T0."DocDueDate",
	 (Case when T0."DocStatus"='O' 
	THEN 'OPEN' WHEN T0."DocStatus"='C' 
	THEN 'CLOSE' 
	ELSE T0."DocStatus" 
	END) "GRN STATUS",
	 T0."DocCur",
	 T3."BaseRef" "PO NO",
	 T0."NumAtCard" "Supplier Inv. No",
	 (CASE WHEN T0."DocCur"='KES' 
	THEN T3."LineTotal" 
	ELSE T3."TotalFrgn" 
	END) "Line Total",
	 (CASE WHEN T0."DocCur"='KES' 
	THEN T3."VatSum" 
	ELSE T3."VatSumFrgn" 
	END) "Tax Amount",
	 T3."DiscPrcnt",
	 T3."InvQty" "Base Qty",
	 T3."unitMsr2" "Base UoM",
	 T3."LineTotal",
	 T1."U_NAME" "GRN CREATER" 
FROM OPDN T0 
INNER JOIN PDN1 T3 ON T0."DocEntry"=T3."DocEntry" 
INNER JOIN OUSR T1 ON T1."USERID"=T0."UserSign" 
AND T0."CANCELED"='N' WITH READ ONLY

GO

-- ===============================================
-- Source: BI_INVENTORY_TRANSACTIONS.txt
-- ===============================================
BI_INVENTORY_TRANSACTIONS

CREATE VIEW "PPL_LIVE"."BI_INVENTORY_TRANSACTIONS" ( "ItemCode",
	 "Warehouse",
	 "DocNum",
	 "TransType",
	 "DocDate",
	 "InQty",
	 "OutQty",
	 "TransValue",
	 "CREATED BY" ) AS SELECT
	 T0."ItemCode",
	 T0."Warehouse",
	 T0."BASE_REF" "DocNum",
	 T0."TransType",
	 T0."DocDate",
	 T0."InQty",
	 T0."OutQty",
	 T0."TransValue",
	 T1."U_NAME" "CREATED BY" 
FROM OINM T0 
INNER JOIN OUSR T1 ON T1."USERID"=T0."UserSign" 
WHERE T0."DocDate" > ADD_YEARS (CAST(CONCAT(YEAR(CURRENT_TIMESTAMP),
	'0630') AS DATE),
	 -3) WITH READ ONLY

GO

-- ===============================================
-- Source: BI_INVENTORY_TRANSACTIONS_CURRENT.txt
-- ===============================================
BI_INVENTORY_TRANSACTIONS_CURRENT

CREATE VIEW "PPL_LIVE"."BI_INVENTORY_TRANSACTIONS_CURRENT" ( "ItemCode",
	 "Warehouse",
	 "DocNum",
	 "TransType",
	 "DocDate",
	 "InQty",
	 "OutQty",
	 "TransValue",
	 "CREATED BY" ) AS SELECT
	 T0."ItemCode",
	 T0."Warehouse",
	 T0."BASE_REF" "DocNum",
	 T0."TransType",
	 T0."DocDate",
	 T0."InQty",
	 T0."OutQty",
	 T0."TransValue",
	 T1."U_NAME" "CREATED BY" 
FROM OINM T0 
INNER JOIN OUSR T1 ON T1."USERID"=T0."UserSign" 
WHERE "DocDate" >= '20250401' WITH READ ONLY

GO

-- ===============================================
-- Source: BI_INVENTORY_TRANSACTIONS_HISTORICA.txt
-- ===============================================
BI_INVENTORY_TRANSACTIONS_HISTORICAL

CREATE VIEW "PPL_LIVE"."BI_INVENTORY_TRANSACTIONS_HISTORICAL" ( "ItemCode",
	 "Warehouse",
	 "DocNum",
	 "TransType",
	 "DocDate",
	 "InQty",
	 "OutQty",
	 "TransValue",
	 "CREATED BY" ) AS SELECT
	 T0."ItemCode",
	 T0."Warehouse",
	 T0."BASE_REF" "DocNum",
	 T0."TransType",
	 T0."DocDate",
	 T0."InQty",
	 T0."OutQty",
	 T0."TransValue",
	 T1."U_NAME" "CREATED BY" 
FROM OINM T0 
INNER JOIN OUSR T1 ON T1."USERID"=T0."UserSign" 
WHERE "DocDate" <= '20250331' WITH READ ONLY

GO

-- ===============================================
-- Source: BI_INVENTORY_TRANSFER.txt
-- ===============================================
BI_INVENTORY_TRANSFER

CREATE VIEW "PPL_LIVE"."BI_INVENTORY_TRANSFER" ( "Transfer No",
	 "Transfer Date",
	 "Request No",
	 "Requested Date",
	 "ItemCode",
	 "FromWhsCod",
	 "To Warehouse",
	 "Transfer Qty",
	 "Request Qty" ) AS ((SELECT
	 top 500 T0."DocNum" "Transfer No",
	 T0."DocDate" "Transfer Date",
	T3."DocNum" "Request No",
	T3."DocDate" "Requested Date",
	 T1."ItemCode",
	 T1."FromWhsCod",
	T1."WhsCode" "To Warehouse",
	 T1."InvQty" "Transfer Qty",
	T2."InvQty" "Request Qty" 
		FROM OWTR T0 
		INNER JOIN WTR1 T1 ON T0."DocEntry" = T1."DocEntry" 
		INNER JOIN WTQ1 T2 ON T1."BaseEntry"=T2."DocEntry" 
		AND T1."BaseLine"=T2."LineNum" 
		INNER JOIN OWTQ T3 ON T2."DocEntry"=T3."DocEntry") 
	UNION ALL (SELECT
	 top 500 T0."DocNum" "Transfer No",
	 T0."DocDate" "Transfer Date",
	'0' "Request No",
	'' "Requested Date",
	 T1."ItemCode",
	 T1."FromWhsCod",
	T1."WhsCode" "To Warehouse",
	 T1."InvQty" "Transfer Qty",
	'0' "Request Qty" 
		FROM OWTR T0 
		INNER JOIN WTR1 T1 ON T0."DocEntry" = T1."DocEntry" 
		AND T1."BaseType"='-1')) WITH READ ONLY

GO

-- ===============================================
-- Source: BI_ITEM_MASTER.txt
-- ===============================================
BI_ITEM_MASTER

CREATE VIEW "PPL_LIVE"."BI_ITEM_MASTER" ( "ItemCode",
	 "ItemName",
	 "FrgnName",
	 "UgpEntry",
	 "UomCode",
	 "ItmsGrpNam",
	 "U_SubCat1",
	 "CardCode",
	 "CreateDate",
	 "Active/InActive",
	 "U_SubCat2",
	 "U_SubCat3",
	 "U_Brand",
	 "U_Formulation",
	 "U_ LongTermProducts",
	 "U_GlovoProduct",
	 "U_BOY_TB_0",
	 "U_Essentials",
	 "U_EssentialsBDM",
	 "U_ActiveIngredient",
	 "U_ControlledProducts",
	 "U_PurchaseCat",
	 "Wholesale Price",
	 "Pos Price",
	 "CodeBars" ) AS SELECT
	 T0."ItemCode",
	 T0."ItemName",
	 T0."FrgnName",
	 T0."UgpEntry",
	 T8."UomCode",
	 T1."ItmsGrpNam",
	 T0."U_SubCat1",
	 T2."CardCode",
	 T0."CreateDate",
	 T0."validFor" "Active/InActive",
	 T0."U_SubCat2",
	 T0."U_SubCat3",
	 T0."U_Brand",
	 T0."U_Formulation" ,
	 T0."U_ LongTermProducts",
	 T0."U_GlovoProduct",
	 T0."U_BOY_TB_0",
	 T0."U_Essentials",
	 T0."U_EssentialsBDM",
	 T0."U_ActiveIngredient",
	 T0."U_ControlledProducts",
	 T0."U_PurchaseCat"
	 (select
	 S."Price" 
	from ITM1 S 
	where T0."ItemCode"=S."ItemCode" 
	and S."PriceList"='2')"Wholesale Price",
	 (select
	 S."Price" 
	from ITM1 S 
	where T0."ItemCode"=S."ItemCode" 
	and S."PriceList"='1') "Pos Price",
	 T0."CodeBars" 
FROM OITM T0 
INNER JOIN OITB T1 ON T0."ItmsGrpCod" = T1."ItmsGrpCod" 
LEFT JOIN OCRD T2 ON T0."CardCode" = T2."CardCode" 
LEFT JOIN OUOM T8 ON T0."IUoMEntry"= T8."UomEntry" WITH READ ONLY

GO

-- ===============================================
-- Source: BI_OPENING_INVENTORY.txt
-- ===============================================
BI_OPENING_INVENTORY

CREATE VIEW "PPL_LIVE"."BI_OPENING_INVENTORY" ( "ItemCode",
	 "Warehouse",
	 "DocNum",
	 "TransType",
	 "DocDate",
	 "InQty",
	 "OutQty",
	 "TransValue",
	 "CREATED BY" ) AS SELECT
	 T0."ItemCode",
	 T0."Warehouse",
	 'OpeningBal' "DocNum",
	 '00' "TransType",
	 ADD_YEARS (CAST(CONCAT(YEAR(CURRENT_TIMESTAMP),
	'0630') AS DATE),
	 -3) "DocDate",
	 SUM(T0."InQty") "InQty",
	 SUM(T0."OutQty") "OutQty",
	 SUM(T0."TransValue") "TransValue",
	 'Admin' "CREATED BY" 
FROM OINM T0 
INNER JOIN OUSR T1 ON T1."USERID"=T0."UserSign" 
WHERE T0."DocDate" <= ADD_YEARS (CAST(CONCAT(YEAR(CURRENT_TIMESTAMP),
	'0630') AS DATE),
	 -3) 
GROUP BY T0."ItemCode",
	T0."Warehouse" WITH READ ONLY

GO

-- ===============================================
-- Source: BI_PETTY_CASH.txt
-- ===============================================
BI_PETTY_CASH

CREATE VIEW "PPL_LIVE"."BI_PETTY_CASH" ( "TransId",
	 "RefDate",
	 "Account",
	 "Debit",
	 "Credit",
	 "Project",
	 "ProfitCode",
	 "OcrCode2",
	 "LineMemo" ) AS select
	 T0."TransId",
	T0."RefDate",
	T0."Account",
	T0."Debit",
	T0."Credit",
	T0."Project",
	T0."ProfitCode",
	T0."OcrCode2",
	T0."LineMemo" 
from JDT1 T0 
where t0."ContraAct" in (select
	 T."Account" 
	from JDT1 T 
	inner join OACT T1 on T."Account"=T1."AcctCode" 
	where T1."FatherNum" IN('102440000','102450000','102460000')

GO

-- ===============================================
-- Source: BI_PO_AMENDMENT_DETAIL.txt
-- ===============================================
BI_PO_AMENDMENT_DETAIL

CREATE VIEW "PPL_LIVE"."BI_PO_AMENDMENT_DETAIL" ( "LogInstanc",
	 "DocEntry",
	 "LineNum",
	 "ItemCode",
	 "Dscription",
	 "Quantity",
	 "Price",
	 "Currency" ) AS select
	 T0."LogInstanc",
	T0."DocEntry",
	T0."LineNum",
	T0."ItemCode",
	T0."Dscription",
	T0."Quantity",
	T0."Price",
	T0."Currency" 
from ADO1 T0 
where "ObjType"='22' 
ORDER BY "ItemCode"

GO

-- ===============================================
-- Source: BI_PO_AMENDMENT_HEADER.txt
-- ===============================================
BI_PO_AMENDMENT_HEADER

CREATE VIEW "PPL_LIVE"."BI_PO_AMENDMENT_HEADER" ( "MAX(LogInstanc)",
	 "DocEntry",
	 "DocNum",
	 "DocDate",
	 "CardCode",
	 "CardName",
	 "DocTotal",
	 "NumAtCard" ) AS select
	 max(T0."LogInstanc"),
	 T1."DocEntry",
	 T1."DocNum",
	 T1."DocDate",
	 T1."CardCode",
	 T1."CardName",
	 T1."DocTotal",
	 T1."NumAtCard" 
from ADOC T0 
INNER JOIN OPOR T1 ON T0."DocEntry"=T1."DocEntry" 
where T0."ObjType"='22' 
GROUP BY T1."DocEntry",
	 T1."DocNum",
	 T1."DocDate",
	 T1."CardCode",
	 T1."CardName",
	 T1."DocTotal",
	 T1."NumAtCard" 
order by T1."DocNum",
	 T1."DocDate" WITH READ ONLY

GO

-- ===============================================
-- Source: BI_PURCHASE_ORDERS.txt
-- ===============================================
BI_PURCHASE_ORDERS

CREATE VIEW "PPL_LIVE"."BI_PURCHASE_ORDERS" ( "DocEntry",
	 "DocType",
	 "DocNum",
	 "DocDate",
	 "CardCode",
	 "ItemCode",
	 "Purchase UoM",
	 "Quantity",
	 "DocDueDate",
	 "PO STATUS",
	 "DocCur",
	 "Line Total",
	 "Tax Amount",
	 "DiscPrcnt",
	 "Base Qty",
	 "Base UoM",
	 "PO CREATED BY" ) AS SELECT
	 T0."DocEntry",
	 T0."DocType",
	 T0."DocNum",
	 T0."DocDate",
	 T0."CardCode",
	 T3."ItemCode",
	 T3."unitMsr" "Purchase UoM",
	 T3."Quantity",
	 T0."DocDueDate",
	 (Case when T0."DocStatus"='O' 
	THEN 'OPEN' WHEN T0."DocStatus"='C' 
	THEN 'CLOSE' 
	ELSE T0."DocStatus" 
	END) "PO STATUS",
	 T0."DocCur",
	 (CASE WHEN T0."DocCur"='KES' 
	THEN T3."LineTotal" 
	ELSE T3."TotalFrgn" 
	END) "Line Total",
	 (CASE WHEN T0."DocCur"='KES' 
	THEN T3."VatSum" 
	ELSE T3."VatSumFrgn" 
	END) "Tax Amount",
	 T3."DiscPrcnt",
	 T3."InvQty" "Base Qty",
	 T3."unitMsr2" "Base UoM",
	 T1."U_NAME" "PO CREATED BY" 
FROM OPOR T0 
INNER JOIN POR1 T3 ON T0."DocEntry"=T3."DocEntry" 
INNER JOIN OUSR T1 ON T1."USERID"=T0."UserSign" 
AND T0."CANCELED"='N' WITH READ ONLY

GO

-- ===============================================
-- Source: BI_SALES_EXEMPTED.txt
-- ===============================================
BI_SALES_EXEMPTED

CREATE VIEW "PPL_LIVE"."BI_SALES_EXEMPTED" ( "DocNum",
	 "DocDate",
	 "CardCode",
	 "CardName",
	 "ItemCode",
	 "Dscription",
	 "Quantity",
	 "Price",
	 "LineTotal",
	 "VatGourpSa",
	 "VatStatus" ) AS select
	 T0."DocNum",
	T0."DocDate",
	T0."CardCode",
	T0."CardName",
	T1."ItemCode",
	T1."Dscription",
	 T1."Quantity",
	T1."Price",
	T1."LineTotal",
	T2."VatGourpSa",
	T3."VatStatus" 
from OINV T0 
INNER JOIN INV1 T1 ON T0."DocEntry"=T1."DocEntry" 
INNER JOIN OITM T2 ON T1."ItemCode"=T2."ItemCode" 
INNER JOIN OCRD T3 ON T0."CardCode"=T3."CardCode" 
where T1."VatGroup" not in ('O1',
	'O3') 
and T1."ItemCode" not like 'P%' WITH READ ONLY

GO

-- ===============================================
-- Source: BI_SALES_ORDERS.txt
-- ===============================================
BI_SALES_ORDERS

CREATE VIEW "PPL_LIVE"."BI_SALES_ORDERS" ( "DocNum",
	 "DocDate",
	 "CardCode",
	 "Quotation No",
	 "ItemCode",
	 "Quantity",
	 "Price",
	 "LineTotal",
	 "LineStatus",
	 "Order Status" ) AS SELECT
	 T0."DocNum",
	 T0."DocDate",
	 T0."CardCode",
	 T1."BaseRef" "Quotation No",
	 T1."ItemCode",
	 T1."Quantity",
	 T1."Price",
	 T1."LineTotal",
	 T1."LineStatus",
	 T0."DocStatus" "Order Status" 
FROM ORDR T0 
INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry" 
ORDER BY T0."DocNum" WITH READ ONLY

GO

-- ===============================================
-- Source: BI_SALES_QUOTATION.txt
-- ===============================================
BI_SALES_QUOTATION

CREATE VIEW "PPL_LIVE"."BI_SALES_QUOTATION" ( "Quotation No",
	 "Quotation Date",
	 "Quotation Due Date",
	 "Customer Code",
	 "ItemCode",
	 "Quantity",
	 "Price",
	 "LineTotal",
	 "LineStatus",
	 "Order Status",
	 "Quotation Type" ) AS SELECT
	 T0."DocNum" "Quotation No",
	 T0."DocDate" "Quotation Date",
	T0."DocDueDate" "Quotation Due Date",
	 T0."CardCode" "Customer Code",
	 T1."ItemCode",
	 T1."Quantity",
	 T1."Price",
	 T1."LineTotal",
	 T1."LineStatus",
	T0."DocStatus" "Order Status",
	FROM OQUT T0 
INNER JOIN QUT1 T1 ON T0."DocEntry" = T1."DocEntry" 
ORDER BY T0."DocNum" WITH READ ONLY

GO

-- ===============================================
-- Source: BI_SALES_REFUND.txt
-- ===============================================
BI_SALES_REFUND

CREATE VIEW "PPL_LIVE"."BI_SALES_REFUND" ( "DocNum",
	 "DocDate",
	 "CardCode",
	 "CardName",
	 "DocTotal",
	 "CashAcct",
	 "CashSum",
	 "CreditSum",
	 "TrsfrAcct",
	 "TrsfrSum",
	 "CheckAcct",
	 "CheckSum",
	 "Comments",
	 "JrnlMemo",
	 "PrjCode" ) AS select
	 T0."DocNum",
	 T0."DocDate",
	 T0."CardCode",
	 T0."CardName",
	 t0."DocTotal",
	 T0."CashAcct",
	 T0."CashSum",
	 T0."CreditSum",
	 T0."TrsfrAcct",
	 T0."TrsfrSum",
	 T0."CheckAcct",
	 T0."CheckSum",
	 T0."Comments",
	 T0."JrnlMemo",
	 T0."PrjCode" 
from OVPM T0 
where "DocType"='C' 
and "CardCode" not like 'CASH%'

GO

-- ===============================================
-- Source: BI_SALES_TRANSACTION.txt
-- ===============================================
BI_SALES_TRANSACTION

CREATE VIEW "PPL_LIVE"."BI_SALES_TRANSACTION" ( "DocNum",
	 "ItemCode",
	 "ItmsGrpNam",
	 "Project",
	 "WhsCode",
	 "CardCode",
	 "DocDate",
	 "Price list",
	 "UOM (Sales)",
	 "QTY Sales UOM",
	 "Line Total (Before Discount)",
	 "Discount %",
	 "Invoice Discount %",
	 "GrssProfit",
	 "Payterm",
	 "Ref Invoice No",
	 "DocDueDate",
	 "Base Qty",
	 "Base UoM",
	 "SlpName" ) AS ((SELECT
	 T0."DocNum",
	 T1."ItemCode",
	 T3."ItmsGrpNam",
	 T1."Project",
	 T1."WhsCode",
	 T0."CardCode",
	 T0."DocDate",
	 T5."ListName" "Price list",
	 T1."UomCode" "UOM (Sales)",
	 T1."Quantity" "QTY Sales UOM",
	 (T1."Quantity"*T1."PriceBefDi") "Line Total (Before Discount)",
	 T1."DiscPrcnt" "Discount %",
	 T0."DiscPrcnt" "Invoice Discount %",
	 T1."GrssProfit",
	 Case when T0."GroupNum"='-1' 
		then 'Cash' 
		else 'Credit' 
		end "Payterm",
	 '' "Ref Invoice No",
	 T0."DocDueDate",
	 T1."InvQty" "Base Qty",
	 T1."unitMsr2" "Base UoM",
	 T6."SlpName" 
		FROM OINV T0 
		INNER JOIN INV1 T1 ON T0."DocEntry" = T1."DocEntry" 
		INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode" 
		INNER JOIN OITB T3 ON T2."ItmsGrpCod" = T3."ItmsGrpCod" 
		INNER JOIN OCRD T4 ON T4."CardCode"=T0."CardCode" 
		left JOIN OPLN T5 ON T4."ListNum" = T5."ListNum" 
		LEFT JOIN OSLP T6 ON T0."SlpCode"=T6."SlpCode" 
		WHERE T0."CANCELED"='N') 
	UNION ALL (SELECT
	 T0."DocNum",
	 T1."ItemCode",
	 T3."ItmsGrpNam",
	 T1."Project",
	 T1."WhsCode",
	 T0."CardCode",
	 T0."DocDate",
	 T5."ListName" "Price list",
	 T1."UomCode" "UOM (Sales)",
	 -1*(T1."Quantity") "QTY Sales UOM",
	 -1*(T1."Quantity"*T1."PriceBefDi") "Line Total (Before Discount)",
	 T1."DiscPrcnt" "Discount %",
	 T0."DiscPrcnt" "Invoice Discount %",
	 T1."GrssProfit",
	 Case when T0."GroupNum"='-1' 
		then 'Cash' 
		else 'Credit' 
		end "Payterm",
	 T1."BaseRef" "Ref Invoice No",
	 T0."DocDueDate",
	 T1."InvQty" "Base Qty",
	 T1."unitMsr2" "Base UoM",
	 T6."SlpName" 
		FROM ORIN T0 
		INNER JOIN RIN1 T1 ON T0."DocEntry" = T1."DocEntry" 
		INNER JOIN OITM T2 ON T1."ItemCode" = T2."ItemCode" 
		INNER JOIN OITB T3 ON T2."ItmsGrpCod" = T3."ItmsGrpCod" 
		INNER JOIN OCRD T4 ON T4."CardCode"=T0."CardCode" 
		LEFT JOIN OPLN T5 ON T4."ListNum" = T5."ListNum" 
		LEFT JOIN OSLP T6 ON T0."SlpCode"=T6."SlpCode" 
		WHERE T0."CANCELED"='N')) WITH READ ONLY

GO

-- ===============================================
-- Source: BI_STOCK_ADJUSTMENT.txt
-- ===============================================
BI_STOCK_ADJUSTMENT

CREATE VIEW "PPL_LIVE"."BI_STOCK_ADJUSTMENT" ( "ObjType",
	 "DocNum",
	 "DocDate",
	 "ItemCode",
	 "Dscription",
	 "Quantity",
	 "Price",
	 "WhsCode" ) AS (((select
	 T0."ObjType",
	 T0."DocNum",
	 T0."DocDate",
	 T1."ItemCode",
	 T1."Dscription",
	 T1."Quantity",
	 T1."INMPrice" "Price",
	 T1."WhsCode" 
			from OIGN T0 
			INNER JOIN IGN1 T1 ON T0."DocEntry"=T1."DocEntry" 
			where T0."CANCELED"='N' 
			and T1."BaseRef" is null) 
		UNION ALL (select
	 T0."ObjType",
	 T0."DocNum",
	 T0."DocDate",
	 T1."ItemCode",
	 T1."Dscription",
	 -T1."Quantity",
	 T1."INMPrice" "Price",
	 T1."WhsCode" 
			from OIGE T0 
			INNER JOIN IGE1 T1 ON T0."DocEntry"=T1."DocEntry" 
			where T0."CANCELED"='N' 
			and T1."BaseRef" is null)) 
	UNION ALL (select
	 T0."ObjType",
	 T0."DocNum",
	 T0."DocDate",
	 T1."ItemCode",
	 T1."ItemName",
	 T1."Quantity",
	 T1."Price",
	 T1."WhsCode" 
		from OIQR T0 
		INNER JOIN IQR1 T1 ON T0."DocEntry"=T1."DocEntry")) WITH READ ONLY

GO

-- ===============================================
-- Source: BI_WAREHOUSE_MASTER.txt
-- ===============================================
BI_WAREHOUSE_MASTER

CREATE VIEW "PPL_LIVE"."BI_WAREHOUSE_MASTER" ( "WhsCode",
	 "WhsName",
	 "Location",
	 "Intransit Warehouse" ) AS select
	 T0."WhsCode",
	T0."WhsName",
	T1."Location",
	T0."U_CXS_ISID" "Intransit Warehouse" 
from OWHS T0 
LEFT JOIN OLCT T1 ON T0."Location"=T1."Code" 
order by T0."Location",
	T0."WhsCode" WITH READ ONLY

GO

