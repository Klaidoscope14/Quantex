#pragma once
#include "backtester/data_handler.h"
#include <string>
#include <map>
#include <vector>

namespace backtester {

struct Position {
    std::string symbol;
    int size = 0; // positive long, negative short (we use only long in this simple model)
    double entry_price = 0.0;
};

struct EquityPoint {
    std::string date;
    double equity = 0.0;
};

class Portfolio {
public:
    Portfolio(double initial_capital, double position_size_value);
    // Called by ExecutionHandler when a fill happens
    void on_fill(const Position& pos, double fill_price, double commission);
    // Called on every bar to update unrealized PnL and record equity
    void update_market(const std::string& date, const std::map<std::string, OHLCV>& latest_bars);
    double total_equity() const;
    double cash() const;
    double position_size_value() const; // how many dollars to allocate per trade (config)
    const std::vector<std::pair<std::string,double>>& equity_curve() const;
    // trade log accessor (very simple)
    struct TradeRecord { std::string entry_date, exit_date, symbol; double entry_price, exit_price; int shares; double pnl; };
    const std::vector<TradeRecord>& trade_log() const;
private:
    double initial_capital_;
    double cash_;
    double position_size_value_;
    std::map<std::string, Position> positions_;
    std::vector<std::pair<std::string,double>> equity_points_;
    std::vector<TradeRecord> trades_;
    // helper: find open position for symbol
    Position* find_position(const std::string& symbol);
};

} // namespace backtester