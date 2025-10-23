#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import sys
import os

def generate_plots(trade_log_file, equity_curve_file, output_dir):
    """Generate plots from backtest results."""
    
    # Set style
    plt.style.use('default')
    
    # Read data
    try:
        trades = pd.read_csv(trade_log_file)
        equity = pd.read_csv(equity_curve_file)
    except Exception as e:
        print(f"Error reading data: {e}")
        return False
    
    # Convert date columns
    if 'entry_date' in trades.columns:
        trades['entry_date'] = pd.to_datetime(trades['entry_date'])
    if 'exit_date' in trades.columns:
        trades['exit_date'] = pd.to_datetime(trades['exit_date'])
    if 'date' in equity.columns:
        equity['date'] = pd.to_datetime(equity['date'])
    
    # Create plots
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle('Backtest Results', fontsize=16)
    
    # 1. Equity curve
    if 'date' in equity.columns and 'equity' in equity.columns:
        axes[0, 0].plot(equity['date'], equity['equity'], linewidth=2)
        axes[0, 0].set_title('Portfolio Equity Curve')
        axes[0, 0].set_xlabel('Date')
        axes[0, 0].set_ylabel('Equity')
        axes[0, 0].grid(True, alpha=0.3)
        axes[0, 0].tick_params(axis='x', rotation=45)
    
    # 2. Trade P&L distribution
    if 'pnl' in trades.columns:
        axes[0, 1].hist(trades['pnl'], bins=20, alpha=0.7, edgecolor='black')
        axes[0, 1].set_title('Trade P&L Distribution')
        axes[0, 1].set_xlabel('P&L')
        axes[0, 1].set_ylabel('Frequency')
        axes[0, 1].grid(True, alpha=0.3)
        axes[0, 1].axvline(x=0, color='red', linestyle='--', alpha=0.7)
    
    # 3. Cumulative P&L
    if 'pnl' in trades.columns:
        cumulative_pnl = trades['pnl'].cumsum()
        axes[1, 0].plot(cumulative_pnl, linewidth=2)
        axes[1, 0].set_title('Cumulative P&L')
        axes[1, 0].set_xlabel('Trade Number')
        axes[1, 0].set_ylabel('Cumulative P&L')
        axes[1, 0].grid(True, alpha=0.3)
        axes[1, 0].axhline(y=0, color='red', linestyle='--', alpha=0.7)
    
    # 4. Trade frequency over time
    if 'entry_date' in trades.columns:
        trades['month'] = trades['entry_date'].dt.to_period('M')
        trade_counts = trades.groupby('month').size()
        axes[1, 1].bar(range(len(trade_counts)), trade_counts.values)
        axes[1, 1].set_title('Trade Frequency by Month')
        axes[1, 1].set_xlabel('Month')
        axes[1, 1].set_ylabel('Number of Trades')
        axes[1, 1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Save plot
    plot_file = os.path.join(output_dir, 'backtest_plots.png')
    plt.savefig(plot_file, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"Plots saved to: {plot_file}")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python generate_plots.py <trade_log> <equity_curve> <output_dir>")
        sys.exit(1)
    
    trade_log_file = sys.argv[1]
    equity_curve_file = sys.argv[2]
    output_dir = sys.argv[3]
    
    success = generate_plots(trade_log_file, equity_curve_file, output_dir)
    sys.exit(0 if success else 1)
