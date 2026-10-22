# Power BI Storage Modes Comparison (Day 15 — D15-L)

| Mode | Where Data Lives | Query Speed | Data Freshness | Key Trade-off / Limitation |
|---|---|---|---|---|
| **Import** | In-memory inside Power BI model (compressed VertiPaq) | Fastest (in-memory columnar engine) | Requires scheduled refresh to pull updates | Model size limits (1 GB on Pro, capacity limits) |
| **DirectQuery** | Stays in the source database (e.g. Azure SQL, PostgreSQL) | Slower (queries source database on every click) | Real-time / live connection | Higher source DB workload, some DAX limitations |
| **Direct Lake (Fabric)** | Delta-Parquet tables in OneLake | Fast (VertiPaq reads Delta files directly into memory) | Up-to-date without running scheduled ETL imports | Requires Microsoft Fabric capacity; falls back to DirectQuery on complex views |

