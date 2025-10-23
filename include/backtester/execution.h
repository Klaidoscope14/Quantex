#pragma once
#include "backtester/data_handler.h"
#include "backtester/portfolio.h"
#include "backtester/strategy.h"
#include <string>

namespace backtester {

class ExecutionHandler {
public:
    ExecutionHandler(double slippage_pct, double commission_per_trade);
    // Executes immediately at bar.close +/- slippage and calls portfolio.on_fill
    void execute_order(const std::string& symbol, Signal signal, Portfolio& portfolio, const OHLCV& bar);
private:
    double slippage_pct_;
    double commission_;
};

} 