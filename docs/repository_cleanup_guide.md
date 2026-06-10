# Repository Cleanup Guide

Use this guide to make the GitHub repository look more professional and easier to review.

## 1. Create folders

```bash
mkdir -p sql notebooks data assets docs scripts
```

## 2. Move and rename files

```bash
mv "milestone1_business_growth.sql" "sql/milestone1_business_growth.sql"
mv "milestone1_cohort_retention.sql" "sql/milestone1_cohort_retention.sql"
mv "milestone2_funnel_overview.sql" "sql/milestone2_funnel_overview.sql"
mv "milestone2_funnel_by_traffic_source.sql" "sql/milestone2_funnel_by_traffic_source.sql"

mv "The_Look_E_Commerce_Forecasting_GMV.ipynb" "notebooks/milestone3_gmv_forecasting.ipynb"

mv "GMV GROWTH.csv" "data/growth_monthly.csv"
mv "COOHORT RETANTION.csv" "data/cohort_retention.csv"
mv "Funnel.csv" "data/funnel_overview.csv"
mv "Breakdown Funnel.csv" "data/funnel_by_traffic_source.csv"
mv "forecast_looker.csv" "data/forecast_looker.csv"

mv "Growth GMV.png" "assets/growth_gmv.png"
mv "GMV Growth Rate.png" "assets/gmv_growth_rate.png"
mv "AVG Order value vs Unique Buyers.png" "assets/aov_vs_unique_buyers.png"
mv "Cohort Retention.png" "assets/cohort_retention.png"
mv "Funnel Over View.png" "assets/funnel_overview.png"
mv "Funnel by source.png" "assets/funnel_by_source.png"
mv "Forecasting.png" "assets/forecasting.png"

mv "The_Look_E-Commerce (1).pdf" "docs/dashboard_export.pdf"
```

## 3. Replace README

Replace the old README with the improved `README.md` from this improvement pack.

## 4. Add supporting files

Copy these files into the repository:

```bash
cp requirements.txt .gitignore .
cp docs/*.md docs/
cp scripts/organize_repo.sh scripts/
```

## 5. Commit changes

```bash
git add .
git commit -m "refactor: improve ecommerce analytics portfolio repository"
git push origin main
```

## 6. Final checks

Before sharing the repository, check:

- README tables render properly.
- Image links work.
- SQL files are inside the `sql/` folder.
- CSV files are inside the `data/` folder.
- Notebook is inside the `notebooks/` folder.
- LinkedIn badge opens LinkedIn.
- Looker Studio badge opens the dashboard.
