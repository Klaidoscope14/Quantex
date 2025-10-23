#!/bin/bash

# C++ Backtester Report Generation Script
#
# This script generates comprehensive reports from backtest results.
# It creates visualizations, performance metrics, and summary reports.
#
# Usage: ./generate_reports.sh [OPTIONS]
#
# Examples:
#   ./generate_reports.sh
#   ./generate_reports.sh --input-dir results/
#   ./generate_reports.sh --output-dir reports/ --format html

set -e  # Exit on any error

# Default values
INPUT_DIR="."
OUTPUT_DIR="reports"
FORMAT="csv"
SYMBOL=""
VERBOSE=false
GENERATE_PLOTS=true
GENERATE_SUMMARY=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --input-dir DIR      Input directory with backtest results (default: .)"
    echo "  --output-dir DIR     Output directory for reports (default: reports)"
    echo "  --format FORMAT      Report format: csv, html, json (default: csv)"
    echo "  --symbol SYMBOL      Filter by symbol (optional)"
    echo "  --no-plots           Skip plot generation"
    echo "  --no-summary         Skip summary generation"
    echo "  --verbose            Verbose output"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --input-dir results/ --output-dir reports/"
    echo "  $0 --format html --symbol AAPL"
    echo "  $0 --no-plots --verbose"
}

# Function to check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for Python (for plotting)
    if [ "$GENERATE_PLOTS" = true ]; then
        if ! command -v python3 &> /dev/null; then
            print_warning "Python3 not found. Plot generation will be skipped."
            GENERATE_PLOTS=false
        else
            # Check for required Python packages
            if ! python3 -c "import pandas, matplotlib, numpy" &> /dev/null; then
                print_warning "Required Python packages not found. Plot generation will be skipped."
                print_info "Install with: pip install pandas matplotlib numpy"
                GENERATE_PLOTS=false
            fi
        fi
    fi
    
    print_success "Dependencies checked"
}

# Function to create output directory
create_output_dir() {
    print_info "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    print_success "Output directory created"
}

# Function to find input files
find_input_files() {
    print_info "Looking for input files in: $INPUT_DIR"
    
    TRADE_LOG=""
    EQUITY_CURVE=""
    
    # Look for trade log
    if [ -f "$INPUT_DIR/trade_log.csv" ]; then
        TRADE_LOG="$INPUT_DIR/trade_log.csv"
    elif [ -f "$INPUT_DIR/trade_log.csv" ]; then
        TRADE_LOG="$INPUT_DIR/trade_log.csv"
    else
        print_error "Trade log not found in $INPUT_DIR"
        print_info "Expected files: trade_log.csv, equity_curve.csv"
        exit 1
    fi
    
    # Look for equity curve
    if [ -f "$INPUT_DIR/equity_curve.csv" ]; then
        EQUITY_CURVE="$INPUT_DIR/equity_curve.csv"
    elif [ -f "$INPUT_DIR/equity_curve.csv" ]; then
        EQUITY_CURVE="$INPUT_DIR/equity_curve.csv"
    else
        print_error "Equity curve not found in $INPUT_DIR"
        exit 1
    fi
    
    print_success "Input files found:"
    print_info "  Trade log: $TRADE_LOG"
    print_info "  Equity curve: $EQUITY_CURVE"
}

# Function to generate summary report
generate_summary() {
    if [ "$GENERATE_SUMMARY" = false ]; then
        return 0
    fi
    
    print_info "Generating summary report..."
    
    SUMMARY_FILE="$OUTPUT_DIR/summary.txt"
    
    {
        echo "Backtest Summary Report"
        echo "======================"
        echo "Generated: $(date)"
        echo ""
        
        # Basic file info
        echo "Input Files:"
        echo "  Trade log: $TRADE_LOG"
        echo "  Equity curve: $EQUITY_CURVE"
        echo ""
        
        # Trade statistics
        if [ -f "$TRADE_LOG" ]; then
            echo "Trade Statistics:"
            echo "  Total trades: $(wc -l < "$TRADE_LOG" | awk '{print $1-1}')"
            
            # Calculate win rate
            if command -v awk &> /dev/null; then
                WINNING_TRADES=$(awk -F',' 'NR>1 && $7>0 {count++} END {print count+0}' "$TRADE_LOG")
                TOTAL_TRADES=$(awk -F',' 'NR>1 {count++} END {print count+0}' "$TRADE_LOG")
                if [ "$TOTAL_TRADES" -gt 0 ]; then
                    WIN_RATE=$(echo "scale=2; $WINNING_TRADES * 100 / $TOTAL_TRADES" | bc -l 2>/dev/null || echo "N/A")
                    echo "  Winning trades: $WINNING_TRADES"
                    echo "  Win rate: ${WIN_RATE}%"
                fi
            fi
            echo ""
        fi
        
        # Equity curve statistics
        if [ -f "$EQUITY_CURVE" ]; then
            echo "Portfolio Statistics:"
            echo "  Data points: $(wc -l < "$EQUITY_CURVE" | awk '{print $1-1}')"
            
            # Calculate final equity
            if command -v tail &> /dev/null; then
                FINAL_EQUITY=$(tail -n 1 "$EQUITY_CURVE" | cut -d',' -f2)
                echo "  Final equity: $FINAL_EQUITY"
            fi
            echo ""
        fi
        
        echo "Report generated by C++ Backtester"
        echo "For more details, see individual CSV files."
        
    } > "$SUMMARY_FILE"
    
    print_success "Summary report generated: $SUMMARY_FILE"
}

# Function to generate plots
generate_plots() {
    if [ "$GENERATE_PLOTS" = false ]; then
        return 0
    fi
    
    print_info "Generating plots..."
    
    PLOT_SCRIPT="$OUTPUT_DIR/generate_plots.py"
    
    # Create Python script for plotting
    cat > "$PLOT_SCRIPT" << 'EOF'
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
EOF
    
    # Make script executable
    chmod +x "$PLOT_SCRIPT"
    
    # Run the plotting script
    if python3 "$PLOT_SCRIPT" "$TRADE_LOG" "$EQUITY_CURVE" "$OUTPUT_DIR"; then
        print_success "Plots generated successfully"
    else
        print_warning "Plot generation failed"
    fi
}

# Function to generate HTML report
generate_html_report() {
    if [ "$FORMAT" != "html" ]; then
        return 0
    fi
    
    print_info "Generating HTML report..."
    
    HTML_FILE="$OUTPUT_DIR/report.html"
    
    {
        echo "<!DOCTYPE html>"
        echo "<html lang=\"en\">"
        echo "<head>"
        echo "    <meta charset=\"UTF-8\">"
        echo "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
        echo "    <title>Backtest Report</title>"
        echo "    <style>"
        echo "        body { font-family: Arial, sans-serif; margin: 40px; }"
        echo "        h1, h2 { color: #333; }"
        echo "        table { border-collapse: collapse; width: 100%; margin: 20px 0; }"
        echo "        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }"
        echo "        th { background-color: #f2f2f2; }"
        echo "        .positive { color: green; }"
        echo "        .negative { color: red; }"
        echo "    </style>"
        echo "</head>"
        echo "<body>"
        echo "    <h1>Backtest Report</h1>"
        echo "    <p>Generated: $(date)</p>"
        echo ""
        echo "    <h2>Summary</h2>"
        echo "    <p>This report contains the results of the backtest analysis.</p>"
        echo ""
        echo "    <h2>Files</h2>"
        echo "    <ul>"
        echo "        <li><a href=\"trade_log.csv\">Trade Log</a></li>"
        echo "        <li><a href=\"equity_curve.csv\">Equity Curve</a></li>"
        if [ -f "$OUTPUT_DIR/backtest_plots.png" ]; then
            echo "        <li><a href=\"backtest_plots.png\">Plots</a></li>"
        fi
        echo "    </ul>"
        echo ""
        echo "    <h2>Trade Log Preview</h2>"
        if [ -f "$TRADE_LOG" ]; then
            echo "    <table>"
            head -n 6 "$TRADE_LOG" | while IFS=',' read -r line; do
                echo "        <tr>"
                echo "$line" | sed 's/,/<\/td><td>/g' | sed 's/^/<td>/' | sed 's/$/<\/td>/'
                echo "        </tr>"
            done
            echo "    </table>"
        fi
        echo ""
        echo "    <h2>Equity Curve Preview</h2>"
        if [ -f "$EQUITY_CURVE" ]; then
            echo "    <table>"
            head -n 6 "$EQUITY_CURVE" | while IFS=',' read -r line; do
                echo "        <tr>"
                echo "$line" | sed 's/,/<\/td><td>/g' | sed 's/^/<td>/' | sed 's/$/<\/td>/'
                echo "        </tr>"
            done
            echo "    </table>"
        fi
        echo "</body>"
        echo "</html>"
    } > "$HTML_FILE"
    
    print_success "HTML report generated: $HTML_FILE"
}

# Function to copy input files
copy_input_files() {
    print_info "Copying input files to output directory..."
    
    if [ -f "$TRADE_LOG" ]; then
        cp "$TRADE_LOG" "$OUTPUT_DIR/"
        print_success "Trade log copied"
    fi
    
    if [ -f "$EQUITY_CURVE" ]; then
        cp "$EQUITY_CURVE" "$OUTPUT_DIR/"
        print_success "Equity curve copied"
    fi
}

# Function to show final results
show_results() {
    print_success "Report generation completed!"
    echo ""
    print_info "Output directory: $OUTPUT_DIR"
    print_info "Generated files:"
    
    if [ -f "$OUTPUT_DIR/summary.txt" ]; then
        echo "  - summary.txt"
    fi
    
    if [ -f "$OUTPUT_DIR/trade_log.csv" ]; then
        echo "  - trade_log.csv"
    fi
    
    if [ -f "$OUTPUT_DIR/equity_curve.csv" ]; then
        echo "  - equity_curve.csv"
    fi
    
    if [ -f "$OUTPUT_DIR/backtest_plots.png" ]; then
        echo "  - backtest_plots.png"
    fi
    
    if [ -f "$OUTPUT_DIR/report.html" ]; then
        echo "  - report.html"
    fi
    
    echo ""
    print_success "Reports generated successfully!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --input-dir)
            INPUT_DIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --symbol)
            SYMBOL="$2"
            shift 2
            ;;
        --no-plots)
            GENERATE_PLOTS=false
            shift
            ;;
        --no-summary)
            GENERATE_SUMMARY=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            print_error "Unknown argument: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_info "Starting report generation..."
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Create output directory
    create_output_dir
    
    # Find input files
    find_input_files
    
    # Copy input files
    copy_input_files
    
    # Generate summary
    generate_summary
    
    # Generate plots
    generate_plots
    
    # Generate HTML report
    generate_html_report
    
    # Show results
    show_results
}

# Run main function
main
