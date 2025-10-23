#include "backtester/portfolio.h"
#include <iostream>

namespace backtester {

Portfolio::Portfolio(double initial_capital, double position_size_value)
    : initial_capital_(initial_capital), cash_(initial_capital), position_size_value_(position_size_value) {}

void Portfolio::on_fill(const Position& pos, double fill_price, double commission) {
    // Simplified: if pos.size > 0 we open or add to long; if negative -> close
    if (pos.size > 0) {
        // buy shares: reduce cash
        double cost = fill_price * pos.size + commission;
        if (cost > cash_) {
            // insufficient cash: buy as many as possible
            long affordable = static_cast<long>((cash_ - commission) / fill_price);
            if (affordable <= 0) {
                return;
            }
            Position p = pos;
            p.size = static_cast<int>(affordable);
            p.entry_price = fill_price;
            positions_[p.symbol] = p;
            cash_ -= (fill_price * p.size + commission);
            // log entry (no exit date yet)
            TradeRecord tr;
            tr.entry_date = ""; // will be filled later by update logic if needed
            tr.symbol = p.symbol;
            tr.entry_price = fill_price;
            tr.shares = p.size;
            tr.exit_date = "";
            tr.exit_price = 0.0;
            tr.pnl = 0.0;
            trades_.push_back(tr);
        } else {
            Position p = pos;
            p.entry_price = fill_price;
            // if existing position exists, we overwrite (simple model)
            positions_[p.symbol] = p;
            cash_ -= cost;
            // record trade (entry)
            TradeRecord tr;
            tr.entry_date = ""; // to be set by caller if needed
            tr.symbol = p.symbol;
            tr.entry_price = fill_price;
            tr.shares = p.size;
            tr.exit_date = "";
            tr.exit_price = 0.0;
            tr.pnl = 0.0;
            trades_.push_back(tr);
        }
    } else if (pos.size < 0) {
        // Sell/close: for simplicity, we close entire position if exists
        auto it = positions_.find(pos.symbol);
        if (it == positions_.end()) return;
        Position existing = it->second;
        long shares = existing.size;
        double proceeds = fill_price * std::abs(shares) - commission;
        cash_ += proceeds;
        // find last trade record for this symbol without exit_date set
        for (auto it2 = trades_.rbegin(); it2 != trades_.rend(); ++it2) {
            if (it2->symbol == pos.symbol && it2->exit_date.empty()) {
                it2->exit_price = fill_price;
                it2->exit_date = ""; // will be set by update_market with date
                it2->pnl = (fill_price - it2->entry_price) * it2->shares - commission;
                break;
            }
        }
        // remove position
        positions_.erase(it);
    }
}

void Portfolio::update_market(const std::string& date, const std::map<std::string, OHLCV>& latest_bars) {
    // calculate equity: cash + sum(position shares * latest price)
    double equity = cash_;
    for (const auto& kv : positions_) {
        const std::string& symbol = kv.first;
        const Position& pos = kv.second;
        auto it = latest_bars.find(symbol);
        if (it != latest_bars.end()) {
            double market_price = it->second.close;
            equity += market_price * pos.size;
        } else {
            equity += pos.entry_price * pos.size;
        }
    }
    equity_points_.push_back({date, equity});

    // update trade records' dates for open entries if empty
    for (auto& tr : trades_) {
        if (tr.entry_date.empty()) tr.entry_date = date;
        if (!tr.exit_date.empty() && tr.exit_date == "") {
            tr.exit_date = date; // finalize exit date (if exit happened earlier)
        }
    }
}

double Portfolio::total_equity() const { 
    if (equity_points_.empty()) return initial_capital_;
    return equity_points_.back().second;
}
double Portfolio::cash() const { return cash_; }
double Portfolio::position_size_value() const { return position_size_value_; }
const std::vector<std::pair<std::string,double>>& Portfolio::equity_curve() const { return equity_points_; }
const std::vector<Portfolio::TradeRecord>& Portfolio::trade_log() const { return trades_; }

Position* Portfolio::find_position(const std::string& symbol) {
    auto it = positions_.find(symbol);
    if (it == positions_.end()) return nullptr;
    return &(it->second);
}

} // namespace backtester
