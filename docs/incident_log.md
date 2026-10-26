# Incident Log

## INC-001: 2026-10-26 — Semantic Model Refresh Failure (Authentication)
- **Incident:** Semantic model `bank_mi_pack_cloud` failed scheduled refresh in Power BI Service.
- **Detection:** Refresh history status marked Failed with error banner in Power BI workspace.
- **Error Text:** `Failed to update data source credentials: Login failed for user 'sqladmin'.`
- **Root Cause:** Invalid or expired database password for Azure SQL user `sqladmin` connecting to `sql-ancy-da.database.windows.net;bankmi`.
- **Resolution:** Re-authenticated with valid credentials under Data source credentials in Service settings and initiated on-demand refresh.
- **Prevention in Production:** Replace personal/basic SQL user accounts with Microsoft Entra Service Principals or Managed Identities; set up automated refresh failure notifications to the data platform team.
