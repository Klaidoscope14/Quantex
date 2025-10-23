#pragma once
#include "backtester/portfolio.h"
#include <string>

namespace backtester {

class Reporting {
public:
    Reporting(const std::string& out_dir = ".");
    void write_trade_log(const Portfolio& portfolio) const;
    void write_equity_curve(const Portfolio& portfolio) const;
private:
    std::string out_dir_;
};

} // namespace backtester