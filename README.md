# Power BI Project Scripts - Canonical Project README
This is the single canonical README for the entire project.
All long-form documentation that previously lived across multiple folder-level READMEs has been consolidated here so that:
- there is one authoritative project map
- finance, retail, inventory, profitability, and HRMIS logic can be understood from one place
- SSIS, Postgres, SAP HANA, and SQL Server operational notes are not split across folders
- future documentation updates have one primary target instead of several competing ones
This file is intentionally very long. That is deliberate. The repository is not a simple script dump; it is the reporting-logic boundary for a multi-domain BI estate, and the documentation needs to be comprehensive enough to support development, support, QA, handover, onboarding, and production troubleshooting without depending on chat history.
## Canonical Use
Use this README as the primary reference for:
- repository structure
- query inventory
- business meaning of the report models
- source-system assumptions
- SSIS and downstream load considerations
- finance-specific statement logic
- HRMIS reporting coverage
- the legacy generated-query data dictionary
Folder-level READMEs now exist only as short pointer documents so that this file remains the single source of truth.
## Contents
- [Project-Wide Reference](#project-wide-reference)
- [Finance Deep Reference](#finance-deep-reference)
- [Legacy Generated Queries Deep Reference](#legacy-generated-queries-deep-reference)
- [HRMIS Structural Reference](#hrmis-structural-reference)
## Project-Wide Reference
This repository is the SQL and reporting-logic layer for the Power BI estate behind the SAP, retail, finance, inventory, profitability, and HR reporting workstreams. It is not only a script store. It is the business logic boundary between source systems and reporting outputs.

The project currently contains 47 reporting query files across three domains:
- 25 non-finance commercial, retail, profitability, and inventory queries in `generated_queries/`
- 15 finance-specific reporting queries in `finance_generated_reports/`
- 7 HRMIS queries in `HRMIS/generated queries/`

This document is intentionally broad and long. Its purpose is to give a single place where a developer, BI engineer, analyst, reviewer, or support person can understand:
- what the project contains
- how the query estate is organized
- what each query is meant to do
- what folders already have deeper documentation
- where the source-system assumptions live
- what operational issues matter when promoting changes into SSIS, Postgres, and Power BI

## 1. Repository Purpose

At a high level, this repository supports a reporting flow like this:
- Source systems expose operational data.
- SQL views transform that data into report-ready datasets.
- SSIS packages extract and load the results into downstream storage, including Postgres.
- Power BI consumes the curated outputs.

The source systems visible from the repository are:
- SAP HANA, primarily through schema `PPL_LIVE`, for finance, inventory, sales, profitability, and branch reporting.
- HRMIS on SQL Server, for workforce, payroll, recruitment, training, engagement, attendance, and turnover reporting.

The repository also contains requirement notes and source reference extracts that help explain the intended semantics of individual datasets.

## 2. Folder Map

### `generated_queries/`
This folder contains the broader retail, inventory, commercial, and profitability query set. It also contains an existing long-form README that acts as a business-facing data dictionary for that legacy query estate.

Important note:
- Some finance queries were originally documented there but now physically live in `finance_generated_reports/`.
- The older `generated_queries/README.md` still has useful business descriptions, but the root documentation in this file should be treated as the current structural map.

### `finance_generated_reports/`
This folder contains finance-focused report views, including statement-style outputs, ageing, open items, branch finance reporting, and comparative P&L outputs. These are the queries most likely to feed SSIS packages that land data in Postgres for finance dashboards or scheduled extracts.

### `HRMIS/`
This folder contains two distinct kinds of content:
- extracted table DDL and HRMIS structural reference files
- generated HR reporting queries under `HRMIS/generated queries/`

The HRMIS query files are well self-documented in-file using sections such as:
- Purpose
- Design note
- Assumptions
- SQL Server note

### `requirements/`
This folder contains requirement and planning artifacts. The most immediately useful file is `requirements/BI_reports2.txt`, which looks like a reporting backlog and operating matrix by metric, frequency, audience, priority, and status.

### Root-level `BI_*.txt` files
These appear to be source extracts or schema/view definitions for key business entities. They are useful as technical reference inputs when validating or extending queries. Examples include:
- `BI_COA.txt`
- `BI_GL_TRANSACTIONS.txt`
- `BI_AP_INVOICE.txt`
- `BI_SALES_TRANSACTION.txt`
- `BI_PURCHASE_ORDERS.txt`
- `BI_CURRENT_INVENTORY_FINAL.txt`
- `BI_WAREHOUSE_MASTER.txt`

## 3. Existing Documentation Already Present

The repository already had documentation before this README was added. The most important existing artifacts are:

### `generated_queries/README.md`
This is the deepest existing documentation asset in the repo. It explains many of the non-finance SAP HANA views in business language and covers:
- purpose
- grain
- column meanings
- calculations
- interpretation cautions

It is a strong functional data dictionary for the `generated_queries/` set.

### `HRMIS/README.md`
This documents the HRMIS structural extraction work and the generated DDL/table files. It is mostly a structural README rather than a business-report README.

### Embedded query comments in HRMIS report SQL
The HR report views are self-documenting in a disciplined way and are currently the best example of in-file reporting documentation in the repo.

### `requirements/BI_reports2.txt`
This is a planning/requirements artifact. It is useful for understanding which reporting ideas are complete, open, high priority, or intended for different business audiences.

### `generated_queries/stogaja_Docs_Reference_Formatted.docx`
This is a secondary reference document. It should be treated as supplemental rather than the canonical technical source unless the business specifically confirms it as authoritative.

## 4. Query Naming Conventions

The query estate follows a mostly consistent naming model:
- `bi_` prefix for business intelligence views
- domain in the middle of the name, such as `finance`, `retail`, `profitability`, or `hr`
- descriptive suffix indicating the specific report or subject area

Examples:
- `bi_finance_ageing`
- `bi_retail_sales_report`
- `bi_profitability_dashboard`
- `bi_hr_turnover_and_retention`

This convention is valuable because it lets you infer both business domain and intended use from the filename alone.

## 5. Full Query Catalog

This section is the repository-wide query index. It is intentionally explicit so that a person new to the project can scan every active reporting query without navigating three different folders first.

## 5.1 Finance Query Catalog

These files live in `finance_generated_reports/`.

### `finance_generated_reports/bi_finance_DOC.sql`
A static finance report-catalog view that reproduces the finance reporting checklist in SQL form. It is useful as a requirement manifest, progress tracker, and documentation-friendly index of planned or delivered finance reports.

### `finance_generated_reports/bi_finance_ageing.sql`
Finance ageing output for payables-style analysis. It is organized around vendor balances by posting month with consolidated business-partner attributes, making it suitable for ageing layouts, month-bucket pivots, and downstream reshaping in BI tools.

### `finance_generated_reports/bi_finance_annual_balance_sheet.sql`
Annual balance-sheet dataset using the chart of accounts and GL movements. It supports year-end or annual closing balance reporting by account, parent account, and statement section.

### `finance_generated_reports/bi_finance_branch_cash_bank_recon.sql`
Branch cash and bank reconciliation dataset. It is intended to compare branch receipts or tender behavior against operational sales signals and reconciliation-style measures.

### `finance_generated_reports/bi_finance_branch_level_report.sql`
Consolidated branch-level finance reporting layer. It is a management-style dataset that brings together branch commercial and financial indicators for a branch performance lens.

### `finance_generated_reports/bi_finance_branch_pnl_statement.sql`
Monthly branch P&L model. It derives branch revenue, cost of goods sold, gross margin, operating expenses, and net profit using branch-coded commercial and GL logic.

### `finance_generated_reports/bi_finance_expense_tracking.sql`
Expense-tracking dataset organized around GL expense activity. It is intended to support branch- or category-level visibility into expense patterns and operating-cost drivers.

### `finance_generated_reports/bi_finance_open_item_list.sql`
Open-item style finance dataset currently oriented around open goods-receipt or open receipt documents. It includes report-date filtering, document attributes, vendor details, branch mapping, and amount breakdown columns.

### `finance_generated_reports/bi_finance_pending_POs_from_branches.sql`
Pending/open purchase-order dataset for branch-originated procurement. It captures document date, vendor, tax, total, and branch or source-store identifier for operational pending-PO monitoring.

### `finance_generated_reports/bi_finance_profit_&_loss_per_cost_centre.sql`
Pivot-ready P&L-by-cost-centre dataset. Instead of hardcoding branch columns in SQL, it returns statement lines by cost centre so Power BI or Excel can place cost centres on columns dynamically.

### `finance_generated_reports/bi_finance_profit_and_loss_statement.sql`
Monthly profit-and-loss statement model. It builds statement rows from chart-of-accounts hierarchy, GL movements, subtotal lines, and calculated rows such as gross profit, operating profit, profit period, and net profit.

### `finance_generated_reports/bi_finance_profit_and_loss_comparative_annually.sql`
Annual comparative P&L statement model. It returns statement rows with rolling three-year comparison columns plus total, making it suitable for annual finance comparison reports without physically hardcoding specific year names into the column list.

### `finance_generated_reports/bi_finance_receivables_branch_level.sql`
Receivables dataset at branch level. It is intended to show branch exposure, branch responsibility, and the aging or composition of customer receivables from a branch perspective.

### `finance_generated_reports/bi_finance_sales_vs_purchases_value_by_day.sql`
Daily sales-versus-purchases comparison dataset. It is useful for day-level movement analysis, daily gross profit comparisons, and management views comparing inflows and outflows by day.

### `finance_generated_reports/bi_finance_sales_vs_transfers.sql`
Daily branch or warehouse comparison of sales value versus stock transfers in and out. It supports operational variance analysis and is especially useful when branches are being evaluated against internal transfer dependency.

## 5.2 Non-Finance SAP HANA Query Catalog

These files live in `generated_queries/`.

### `generated_queries/bi_availability_report.sql`
Availability-focused inventory dataset used to determine whether items are present, absent, or under pressure across branches. It is a foundational stock-availability report for retail operations.

### `generated_queries/BI_BUYER_PERFORMANCE_DASHBOARD.sql`
Procurement and buyer-performance dataset. It is intended to support management visibility into buyer output, sourcing effectiveness, or purchase execution quality.

### `generated_queries/bi_category_growth_market_share.sql`
Category growth and market-share style view. It helps analyze how categories evolve by time and how much they contribute relative to broader branch or company performance.

### `generated_queries/bi_customer_count.sql`
Customer-count or footfall-oriented dataset at store/date grain. It is useful for understanding visit volumes, customer movement trends, and store traffic evolution.

### `generated_queries/bi_employee_performance.sql`
Retail-side employee performance dataset distinct from HRMIS. It is meant for sales or commercial performance tracking of employees, likely using operational retail metrics rather than HR appraisals.

### `generated_queries/bi_inventory_health_by_category.sql`
Inventory-health analysis by category. This is intended for category-level stock quality review, including aging, slow movement, or stock-holding interpretation.

### `generated_queries/bi_inventory_stock_health.sql`
Stock-health view at item/branch level. It is suited to inventory control, holding analysis, and operational review of stock behavior across the network.

### `generated_queries/bi_product_mix_pricing_analysis.sql`
Product-mix and pricing view. This is useful for analyzing realized pricing, assortment behavior, and the relationship between mix and commercial outcomes.

### `generated_queries/bi_profitability_category.sql`
Category profitability reporting layer. It focuses on how profit is distributed or earned by product category over time.

### `generated_queries/bi_profitability_dashboard.sql`
High-level profitability dashboard dataset. It likely serves as an executive or management layer for profitability KPIs across time and branch dimensions.

### `generated_queries/bi_profitability_discount_impact_analysis.sql`
Discount-impact analysis model focused on margin pressure caused by discounting behavior. It helps quantify trade-offs between sales generation and profitability leakage.

### `generated_queries/bi_profitability_product_profit_leakage.sql`
Product-level leakage analysis. It is intended to expose where expected product profitability is being eroded by pricing, discounting, cost structure, or operational handling.

### `generated_queries/bi_promotions_campaign_performance.sql`
Promotional campaign performance dataset. It supports uplift analysis, campaign contribution, branch participation, and item-level performance under campaign conditions.

### `generated_queries/bi_retail_branch_performance_ranking.sql`
Branch ranking view for retail performance. It is likely used to rank branches by sales, margin, or blended commercial KPIs.

### `generated_queries/bi_retail_branch_sales_performance.sql`
Branch sales performance trend dataset. It is a retail-focused layer for comparing how branches perform over time.

### `generated_queries/bi_retail_channel_sales_report.sql`
Channel-level sales report across retail and digital or partner channels. It is used to compare how different sales channels contribute to total business.

### `generated_queries/bi_retail_employee_performance_ranking.sql`
Retail employee ranking dataset. It is useful for leaderboards, branch-level staff comparison, and reward or coaching use cases.

### `generated_queries/bi_retail_high_value_items_sales.sql`
High-value-item sales analysis. It focuses on products with outsized ticket contribution and is useful for branch comparisons and item-priority monitoring.

### `generated_queries/bi_retail_inventory_report.sql`
Inventory reporting layer for retail operations. It likely combines quantity, stock position, and period-based inventory insights at branch and item level.

### `generated_queries/bi_retail_newly_listed_items_sales.sql`
Newly listed item performance report. This is used to track whether new SKUs are being adopted, selling, or underperforming after launch.

### `generated_queries/bi_retail_regional_pricing_report.sql`
Regional pricing report for comparing realized price behavior by region. It is useful in identifying whether pricing consistency or regional pricing strategy is holding.

### `generated_queries/bi_retail_sales_report.sql`
Core retail sales reporting layer. This is one of the foundational sales datasets and is likely used widely for detailed sales slicing by branch, category, item, or time.

### `generated_queries/bi_retail_top_1000_selling_items.sql`
Top-selling-item ranking dataset. It supports SKU prioritization, assortment review, and branch/company comparison of leading products.

### `generated_queries/bi_sales_breakdown_report.sql`
Sales breakdown view that decomposes revenue into reporting dimensions such as branch, period, category, or other business segments.

### `generated_queries/bi_sales_profitability.sql`
Sales profitability dataset that combines sales outcomes with margin-oriented or variance-oriented analysis. It is a commercial profitability lens rather than a statutory finance statement.

## 5.3 HRMIS Query Catalog

These files live in `HRMIS/generated queries/`. Their purposes below reflect the embedded headers in the SQL files.

### `HRMIS/generated queries/bi_hr_attendance_and_productivity.sql`
Purpose:
- absenteeism rate
- attendance compliance such as late check-ins and missed shifts
- sales-per-employee placeholder for future HR-to-retail linkage

### `HRMIS/generated queries/bi_hr_compensation_and_benefits.sql`
Purpose:
- total payroll cost
- payroll as a percent of sales placeholder
- bonus distribution
- average pay per staff category

### `HRMIS/generated queries/bi_hr_engagement_and_performance.sql`
Purpose:
- performance ratings distribution
- employee satisfaction when survey-like data is available
- high-versus-low performer retention

### `HRMIS/generated queries/bi_hr_learning_and_development.sql`
Purpose:
- training hours per employee
- training spend per employee
- promotion rate and internal mobility support
- skills coverage and training breadth

### `HRMIS/generated queries/bi_hr_recruitment.sql`
Purpose:
- new hires versus exits trend
- offer acceptance rate
- cost per hire placeholder

### `HRMIS/generated queries/bi_hr_turnover_and_retention.sql`
Purpose:
- employee turnover percent
- exit reasons by period
- retention percent

### `HRMIS/generated queries/bi_hr_workforce_profile.sql`
Purpose:
- workforce profile by branch, department, gender, role, and age group
- employee distribution across regions

## 6. Supporting Reference Assets

Beyond the query files themselves, these artifacts matter when extending or validating logic:

### Business and planning reference
- `requirements/BI_reports2.txt`
- `finance_generated_reports/bi_finance_DOC.sql`

These capture what the business expects to see, what is complete, and what still needs to be built.

### Technical source-reference files
Examples include:
- `BI_COA.txt` for chart-of-accounts structure
- `BI_GL_TRANSACTIONS.txt` for finance movement logic
- `BI_AP_INVOICE.txt` for AP-related reporting
- `BI_GRN_FINAL.txt` for goods receipt reference
- `BI_PURCHASE_ORDERS.txt` for procurement reference
- `BI_SALES_TRANSACTION.txt` for retail sales facts
- `BI_INVENTORY_TRANSFER.txt` for transfer logic
- `BI_WAREHOUSE_MASTER.txt` for branch and warehouse mapping

### Deep-dive docs already present
- `generated_queries/README.md`
- `HRMIS/README.md`
- `generated_queries/stogaja_Docs_Reference_Formatted.docx`

## 7. Common Modeling Conventions In This Repository

Several patterns appear repeatedly across the query estate.

### 7.1 Explicit report dates
Most reporting views expose a date column intended for downstream filtering. This is often called:
- `Report Date`
- `DocDate`
- `Posting Date`
- `Period Start Date`
- `Period End Date`

The project tends to work best when every model has at least one clear filter date. Statement-style outputs often include both statement period bounds and a report date for slicing.

### 7.2 Business logic lives in the SQL layer
These queries generally do more than expose raw data. They:
- normalize source rows
- de-duplicate operational records
- encode business rules
- produce reporting grains that are safer for Power BI

This means a change to a SQL view can change report meaning, not just report availability.

### 7.3 Statement-style outputs need ordering columns
Financial statement models often require a dedicated ordering field such as `Sort Order`. This is necessary because report rows mix:
- headers
- leaf accounts
- subtotal rows
- calculated lines like gross profit or net profit

Without an ordering key, downstream tools cannot reliably reconstruct the intended statement layout.

### 7.4 Pivot-ready instead of hardcoded pivots
Where columns would otherwise need to change dynamically, the repo often prefers pivot-ready datasets rather than physically pivoted SQL views. The cost-centre P&L is a good example: branches are meant to become columns in Power BI or Excel, not be hardcoded in the SQL view.

### 7.5 Source-system-specific SQL
This project spans two different SQL environments:
- SAP HANA SQL for `PPL_LIVE` queries
- SQL Server T-SQL for HRMIS queries

Assumptions or syntax are not portable across these domains.

## 8. Operational Notes For SSIS And Downstream Loads

These notes matter in practice because the repository is not consumed only by humans. It is also consumed by SSIS packages and Postgres destinations.

### 8.1 View changes require SSIS metadata refresh
If a view changes any of the following, SSIS may still hold stale metadata and fail even though the SQL is correct:
- column type
- column length
- column order
- nullability
- alias names

This has already shown up in practice with fields like:
- `Sort Order`
- `Month/Year`

If SSIS warns that external columns are out of sync, refresh the metadata before concluding that the SQL is still wrong.

### 8.2 Avoid ambiguous numeric types for destination keys
Statement ordering fields should be emitted as integer-safe types where the destination expects integers. Sending decimal-formatted text such as `100000000000.000000` into a `bigint` destination is a common avoidable failure pattern.

### 8.3 Avoid LOB-like string expressions where not necessary
Derived string expressions can sometimes be surfaced by connectors as less friendly text types. Where a fixed-width text field is intended, it is safer to cast explicitly to a bounded type such as `NVARCHAR(7)`.

### 8.4 Recreate the source view before rerunning packages
When a script is changed locally, the repo is not the system of record until the corresponding HANA or SQL Server view is recreated in the source environment.

The practical order is:
1. update the SQL file
2. recreate the source view in the database
3. refresh SSIS metadata if the schema changed
4. rerun the package
5. validate the target landing table and Power BI model

## 9. How To Use This Repository Effectively

### If you are extending a report
Start with:
- the relevant SQL view
- this root README
- the folder-specific README if present
- `generated_queries/README.md` for legacy SAP non-finance logic
- source reference `.txt` files when the semantics are uncertain

### If you are debugging an SSIS load
Check in order:
- whether the source view was recreated in the database
- whether SSIS external columns are stale
- whether a text or numeric cast changed
- whether a date or sort field changed type
- whether the destination table still matches the source view

### If you are validating business logic
Check:
- query grain
- filter date columns
- whether outputs are raw, subtotaled, or already aggregated
- whether nulls are placeholders or true missing values
- whether the query is meant to be pivoted downstream

## 10. Documentation Gaps Still To Watch

This repository is now better documented than it was, but there are still gaps worth acknowledging.

### Finance query descriptions are newer than legacy docs
The finance folder was separated from `generated_queries`, so the older `generated_queries/README.md` should not be treated as the final word on finance folder structure.

### Not every query has embedded business comments
The HRMIS queries do this well. The finance and retail queries are less consistent. Some are clear from name and logic, but some would still benefit from embedded purpose/grain notes directly in the SQL.

### Requirement files are broader than implemented SQL
Some items in `requirements/BI_reports2.txt` appear to be pipeline or dashboard ambitions rather than already-delivered SQL objects.

## 11. Recommended Documentation Maintenance Policy

When a query changes in a meaningful way, update documentation in the same change set.

At minimum, update:
- the query file itself if it contains embedded purpose notes
- this root `README.md` if a new report is added or moved
- `finance_generated_reports/README.md` for finance changes
- `generated_queries/README.md` if a business-facing description changes materially

If a field is added that downstream systems depend on, record:
- business meaning
- expected data type
- whether it is a filter column, sort column, identifier, or measure

## 12. Fast Navigation Index

If you are looking for:
- finance statements: see `finance_generated_reports/bi_finance_profit_and_loss_statement.sql`, `finance_generated_reports/bi_finance_profit_and_loss_comparative_annually.sql`, `finance_generated_reports/bi_finance_annual_balance_sheet.sql`
- finance operations: see `finance_generated_reports/bi_finance_open_item_list.sql`, `finance_generated_reports/bi_finance_pending_POs_from_branches.sql`, `finance_generated_reports/bi_finance_ageing.sql`
- branch finance performance: see `finance_generated_reports/bi_finance_branch_level_report.sql`, `finance_generated_reports/bi_finance_branch_cash_bank_recon.sql`, `finance_generated_reports/bi_finance_branch_pnl_statement.sql`
- retail sales analytics: see `generated_queries/bi_retail_sales_report.sql`, `generated_queries/bi_sales_breakdown_report.sql`, `generated_queries/bi_customer_count.sql`
- promotions and product performance: see `generated_queries/bi_promotions_campaign_performance.sql`, `generated_queries/bi_retail_newly_listed_items_sales.sql`, `generated_queries/bi_retail_high_value_items_sales.sql`
- profitability: see `generated_queries/bi_profitability_dashboard.sql`, `generated_queries/bi_profitability_category.sql`, `generated_queries/bi_profitability_discount_impact_analysis.sql`, `generated_queries/bi_profitability_product_profit_leakage.sql`
- inventory: see `generated_queries/bi_inventory_stock_health.sql`, `generated_queries/bi_inventory_health_by_category.sql`, `generated_queries/bi_retail_inventory_report.sql`, `generated_queries/bi_availability_report.sql`
- HRMIS people analytics: see `HRMIS/generated queries/bi_hr_workforce_profile.sql`, `HRMIS/generated queries/bi_hr_turnover_and_retention.sql`, `HRMIS/generated queries/bi_hr_engagement_and_performance.sql`, `HRMIS/generated queries/bi_hr_compensation_and_benefits.sql`

## 13. Final Guidance

This repository should be treated as a reporting codebase, not as a loose collection of ad hoc SQL files. The views here encode business definitions, reporting grains, account rollup behavior, and statement logic that directly affect what business users see.

The safest way to work in this project is:
- understand the business purpose first
- confirm the grain second
- change the SQL third
- update documentation immediately after
- refresh SSIS metadata when column types or aliases change
- validate the downstream report before closing the task

---
## Finance Deep Reference
The section below consolidates the previous folder-specific finance documentation so the finance reporting layer is fully represented in the root README.
This folder contains the finance-specific reporting models used by the Power BI project. These views are primarily SAP HANA views under schema `PPL_LIVE` and are designed to support management reporting, finance operations, statement outputs, reconciliation views, and SSIS-to-Postgres data movement.

This README is intentionally detailed so that finance report work is not dependent on memory, chat history, or reverse-engineering individual SQL files.

## 1. Folder Purpose

The finance folder exists to separate finance reporting logic from the broader retail and commercial query estate. The main reasons for the split are:
- finance reporting has distinct statement-style needs
- finance models often include special ordering logic for statement layouts
- finance models are frequently consumed by SSIS packages that are sensitive to schema changes
- finance outputs are more likely to be loaded into downstream relational targets for scheduled reporting

## 2. File Inventory

The finance folder currently contains 15 SQL report views:
- `bi_finance_DOC.sql`
- `bi_finance_ageing.sql`
- `bi_finance_annual_balance_sheet.sql`
- `bi_finance_branch_cash_bank_recon.sql`
- `bi_finance_branch_level_report.sql`
- `bi_finance_branch_pnl_statement.sql`
- `bi_finance_expense_tracking.sql`
- `bi_finance_open_item_list.sql`
- `bi_finance_pending_POs_from_branches.sql`
- `bi_finance_profit_&_loss_per_cost_centre.sql`
- `bi_finance_profit_and_loss_comparative_annually.sql`
- `bi_finance_profit_and_loss_statement.sql`
- `bi_finance_receivables_branch_level.sql`
- `bi_finance_sales_vs_purchases_value_by_day.sql`
- `bi_finance_sales_vs_transfers.sql`

## 3. Query-by-Query Guide

## 3.1 `bi_finance_DOC.sql`
A static documentation/report-manifest style view. It mirrors the finance reporting checklist and is useful for mapping report names, priorities, and delivery status.

Typical use:
- finance roadmap visibility
- report cataloging
- project tracking

## 3.2 `bi_finance_ageing.sql`
Supplier ageing output organized by vendor and posting month. It is suited to ageing schedules and downstream pivots by month/year.

Key behavior:
- derives open balances from journal lines adjusted for reconciliation
- uses consolidated business-partner fields where applicable
- designed for ageing layouts rather than transactional drill-down

Primary interpretation note:
- in its current shape it is more of a normalized ageing dataset than a fixed Excel-style month-column layout

## 3.3 `bi_finance_annual_balance_sheet.sql`
Annual balance-sheet dataset based on chart-of-accounts structure and annual GL balances.

Typical use:
- annual balance-sheet reporting
- year-end account reviews
- downstream statement assembly in Power BI or exports

Important fields:
- `Report Date`
- `Balance Year`
- `Statement Section`
- `Parent Account Code`
- `Account Code`
- `Closing Balance`

## 3.4 `bi_finance_branch_cash_bank_recon.sql`
Branch-level cash and bank reconciliation support view.

Typical use:
- compare branch collection behavior to commercial activity
- identify reconciliation pressure or mismatch between transactional and tender-based signals

## 3.5 `bi_finance_branch_level_report.sql`
Management-style branch finance output that combines branch-level indicators from multiple finance and operational signals.

Typical use:
- branch performance reviews
- cross-branch comparisons
- operational finance dashboards

## 3.6 `bi_finance_branch_pnl_statement.sql`
Monthly branch P&L dataset by branch code and month.

Measures typically represented:
- revenue
- cost of goods sold
- gross margin
- operating expenses
- net profit

Typical use:
- monthly branch management P&L
- region-versus-branch profit reviews
- branch trend reporting

## 3.7 `bi_finance_expense_tracking.sql`
Expense analysis view for operating expenses.

Typical use:
- expense-category trend reporting
- branch expense comparisons
- identifying cost drivers and categories under pressure

## 3.8 `bi_finance_open_item_list.sql`
Open-item report centered on open receipt-style or open-document records.

Typical use:
- finance operations follow-up
- open item review by vendor and branch
- document-level issue tracking

Primary filter field:
- `Report Date`

## 3.9 `bi_finance_pending_POs_from_branches.sql`
Open purchase-order report for branch-originated procurement.

Typical use:
- pending branch PO monitoring
- procurement follow-up
- branch sourcing backlog review

Primary filter field:
- `Report Date`

## 3.10 `bi_finance_profit_&_loss_per_cost_centre.sql`
Pivot-ready cost-centre P&L dataset. It does not hardcode branch columns; instead it returns one line per statement row per cost centre so the reporting tool can pivot branches to columns.

Typical use:
- branch or cost-centre statement matrices
- management P&L by branch
- total-company plus branch comparison in a single dataset

Important note:
- because the filename contains `&`, PowerShell path handling is easier with `-LiteralPath`

## 3.11 `bi_finance_profit_and_loss_statement.sql`
Monthly P&L statement model with statement row ordering.

Typical use:
- monthly finance statement extracts
- Power BI matrix statement reporting
- SSIS landing into downstream finance statement tables

Important fields:
- `Report Date`
- `Period Start Date`
- `Period End Date`
- `Month/Year`
- `Sort Order`
- `Row Type`
- `G/L Account`
- `Name`
- `Amount`

Important operational note:
- `Sort Order` has been made integer-safe for downstream loads
- `Month/Year` has been explicitly cast to a fixed-width string to reduce SSIS metadata friction

## 3.12 `bi_finance_profit_and_loss_comparative_annually.sql`
Annual comparative P&L model using a rolling three-year comparison.

Typical use:
- annual statement comparison
- year-over-year finance review
- export to Excel layouts showing multiple annual columns plus total

Important fields:
- `Year 1 Label`
- `Year 2 Label`
- `Year 3 Label`
- `Year 1 Amount`
- `Year 2 Amount`
- `Year 3 Amount`
- `TOTAL`

Important operational note:
- the year columns are not physically named `2023`, `2024`, `2025`; the labels are provided separately so the report layer can display them safely without making the SQL view non-reusable every year

## 3.13 `bi_finance_receivables_branch_level.sql`
Receivables reporting at branch level.

Typical use:
- branch exposure monitoring
- receivables accountability by branch
- collection and ageing review from a branch perspective

## 3.14 `bi_finance_sales_vs_purchases_value_by_day.sql`
Daily comparison of sales value, purchases value, and gross profit.

Typical use:
- daily finance/commercial trend review
- operating control views
- short-horizon management reporting

## 3.15 `bi_finance_sales_vs_transfers.sql`
Daily comparison of sales value versus transfer in/out value by warehouse or branch.

Typical use:
- understand whether branch sales are organically supported or transfer-dependent
- identify mismatches between transfer support and sales performance
- monitor transfer-heavy branches

## 4. Common Finance Modeling Patterns

Several patterns repeat across the finance models in this folder.

### 4.1 Statement ordering columns
Statement-style datasets use `Sort Order` to preserve display sequence across:
- headers
- detailed accounts
- subtotals
- calculated totals such as gross profit and net profit

### 4.2 Explicit date filters
Where possible, finance reports expose a clear date field such as:
- `Report Date`
- `Posting Date`
- `Period Start Date`
- `Period End Date`

These should be used consistently in Power BI and downstream ETL.

### 4.3 SAP HANA chart-of-accounts rollups
Statement models often derive hierarchy from account-code structure and `OACT`, rather than depending on a manually maintained flat mapping table.

### 4.4 Pivot-ready rather than hardcoded matrix outputs
For dynamic reporting needs such as cost-centre columns, the SQL layer usually returns a normalized dataset and lets Power BI or Excel handle the final pivot.

## 5. SSIS and Postgres Considerations

These notes matter for operations.

### 5.1 Refresh metadata after schema changes
SSIS can cache source metadata aggressively. If a finance view changes a column alias, type, or length, refresh:
- ODBC Source external columns
- ODBC Destination mappings
- any downstream derived-column or data-conversion transforms

### 5.2 Prefer integer-safe sort keys
If a destination expects `bigint`, do not emit decimal-formatted sort values. Statement ordering logic should be stored as integers.

### 5.3 Use fixed-width strings where appropriate
Fields such as `Month/Year` should be emitted with bounded text types instead of loose concatenation expressions that connectors may surface as less predictable types.

### 5.4 Recreate the source view before rerunning packages
Editing the repository file does not update the source database. The expected deployment path is:
1. update the SQL file
2. recreate the HANA view
3. refresh SSIS metadata if needed
4. rerun the package
5. validate downstream table contents

## 6. Relationship To Other Project Docs

Use this README together with:
- root `README.md` for project-wide context
- `generated_queries/README.md` for legacy non-finance business logic explanations
- `requirements/BI_reports2.txt` for report backlog and priorities
- root-level `BI_*.txt` files for technical source references

## 7. Recommended Maintenance Rule

Every time a finance model is added or materially changed, update this file with:
- the purpose of the model
- the main reporting grain
- the primary filter field
- any non-obvious operational notes for SSIS or Power BI

---
## Legacy Generated Queries Deep Reference
The section below consolidates the long-form generated_queries data dictionary into the root README so the broader retail, inventory, profitability, and commercial query estate is documented in the same place as finance and HRMIS.
Important note:
- Finance-specific report models now live in `finance_generated_reports/`.
- This README remains useful as a business/data-dictionary reference, but the root `README.md` should be treated as the current project-wide structural guide.

This document explains the SQL scripts in `generated_queries` as business-facing reporting assets rather than just technical files. It is intentionally long and descriptive because these scripts are not only data-extraction objects; they are also the business logic layer behind the reports that users consume in Power BI.

Each section covers:
- what the script is for
- the reporting grain and how to read the output
- the business meaning of every output column
- the main calculations and transformation rules
- interpretation notes and practical cautions

## Table Of Contents

Use the links below to jump directly to the relevant section heading in this document.

### Core Sections

- [How To Read This Document](#how-to-read-this-document)
- [Shared Sales Logic Used In Many Scripts](#shared-sales-logic-used-in-many-scripts)
- [Script Index](#script-index)
- [Using The README In Practice](#using-the-readme-in-practice)

### Query Sections

- [bi_availability_report.sql](#bi_availability_reportsql)
- [BI_BUYER_PERFORMANCE_DASHBOARD.sql](#bi_buyer_performance_dashboardsql)
- [bi_category_growth_market_share.sql](#bi_category_growth_market_sharesql)
- [bi_customer_count.sql](#bi_customer_countsql)
- [bi_employee_performance.sql](#bi_employee_performancesql)
- [bi_finance_branch_cash_bank_recon.sql](#bi_finance_branch_cash_bank_reconsql)
- [bi_finance_branch_level_report.sql](#bi_finance_branch_level_reportsql)
- [bi_finance_branch_pnl_statement.sql](#bi_finance_branch_pnl_statementsql)
- [bi_finance_ageing.sql](#bi_finance_ageingsql)
- [bi_finance_expense_tracking.sql](#bi_finance_expense_trackingsql)
- [bi_finance_receivables_branch_level.sql](#bi_finance_receivables_branch_levelsql)
- [bi_finance_sales_vs_purchases_value_by_day.sql](#bi_finance_sales_vs_purchases_value_by_daysql)
- [bi_finance_sales_vs_transfers.sql](#bi_finance_sales_vs_transferssql)
- [bi_inventory_health_by_category.sql](#bi_inventory_health_by_categorysql)
- [bi_inventory_stock_health.sql](#bi_inventory_stock_healthsql)
- [bi_product_mix_pricing_analysis.sql](#bi_product_mix_pricing_analysissql)
- [bi_profitability_category.sql](#bi_profitability_categorysql)
- [bi_profitability_dashboard.sql](#bi_profitability_dashboardsql)
- [bi_profitability_discount_impact_analysis.sql](#bi_profitability_discount_impact_analysissql)
- [bi_profitability_product_profit_leakage.sql](#bi_profitability_product_profit_leakagesql)
- [bi_promotions_campaign_performance.sql](#bi_promotions_campaign_performancesql)
- [bi_retail_branch_performance_ranking.sql](#bi_retail_branch_performance_rankingsql)
- [bi_retail_branch_sales_performance.sql](#bi_retail_branch_sales_performancesql)
- [bi_retail_channel_sales_report.sql](#bi_retail_channel_sales_reportsql)
- [bi_retail_employee_performance_ranking.sql](#bi_retail_employee_performance_rankingsql)
- [bi_retail_high_value_items_sales.sql](#bi_retail_high_value_items_salessql)
- [bi_retail_inventory_report.sql](#bi_retail_inventory_reportsql)
- [bi_retail_newly_listed_items_sales.sql](#bi_retail_newly_listed_items_salessql)
- [bi_retail_regional_pricing_report.sql](#bi_retail_regional_pricing_reportsql)
- [bi_retail_sales_report.sql](#bi_retail_sales_reportsql)
- [bi_retail_top_1000_selling_items.sql](#bi_retail_top_1000_selling_itemssql)
- [bi_sales_breakdown_report.sql](#bi_sales_breakdown_reportsql)
- [bi_sales_profitability.sql](#bi_sales_profitabilitysql)

## How To Read This Document

Most of the reports in this folder follow a common pattern:
- the SQL file creates a view in schema `PPL_LIVE`
- the view exposes one row per reporting grain such as branch-day, branch-month, item-day, item-month, buyer-month, or category-month
- invoices are treated as positive commercial activity
- credit notes are treated as negative commercial activity
- dimensional fields such as branch, region, category, supplier, item, or employee are attached after the base commercial facts are prepared

When reading the column explanations below:
- a `date` column usually defines the reporting period or snapshot period
- a `code` column is normally the system key used to join or filter
- a `name` column is the human-readable label used in reporting
- any column ending in `Pct` or `%` is a ratio or percentage
- any column ending in `Value`, `Sales`, `Profit`, `Budget`, `Cost`, or `Amount` is a money metric
- any column ending in `Qty` is a quantity metric

## Shared Sales Logic Used In Many Scripts

Many of the retail and profitability scripts calculate sales in a consistent way:
- `OINV` joined to `INV1` contributes positive sales
- `ORIN` joined to `RIN1` contributes negative sales
- canceled documents are excluded
- retail-only views usually filter `U_CXS_FRST = 'Y'`
- `LineTotal + VatSum` is used when the report wants customer-facing sales including VAT
- `LineTotal` is used when the report wants pre-VAT sales
- `GrssProfit` is used when the report wants gross profit

This convention matters because two reports can both say "sales" while meaning different things:
- one may mean sales before VAT
- another may mean sales including VAT
- another may mean net of returns

The explanations below call this out where relevant.

## Script Index

- `bi_availability_report.sql`
- `BI_BUYER_PERFORMANCE_DASHBOARD.sql`
- `bi_category_growth_market_share.sql`
- `bi_customer_count.sql`
- `bi_employee_performance.sql`
- `bi_finance_branch_cash_bank_recon.sql`
- `bi_finance_branch_level_report.sql`
- `bi_finance_branch_pnl_statement.sql`
- `bi_finance_ageing.sql`
- `bi_finance_expense_tracking.sql`
- `bi_finance_receivables_branch_level.sql`
- `bi_finance_sales_vs_purchases_value_by_day.sql`
- `bi_finance_sales_vs_transfers.sql`
- `bi_inventory_health_by_category.sql`
- `bi_inventory_stock_health.sql`
- `bi_product_mix_pricing_analysis.sql`
- `bi_profitability_category.sql`
- `bi_profitability_dashboard.sql`
- `bi_profitability_discount_impact_analysis.sql`
- `bi_profitability_product_profit_leakage.sql`
- `bi_promotions_campaign_performance.sql`
- `bi_retail_branch_performance_ranking.sql`
- `bi_retail_branch_sales_performance.sql`
- `bi_retail_channel_sales_report.sql`
- `bi_retail_employee_performance_ranking.sql`
- `bi_retail_high_value_items_sales.sql`
- `bi_retail_inventory_report.sql`
- `bi_retail_newly_listed_items_sales.sql`
- `bi_retail_regional_pricing_report.sql`
- `bi_retail_sales_report.sql`
- `bi_retail_top_1000_selling_items.sql`
- `bi_sales_breakdown_report.sql`
- `bi_sales_profitability.sql`

## bi_availability_report.sql

- `View`: `PPL_LIVE.bi_availability_report`
- `Business purpose`: Shows item sales movement against HQ stock so the business can see whether the items that are selling are adequately backed by central stock.
- `Typical use`: Availability reporting, supplier follow-up, replenishment review, and identification of items with strong movement but weak supporting stock.
- `Reporting grain`: One row per item per sales date, with companywide sales movement and HQ stock position.

### Business Meaning Of Columns

- `WhsCode`: A fixed label of `COMPANYWISE`; it tells the report user that this is not branch-specific output.
- `DocDate`: The business date of the sales movement being analyzed.
- `ItemCode`: The stock-keeping code used to identify the product in SAP.
- `ItemName`: The commercial description of the item.
- `UOM Group`: The unit-of-measure family used for the item, useful when whole packs and pieces coexist.
- `Qty Whole Sales`: Sales quantity translated into whole-unit terms, useful for pack-level demand review.
- `Qty Pieces Sales`: Sales quantity translated into piece-level terms, useful where the item is sold in loose units.
- `Qty Whole Whs`: Current HQ stock translated into whole-unit terms.
- `Difference`: HQ whole stock minus whole-unit sales; positive means stock is still available at HQ, negative means demand has outpaced HQ backing.
- `Preferred Vendor Code`: Supplier key for the preferred vendor attached to the item master.
- `Preferred Vendor Name`: Supplier name for commercial follow-up.

### Main Calculations And Rules

- Sales quantity is based on invoices minus credit notes.
- Only valid retail sales are included.
- Quantities are normalized into both whole and piece equivalents.
- HQ stock is read from warehouse stock and converted into whole-unit terms.
- `Difference = Qty Whole Whs - Qty Whole Sales`.

### Interpretation Notes

- A large negative `Difference` usually means replenishment risk.
- A large positive `Difference` may indicate slow replenishment consumption or deliberate buffer stock.
- Piece and whole metrics should be interpreted together for items sold in mixed pack formats.

## BI_BUYER_PERFORMANCE_DASHBOARD.sql

- `View`: `PPL_LIVE.BI_BUYER_PERFORMANCE_DASHBOARD`
- `Business purpose`: Measures how buyers perform against procurement budgets, negotiated savings, portfolio profit growth, and overall business impact.
- `Typical use`: Monthly buyer reviews, sourcing effectiveness discussions, and procurement performance scorecards.
- `Reporting grain`: One row per buyer, category, and month.

### Business Meaning Of Columns

- `ReportDate`: The first day of the month representing the reporting month.
- `BuyerCode`: The SAP user or buyer identifier.
- `BuyerName`: The readable name of the buyer or sourcing owner.
- `Category`: The item category under the buyer's portfolio.
- `ActualPurchaseSpend`: The actual invoiced procurement value for that buyer and category in the month.
- `PurchaseBudget`: The planned buying value, represented from purchase-order budgeting logic.
- `PurchaseBudgetAchievementPct`: How much of the purchase budget was consumed; values above 100 mean spending exceeded plan.
- `DiscountSavings`: Value saved from line-level price reductions negotiated with suppliers.
- `RebateSavings`: Additional value saved through header-level discounts or rebate style mechanisms.
- `CreditTermSavings`: The financing benefit of having longer supplier payment terms.
- `TotalNegotiationSavings`: Total commercial gain from discounts, rebates, and payment terms combined.
- `NegotiationSavingsPctOfSpend`: Savings expressed as a share of actual spend; useful for comparing buyers with different portfolio sizes.
- `BuyerAllocatedSales`: The share of category sales attributed back to the buyer based on the buyer's share of category purchase spend.
- `BuyerAllocatedProfit`: The share of category gross profit attributed to the buyer using the same allocation logic.
- `PrevBuyerAllocatedProfit`: The prior-month allocated profit for the same buyer and category.
- `CategoryProfitGrowthValue`: Absolute increase or decline in allocated profit versus the prior month.
- `CategoryProfitGrowthPct`: Percentage growth or decline in allocated profit versus the prior month.
- `OverallBusinessSales`: The total sales of the business in that month; intentionally shown only once per month block in the current query.
- `OverallBusinessProfit`: The total business gross profit in that month; also shown once per month block in the current query.
- `SourcingImpactValue`: The buyer's allocated profit plus negotiated savings; a practical proxy for commercial impact.
- `SourcingImpactPctOfBusinessProfit`: The sourcing impact expressed as a share of overall business profit.

### Main Calculations And Rules

- Actual procurement is drawn from AP invoice lines.
- Budget is derived from purchase-order lines.
- Category sales and gross profit are derived from retail sales and returns.
- Buyer sales and buyer profit are not direct sales ownership; they are allocated from category performance using buyer purchase-spend share.
- `PurchaseBudgetAchievementPct = ActualPurchaseSpend / PurchaseBudget * 100`.
- `TotalNegotiationSavings = DiscountSavings + RebateSavings + CreditTermSavings`.
- `CategoryProfitGrowthValue = BuyerAllocatedProfit - PrevBuyerAllocatedProfit`.
- `SourcingImpactValue = BuyerAllocatedProfit + TotalNegotiationSavings`.

### Interpretation Notes

- This report is strongest as a portfolio-management view, not as a literal direct-sales ownership view.
- High savings with low profit growth may indicate overbuying or weak sell-through.
- High budget achievement is not automatically good; overspending against budget can still be negative.

## bi_category_growth_market_share.sql

- `View`: `PPL_LIVE.bi_category_growth_market_share`
- `Business purpose`: Tracks whether a category is growing faster or slower than the branch total and how much of total branch sales that category represents.
- `Typical use`: Category management, branch mix reviews, market-share style analysis inside the business, and benchmarking against competitor estimates where available.
- `Reporting grain`: One row per branch, category, and month.

### Business Meaning Of Columns

- `ReportDate`: The month bucket for the performance record.
- `BranchCode`: System branch code.
- `BranchName`: Human-readable branch name.
- `Region`: Branch region used for area-level analysis.
- `Category`: Item category being analyzed.
- `CategorySales`: Net category sales for the month at the branch.
- `BranchSales`: Total net branch sales for the month across all categories.
- `PrevCategorySales`: Same branch-category sales in the previous month.
- `CategoryGrowthValue`: Absolute movement in category sales versus the previous month.
- `CategoryGrowthPct`: Percentage category growth versus the previous month.
- `PrevBranchSales`: Prior-month total branch sales.
- `BranchGrowthValue`: Absolute movement in total branch sales versus the prior month.
- `BranchGrowthPct`: Percentage branch growth versus the prior month.
- `InternalCategoryVsBranchGrowthPct`: The gap between category growth and branch growth; positive means the category is outperforming the branch.
- `CategorySharePct`: The category's share of total branch sales.
- `NewProductSales`: Sales contributed by items classified as new within the script logic.
- `NewProductContributionPct`: Share of category sales coming from new products.
- `NewProductContributionToGrowthRatio`: How much of the category's growth can be linked to new-product sales.
- `CompetitorSales`: External or benchmarked competitor category sales where such data exists.
- `InternalVsCompetitorSharePct`: Internal sales compared to combined internal and competitor sales.
- `CategoryShareBenchmarkGapPct`: Difference between internal category share and competitor/benchmark share.

### Main Calculations And Rules

- Sales are net of returns.
- Previous-period values use window functions such as `LAG`.
- `CategorySharePct = CategorySales / BranchSales`.
- `CategoryGrowthValue = CategorySales - PrevCategorySales`.
- `BranchGrowthValue = BranchSales - PrevBranchSales`.
- New-product contribution is driven by item listing or creation timing.
- Competitor fields are only meaningful if external data is actually populated.

### Interpretation Notes

- If the sum of `CategorySales` across all categories for one branch-month does not equal `BranchSales`, the branch total logic should be reviewed.
- `InternalCategoryVsBranchGrowthPct` is useful for spotting categories carrying the branch versus categories dragging the branch down.

## bi_customer_count.sql

- `View`: `PPL_LIVE.bi_customer_count`
- `Business purpose`: Tracks branch customer counts, sales, average basket value, and month-to-date comparison with the previous month.
- `Typical use`: Store traffic review, basket-value monitoring, and short-cycle branch performance review.
- `Reporting grain`: One row per store, with current MTD and prior-MTD comparison values.

### Business Meaning Of Columns

- `Store Code`: Store identifier.
- `Store Name`: Display name of the store.
- `MTD Start Date`: First day of the current month used for the current period.
- `MTD As At Date`: Current cut-off date for the current MTD period.
- `MTD No. Of Customers`: Number of distinct current-period retail transactions, used as a customer-count proxy.
- `MTD Sales`: Current-period sales value.
- `MTD ABV`: Average basket value in the current period.
- `Last MTD No. Of Customers`: Number of distinct transactions in the comparable prior-month period.
- `Last MTD Sales`: Sales in the comparable prior-month period.
- `Last MTD ABV`: Average basket value in the prior-month period.
- `% ABV Growth`: Percentage change in basket value between current MTD and last MTD.

### Main Calculations And Rules

- Transaction count is normally based on distinct invoice documents.
- Sales are invoices minus credit notes.
- `MTD ABV = MTD Sales / MTD No. Of Customers`.
- `Last MTD ABV = Last MTD Sales / Last MTD No. Of Customers`.
- `% ABV Growth` compares current ABV against prior-period ABV.

### Interpretation Notes

- This report measures transaction count, not unique individual shoppers.
- A rise in `MTD Sales` with flat customer count usually means larger baskets rather than higher traffic.

## bi_employee_performance.sql

- `View`: `PPL_LIVE.bi_employee_performance`
- `Business purpose`: Annual salesperson sales summary pivoted by month.
- `Typical use`: Performance scorecards, annual reviews, incentive discussions, and year-level salesperson ranking.
- `Reporting grain`: One row per salesperson per year.

### Business Meaning Of Columns

- `Year`: Calendar year of the sales summary.
- `SlpName`: Salesperson name.
- `January` to `December`: Net sales assigned to the salesperson in each respective month.
- `Total`: Total annual sales for that salesperson.

### Main Calculations And Rules

- Sales come from invoice lines less credit-note lines.
- Only eligible sales lines are included based on the script filters.
- Month columns are built from monthly sales and then pivoted into a year summary.
- `Total` is the sum of all monthly amounts.

### Interpretation Notes

- This is a wide-format performance table optimized for Excel and BI visuals, not for transactional drill-through.
- `Total` should match the sum of the twelve month columns for a given salesperson-year.

## bi_finance_branch_cash_bank_recon.sql

- `View`: `PPL_LIVE.bi_finance_branch_cash_bank_recon`
- `Business purpose`: Compares tender collections by type against branch sales so finance can identify reconciliation gaps.
- `Typical use`: Daily cash-up review, branch finance control, and investigation of missing or overstated tender postings.
- `Reporting grain`: One row per branch and date.

### Business Meaning Of Columns

- `ReportDate`: Date of the tender and sales reconciliation.
- `BranchCode`: Branch code being reconciled.
- `BranchName`: Branch display name.
- `Region`: Branch region.
- `Cash`: Cash tender recorded for the date.
- `M-Pesa`: Mobile money collections recorded for the date.
- `Card`: Card collections recorded for the date.
- `TotalTender`: Sum of all reported tenders.
- `NetSales`: Net branch sales for the same date.
- `ReconciliationVariance`: Difference between tenders and net sales.
- `ReconciliationStatus`: Business-friendly flag describing whether the branch balances or requires review.

### Main Calculations And Rules

- Tender values are split by payment mode.
- `TotalTender = Cash + M-Pesa + Card`.
- `ReconciliationVariance = TotalTender - NetSales` or the inverse depending on the query implementation, but it always represents the mismatch.
- Status is assigned based on whether the variance falls within acceptable tolerance.

### Interpretation Notes

- A variance close to zero means the branch largely balances.
- Persistent negative or positive variances usually require branch-level receipt and cash-up review.

## bi_finance_branch_level_report.sql

- `View`: `PPL_LIVE.bi_finance_branch_level_report`
- `Business purpose`: Executive branch summary combining sales, gross margin, stock transfers, receivables, and compliance signals in one branch-level finance view.
- `Typical use`: Branch review meetings, branch finance packs, and high-level risk/compliance monitoring.
- `Reporting grain`: One row per branch and date or month depending on the script implementation.

### Business Meaning Of Columns

- `ReportDate`: Reporting date for the branch snapshot.
- `BranchCode`: Branch identifier.
- `BranchName`: Branch name.
- `Region`: Region assignment for the branch.
- `SalesValueTotal`: Sales value for the branch in the period.
- `GrossProfitTotal`: Gross profit generated by the branch in the period.
- `GrossMarginPct`: Gross profit expressed as a percentage of sales.
- `TransfersInValue`: Value of stock transferred into the branch.
- `TransfersOutValue`: Value of stock transferred out of the branch.
- `NetTransferFlow`: Net stock movement value after offsetting transfers in and out.
- `OpenReceivableValue`: Outstanding receivables linked to the branch.
- `OverdueReceivableValue`: The portion of receivables already past due.
- `OpenInvoiceCount`: Number of open receivable documents.
- `OverdueInvoiceCount`: Number of overdue receivable documents.
- `OverdueReceivablePct`: Share of branch receivables that are overdue.
- `ComplianceStatus`: Overall control flag indicating whether the branch is within finance tolerance.

### Main Calculations And Rules

- Gross margin is derived from sales and gross profit.
- Transfer metrics are sourced from inventory-movement logic.
- Receivable metrics are sourced from open-item logic.
- `GrossMarginPct = GrossProfitTotal / SalesValueTotal`.
- `NetTransferFlow = TransfersInValue - TransfersOutValue`.
- `OverdueReceivablePct = OverdueReceivableValue / OpenReceivableValue`.

### Interpretation Notes

- This report is designed as a summary dashboard input, not as an accounting sub-ledger.
- `ComplianceStatus` should be read as a management flag, not an audited accounting opinion.

## bi_finance_branch_pnl_statement.sql

- `View`: `PPL_LIVE.bi_finance_branch_pnl_statement`
- `Business purpose`: Simplified branch profit-and-loss statement.
- `Typical use`: Branch profitability review, regional performance review, and operating leverage analysis.
- `Reporting grain`: One row per branch and reporting period.

### Business Meaning Of Columns

- `ReportDate`: Date or month to which the P&L line belongs.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `Region`: Branch region.
- `Revenue`: Total branch sales or revenue recognized in the period.
- `COGS`: Cost of goods sold for the branch in the period.
- `Gross Margin`: Revenue less COGS.
- `Operating Expenses`: Directly assigned branch operating expenses.
- `Net Profit`: Gross margin after operating expenses.

### Main Calculations And Rules

- `Gross Margin = Revenue - COGS`.
- `Net Profit = Gross Margin - Operating Expenses`.
- Expense mapping depends on the GL or cost-centre design available in the source model.

### Interpretation Notes

- This is a management P&L and may not reconcile exactly to statutory reporting if allocations or timing differences exist.

## bi_finance_expense_tracking.sql

- `View`: `PPL_LIVE.bi_finance_expense_tracking`
- `Business purpose`: Monitors branch operating expenses by category.
- `Typical use`: Expense control, branch cost analysis, and regional cost comparison.
- `Reporting grain`: One row per branch, period, and expense category.

### Business Meaning Of Columns

- `ReportDate`: Reporting date or month.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `Region`: Branch region.
- `ExpenseCategory`: Expense bucket such as rent, utilities, payroll, petty cash, or other operating expense.
- `ExpenseAmount`: Amount posted to that expense category for the branch and period.
- `BranchOperatingExpenses`: Total operating expenses for the branch and period across all categories.
- `CategorySharePct`: Share of the branch's total operating expenses represented by the category.

### Main Calculations And Rules

- Expense mapping is usually done from GL account or cost-centre groupings.
- `CategorySharePct = ExpenseAmount / BranchOperatingExpenses`.

### Interpretation Notes

- This report is useful for mix analysis: two branches can spend the same total amount but have different cost structures.

## bi_finance_receivables_branch_level.sql

- `View`: `PPL_LIVE.bi_finance_receivables_branch_level`
- `Business purpose`: Breaks down receivables exposure by branch and receivable type.
- `Typical use`: Credit control, collection planning, and partner reconciliation monitoring.
- `Reporting grain`: One row per branch, period, and receivable type.

### Business Meaning Of Columns

- `ReportDate`: Date of the receivable snapshot.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `Region`: Region name.
- `ReceivableType`: Business classification of the receivable such as Glovo, UberEats, Sukhiba, SAP, or another partner/customer stream.
- `OpenReceivableValue`: Total outstanding balance not yet settled.
- `OverdueReceivableValue`: Open balance already past due.
- `OpenInvoiceCount`: Number of open documents behind the receivable balance.
- `OverdueInvoiceCount`: Number of overdue documents behind the overdue balance.
- `OverduePct`: Share of open receivables that are overdue.

### Main Calculations And Rules

- Open receivables are usually based on customer ledger open-item logic.
- `OverduePct = OverdueReceivableValue / OpenReceivableValue`.

### Interpretation Notes

- A high `OverduePct` on a specific `ReceivableType` usually points to a partner-specific reconciliation or collection issue.

## bi_inventory_health_by_category.sql

- `View`: `PPL_LIVE.bi_inventory_health_by_category`
- `Business purpose`: Gives a category-aware inventory health view by SKU while still allowing roll-up to supplier, brand, and category.
- `Typical use`: Days-of-stock review, excess stock analysis, expiry control, and stock-versus-sales trend monitoring.
- `Reporting grain`: One row per branch, item, and month-end or snapshot date depending on the script version.

### Business Meaning Of Columns

- `As_At_Date`: Snapshot date for the inventory-health record.
- `BranchCode`: Branch code where the stock sits.
- `BranchName`: Branch name.
- `Region`: Region for the branch.
- `SupplierCode`: Preferred or mapped supplier code for the item.
- `SupplierName`: Supplier name.
- `Brand`: Item brand.
- `Category`: Item category.
- `ItemCode`: Item identifier.
- `ItemName`: Item description.
- `SOH`: Stock on hand quantity.
- `Inventory_Value`: Monetary value of current stock holding for the item in that branch.
- `Sales_30d_Total`: Sales value over the trailing month or month bucket used by the query.
- `Sales_30d_Avg_Daily`: Average daily sales value over the same lookback period.
- `Sales_Prev30d_Avg_Daily`: Average daily sales value in the preceding comparison period.
- `Days_of_Stock_SKU`: How many days the item's current stock value can cover at its current sales pace.
- `Days_of_Stock_Category`: Similar cover metric but using category totals.
- `Target_Stock_Value_30D`: The stock value required to cover roughly 30 days of demand at the current sales rate.
- `Excess_Stock_Value`: Inventory value above the 30-day target; can be negative when understocked.
- `OverUnderStockRisk`: Business label such as overstock, understock, or balanced.
- `Expired_Stock_Value`: Value of already expired stock.
- `NearExpiry_Stock_Value`: Value of stock approaching expiry inside the defined warning horizon.
- `ExpiryNearExpiry_Stock_Value`: Combined value of expired and near-expiry stock.
- `ExpiryNearExpiry_Pct_of_Category`: The item's expiry-risk value as a share of total category inventory value.
- `Sales_Trend_Pct`: Change in current average sales versus the previous comparison period.
- `StockCoverageVsSalesTrend`: Narrative flag describing whether cover is aligned with sales trend.

### Main Calculations And Rules

- Sales are based on invoice sales less returns.
- Inventory value is taken from inventory-transaction or stock-value logic defined in the query.
- `Days_of_Stock_SKU = Inventory_Value / Sales_30d_Avg_Daily`.
- `Target_Stock_Value_30D = Sales_30d_Avg_Daily * 30`.
- `Excess_Stock_Value = Inventory_Value - Target_Stock_Value_30D`.
- Expiry metrics come from batch tables where available.
- Trend compares current average daily sales to previous average daily sales.

### Interpretation Notes

- A high `Days_of_Stock_SKU` is not automatically bad if the item is strategic or seasonal.
- `ExpiryNearExpiry_Pct_of_Category` is useful for spotting categories carrying hidden expiry risk.

## bi_inventory_stock_health.sql

- `View`: `PPL_LIVE.bi_inventory_stock_health`
- `Business purpose`: A simpler item-level stock-health view focused on sales value, stock holding, and essential-item availability.
- `Typical use`: Store-level stock review, essential-item monitoring, and shortage versus overstock control.
- `Reporting grain`: One row per branch, item, and snapshot date.

### Business Meaning Of Columns

- `As_At_Date`: Snapshot date for the stock-health record.
- `WhsCode`: Warehouse or branch code.
- `Branch`: Warehouse name or branch name.
- `ItemCode`: Item key.
- `ItemName`: Item description.
- `Category`: Item category.
- `Molecule`: Active ingredient or molecule attribute from item master.
- `Sales_Value`: Sales value used as the demand reference.
- `SOH`: Stock on hand quantity.
- `Inventory_Value`: Current stock value.
- `Days_of_Stock`: Number of stock-cover days based on the stock value and sales value logic in the query.
- `Stock_Status`: Business traffic light or stock-health classification.
- `Essential_Molecule_Status`: Availability status for essential items.

### Main Calculations And Rules

- Sales value follows the retail sales convention used in other inventory scripts.
- `Days_of_Stock` is typically inventory value divided by average or current sales value.
- `Stock_Status` uses threshold bands to label risk.
- `Essential_Molecule_Status` depends on the essential-item marker from the item master.

### Interpretation Notes

- This is a practical operating report; it is intentionally less detailed than `bi_inventory_health_by_category.sql`.

## bi_product_mix_pricing_analysis.sql

- `View`: `PPL_LIVE.bi_product_mix_pricing_analysis`
- `Business purpose`: Combines sales, pricing, and stock holding to assess assortment quality, price realization, and holding efficiency.
- `Typical use`: Category management, margin review, product mix optimization, and stock-vs-sales balance analysis.
- `Reporting grain`: One row per branch, date, and item.

### Business Meaning Of Columns

- `DocDate`: Sales date.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `Region`: Region name.
- `ItemCode`: Item identifier.
- `ItemName`: Item description.
- `Category`: Category name.
- `Brand`: Brand name.
- `SubCategory1`: First subcategory attribute.
- `SubCategory2`: Second subcategory attribute.
- `SubCategory3`: Third subcategory attribute.
- `Formulation`: Product formulation attribute.
- `QtyBaseUoM`: Quantity sold in the base unit of measure.
- `SalesLineTotal`: Sales before VAT.
- `SalesVat`: VAT on the sales line.
- `SalesValueTotal`: Sales including VAT.
- `AvgSellingPrice`: Average realized selling price per base unit.
- `OnHandQty`: Current physical stock quantity.
- `StockValue`: Current stock value.
- `SalesVsHoldingValue`: Ratio or comparison of sales value to stock value.
- `SalesVsHoldingQty`: Ratio or comparison of sales quantity to stock quantity.

### Main Calculations And Rules

- `AvgSellingPrice = SalesValueTotal / QtyBaseUoM` or the equivalent pre-VAT basis depending on the script.
- Holding ratios compare demand to current stock investment.
- The mix dimensions come from the item master.

### Interpretation Notes

- High stock value with low sales value often flags range inefficiency.
- A strong `AvgSellingPrice` should always be read together with quantity and stock position.

## bi_profitability_category.sql

- `View`: `PPL_LIVE.bi_profitability_category`
- `Business purpose`: Tracks category sales, margin, share, and comparative movement over time.
- `Typical use`: Category-level gross-profit analysis and monthly commercial reviews.
- `Reporting grain`: One row per category and reporting date.

### Business Meaning Of Columns

- `ReportDate`: Date or month of the category performance record.
- `Category`: Category name.
- `Monthly Sales`: Net category sales for the period.
- `GP %`: Gross profit percentage on category sales.
- `% Share`: Category share of total sales for the same date.
- `MoM_Change`: Month-over-month sales change value.
- `YoY_Change`: Year-over-year sales change value.

### Main Calculations And Rules

- Sales are invoices less returns.
- Gross profit is summed from line gross profit.
- `% Share = Category Sales / Total Sales`.
- `GP % = GP / Sales * 100`.

### Interpretation Notes

- A category can grow sales while losing `GP %`, which usually points to price pressure or a changed product mix.

## bi_profitability_dashboard.sql

- `View`: `PPL_LIVE.bi_profitability_dashboard`
- `Business purpose`: Daily store-level profitability and budget tracking dashboard.
- `Typical use`: Daily branch performance review, budget variance monitoring, and store profitability steering.
- `Reporting grain`: One row per store and date.

### Business Meaning Of Columns

- `ReportDate`: Trading date.
- `Store`: Store name.
- `Region`: Store region.
- `Daily Sales`: Net sales for the day.
- `Daily GP`: Gross profit for the day.
- `Daily Budget`: Daily pro-rated sales budget.
- `GP %`: Gross profit percentage for the day.
- `Budget_Variance`: Difference between actual daily sales and daily budget.
- `MoM_Change`: Difference versus the comparable prior-month date.
- `YoY_Change`: Difference versus the comparable prior-year date.

### Main Calculations And Rules

- Budget is usually a monthly target divided by days in month.
- `GP % = Daily GP / Daily Sales * 100`.
- `Budget_Variance = Daily Sales - Daily Budget`.
- Prior-month and prior-year comparisons are date-aligned in the query.

### Interpretation Notes

- This is useful for daily steering but should not be mistaken for a full management P&L.

## bi_profitability_discount_impact_analysis.sql

- `View`: `PPL_LIVE.bi_profitability_discount_impact_analysis`
- `Business purpose`: Measures how discounts and promotions reduce gross profit by category.
- `Typical use`: Promotion review, discount governance, and leakage analysis.
- `Reporting grain`: One row per category and date.

### Business Meaning Of Columns

- `ReportDate`: Date of the category discount-impact record.
- `Category`: Category name.
- `Sales`: Net sales after discount.
- `Promo`: Value given away through discounts or promotional price reductions.
- `Discount %`: Discount as a percentage of gross-before-discount sales.
- `GP_With_Promo`: Actual gross profit after promotion.
- `GP_Without_Promo`: Implied gross profit if the promotional discount had not been given.
- `% lost to Discount`: Share of potential gross profit given away through discounting.

### Main Calculations And Rules

- Promo amount is usually `(Quantity * PriceBeforeDiscount) - LineTotal`.
- `Discount % = Promo / (Sales + Promo)`.
- `GP_Without_Promo = GP_With_Promo + Promo`.
- `% lost to Discount = Promo / GP_Without_Promo`.

### Interpretation Notes

- High promo cost is acceptable only if the volume or strategic payoff justifies it.

## bi_profitability_product_profit_leakage.sql

- `View`: `PPL_LIVE.bi_profitability_product_profit_leakage`
- `Business purpose`: Highlights products with weak gross-profit performance.
- `Typical use`: Product rationalization, price review, and margin leakage investigation.
- `Reporting grain`: One row per product and date.

### Business Meaning Of Columns

- `ReportDate`: Date of the product record.
- `Description`: Product description.
- `Category`: Product category.
- `Sales`: Net sales value.
- `GP`: Gross profit value.
- `GP %`: Gross profit margin percentage.

### Main Calculations And Rules

- Sales and profit are both net of returns.
- `GP % = GP / Sales * 100`.

### Interpretation Notes

- Sort ascending on `GP %` to see the largest leakage candidates first.
- A low `GP %` item is not always wrong; some items are deliberate traffic drivers.

## bi_promotions_campaign_performance.sql

- `View`: `PPL_LIVE.bi_promotions_campaign_performance`
- `Business purpose`: Evaluates campaign uplift, discount cost, and funded-promotion performance.
- `Typical use`: Promotion post-mortems, supplier-funded campaign review, and category-manager scorecards.
- `Reporting grain`: One row per campaign, branch, item, and date.

### Business Meaning Of Columns

- `ReportDate`: Date of the campaign performance record.
- `CampaignCode`: Campaign or promotion identifier.
- `FundingType`: Funding ownership such as supplier-funded or retailer-funded.
- `BranchCode`: Branch where the campaign performance is measured.
- `BranchName`: Branch name.
- `Region`: Branch region.
- `ItemCode`: Item code.
- `ItemName`: Item name.
- `Category`: Item category.
- `SupplierCode`: Supplier code.
- `SupplierName`: Supplier name.
- `PromoQty`: Quantity sold during the campaign period.
- `BaselineQty`: Expected quantity in a normal non-campaign period.
- `UpliftQty`: Additional quantity sold because of the campaign.
- `UpliftQtyPct`: Percentage uplift in quantity versus baseline.
- `PromoSales`: Sales generated during the campaign.
- `BaselineSales`: Expected sales without the campaign.
- `UpliftSales`: Additional sales generated above baseline.
- `UpliftSalesPct`: Percentage uplift in sales versus baseline.
- `PromoGrossBeforeDiscount`: Gross sales before applying the promotional give-away.
- `PromoCost`: Commercial cost of the promotion.
- `PromoROI`: Return on the promotional spend.
- `SupplierFundedPromoSales`: Promo sales attached to supplier-funded campaigns.
- `SupplierFundedPromoCost`: Supplier-funded promo cost.
- `RetailerFundedPromoSales`: Promo sales attached to retailer-funded campaigns.
- `RetailerFundedPromoCost`: Retailer-funded promo cost.

### Main Calculations And Rules

- Baseline values are meant to represent normal, non-promoted sales.
- `UpliftQty = PromoQty - BaselineQty`.
- `UpliftSales = PromoSales - BaselineSales`.
- `PromoROI` compares incremental gain to promotional cost.
- Funding splits are driven by `FundingType`.

### Interpretation Notes

- High `PromoSales` does not always mean a successful campaign if `PromoROI` is weak.
- Supplier-funded and retailer-funded activity should be reviewed separately because the risk owner is different.

## bi_retail_branch_performance_ranking.sql

- `View`: `PPL_LIVE.bi_retail_branch_performance_ranking`
- `Business purpose`: Ranks branches by sales and profit.
- `Typical use`: Top-bottom branch league tables and branch recognition or intervention lists.
- `Reporting grain`: One row per branch, category, and report date.

### Business Meaning Of Columns

- `ReportDate`: Reporting period.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `Category`: Category used for ranking context.
- `SalesLineTotal`: Sales before VAT.
- `SalesVat`: VAT amount.
- `SalesValueTotal`: Sales including VAT.
- `NetSalesApprox`: Approximate net sales measure used for comparison.
- `TopSalesRank`: Position when ranking branches from highest to lowest sales.
- `BottomSalesRank`: Position when ranking branches from lowest to highest sales.
- `TopProfitRank`: Position when ranking branches from highest to lowest profit.
- `BottomProfitRank`: Position when ranking branches from lowest to highest profit.
- `Top10Flag`: Flag for branches inside the top-ten set.
- `Bottom10Flag`: Flag for branches inside the bottom-ten set.

### Main Calculations And Rules

- Ranks use window functions over the chosen period and category grouping.
- Top/bottom flags are derived from the rank fields.

### Interpretation Notes

- The branch can be top in sales and still weak in profit, so both sales and profit ranks should be read together.

## bi_retail_branch_sales_performance.sql

- `View`: `PPL_LIVE.bi_retail_branch_sales_performance`
- `Business purpose`: Flexible branch sales performance fact table that supports daily, hourly, branch, employee, and item analysis.
- `Typical use`: Detailed branch operational reporting, productivity review, trading pattern analysis, and time-series comparisons.
- `Reporting grain`: Mixed grain defined by `GrainType`, commonly one row per date-hour-branch-employee-item combination.

### Business Meaning Of Columns

- `GrainType`: Identifies whether the row is daily, hourly, or another summary grain.
- `ReportDate`: Business date.
- `HourNo`: Hour bucket for hourly analysis.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `Region`: Region name.
- `EmployeeName`: Salesperson or serving staff linked to the row.
- `ItemCode`: Item code.
- `ItemName`: Item name.
- `CustomerCount`: Count of transactions or customers represented in the row.
- `SalesLineTotal`: Sales before VAT.
- `SalesVat`: VAT amount.
- `SalesValueTotal`: Sales including VAT.
- `NetSalesRatio`: Ratio used to compare net performance within the selected grain.
- `ActiveHours`: Number of hours with trading activity.
- `Branch24HFlag`: Flag identifying 24-hour stores.
- `PrevDaySalesValue`: Comparable prior-day sales value.
- `PrevWeekSalesValue`: Comparable prior-week sales value.
- `PrevMonthSalesValue`: Comparable prior-month sales value.
- `DoDDeltaPct`: Day-over-day percentage change.
- `WoWDeltaPct`: Week-over-week percentage change.
- `MoMDeltaPct`: Month-over-month percentage change.

### Main Calculations And Rules

- Comparative metrics use lagged sales at matching grain.
- Ratio fields are intended for trend reading rather than strict accounting.

### Interpretation Notes

- This view is useful as a reusable semantic layer because it supports multiple BI visuals from one source.

## bi_retail_channel_sales_report.sql

- `View`: `PPL_LIVE.bi_retail_channel_sales_report`
- `Business purpose`: Shows sales and inventory by sales channel.
- `Typical use`: Store-channel comparisons, channel productivity review, and inventory support analysis.
- `Reporting grain`: One row per report date, branch, and channel.

### Business Meaning Of Columns

- `ReportDate`: Reporting date.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `Region`: Region name.
- `Channel`: Sales channel such as walk-in, online, partner, or another mapped stream.
- `SalesLineTotal`: Sales before VAT.
- `SalesVat`: VAT value.
- `SalesValueTotal`: Sales including VAT.
- `InventoryValue`: Stock value assigned to the branch or channel context.
- `PrevSalesValue`: Prior-period sales for the same branch-channel.
- `SalesValueDelta`: Absolute movement versus prior period.
- `SalesValueDeltaPct`: Percentage movement versus prior period.

### Main Calculations And Rules

- Channel mapping is driven by customer, project, or branch-channel logic in the script.
- `SalesValueDelta = SalesValueTotal - PrevSalesValue`.

### Interpretation Notes

- This is strong for mix analysis but channel assignment quality depends entirely on source tagging quality.

## bi_retail_employee_performance_ranking.sql

- `View`: `PPL_LIVE.bi_retail_employee_performance_ranking`
- `Business purpose`: Ranks employees by sales, profit, and improvement.
- `Typical use`: Incentive reviews, coaching, and identifying top and bottom performers.
- `Reporting grain`: One row per employee, category, and report period.

### Business Meaning Of Columns

- `ReportDate`: Reporting date or month.
- `EmployeeCode`: Employee or salesperson code.
- `EmployeeName`: Employee name.
- `Category`: Category context for the performance row.
- `SalesLineTotal`: Sales before VAT.
- `SalesVat`: VAT amount.
- `SalesValueTotal`: Sales including VAT.
- `NetSalesApprox`: Approximate net sales metric used for ranking.
- `PrevMonthSalesValue`: Prior-month sales value.
- `MoMSalesValueDelta`: Absolute change versus previous month.
- `TopSalesRank`: Best-to-worst sales ranking.
- `BottomSalesRank`: Worst-to-best sales ranking.
- `TopProfitRank`: Best-to-worst profit ranking.
- `BottomProfitRank`: Worst-to-best profit ranking.
- `MostImprovedRank`: Rank by positive sales improvement.
- `MostDroppedRank`: Rank by largest decline.
- `Top10Flag`: Flag for top performers.
- `Bottom10Flag`: Flag for bottom performers.

### Main Calculations And Rules

- Ranking uses window functions.
- Improvement ranks are based on period-over-period deltas.

### Interpretation Notes

- Rank output should be read together with actual sales values; a strong rank in a tiny category may still mean modest commercial impact.

## bi_retail_high_value_items_sales.sql

- `View`: `PPL_LIVE.bi_retail_high_value_items_sales`
- `Business purpose`: Focuses on high-value items and price-sensitive premium stock.
- `Typical use`: Premium-item review, price control, branch mix review, and visibility into valuable SKUs.
- `Reporting grain`: One row per report date, branch, and item.

### Business Meaning Of Columns

- `ReportDate`: Trading date.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `ItemCode`: Item code.
- `ItemName`: Item description.
- `Category`: Category name.
- `Brand`: Brand name.
- `Formulation`: Formulation attribute.
- `QtyBaseUoM`: Quantity sold in base UoM.
- `SalesLineTotal`: Sales before VAT.
- `SalesVat`: VAT amount.
- `SalesValueTotal`: Sales including VAT.
- `AvgSellingPrice`: Average price realized per unit.
- `HighValueFlag`: Flag that identifies items classified as high value by the script.
- `TabletAt50Flag`: Additional business rule flag used for a specific pricing or assortment condition.
- `TopSalesRankInBranch`: The item's sales rank inside its branch.

### Main Calculations And Rules

- High-value logic is rule-based and uses thresholds defined in the script.
- `AvgSellingPrice` is derived from sales divided by quantity.

### Interpretation Notes

- This report is usually used as an exception report rather than a full assortment report.

## bi_retail_inventory_report.sql

- `View`: `PPL_LIVE.bi_retail_inventory_report`
- `Business purpose`: Despite the filename, the current SQL body behaves as a cross-sell style report rather than a classic inventory report.
- `Typical use`: Measures how often an item appears in documents that contain at least one additional item, across daily, weekly, and monthly views.
- `Reporting grain`: One row per period type, period start date, branch, and item.

### Business Meaning Of Columns

- `PeriodType`: Indicates whether the row is a daily, weekly, or monthly summary.
- `ReportDate`: Start date of the reporting period.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `ItemCode`: Item code.
- `ItemName`: Item description.
- `Category`: Category name.
- `ItemDocs`: Number of documents in which the item appeared during the period.
- `CrossSellDocs`: Number of those documents that contained at least one additional distinct item.
- `CrossSellRate`: Share of the item's documents that were cross-sell capable.
- `PrevCrossSellRate`: Previous comparable period's cross-sell rate for the same branch-item.
- `CrossSellRateDeltaPct`: Percentage change in cross-sell rate versus the previous comparable period.

### Main Calculations And Rules

- The query only uses invoice documents in its current form.
- A document counts as cross-sell when it contains at least two distinct items.
- `CrossSellRate = CrossSellDocs / ItemDocs`.
- Lag logic provides `PrevCrossSellRate`.

### Interpretation Notes

- The filename should not be read literally; document the current logic before repurposing it.
- If you intend this file to become a true inventory report, the SQL body should be redesigned.

## bi_retail_newly_listed_items_sales.sql

- `View`: `PPL_LIVE.bi_retail_newly_listed_items_sales`
- `Business purpose`: Tracks performance of items newly introduced into the assortment.
- `Typical use`: New product launch tracking, listing success measurement, and post-listing ramp-up analysis.
- `Reporting grain`: One row per report date, item, and branch.

### Business Meaning Of Columns

- `ReportDate`: Sales date.
- `ListDate`: Item listing or creation date used as the reference start.
- `DaysFromListing`: Number of days from listing to the report date.
- `ListingStage`: Script-defined maturity stage such as newly listed, early life, or established.
- `ItemCode`: Item code.
- `ItemName`: Item name.
- `Category`: Category name.
- `Brand`: Brand name.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `QtyBaseUoM`: Quantity sold in base units.
- `SalesLineTotal`: Sales before VAT.
- `SalesVat`: VAT amount.
- `SalesValueTotal`: Sales including VAT.

### Main Calculations And Rules

- Listing-stage buckets are based on `DaysFromListing`.
- Sales metrics follow the normal retail sales logic.

### Interpretation Notes

- This report is helpful for distinguishing weak launches from products that simply have not had enough time to mature.

## bi_retail_regional_pricing_report.sql

- `View`: `PPL_LIVE.bi_retail_regional_pricing_report`
- `Business purpose`: Compares realized pricing across regions versus the company average.
- `Typical use`: Price governance, regional pricing consistency checks, and margin protection.
- `Reporting grain`: One row per report date, region, and item.

### Business Meaning Of Columns

- `ReportDate`: Reporting date or month.
- `Region`: Region name.
- `ItemCode`: Item code.
- `ItemName`: Item description.
- `Category`: Category name.
- `Brand`: Brand name.
- `QtyBaseUoM`: Quantity sold.
- `SalesLineTotal`: Sales before VAT.
- `SalesVat`: VAT amount.
- `SalesValueTotal`: Sales including VAT.
- `RegionalAvgPrice`: Average realized price in the region.
- `CompanyAvgPrice`: Average realized price across the business.
- `RegionalPriceIndex`: Ratio of regional average price to company average price.
- `PrevMonthAvgPrice`: Prior-month regional average price.
- `MoMPriceDeltaPct`: Month-over-month regional price movement.

### Main Calculations And Rules

- Average price is derived from sales divided by quantity.
- `RegionalPriceIndex = RegionalAvgPrice / CompanyAvgPrice`.
- `MoMPriceDeltaPct` compares current regional average price to previous month.

### Interpretation Notes

- A price index significantly above 1 indicates the region is selling above the company average.

## bi_retail_sales_report.sql

- `View`: `PPL_LIVE.bi_retail_sales_report`
- `Business purpose`: Core detailed retail sales fact table used for multiple downstream analyses.
- `Typical use`: Drill-through, custom analytics, branch performance, employee performance, category reviews, and pricing analysis.
- `Reporting grain`: One row per sales document line.

### Business Meaning Of Columns

- `DocType`: Sales document type such as invoice or credit note.
- `DocEntry`: Internal SAP document identifier.
- `DocNum`: User-facing document number.
- `LineNum`: Line number inside the source document.
- `DocDate`: Document date.
- `YearNo`: Calendar year of the document.
- `MonthNo`: Calendar month number.
- `MonthKey`: Text key representing the month bucket.
- `WeekKey`: Text key representing the week bucket.
- `DocHour`: Trading hour of the document where captured.
- `ShiftName`: Script-defined shift grouping.
- `CustomerCode`: Customer code.
- `CustomerName`: Customer name.
- `SalespersonCode`: Salesperson code.
- `SalespersonName`: Salesperson name.
- `ItemCode`: Item code.
- `ItemName`: Item description.
- `Category`: Item category.
- `Brand`: Item brand.
- `SubCategory1`: First subcategory attribute.
- `SubCategory2`: Second subcategory attribute.
- `SubCategory3`: Third subcategory attribute.
- `Formulation`: Product formulation.
- `Molecule`: Active ingredient or molecule.
- `SupplierCode`: Supplier code.
- `SupplierName`: Supplier name.
- `BranchCode`: Branch code.
- `BranchName`: Branch name.
- `Region`: Region name.
- `BranchTier`: Tier or format classification for the branch.
- `BM`: Branch manager or business manager field used by the model.
- `RM`: Regional manager field.
- `HOR`: Head-of-retail or similar management field.
- `Channel`: Sales channel.
- `Project`: Project or commercial tag attached to the transaction.
- `QtySalesUoM`: Quantity in sales unit of measure.
- `QtyBaseUoM`: Quantity translated into base unit of measure.
- `GrossBeforeDiscount`: Value before discounts.
- `DiscountAmount`: Monetary discount given.
- `NetSales`: Final net sales amount.
- `GrossProfit`: Gross profit.
- `CostAmount`: Cost assigned to the sale.
- `GPMarginPct`: Gross-profit percentage.
- `MarkupPct`: Markup percentage.

### Main Calculations And Rules

- This is the most reusable retail fact source in the folder.
- It combines sales headers, sales lines, and item dimensions.
- Net sales are after discounts and after returns are netted off.
- `GPMarginPct = GrossProfit / NetSales`.
- `MarkupPct = GrossProfit / CostAmount`.

### Interpretation Notes

- If a downstream report disagrees with another report, this file is often the first place to reconcile the sales logic.

## bi_retail_top_1000_selling_items.sql

- `View`: `PPL_LIVE.bi_retail_top_1000_selling_items`
- `Business purpose`: Produces a ranked list of the top-selling items, currently at company level in the latest script revision.
- `Typical use`: Top-item lists, assortment focus, promotional prioritization, and executive reporting.
- `Reporting grain`: One row per month and item for the top-ranked company items.

### Business Meaning Of Columns

- `GrainType`: Identifies the ranking grain; currently `COMPANY`.
- `ReportDate`: Month bucket represented by the row.
- `BranchCode`: Branch code field reserved for future lower-grain versions; currently null.
- `BranchName`: Branch name field reserved for future lower-grain versions; currently null.
- `Region`: Region context; currently set to `COMPANY`.
- `ItemCode`: Item code.
- `ItemName`: Item name.
- `Category`: Category name.
- `Brand`: Brand name.
- `QtyBaseUoM`: Net quantity sold in base units.
- `SalesLineTotal`: Net sales before VAT.
- `SalesVat`: Net VAT amount.
- `SalesValueTotal`: Net sales including VAT.
- `SalesRank`: Companywide rank for the item in the month.
- `Top1000Flag`: Flag showing that the row belongs to the top-1000 set.
- `RegionSalesValueTotal`: Placeholder for region-level sales in this script revision; currently null.
- `RegionSalesRank`: Placeholder for region-level rank; currently null.
- `Top1000RegionFlag`: Placeholder flag for region ranking; currently null.
- `CompanySalesValueTotal`: Company sales value repeated explicitly for company-ranking use.
- `CompanySalesRank`: Companywide rank repeated explicitly.
- `Top1000CompanyFlag`: Companywide top-1000 flag.

### Main Calculations And Rules

- Sales are derived from invoices minus credit notes.
- Quantities and values are first aggregated to daily item level, then to monthly item level.
- Ranking uses `RANK()` by descending `SalesValueTotal`.
- Only rows with `SalesRank <= 1000` are retained.

### Interpretation Notes

- This report should now avoid the inflation problem that appears when company, region, and branch grains are mixed in one rowset.
- Because the current script is company-level only, branch and region fields are placeholders rather than active dimensions.

## bi_sales_breakdown_report.sql

- `View`: `PPL_LIVE.bi_sales_breakdown_report`
- `Business purpose`: Daily branch sales versus daily, MTD, and YTD budgets.
- `Typical use`: Sales-control dashboard, target tracking, and branch budget-performance reporting.
- `Reporting grain`: One row per branch and date.

### Business Meaning Of Columns

- `DocDate`: Trading date.
- `WhsCode`: Branch code.
- `Business`: Branch name or business unit label.
- `Region`: Region name.
- `Daily_Budget`: The pro-rated budget for the single day.
- `Daily_Actual`: Actual sales for the day.
- `Mtd_Budget_Run`: Running month-to-date budget up to that date.
- `Mtd_Actual_Run`: Running month-to-date actual sales up to that date.
- `Ytd_Budget_Run`: Running year-to-date budget up to that date.
- `Ytd_Actual_Run`: Running year-to-date actual sales up to that date.

### Main Calculations And Rules

- Daily budget is generally monthly target divided by number of days in month.
- MTD and YTD fields use windowed cumulative sums.
- Actual sales are based on invoice sales less returns.

### Interpretation Notes

- This report is particularly useful in visuals where users filter to a date range and expect cumulative budget and actual views.

## bi_sales_profitability.sql

- `View`: `PPL_LIVE.bi_sales_profitability`
- `Business purpose`: Compares branch sales to stock-transfer flows to approximate commercial profitability pressure.
- `Typical use`: Branch profitability review, transfer dependency review, and operational margin monitoring.
- `Reporting grain`: One row per branch and date.

### Business Meaning Of Columns

- `DocDate`: Reporting date.
- `Warehouse`: Branch or warehouse code.
- `Branch Name`: Branch name.
- `Branch Region`: Region name.
- `Sales Value`: Net branch sales value.
- `Transfers In Value`: Value of stock moved into the branch.
- `Transfers Out Value`: Value of stock moved out of the branch.
- `Transfers In - Out Value`: Net transfer value.
- `Variance`: Sales value less net transfer value.
- `GP %`: A ratio expressing the branch's commercial spread under the script logic.

### Main Calculations And Rules

- Sales follow the normal invoice-minus-credit-note approach.
- Transfer flows come from inventory movement data.
- `Transfers In - Out Value = Transfers In Value - Transfers Out Value`.
- `Variance = Sales Value - (Transfers In - Out Value)`.

### Interpretation Notes

- This is a management proxy and not a statutory gross-profit statement.
- High transfer dependency can distort apparent profitability when read without the wider operational context.

## bi_finance_sales_vs_transfers.sql

- `View`: `PPL_LIVE.bi_finance_sales_vs_transfers`
- `Business purpose`: Compares branch sales to stock-transfer flows in a finance-facing view that can be filtered directly by reporting date.
- `Typical use`: Branch finance review, stock-movement dependency tracking, and sales-versus-transfer variance analysis.
- `Reporting grain`: One row per branch and date.

### Business Meaning Of Columns

- `DocDate`: Reporting date used for filtering and period slicing.
- `Warehouse`: Branch or warehouse code.
- `Branch Name`: Branch name.
- `Branch Region`: Region name.
- `Sales Value`: Net branch sales value.
- `Transfers In Value`: Value of stock moved into the branch.
- `Transfers Out Value`: Value of stock moved out of the branch.
- `Transfers In - Out Value`: Net transfer value.
- `Variance`: Sales value less net transfer value.
- `GP %`: A ratio expressing the branch's commercial spread under the script logic.

### Main Calculations And Rules

- Sales follow the normal invoice-minus-credit-note approach.
- Transfer flows come from inventory movement data with `TransType = '67'`.
- `DocDate` is retained in the output so BI tools can filter without rewriting the query.
- `Transfers In - Out Value = Transfers In Value - Transfers Out Value`.
- `Variance = Sales Value - (Transfers In - Out Value)`.

### Interpretation Notes

- This is an operational finance view rather than a statutory gross-profit statement.
- Branches with no sales and no transfer activity for a date will not appear unless a separate branch-date scaffold is introduced.

## bi_finance_sales_vs_purchases_value_by_day.sql

- `View`: `PPL_LIVE.bi_finance_sales_vs_purchases_value_by_day`
- `Business purpose`: Compares daily net sales, daily net purchase postings, and daily gross profit in one finance-ready time series.
- `Typical use`: Daily finance dashboarding, purchase-versus-sales trend review, and gross-profit trend tracking.
- `Reporting grain`: One row per posting date.

### Business Meaning Of Columns

- `Posting Date`: The SAP posting date used for period filtering.
- `Sales Value`: Daily net sales value from A/R invoices less A/R credit notes.
- `Purchases Value`: Daily net purchases value from A/P invoices less A/P credit notes.
- `Gross Profit`: Daily gross profit from sales transactions net of returns.

### Main Calculations And Rules

- Sales come from `OINV` and `INV1`, reduced by `ORIN` and `RIN1`.
- Purchases come from `OPCH` and `PCH1`, reduced by `ORPC` and `RPC1`.
- Sales and purchases are both measured on pre-VAT line value using `LineTotal`.
- Gross profit comes from `GrssProfit` on sales lines, net of returns.
- Dates are unioned from both daily sales and daily purchases so a date appears even if only one side had activity.

### Interpretation Notes

- This is a date-level finance trend view; it does not include branch, item, or supplier dimensions.
- If you want a VAT-inclusive version instead, the sales and purchase value logic should be changed explicitly rather than mixed silently.

## bi_finance_ageing.sql

- `View`: `PPL_LIVE.bi_finance_ageing`
- `Business purpose`: Produces a vendor ageing extract in a normalized vendor-year-month format.
- `Typical use`: Accounts payable ageing analysis, vendor monthly balance review, and Power BI pivoting by year and month.
- `Reporting grain`: One row per vendor per posting year per posting month.

### Business Meaning Of Columns

- `Vendor Code`: Supplier business partner code.
- `Year`: Calendar year of the posting month contributing to the ageing balance.
- `MonthName`: Calendar month name of the posting month contributing to the ageing balance.
- `Balance Due`: Open payable balance attributed to that vendor-year-month row.
- `Consolidated BP Code`: Parent or head-office BP code using `OCRD.FatherCard`, falling back to the vendor's own code.
- `Consolidated BP Name`: Parent or head-office BP name, falling back to the vendor's own name.

### Main Calculations And Rules

- Open balances are sourced from `JDT1` and adjusted using internal reconciliation data from `OITR` and `ITR1`.
- Only supplier BPs with `OCRD.CardType = 'S'` are included.
- The payable balance uses the vendor-sign logic, so only positive open supplier balances are retained.
- Posting months are derived from `RefDate` and automatically expand as new months appear in the source.
- The view is normalized so month values are stored as rows rather than hard-coded columns.
- `Balance Due` stores the ageing amount for the specific vendor-year-month row.

### Interpretation Notes

- This is a current-state ageing view because reconciliation is applied up to `CURRENT_DATE`.
- In Power BI, sort `MonthName` by a month-number helper in the model if you need true January-to-December order in visuals.

## Using The README In Practice

- Use this README as a functional data dictionary for report developers and business reviewers.
- When a report total looks wrong, first confirm the script's grain and the definition of sales being used.
- If a file name and SQL body do not match, trust the SQL body and update the filename or logic as part of cleanup.
- If a report is going to production, keep this README in sync with any changes to columns, naming, or calculation logic.

---
## HRMIS Structural Reference
The section below consolidates the previous HRMIS folder README so the structural extraction context also lives in the main project document.
This folder was generated from the HRMIS table DDL you pasted into the session on 2026-03-22.

- `00_schema.sql`: schema creation statement.
- `_raw_ddl_from_session.sql`: recovered source text from the session, including non-table content.
- `_source_tables_only.sql`: full extracted table-only DDL source.
- `generate_hrmis_tables.ps1`: rebuilds the per-table files from the recovered source.
- `*.sql`: one file per table definition, preserving the original table block from the DDL.

## Table Count

492 tables extracted.

## Tables

- `A1.sql`
- `AA.sql`
- `AAA.sql`
- `AAAA.sql`
- `AAAAA.sql`
- `ACC0001.sql`
- `ACC00011.sql`
- `ACC0001_APPLICANTS.sql`
- `ACC0002.sql`
- `ACC0003.sql`
- `ACC0004.sql`
- `ACC0005.sql`
- `ACC0006.sql`
- `ACC0007.sql`
- `ACC0008.sql`
- `ACC0009.sql`
- `ACC0010.sql`
- `ACC00100.sql`
- `ACC0011.sql`
- `ACC0012.sql`
- `ACC0013.sql`
- `ACC0014.sql`
- `ACC0015.sql`
- `ACC0016.sql`
- `ACC0017.sql`
- `ACC0018.sql`
- `ACC0019.sql`
- `ACC0020.sql`
- `ACC0021.sql`
- `ACC0022.sql`
- `ACC0023.sql`
- `ACC00238.sql`
- `ACC0024.sql`
- `ACC0025.sql`
- `ACC0026.sql`
- `ACC0027.sql`
- `ACC0028.sql`
- `ACC0029.sql`
- `ACC0030.sql`
- `ACC0031.sql`
- `ACC0032.sql`
- `ACC0033.sql`
- `ACC0034.sql`
- `ACC0035.sql`
- `ACC0036.sql`
- `ACC0036_UPLOAD.sql`
- `ACC0037.sql`
- `ACC0038.sql`
- `ACC0038_UPLOAD.sql`
- `ACC0040.sql`
- `ACC0041.sql`
- `ACC0042.sql`
- `ACC0042_CASUALS.sql`
- `ACC0043.sql`
- `ACC0044.sql`
- `ACC0044_CASUALS.sql`
- `ACC0045.sql`
- `ACC0046.sql`
- `ACC0047.sql`
- `ACC0048.sql`
- `ACC0049.sql`
- `ACC0050.sql`
- `ACC0051.sql`
- `ACC0052.sql`
- `ACC0053.sql`
- `ACC0053.01.sql`
- `ACC0053.02.sql`
- `ACC0054.sql`
- `ACC0055.sql`
- `ACC00555.sql`
- `ACC0055_CASUALS.sql`
- `ACC0056.sql`
- `ACC0057.sql`
- `ACC0058.sql`
- `ACC0059.sql`
- `ACC0060.sql`
- `ACC0061.sql`
- `ACC0062.sql`
- `ACC0063.sql`
- `ACC0064.sql`
- `ACC0065.sql`
- `ACC0066.sql`
- `ACC0067.sql`
- `ACC0069.sql`
- `ACC0070.sql`
- `ACC0071.sql`
- `ACC0072.sql`
- `ACC0073.sql`
- `ACC0074.sql`
- `ACC0075.sql`
- `ACC0076.sql`
- `ACC0077.sql`
- `ACC0078.sql`
- `ACC0079.sql`
- `ACC0080.sql`
- `ACC0081.sql`
- `ACC0082.sql`
- `ACC0083.sql`
- `ACC0084.sql`
- `ACC0085.sql`
- `ACC0086.sql`
- `ACC0087.sql`
- `ACC0088.sql`
- `ACC0089.sql`
- `ACC0090.sql`
- `ACC0091.sql`
- `ACC0092.sql`
- `ACC0093.sql`
- `ACC0094.sql`
- `ACC0094_CASUALS.sql`
- `ACC0095.sql`
- `ACC0096.sql`
- `ACC0097.sql`
- `ACC0098.sql`
- `ACC0098_CASUALS.sql`
- `ACC0099.sql`
- `ACC0100.sql`
- `ACC0101.sql`
- `ACC0102.sql`
- `ACC0103.sql`
- `ACC0104.sql`
- `ACC0105.sql`
- `ACC0106.sql`
- `ACC01062.sql`
- `ACC01063.sql`
- `ACC0107.sql`
- `ACC0108.sql`
- `ACC0109.sql`
- `ACC0110.sql`
- `ACC0111.sql`
- `ACC0112.sql`
- `ACC0113.sql`
- `ACC0120.sql`
- `ACC0120_CASUALS.sql`
- `ACC0121.sql`
- `ACC0122.sql`
- `ACC0123.sql`
- `ACC0124.sql`
- `ACC0125.sql`
- `ACC0126.sql`
- `ACC0127.sql`
- `ACC0128.sql`
- `ACC0129.sql`
- `ACC0130.sql`
- `ACC0131.sql`
- `ACC0132.sql`
- `ACC0133.sql`
- `ACC0134.sql`
- `ACC0138.sql`
- `ACC0139.sql`
- `ACC0140.sql`
- `ACC0141.sql`
- `ACC0142.sql`
- `ACC0143.sql`
- `ACC0144.sql`
- `ACC0145.sql`
- `ACC0146.sql`
- `ACC0147.sql`
- `ACC0148.sql`
- `ACC0149.sql`
- `ACC0150.sql`
- `ACC0151.sql`
- `ACC0152.sql`
- `ACC0153.sql`
- `ACC0156.sql`
- `ACC0158.sql`
- `ACC0159.sql`
- `ACC0161.sql`
- `ACC0163.sql`
- `ACC0164.sql`
- `ACC0165.sql`
- `ACC0167.sql`
- `ACC0171.sql`
- `ACC0172.sql`
- `ACC0174.sql`
- `ACC0175.sql`
- `ACC0176.sql`
- `ACC0177.sql`
- `ACC0178.sql`
- `ACC0179.sql`
- `ACC0180.sql`
- `ACC0181.sql`
- `ACC0182.sql`
- `ACC0184.sql`
- `ACC0185.sql`
- `ACC0186.sql`
- `ACC0187.sql`
- `ACC0188.sql`
- `ACC0194.sql`
- `ACC0195.sql`
- `ACC0196.sql`
- `ACC0197.sql`
- `ACC0198.sql`
- `ACC0199.sql`
- `ACC0200.sql`
- `ACC0201.sql`
- `ACC0202.sql`
- `ACC0203.sql`
- `ACC0204.sql`
- `ACC0205.sql`
- `ACC0206.sql`
- `ACC0207.sql`
- `ACC0208.sql`
- `ACC0209.sql`
- `ACC0210.sql`
- `ACC0211.sql`
- `ACC0212.sql`
- `ACC0213.sql`
- `ACC0214.sql`
- `ACC0215.sql`
- `ACC0216.sql`
- `ACC0217.sql`
- `ACC0218.sql`
- `ACC0219.sql`
- `ACC0220.sql`
- `ACC0221.sql`
- `ACC0222.sql`
- `ACC0223.sql`
- `ACC0224.sql`
- `ACC0225.sql`
- `ACC0225_UPLOAD.sql`
- `ACC0226.sql`
- `ACC0227.sql`
- `ACC0228.sql`
- `ACC0229.sql`
- `ACC0230.sql`
- `ACC0231.sql`
- `ACC0232.sql`
- `ACC0233.sql`
- `ACC0234.sql`
- `ACC0235.sql`
- `ACC0236.sql`
- `ACC0237.sql`
- `ACC0238.sql`
- `ACC0239.sql`
- `ACC0240.sql`
- `ACC0241.sql`
- `ACC0242.sql`
- `ACC0243.sql`
- `ACC0244.sql`
- `ACC0245.sql`
- `ACC0245_CASUALS.sql`
- `ACC0246.sql`
- `ACC0246_CASUALS.sql`
- `ACC0247.sql`
- `ACC0248.sql`
- `ACC0249.sql`
- `ACC0250.sql`
- `ACC0251.sql`
- `ACC0252.sql`
- `ACC0253.sql`
- `ACC0254.sql`
- `ACC0255.sql`
- `ACC0256.sql`
- `ACC0258.sql`
- `ACC0259.sql`
- `ACC0260.sql`
- `ACC0261.sql`
- `ACC0262.sql`
- `ACC0263.sql`
- `ACC0264.sql`
- `ACC0265.sql`
- `ACC0266.sql`
- `ACC0267.sql`
- `ACC0268.sql`
- `ACC0269.sql`
- `ACC0270.sql`
- `ACC0271.sql`
- `ACC0272.sql`
- `ACC0273.sql`
- `ACC0274.sql`
- `ACC0275.sql`
- `ACC0276.sql`
- `ACC0277.sql`
- `ACC0278.sql`
- `ACC0279.sql`
- `ACC0280.sql`
- `ACC0281.sql`
- `ACC0282.sql`
- `ACC0283.sql`
- `ACC0284.sql`
- `ACC0285.sql`
- `ACC0286.sql`
- `ACC0287.sql`
- `ACC0288.sql`
- `ACC0289.sql`
- `ACC0290.sql`
- `ACC0291.sql`
- `ACC0292.sql`
- `ACC0293.sql`
- `ACC0394.sql`
- `ACC0395.sql`
- `ACC0396.sql`
- `ACC0397.sql`
- `ACC0398.sql`
- `ACC0399.sql`
- `ACC0400.sql`
- `ACC0401.sql`
- `ACC0450.sql`
- `ACC0451.sql`
- `ACC0452.sql`
- `ACC0453.sql`
- `ACC0454.sql`
- `ACC0455.sql`
- `ACC0456.sql`
- `ACC0457.sql`
- `ACC0458.sql`
- `ACCESS_GROUPS.sql`
- `ACGroup.sql`
- `ACTING_ADVICES.sql`
- `ACTimeZones.sql`
- `ACUnlockComb.sql`
- `ADDITIONS.sql`
- `ALLOWANCE.sql`
- `ALLOWANCESUPLOADS.sql`
- `ASSETS.sql`
- `ASSETS_REPAYMENTPLAN.sql`
- `ASSET_CATEGORIES.sql`
- `ASSET_STATUS.sql`
- `ASSTMANAGERS.sql`
- `AUTHDEVICE.sql`
- `AdvanceGroups.sql`
- `AlarmLog.sql`
- `AttLogs.sql`
- `AttParam.sql`
- `Attendance.sql`
- `AuditedExc.sql`
- `BANKBRANCHUPLOAD.sql`
- `BIODATA.sql`
- `BUDGET.sql`
- `CASUALMASTER.sql`
- `CASUALS.sql`
- `CASUALS_DATA.sql`
- `CASUALS_NSSFRATES.sql`
- `CASUALS_SHEETS.sql`
- `CASUAL_CATEGORIES.sql`
- `CHECKEXACT.sql`
- `CHECKINOUT.sql`
- `CIRCULARS.sql`
- `CLEARANCE.sql`
- `COMPANY_DOCUMENTS.sql`
- `COOPLOANS.sql`
- `CUSTOMDEDUCTIONPARAMS.sql`
- `Contracts.sql`
- `Contracts_Uploads.sql`
- `Customers.sql`
- `DDD.sql`
- `DEDUCTIONS.sql`
- `DEPARTMENTS.sql`
- `DIT.sql`
- `DUMMY.sql`
- `DeptUsedSchs.sql`
- `DumbTbl.sql`
- `EARNED_LEAVE.sql`
- `EARNING_SUMMARY.sql`
- `ECICalendarEvent_Test.sql`
- `EMPAPPRAISALS.sql`
- `EMPTARGETS.sql`
- `EMP_ASSETS.sql`
- `ESS0052.sql`
- `ESS_NOTIFICATIONS.sql`
- `EXCNOTES.sql`
- `EmOpLog.sql`
- `EmailPayslips.sql`
- `EmailUploads.sql`
- `EmpAppraisalPeriod.sql`
- `EmpPensionSchemes.sql`
- `EmployeeTypes.sql`
- `EmployeesHierarchy.sql`
- `ExceptionLog.sql`
- `ExceptionLog2.sql`
- `FaceTemp.sql`
- `HOD_Overtime.sql`
- `HODs.sql`
- `HOLIDAYS.sql`
- `HousingTax.sql`
- `INACTIVE_EMPLOYEES.sql`
- `INSURANCE.sql`
- `InterestMethods.sql`
- `KPAs.sql`
- `KPIs.sql`
- `LEAVEMASTER.sql`
- `LeaveClass.sql`
- `LeaveClass1.sql`
- `LeavePeriods.sql`
- `LoanRepayment.sql`
- `MEMO.sql`
- `MEMO_CATEGORY.sql`
- `Machines.sql`
- `NOKUpload.sql`
- `NOTIFICATIONS.sql`
- `NSSFRATES.sql`
- `NUM_RUN.sql`
- `NUM_RUN_DEIL.sql`
- `OTHERDEDUCTIONS.sql`
- `OVERTIME_HOD.sql`
- `OVERTIME_PAY.sql`
- `OVERTIME_PAY_CASUALS.sql`
- `OVERTIME_UPLOAD.sql`
- `Overtime.sql`
- `PAYADVICES.sql`
- `PAYMENTS.sql`
- `PAYROLL_MONTHS.sql`
- `PAYROLL_SUMMARY.sql`
- `PENSION.sql`
- `PENSIONS.sql`
- `PETTY_CASH.sql`
- `Projects.sql`
- `RECLAIMED_ASSETS.sql`
- `REINSTATEMENT.sql`
- `ReportItem.sql`
- `SACCO.sql`
- `SACCODATA.sql`
- `SALARIES.sql`
- `SALARY_REVIEW.sql`
- `SECURITYDETAILS.sql`
- `SHARES.sql`
- `SHIFT.sql`
- `STAFF_UNIFORMS.sql`
- `SYSTEM_EMAIL.sql`
- `SchClass.sql`
- `Section.sql`
- `ServerLog.sql`
- `ShiftDetails.sql`
- `StaffDetails.sql`
- `SystemLog.sql`
- `TARGETS.sql`
- `TARGET_REVIEWS.sql`
- `TBKEY.sql`
- `TBL0001.sql`
- `TBSMSALLOT.sql`
- `TBSMSINFO.sql`
- `TEKE_GROUPS.sql`
- `TEMPLATE.sql`
- `TEMPMASTER.sql`
- `TRANSFERS.sql`
- `Temp.sql`
- `Templates.sql`
- `UNIFORM_TYPES.sql`
- `UPLOAD_BASICPAY.sql`
- `USERINFO.sql`
- `USER_OF_RUN.sql`
- `USER_SPEDAY.sql`
- `USER_TEMP_SCH.sql`
- `UserACMachines.sql`
- `UserACPrivilege.sql`
- `UserUpdates.sql`
- `UserUsedSClasses.sql`
- `UsersMachines.sql`
- `WEEKS.sql`
- `WELFARE_CLAIMS.sql`
- `WELFARE_CLAIMTYPES.sql`
- `WELFARE_DEDUCTIONS.sql`
- `WORKDAYS.sql`
- `ZKAttendanceMonthStatistics.sql`
- `a.sql`
- `acholiday.sql`
- `aspnet_Applications.sql`
- `aspnet_SchemaVersions.sql`
- `aspnet_WebEvent_Events.sql`
- `b.sql`
- `ozekimessagein.sql`
- `ozekimessageout.sql`
- `tribe.sql`
- `ACC0137.sql`
- `ACC0154.sql`
- `ACC0155.sql`
- `ACC0157.sql`
- `ACC0160.sql`
- `ACC0162.sql`
- `ACC0166.sql`
- `ACC0168.sql`
- `ACC0169.sql`
- `ACC0170.sql`
- `ACC0173.sql`
- `ACC0183.sql`
- `ACC0189.sql`
- `ACC0190.sql`
- `ACC0191.sql`
- `ACC0192.sql`
- `ACC0193.sql`
- `aspnet_Paths.sql`
- `aspnet_PersonalizationAllUsers.sql`
- `aspnet_Roles.sql`
- `aspnet_Users.sql`
- `aspnet_UsersInRoles.sql`
- `ACC0068.sql`
- `ACC0135.sql`
- `ACC0136.sql`
- `aspnet_Membership.sql`
- `aspnet_PersonalizationPerUser.sql`
- `aspnet_Profile.sql`

