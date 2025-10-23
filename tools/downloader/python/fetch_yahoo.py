#!/usr/bin/env python3
"""
Yahoo Finance Data Fetcher for C++ Backtester

Downloads historical stock data from Yahoo Finance and saves it in CSV format
compatible with the C++ backtester.

Usage:
    python fetch_yahoo.py SYMBOL [START_DATE] [END_DATE] [OUTPUT_DIR]
    
Examples:
    python fetch_yahoo.py AAPL
    python fetch_yahoo.py MSFT 2020-01-01 2023-12-31
    python fetch_yahoo.py GOOGL 2022-01-01 2023-12-31 data/
"""

import sys
import os
import pandas as pd
import yfinance as yf
from datetime import datetime, timedelta
import argparse


def fetch_yahoo_data(symbol, start_date=None, end_date=None, output_dir="data"):
    """
    Fetch historical data from Yahoo Finance for a given symbol.
    
    Args:
        symbol (str): Stock symbol (e.g., 'AAPL', 'MSFT')
        start_date (str): Start date in YYYY-MM-DD format (optional)
        end_date (str): End date in YYYY-MM-DD format (optional)
        output_dir (str): Directory to save CSV file (default: 'data')
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        print(f"Fetching data for {symbol} from Yahoo Finance...")
        
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        # Create yfinance ticker object
        ticker = yf.Ticker(symbol)
        
        # Set default date range if not provided
        if not start_date:
            start_date = (datetime.now() - timedelta(days=365*5)).strftime('%Y-%m-%d')
        if not end_date:
            end_date = datetime.now().strftime('%Y-%m-%d')
        
        print(f"Date range: {start_date} to {end_date}")
        
        # Fetch historical data
        hist = ticker.history(start=start_date, end=end_date)
        
        if hist.empty:
            print(f"Error: No data found for symbol {symbol}")
            return False
        
        # Ensure we have the required columns
        required_columns = ['Open', 'High', 'Low', 'Close', 'Adj Close', 'Volume']
        missing_columns = [col for col in required_columns if col not in hist.columns]
        
        if missing_columns:
            print(f"Warning: Missing columns {missing_columns}")
            # Fill missing columns with Close price
            for col in missing_columns:
                if col == 'Volume':
                    hist[col] = 0
                elif col == 'Adj Close':
                    hist[col] = hist['Close']  # Use Close as Adj Close if missing
                else:
                    hist[col] = hist['Close']
        
        # Reset index to make Date a column
        hist.reset_index(inplace=True)
        
        # Ensure we have exactly the columns we need
        if 'Adj Close' not in hist.columns:
            hist['Adj Close'] = hist['Close']
        
        # Select only the columns we need in the right order
        hist = hist[['Date', 'Open', 'High', 'Low', 'Close', 'Adj Close', 'Volume']]
        
        # Convert Date to string format
        hist['Date'] = hist['Date'].dt.strftime('%Y-%m-%d')
        
        # Sort by date (oldest first)
        hist = hist.sort_values('Date')
        
        # Save to CSV
        output_file = os.path.join(output_dir, f"{symbol}.csv")
        hist.to_csv(output_file, index=False)
        
        print(f"Successfully saved {len(hist)} records to {output_file}")
        print(f"Date range: {hist['Date'].min()} to {hist['Date'].max()}")
        
        return True
        
    except Exception as e:
        print(f"Error fetching data for {symbol}: {str(e)}")
        return False


def main():
    """Main function to handle command line arguments and fetch data."""
    parser = argparse.ArgumentParser(
        description="Fetch historical stock data from Yahoo Finance",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python fetch_yahoo.py AAPL
  python fetch_yahoo.py MSFT 2020-01-01 2023-12-31
  python fetch_yahoo.py GOOGL 2022-01-01 2023-12-31 data/
        """
    )
    
    parser.add_argument('symbol', help='Stock symbol (e.g., AAPL, MSFT)')
    parser.add_argument('start_date', nargs='?', help='Start date (YYYY-MM-DD)')
    parser.add_argument('end_date', nargs='?', help='End date (YYYY-MM-DD)')
    parser.add_argument('output_dir', nargs='?', default='data', 
                       help='Output directory (default: data)')
    
    args = parser.parse_args()
    
    # Validate symbol
    if not args.symbol or len(args.symbol) < 1:
        print("Error: Symbol is required")
        sys.exit(1)
    
    # Validate dates if provided
    if args.start_date:
        try:
            datetime.strptime(args.start_date, '%Y-%m-%d')
        except ValueError:
            print("Error: Start date must be in YYYY-MM-DD format")
            sys.exit(1)
    
    if args.end_date:
        try:
            datetime.strptime(args.end_date, '%Y-%m-%d')
        except ValueError:
            print("Error: End date must be in YYYY-MM-DD format")
            sys.exit(1)
    
    # Fetch data
    success = fetch_yahoo_data(args.symbol, args.start_date, args.end_date, args.output_dir)
    
    if success:
        print(f"Data fetch completed successfully for {args.symbol}")
        sys.exit(0)
    else:
        print(f"Failed to fetch data for {args.symbol}")
        sys.exit(1)


if __name__ == "__main__":
    main()
