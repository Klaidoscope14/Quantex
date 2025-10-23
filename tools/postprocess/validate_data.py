#!/usr/bin/env python3
"""
Data Validation Tool for C++ Backtester

Validates CSV data files for proper format and data quality.
Checks for missing values, date consistency, and price validity.

Usage:
    python validate_data.py [DATA_FILE] [OPTIONS]
    
Examples:
    python validate_data.py data/AAPL.csv
    python validate_data.py data/AAPL.csv --verbose
    python validate_data.py data/AAPL.csv --fix-issues
"""

import sys
import pandas as pd
import argparse
from datetime import datetime
import os


def validate_csv_data(file_path, verbose=False, fix_issues=False):
    """
    Validate CSV data file for backtester compatibility.
    
    Args:
        file_path (str): Path to CSV file
        verbose (bool): Verbose output
        fix_issues (bool): Attempt to fix common issues
    
    Returns:
        bool: True if valid, False otherwise
    """
    try:
        if verbose:
            print(f"Validating data file: {file_path}")
        
        # Check if file exists
        if not os.path.exists(file_path):
            print(f"Error: File not found: {file_path}")
            return False
        
        # Read CSV file
        try:
            df = pd.read_csv(file_path)
        except Exception as e:
            print(f"Error reading CSV file: {e}")
            return False
        
        if verbose:
            print(f"Loaded {len(df)} records")
        
        # Check required columns
        required_columns = ['Date', 'Open', 'High', 'Low', 'Close', 'Adj Close', 'Volume']
        missing_columns = [col for col in required_columns if col not in df.columns]
        
        if missing_columns:
            print(f"Error: Missing required columns: {missing_columns}")
            return False
        
        if verbose:
            print("✓ All required columns present")
        
        # Check for empty data
        if len(df) == 0:
            print("Error: No data rows found")
            return False
        
        # Validate date format
        try:
            df['Date'] = pd.to_datetime(df['Date'])
        except Exception as e:
            print(f"Error: Invalid date format: {e}")
            return False
        
        if verbose:
            print("✓ Date format is valid")
        
        # Check for missing values in critical columns
        critical_columns = ['Open', 'High', 'Low', 'Close']
        for col in critical_columns:
            if df[col].isna().any():
                print(f"Warning: Missing values found in {col}")
                if fix_issues:
                    # Forward fill missing values
                    df[col] = df[col].fillna(method='ffill')
                    print(f"  Fixed missing values in {col}")
        
        # Validate price data
        for col in critical_columns:
            if (df[col] <= 0).any():
                print(f"Error: Non-positive prices found in {col}")
                return False
        
        if verbose:
            print("✓ All prices are positive")
        
        # Check OHLC consistency
        invalid_ohlc = (df['High'] < df['Low']) | (df['High'] < df['Open']) | (df['High'] < df['Close']) | \
                      (df['Low'] > df['Open']) | (df['Low'] > df['Close'])
        
        if invalid_ohlc.any():
            print(f"Warning: {invalid_ohlc.sum()} records have invalid OHLC data")
            if fix_issues:
                # Fix invalid OHLC data
                for idx in df[invalid_ohlc].index:
                    row = df.loc[idx]
                    high = max(row['Open'], row['Close'])
                    low = min(row['Open'], row['Close'])
                    df.loc[idx, 'High'] = max(high, row['High'])
                    df.loc[idx, 'Low'] = min(low, row['Low'])
                print("  Fixed invalid OHLC data")
        
        # Check volume data
        if (df['Volume'] < 0).any():
            print("Warning: Negative volume values found")
            if fix_issues:
                df['Volume'] = df['Volume'].abs()
                print("  Fixed negative volume values")
        
        # Check date ordering
        if not df['Date'].is_monotonic_increasing:
            print("Warning: Dates are not in chronological order")
            if fix_issues:
                df = df.sort_values('Date')
                print("  Sorted data by date")
        
        # Check for duplicate dates
        if df['Date'].duplicated().any():
            print("Warning: Duplicate dates found")
            if fix_issues:
                df = df.drop_duplicates(subset=['Date'], keep='last')
                print("  Removed duplicate dates")
        
        # Save fixed data if requested
        if fix_issues:
            backup_path = file_path + '.backup'
            if not os.path.exists(backup_path):
                df.to_csv(backup_path, index=False)
                print(f"Created backup: {backup_path}")
            
            df.to_csv(file_path, index=False)
            print(f"Saved fixed data to: {file_path}")
        
        # Summary statistics
        if verbose:
            print("\nData Summary:")
            print(f"  Date range: {df['Date'].min()} to {df['Date'].max()}")
            print(f"  Total records: {len(df)}")
            print(f"  Price range: ${df['Close'].min():.2f} - ${df['Close'].max():.2f}")
            print(f"  Average volume: {df['Volume'].mean():,.0f}")
        
        print("✓ Data validation completed successfully")
        return True
        
    except Exception as e:
        print(f"Error during validation: {e}")
        return False


def main():
    """Main function to handle command line arguments and validate data."""
    parser = argparse.ArgumentParser(
        description="Validate CSV data files for C++ Backtester",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python validate_data.py data/AAPL.csv
  python validate_data.py data/AAPL.csv --verbose
  python validate_data.py data/AAPL.csv --fix-issues
        """
    )
    
    parser.add_argument('file', help='CSV file to validate')
    parser.add_argument('--verbose', '-v', action='store_true', 
                       help='Verbose output')
    parser.add_argument('--fix-issues', '-f', action='store_true',
                       help='Attempt to fix common issues')
    
    args = parser.parse_args()
    
    # Validate data
    success = validate_csv_data(args.file, args.verbose, args.fix_issues)
    
    if success:
        print(f"Data validation passed for {args.file}")
        sys.exit(0)
    else:
        print(f"Data validation failed for {args.file}")
        sys.exit(1)


if __name__ == "__main__":
    main()
