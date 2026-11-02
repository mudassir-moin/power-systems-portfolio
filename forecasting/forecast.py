"""
Short-term electricity demand forecasting (PJM hourly data).

Task: predict the NEXT hour's demand (MW) from the previous 24 hours.
Model: linear regression implemented in PyTorch.
Baseline: "same hour yesterday" (the naive forecast we must beat).
Metric: MAPE (Mean Absolute Percentage Error).

Data: download PJME_hourly.csv from Kaggle ("Hourly Energy Consumption", PJM)
and put it next to this file. Columns: Datetime, PJME_MW.
"""
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

CSV = "PJME_hourly.csv"
LAGS = 24          # use the previous 24 hours as input
TRAIN_FRAC = 0.8   # first 80% of time = train, last 20% = test
EPOCHS = 300
LR = 0.01
SEED = 42


def load_series(path):
    """Read the CSV into a clean, evenly spaced hourly series of MW values."""
    df = pd.read_csv(path, parse_dates=["Datetime"]).set_index("Datetime").sort_index()
    df = df[~df.index.duplicated(keep="first")]      # daylight-saving gives duplicate timestamps
    s = df.iloc[:, 0].astype(float)
    s = s.asfreq("h")                                # insert any missing hours as NaN
    print(f"Missing hours filled by interpolation: {s.isna().sum()}")
    return s.interpolate(method="time")


def make_windows(values, lags):
    """Row i: X = values[i : i+lags], y = values[i+lags] (the next hour)."""
    n = len(values) - lags
    X = np.stack([values[i:i + lags] for i in range(n)])
    y = values[lags:]
    return X, y


def mape(actual, predicted):
    return float(np.mean(np.abs((actual - predicted) / actual)) * 100)


def main():
    torch.manual_seed(SEED)
    series = load_series(CSV)
    print(f"Hourly records: {len(series)}")

    X, y = make_windows(series.values, LAGS)
    split = int(len(X) * TRAIN_FRAC)                 # chronological split: never shuffle time series
    X_train, X_test, y_train, y_test = X[:split], X[split:], y[:split], y[split:]

    # Normalise using TRAIN statistics only (using the test set would leak future information)
    mean, std = X_train.mean(), X_train.std()
    norm = lambda a: torch.tensor((a - mean) / std, dtype=torch.float32)
    Xtr, Xte = norm(X_train), norm(X_test)
    ytr = norm(y_train).unsqueeze(1)

    # Linear regression = one Linear layer: y_hat = w1*x1 + ... + w24*x24 + b
    model = nn.Linear(LAGS, 1)
    loss_fn = nn.MSELoss()
    opt = torch.optim.Adam(model.parameters(), lr=LR)

    for epoch in range(EPOCHS):
        opt.zero_grad()
        loss = loss_fn(model(Xtr), ytr)
        loss.backward()
        opt.step()
        if (epoch + 1) % 50 == 0:
            print(f"epoch {epoch + 1:4d}  train MSE (normalised): {loss.item():.5f}")

    with torch.no_grad():
        pred = model(Xte).squeeze(1).numpy() * std + mean   # back to MW

    baseline = X_test[:, 0]                          # demand 24 h before the target hour
    persistence = X_test[:, -1]                      # demand 1 h before the target hour

    print("\nTest-set MAPE")
    print(f"  Same hour yesterday : {mape(y_test, baseline):.2f}%")
    print(f"  Previous hour       : {mape(y_test, persistence):.2f}%")
    print(f"  Linear regression   : {mape(y_test, pred):.2f}%")

    # Plot the last 7 days of the test set
    h = 24 * 7
    plt.figure(figsize=(11, 4))
    plt.plot(y_test[-h:], label="Actual")
    plt.plot(pred[-h:], label="Linear regression")
    plt.plot(baseline[-h:], "--", alpha=0.6, label="Same hour yesterday")
    plt.xlabel("Hour"); plt.ylabel("Demand (MW)"); plt.legend()
    plt.title("Next-hour demand forecast, last 7 days of test set")
    plt.tight_layout(); plt.savefig("results.png", dpi=150)


if __name__ == "__main__":
    main()
