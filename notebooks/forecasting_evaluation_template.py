"""
Forecasting Evaluation Template
Use this in Google Colab after exporting monthly GMV from BigQuery.

Expected input CSV:
- data/growth_monthly.csv
- must contain date column and GMV column

Recommended columns:
- ds: month/date
- y: monthly GMV proxy

This template evaluates Prophet against a naive baseline using MAE, RMSE, and MAPE.
"""

import pandas as pd
import numpy as np
from prophet import Prophet
from sklearn.metrics import mean_absolute_error, mean_squared_error


def mean_absolute_percentage_error(y_true, y_pred):
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    mask = y_true != 0
    return np.mean(np.abs((y_true[mask] - y_pred[mask]) / y_true[mask])) * 100


# 1. Load data
df = pd.read_csv("data/growth_monthly.csv")

# Adjust these names if your CSV uses different columns.
if "ds" not in df.columns:
    date_col = "order_month"
    df = df.rename(columns={date_col: "ds"})

if "y" not in df.columns:
    gmv_col = "total_gmv"
    df = df.rename(columns={gmv_col: "y"})

df["ds"] = pd.to_datetime(df["ds"])
df = df[["ds", "y"]].sort_values("ds").dropna()

# 2. Train-test split
# Use the last 6 months as holdout test data.
train = df.iloc[:-6].copy()
test = df.iloc[-6:].copy()

# 3. Prophet model
model = Prophet(
    yearly_seasonality=True,
    weekly_seasonality=False,
    daily_seasonality=False,
    changepoint_prior_scale=0.05,
    interval_width=0.95,
)

model.fit(train)

future = model.make_future_dataframe(periods=6, freq="MS")
forecast = model.predict(future)

pred = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].merge(
    test,
    on="ds",
    how="inner"
)

# 4. Naive baseline
# Baseline: predict this month using previous month's actual GMV.
baseline = df[["ds", "y"]].copy()
baseline["naive_yhat"] = baseline["y"].shift(1)
baseline_test = test.merge(baseline[["ds", "naive_yhat"]], on="ds", how="left")

# 5. Evaluation
prophet_mae = mean_absolute_error(pred["y"], pred["yhat"])
prophet_rmse = np.sqrt(mean_squared_error(pred["y"], pred["yhat"]))
prophet_mape = mean_absolute_percentage_error(pred["y"], pred["yhat"])

naive_mae = mean_absolute_error(baseline_test["y"], baseline_test["naive_yhat"])
naive_rmse = np.sqrt(mean_squared_error(baseline_test["y"], baseline_test["naive_yhat"]))
naive_mape = mean_absolute_percentage_error(baseline_test["y"], baseline_test["naive_yhat"])

evaluation = pd.DataFrame({
    "model": ["Prophet", "Naive Previous Month"],
    "MAE": [prophet_mae, naive_mae],
    "RMSE": [prophet_rmse, naive_rmse],
    "MAPE": [prophet_mape, naive_mape],
})

print(evaluation)

# 6. Forecast next 6 months after full-data training
final_model = Prophet(
    yearly_seasonality=True,
    weekly_seasonality=False,
    daily_seasonality=False,
    changepoint_prior_scale=0.05,
    interval_width=0.95,
)

final_model.fit(df)

future_final = final_model.make_future_dataframe(periods=6, freq="MS")
forecast_final = final_model.predict(future_final)

forecast_output = forecast_final[["ds", "yhat", "yhat_lower", "yhat_upper"]].tail(6)
forecast_output.to_csv("data/forecast_looker.csv", index=False)

print(forecast_output)
