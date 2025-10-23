#include "backtester/execution.h"
#include <cmath>

namespace backtester {

ExecutionHandler::ExecutionHandler(double slippage_pct, double commission_per_trade)
    : slippage_pct_(slippage_pct), commission_(commission_per_trade) {}

void ExecutionHandler::execute_order(const std::string& symbol, Signal signal, Portfolio& portfolio, const OHLCV& bar) {
    double price = bar.close;
    // slippage applied as percentage away from price
    double slippage = price * slippage_pct_;
    double fill_price = price;
    if (signal == Signal::Buy) fill_price = price + slippage;
    else if (signal == Signal::Sell) fill_price = price - slippage;

    // Determine qty from portfolio.position_size (Portfolio will manage cash & positions)
    double qty = portfolio.position_size_value(); // returns dollars to allocate (not share count)
    if (qty <= 0) return;

    // Convert dollar qty to share count (integer shares)
    long shares = static_cast<long>(qty / fill_price);
    if (shares == 0) return;

    // Create Position and fill
    Position pos;
    pos.symbol = symbol;
    if (signal == Signal::Buy) pos.size = static_cast<int>(shares);
    else if (signal == Signal::Sell) pos.size = -static_cast<int>(shares);

    portfolio.on_fill(pos, fill_price, commission_);
}

} // namespace backtester