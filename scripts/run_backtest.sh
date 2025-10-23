#!/bin/bash

# C++ Backtester Run Script
# 
# This script builds and runs the C++ backtester with proper configuration.
# It handles build setup, data validation, and execution.
#
# Usage: ./run_backtest.sh [SYMBOL] [OPTIONS]
#
# Examples:
#   ./run_backtest.sh AAPL
#   ./run_backtest.sh MSFT --config custom_config.json
#   ./run_backtest.sh GOOGL --data-dir /path/to/data

set -e  # Exit on any error

# Default values
SYMBOL="AAPL"
CONFIG_FILE="configs/default_config.json"
DATA_DIR="data"
BUILD_DIR="build"
OUTPUT_DIR="."
VERBOSE=false
CLEAN_BUILD=false

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
    echo "Usage: $0 [SYMBOL] [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  SYMBOL              Stock symbol to backtest (default: AAPL)"
    echo ""
    echo "Options:"
    echo "  --config FILE       Configuration file (default: configs/default_config.json)"
    echo "  --data-dir DIR      Data directory (default: data)"
    echo "  --output-dir DIR    Output directory (default: .)"
    echo "  --build-dir DIR     Build directory (default: build)"
    echo "  --clean             Clean build directory before building"
    echo "  --verbose           Verbose output"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 AAPL"
    echo "  $0 MSFT --config custom_config.json"
    echo "  $0 GOOGL --data-dir /path/to/data --verbose"
    echo "  $0 --clean AAPL"
}

# Function to check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for CMake
    if ! command -v cmake &> /dev/null; then
        print_error "CMake is not installed. Please install CMake to build the project."
        exit 1
    fi
    
    # Check for C++ compiler
    if ! command -v g++ &> /dev/null && ! command -v clang++ &> /dev/null; then
        print_error "No C++ compiler found. Please install g++ or clang++."
        exit 1
    fi
    
    # Check for make or ninja
    if ! command -v make &> /dev/null && ! command -v ninja &> /dev/null; then
        print_error "No build system found. Please install make or ninja."
        exit 1
    fi
    
    print_success "All dependencies found"
}

# Function to clean build directory
clean_build() {
    if [ "$CLEAN_BUILD" = true ]; then
        print_info "Cleaning build directory..."
        if [ -d "$BUILD_DIR" ]; then
            rm -rf "$BUILD_DIR"
            print_success "Build directory cleaned"
        fi
    fi
}

# Function to build the project
build_project() {
    print_info "Building C++ backtester..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Configure with CMake
    print_info "Configuring with CMake..."
    if [ "$VERBOSE" = true ]; then
        cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_VERBOSE_MAKEFILE=ON
    else
        cmake .. -DCMAKE_BUILD_TYPE=Release
    fi
    
    # Build the project
    print_info "Compiling..."
    if [ "$VERBOSE" = true ]; then
        make VERBOSE=1
    else
        make
    fi
    
    cd ..
    print_success "Build completed successfully"
}

# Function to validate data
validate_data() {
    print_info "Validating data for symbol: $SYMBOL"
    
    DATA_FILE="$DATA_DIR/$SYMBOL.csv"
    
    if [ ! -f "$DATA_FILE" ]; then
        print_error "Data file not found: $DATA_FILE"
        print_info "Please download data first using:"
        print_info "  python tools/downloader/python/fetch_yahoo.py $SYMBOL"
        print_info "  or"
        print_info "  python tools/downloader/python/fetch_alpha_vantage.py $SYMBOL YOUR_API_KEY"
        exit 1
    fi
    
    # Check if file has content
    if [ ! -s "$DATA_FILE" ]; then
        print_error "Data file is empty: $DATA_FILE"
        exit 1
    fi
    
    # Check if file has header
    if ! head -n 1 "$DATA_FILE" | grep -q "Date,Open,High,Low,Close"; then
        print_warning "Data file may not have correct format: $DATA_FILE"
        print_info "Expected format: Date,Open,High,Low,Close,Adj Close,Volume"
    fi
    
    print_success "Data validation passed"
}

# Function to validate configuration
validate_config() {
    print_info "Validating configuration: $CONFIG_FILE"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        print_warning "Configuration file not found: $CONFIG_FILE"
        print_info "Using default configuration"
        return 0
    fi
    
    # Check if it's valid JSON (basic check)
    if command -v python3 &> /dev/null; then
        if ! python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
            print_warning "Configuration file may not be valid JSON: $CONFIG_FILE"
        fi
    fi
    
    print_success "Configuration validation passed"
}

# Function to run the backtest
run_backtest() {
    print_info "Running backtest for symbol: $SYMBOL"
    
    EXECUTABLE="$BUILD_DIR/bt_run"
    
    if [ ! -f "$EXECUTABLE" ]; then
        print_error "Executable not found: $EXECUTABLE"
        print_info "Please build the project first"
        exit 1
    fi
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Run the backtest
    print_info "Executing backtest..."
    if [ "$VERBOSE" = true ]; then
        "$EXECUTABLE" "$SYMBOL" 2>&1 | tee "$OUTPUT_DIR/backtest.log"
    else
        "$EXECUTABLE" "$SYMBOL" > "$OUTPUT_DIR/backtest.log" 2>&1
    fi
    
    # Check if backtest completed successfully
    if [ $? -eq 0 ]; then
        print_success "Backtest completed successfully"
        
        # Check for output files
        if [ -f "$OUTPUT_DIR/trade_log.csv" ]; then
            print_success "Trade log generated: $OUTPUT_DIR/trade_log.csv"
        fi
        
        if [ -f "$OUTPUT_DIR/equity_curve.csv" ]; then
            print_success "Equity curve generated: $OUTPUT_DIR/equity_curve.csv"
        fi
        
        # Show summary
        if [ -f "$OUTPUT_DIR/backtest.log" ]; then
            echo ""
            print_info "Backtest Summary:"
            tail -n 5 "$OUTPUT_DIR/backtest.log"
        fi
        
    else
        print_error "Backtest failed"
        if [ -f "$OUTPUT_DIR/backtest.log" ]; then
            print_info "Error log:"
            cat "$OUTPUT_DIR/backtest.log"
        fi
        exit 1
    fi
}

# Function to show results
show_results() {
    print_info "Backtest Results:"
    echo ""
    
    if [ -f "$OUTPUT_DIR/trade_log.csv" ]; then
        print_info "Trade Log ($OUTPUT_DIR/trade_log.csv):"
        if command -v head &> /dev/null; then
            head -n 5 "$OUTPUT_DIR/trade_log.csv"
            echo "..."
        fi
        echo ""
    fi
    
    if [ -f "$OUTPUT_DIR/equity_curve.csv" ]; then
        print_info "Equity Curve ($OUTPUT_DIR/equity_curve.csv):"
        if command -v head &> /dev/null; then
            head -n 5 "$OUTPUT_DIR/equity_curve.csv"
            echo "..."
        fi
        echo ""
    fi
    
    print_success "Backtest completed for $SYMBOL"
    print_info "Output files:"
    print_info "  - Trade log: $OUTPUT_DIR/trade_log.csv"
    print_info "  - Equity curve: $OUTPUT_DIR/equity_curve.csv"
    print_info "  - Log file: $OUTPUT_DIR/backtest.log"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --data-dir)
            DATA_DIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
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
            if [ -z "$SYMBOL" ] || [ "$SYMBOL" = "AAPL" ]; then
                SYMBOL="$1"
            else
                print_error "Multiple symbols specified: $SYMBOL and $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Main execution
main() {
    print_info "Starting C++ Backtester for symbol: $SYMBOL"
    echo ""
    
    # Check dependencies
    check_dependencies
    
    # Clean build if requested
    clean_build
    
    # Build the project
    build_project
    
    # Validate data
    validate_data
    
    # Validate configuration
    validate_config
    
    # Run the backtest
    run_backtest
    
    # Show results
    show_results
}

# Run main function
main
