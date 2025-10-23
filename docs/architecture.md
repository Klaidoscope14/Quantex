# Backtester Architecture

## System Overview

The C++ Backtester is a modular financial trading strategy backtesting framework designed for performance and extensibility. It simulates trading strategies against historical market data to evaluate their performance.

## Architecture Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   DataHandler   │───▶│    Strategy     │───▶│ ExecutionHandler│
│                 │    │                 │    │                 │
│ - Load CSV data │    │ - Moving Avg    │    │ - Apply slippage│
│ - Parse OHLCV   │    │ - Generate      │    │ - Apply fees    │
│ - Validate      │    │   signals       │    │ - Execute orders│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       ▼                       ▼
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │    Portfolio    │    │    Reporting    │
         │              │                 │    │                 │
         └─────────────▶│ - Track cash    │    │ - Trade log     │
                        │ - Track pos     │    │ - Equity curve  │
                        │ - Calculate P&L │    │ - CSV output    │
                        └─────────────────┘    └─────────────────┘
```

## Core Components

### 1. DataHandler
**Purpose**: Load and validate historical market data

**Key Features**:
- CSV file parsing with error handling
- OHLCV data structure validation
- Chronological data ordering
- Support for multiple data sources

**Dependencies**: Standard library only

### 2. Strategy
**Purpose**: Implement trading logic and generate signals

**Current Implementation**: Moving Average Crossover
- Short-term moving average (default: 50 periods)
- Long-term moving average (default: 200 periods)
- Buy signal: Short MA crosses above Long MA
- Sell signal: Short MA crosses below Long MA

**Design Pattern**: Stateful strategy with position tracking

### 3. ExecutionHandler
**Purpose**: Simulate realistic trade execution

**Features**:
- Slippage modeling (configurable percentage)
- Commission costs (per-trade fees)
- Position sizing (dollar-based allocation)
- Integer share quantities

### 4. Portfolio
**Purpose**: Track positions, cash, and performance

**Key Responsibilities**:
- Cash management
- Position tracking
- P&L calculation (realized and unrealized)
- Trade logging
- Equity curve generation

### 5. Reporting
**Purpose**: Generate analysis outputs

**Outputs**:
- `trade_log.csv`: Complete trade history
- `equity_curve.csv`: Portfolio value over time

## Data Flow

1. **Initialization**
   - Load configuration (JSON or defaults)
   - Initialize all components
   - Load historical data

2. **Event Loop**
   - For each historical bar:
     - Strategy generates signal
     - ExecutionHandler processes signal
     - Portfolio updates positions
     - Market-to-market valuation

3. **Reporting**
   - Generate trade log
   - Generate equity curve
   - Output performance metrics

## Configuration System

### JSON Configuration
```json
{
  "initial_capital": 100000.0,
  "position_size": 10000.0,
  "commission_per_trade": 1.0,
  "slippage_pct": 0.0005,
  "short_window": 50,
  "long_window": 200,
  "data_dir": "data",
  "symbol": "AAPL"
}
```

### Fallback System
- Graceful degradation to hardcoded defaults
- Optional nlohmann/json dependency
- Command-line overrides

## Design Principles

### 1. Modularity
- Clear separation of concerns
- Minimal coupling between components
- Easy to extend with new strategies

### 2. Performance
- Efficient data structures (deque for moving averages)
- Minimal memory allocations
- Fast CSV parsing

### 3. Realism
- Realistic execution costs
- Slippage modeling
- Integer share quantities
- Cash management

### 4. Extensibility
- Strategy interface ready for new implementations
- Configurable parameters
- Multiple data source support

## Build System

### CMake Configuration
- C++20 standard
- Optional dependencies
- Cross-platform compatibility
- Single executable output

### Dependencies
- **Required**: Standard C++20 library
- **Optional**: nlohmann/json for configuration parsing

## Data Structures

### OHLCV
```cpp
struct OHLCV {
    std::string date;      // YYYY-MM-DD
    double open, high, low, close, adj_close;
    long volume;
};
```

### Position
```cpp
struct Position {
    std::string symbol;
    int size;              // positive = long, negative = short
    double entry_price;
};
```

### TradeRecord
```cpp
struct TradeRecord {
    std::string entry_date, exit_date, symbol;
    double entry_price, exit_price;
    int shares;
    double pnl;
};
```

## Error Handling

- Graceful CSV parsing with missing data handling
- Configuration fallbacks
- Insufficient cash handling
- Data validation

## Performance Considerations

- **Time Complexity**: O(n) where n = number of bars
- **Space Complexity**: O(1) for strategy state, O(n) for data storage
- **Memory Usage**: Minimal allocations, efficient data structures

## Future Extensions

### Potential Enhancements
1. **Multi-symbol support**
2. **Advanced strategies** (RSI, MACD, etc.)
3. **Risk management** (stop-loss, position limits)
4. **Performance metrics** (Sharpe ratio, max drawdown)
5. **Real-time data** integration
6. **Database storage** for large datasets

### Strategy Interface
```cpp
class Strategy {
public:
    virtual Signal on_new_bar(const OHLCV& bar) = 0;
    virtual void reset() = 0;
};
```

## Testing Strategy

### Unit Tests
- Individual component testing
- Mock data for isolated testing
- Edge case validation

### Integration Tests
- End-to-end backtesting
- Performance validation
- Output verification

## Deployment

### Build Process
```bash
mkdir build && cd build
cmake ..
make
```

### Usage
```bash
./bt_run [SYMBOL]
```

### Output Files
- `trade_log.csv`
- `equity_curve.csv`
