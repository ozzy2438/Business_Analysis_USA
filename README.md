# Business_Analysis_USA

## Dashboard Screenshots

### Business Readiness Overview Dashboard
<img width="2864" height="1630" alt="Business Readiness Overview Dashboard" src="https://github.com/user-attachments/assets/34270a55-2e22-453f-a517-df20d46d6340" />

### County Rankings and Opportunity Analysis
<img width="2878" height="1622" alt="County Rankings and Opportunity Analysis" src="https://github.com/user-attachments/assets/74d35722-a138-45ce-bc9c-8822d1fd89a4" />

### Industry Growth Distribution Analysis
<img width="2874" height="1618" alt="Industry Growth Distribution Analysis" src="https://github.com/user-attachments/assets/002594a2-ef67-469c-97ba-203b1359ec8a" />

Additional screenshots are available in the [screenshots folder](screenshots/)



# Business Readiness USA — County Expansion Analytics

**A practical, end‑to‑end framework to identify the best US counties for business expansion.**  
Data modeled in **SQL**, engineered & validated with **Python**, and delivered as an interactive **Power BI** dashboard.

---

## Table of Contents
- [Business\_Analysis\_USA](#business_analysis_usa)
  - [Dashboard Screenshots](#dashboard-screenshots)
    - [Business Readiness Overview Dashboard](#business-readiness-overview-dashboard)
    - [County Rankings and Opportunity Analysis](#county-rankings-and-opportunity-analysis)
    - [Industry Growth Distribution Analysis](#industry-growth-distribution-analysis)
- [Business Readiness USA — County Expansion Analytics](#business-readiness-usa--county-expansion-analytics)
  - [Table of Contents](#table-of-contents)
  - [Project Overview](#project-overview)
  - [Problem \& Objectives](#problem--objectives)
  - [What’s in this Repo](#whats-in-this-repo)
  - [Data Pipeline (SQL → Python → Power BI)](#data-pipeline-sql--python--power-bi)
  - [Key Metrics \& Business Logic](#key-metrics--business-logic)
  - [Results at a Glance](#results-at-a-glance)
  - [How to Run](#how-to-run)
  - [Dataset](#dataset)
  - [Lessons Learned](#lessons-learned)
  - [Screenshots](#screenshots)
    - [Business Readiness Overview Dashboard](#business-readiness-overview-dashboard-1)
    - [County Rankings and Opportunity Analysis](#county-rankings-and-opportunity-analysis-1)
    - [Industry Growth Distribution Analysis](#industry-growth-distribution-analysis-1)
  - [Contact](#contact)

---

## Project Overview
**Business Readiness USA** evaluates and ranks every US county using growth, diversity, and specialization signals to answer three questions:
1) *Where should we expand next?*  
2) *Which places are stable vs. high‑risk?*  
3) *Which industry mixes correlate with durable establishment & employment growth?*

Deliverables:
- Clean, analysis‑ready SQL tables (single source of truth)
- Reproducible Python notebook for feature engineering & validation
- A Power BI report for exploration, ranking, and storytelling

---

## Problem & Objectives
**Problem.** Expansion teams need a defensible way to compare counties across the US using consistent metrics—not anecdotes.

**Objectives.**
- Build a transparent, repeatable pipeline from raw CBP to an **Opportunity Score** and **Tiering (A–E)**.
- Detect **high‑risk** counties and **multi‑specialized** economies (≥3 specializations).
- Publish an interactive dashboard with executive KPIs, a national map, rankings, and drivers.

---

## What’s in this Repo
```
Business_Analysis_USA/
├─ sql/
│  ├─ 01_data_exploration.sql
│  ├─ 02_opportunity_scoring.sql
│  ├─ 03_kpi_calculations.sql
│  ├─ 04_ranking_matrices.sql
│  ├─ 05_industry_specialization.sql
│  └─ 06_growth_analysis.sql
├─ notebooks/
│  └─ Business_Readiness_USA.ipynb
├─ screenshots/
│  ├─ business_readiness_overview_dashboard.jpg
│  ├─ county_rankings_opportunity_analysis.jpg
│  └─ industry_growth_distribution_analysis.jpg
└─ README.md
```

---

## Data Pipeline (SQL → Python → Power BI)

**SQL (modeling & QA)**
- Normalize CBP 2020–2023, enforce **zero‑padded FIPS** keys.
- Compute establishment & employment growth, per‑capita density, and specialization features.
- Materialize clean fact tables: e.g., `county_business_readiness_2023`, `county_industry_mix_2023`, `county_opportunity_drivers`, `county_rankings_topline`.

**Python (feature engineering & validation)**
- Standardize inputs, mitigate outliers, and assemble the **Opportunity Score**.
- Validate correlations and stability across years; export `*.parquet` for BI.
- (Optional) Build a choropleth with county **GeoJSON** for QA.

**Power BI (delivery)**
- KPI cards + national map + rankings + drivers.
- Slicers for **STNAME**, **opportunity_tier**, **risk_category**, **total_specializations**.

---

## Key Metrics & Business Logic
- **Opportunity Score** — composite index of growth & structure signals.
- **Opportunity Percentile / Tier (A–E)** — rank & banding for prioritization.
- **High‑Risk** — rule/score‑based flag combining weak growth + low diversity.
- **Multi‑Specialized (≥3)** — counties with broader competitive strengths.
- **Market Potential** — index capturing size/structure pull for expansion.
- **Expansion Ready** — top decile (P90+) on readiness composite.

> Map note: Use **FIPS** as 5‑character *Text* (`FORMAT([FIPS], "00000")`) or join to GeoJSON on `GEOID`.

---

## Results at a Glance
Snapshot from the latest run (may vary with refresh):
- **Total counties:** **3,181**
- **Top opportunity score:** **1,214**
- **Average establishment growth:** **4.87%**
- **High‑risk counties:** **264**
- **Tier‑A counties:** **779**
- **Multi‑specialized (≥3):** **1,494**
- **Market potential leader (index):** **33,374**
- **Expansion‑ready (P90+):** **312**

---

## How to Run
1. Clone the repo.
2. (Optional) Build features with the notebook in `/notebooks` and export to `parquet/csv`.
3. Load the processed data to your SQL warehouse **or** import directly into Power BI.
4. In Power BI, ensure **FIPS is Text** (5 chars). If needed:  
   `FIPS_str = FORMAT('county_business_readiness_2023'[FIPS], "00000")`
5. Use `FIPS_str` for map Location; color by `opportunity_score`; add slicers for `STNAME`, `opportunity_tier`, `risk_category`, `total_specializations`.

---

## Dataset
Full datasets (2020–2023):  
👉 [Download from Google Drive](https://drive.google.com/drive/folders/1dgOh9Ek3PHLVu7hQ_Kt7hpJ7LANWfHvU?usp=drive_link)

---

## Lessons Learned
- **Geography keys matter.** Mapping issues (“undefined”) disappear when FIPS is padded to 5‑char **Text** and joined consistently to GeoJSON `GEOID`.
- **Scale vs. limits.** SQL Server parameter limits were avoided by writing in **small chunks** from Python during bulk operations.
- **Explainable scoring.** Keeping intermediate drivers (growth %, per‑1k, diversity, LQ caps) makes the score auditable and easy to defend.
- **Design for decisions.** KPI cards + tiering + slicers let stakeholders jump from national to county‑level actions in seconds.

---

## Screenshots

### Business Readiness Overview Dashboard
![Business Readiness Overview Dashboard](screenshots/business_readiness_overview_dashboard.jpg)  
<sub>Executive KPIs with national map; quick scan of opportunity, risk, and readiness.</sub>

### County Rankings and Opportunity Analysis
![County Rankings and Opportunity Analysis](screenshots/county_rankings_opportunity_analysis.jpg)  
<sub>Sortable rankings with tier badges, growth labels, and tooltips.</sub>

### Industry Growth Distribution Analysis
![Industry Growth Distribution Analysis](screenshots/industry_growth_distribution_analysis.jpg)  
<sub>Drivers view: opportunity vs. growth scatter, specialization counts, and top‑15 bars.</sub>

---

## Contact
**Osman Orka** — Data Analytics / BI / Data Science  
GitHub: `ozzy2438` · Email: *(add your preferred address)*