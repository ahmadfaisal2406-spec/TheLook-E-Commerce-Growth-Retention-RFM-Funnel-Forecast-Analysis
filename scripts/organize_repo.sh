#!/bin/bash

# ============================================================
# Organize TheLook E-Commerce Analytics Repository
# Run this script from the repository root.
# ============================================================

set -e

mkdir -p sql notebooks data assets docs scripts

mv "milestone1_business_growth.sql" "sql/milestone1_business_growth.sql" 2>/dev/null || true
mv "milestone1_cohort_retention.sql" "sql/milestone1_cohort_retention.sql" 2>/dev/null || true
mv "milestone2_funnel_overview.sql" "sql/milestone2_funnel_overview.sql" 2>/dev/null || true
mv "milestone2_funnel_by_traffic_source.sql" "sql/milestone2_funnel_by_traffic_source.sql" 2>/dev/null || true

mv "The_Look_E_Commerce_Forecasting_GMV.ipynb" "notebooks/milestone3_gmv_forecasting.ipynb" 2>/dev/null || true

mv "GMV GROWTH.csv" "data/growth_monthly.csv" 2>/dev/null || true
mv "COOHORT RETANTION.csv" "data/cohort_retention.csv" 2>/dev/null || true
mv "Funnel.csv" "data/funnel_overview.csv" 2>/dev/null || true
mv "Breakdown Funnel.csv" "data/funnel_by_traffic_source.csv" 2>/dev/null || true
mv "forecast_looker.csv" "data/forecast_looker.csv" 2>/dev/null || true

mv "Growth GMV.png" "assets/growth_gmv.png" 2>/dev/null || true
mv "GMV Growth Rate.png" "assets/gmv_growth_rate.png" 2>/dev/null || true
mv "AVG Order value vs Unique Buyers.png" "assets/aov_vs_unique_buyers.png" 2>/dev/null || true
mv "Cohort Retention.png" "assets/cohort_retention.png" 2>/dev/null || true
mv "Funnel Over View.png" "assets/funnel_overview.png" 2>/dev/null || true
mv "Funnel by source.png" "assets/funnel_by_source.png" 2>/dev/null || true
mv "Forecasting.png" "assets/forecasting.png" 2>/dev/null || true

mv "The_Look_E-Commerce (1).pdf" "docs/dashboard_export.pdf" 2>/dev/null || true

echo "Repository structure has been organized."
