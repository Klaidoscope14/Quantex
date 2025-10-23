# Data Directory

This directory contains historical market data for backtesting trading strategies.

## Data Format

The backtester expects CSV files with the following format (Yahoo Finance standard):

```
Date,Open,High,Low,Close,Adj Close,Volume
2023-01-01,150.00,155.00,149.50,154.20,154.20,1000000
2023-01-02,154.20,156.80,153.10,155.50,155.50,1200000
...
```

### Required Columns:
- **Date**: Date in YYYY-MM-DD format
- **Open**: Opening price
- **High**: Highest price of the day
- **Low**: Lowest price of the day
- **Close**: Closing price
- **Adj Close**: Adjusted closing price (for dividends/splits)
- **Volume**: Trading volume

## File Naming Convention

Data files should be named as `{SYMBOL}.csv` where SYMBOL is the stock ticker (e.g., `AAPL.csv`, `MSFT.csv`).

## Data Sources

Use the provided tools to download data:

### Python Tools:
- `tools/downloader/python/fetch_yahoo.py` - Download from Yahoo Finance
- `tools/downloader/python/fetch_alpha_vantage.py` - Download from Alpha Vantage API

### C++ Tool:
- `tools/downloader/cpp/fetcher.cpp` - C++ data fetcher utility

## Usage Examples

```bash
# Download AAPL data using Python Yahoo fetcher
python tools/downloader/python/fetch_yahoo.py AAPL

# Download MSFT data using Alpha Vantage (requires API key)
python tools/downloader/python/fetch_alpha_vantage.py MSFT YOUR_API_KEY

# Run backtest with downloaded data
./bt_run AAPL
```

## Data Quality Requirements

- Data should be in chronological order (oldest to newest)
- No missing values in critical columns (Date, Close)
- Volume should be non-negative
- Prices should be positive

## Notes

- The backtester automatically reverses data to ensure chronological processing
- Missing volume data is handled gracefully (defaults to 0)
- Data files are expected to be in the `data/` directory relative to the executable
