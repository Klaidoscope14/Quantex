#!/usr/bin/env python3
"""
Alpha Vantage Data Fetcher for C++ Backtester

Downloads historical stock data from Alpha Vantage API and saves it in CSV format
compatible with the C++ backtester.

Usage:
    python fetch_alpha_vantage.py SYMBOL API_KEY [OUTPUT_DIR]
    
Examples:
    python fetch_alpha_vantage.py AAPL YOUR_API_KEY
    python fetch_alpha_vantage.py MSFT YOUR_API_KEY data/
    
Note: Get your free API key from https://www.alphavantage.co/support/#api-key
"""

import sys
import os
import pandas as pd
import requests
import time
from datetime import datetime
import argparse


def fetch_alpha_vantage_data(symbol, api_key, output_dir="data"):
    """
    Fetch historical data from Alpha Vantage API for a given symbol.
    
    Args:
        symbol (str): Stock symbol (e.g., 'AAPL', 'MSFT')
        api_key (str): Alpha Vantage API key
        output_dir (str): Directory to save CSV file (default: 'data')
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        print(f"Fetching data for {symbol} from Alpha Vantage...")
        
        # Create output directory if it doesn't exist
        os.makedirs(output_dir, exist_ok=True)
        
        # Alpha Vantage API endpoint
        url = "https://www.alphavantage.co/query"
        
        # API parameters
        params = {
            'function': 'TIME_SERIES_DAILY_ADJUSTED',
            'symbol': symbol,
            'apikey': api_key,
            'outputsize': 'full',  # Get full historical data
            'datatype': 'json'
        }
        
        print("Making API request...")
        response = requests.get(url, params=params)
        
        if response.status_code != 200:
            print(f"Error: HTTP {response.status_code} - {response.text}")
            return False
        
        data = response.json()
        
        # Check for API errors
        if 'Error Message' in data:
            print(f"API Error: {data['Error Message']}")
            return False
        
        if 'Note' in data:
            print(f"API Note: {data['Note']}")
            return False
        
        if 'Information' in data:
            print(f"API Information: {data['Information']}")
            return False
        
        # Extract time series data
        if 'Time Series (Daily)' not in data:
            print("Error: No time series data found in API response")
            return False
        
        time_series = data['Time Series (Daily)']
        
        if not time_series:
            print(f"Error: No data found for symbol {symbol}")
            return False
        
        # Convert to DataFrame
        df_data = []
        for date, values in time_series.items():
            df_data.append({
                'Date': date,
                'Open': float(values['1. open']),
                'High': float(values['2. high']),
                'Low': float(values['3. low']),
                'Close': float(values['4. close']),
                'Adj Close': float(values['5. adjusted close']),
                'Volume': int(values['6. volume'])
            })
        
        # Create DataFrame
        df = pd.DataFrame(df_data)
        
        # Sort by date (oldest first)
        df = df.sort_values('Date')
        
        # Save to CSV
        output_file = os.path.join(output_dir, f"{symbol}.csv")
        df.to_csv(output_file, index=False)
        
        print(f"Successfully saved {len(df)} records to {output_file}")
        print(f"Date range: {df['Date'].min()} to {df['Date'].max()}")
        
        # Rate limiting - Alpha Vantage has 5 calls per minute limit for free tier
        print("Waiting 12 seconds to respect API rate limits...")
        time.sleep(12)
        
        return True
        
    except Exception as e:
        print(f"Error fetching data for {symbol}: {str(e)}")
        return False


def main():
    """Main function to handle command line arguments and fetch data."""
    parser = argparse.ArgumentParser(
        description="Fetch historical stock data from Alpha Vantage API",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python fetch_alpha_vantage.py AAPL YOUR_API_KEY
  python fetch_alpha_vantage.py MSFT YOUR_API_KEY data/
  
Note: Get your free API key from https://www.alphavantage.co/support/#api-key
        """
    )
    
    parser.add_argument('symbol', help='Stock symbol (e.g., AAPL, MSFT)')
    parser.add_argument('api_key', help='Alpha Vantage API key')
    parser.add_argument('output_dir', nargs='?', default='data', 
                       help='Output directory (default: data)')
    
    args = parser.parse_args()
    
    # Validate symbol
    if not args.symbol or len(args.symbol) < 1:
        print("Error: Symbol is required")
        sys.exit(1)
    
    # Validate API key
    if not args.api_key or len(args.api_key) < 1:
        print("Error: API key is required")
        print("Get your free API key from https://www.alphavantage.co/support/#api-key")
        sys.exit(1)
    
    # Fetch data
    success = fetch_alpha_vantage_data(args.symbol, args.api_key, args.output_dir)
    
    if success:
        print(f"Data fetch completed successfully for {args.symbol}")
        sys.exit(0)
    else:
        print(f"Failed to fetch data for {args.symbol}")
        sys.exit(1)


if __name__ == "__main__":
    main()
