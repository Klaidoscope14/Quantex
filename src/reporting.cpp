#include "backtester/reporting.h"
#include <fstream>
#include <iomanip>

namespace backtester {

Reporting::Reporting(const std::string& out_dir) : out_dir_(out_dir) {}

void Reporting::write_trade_log(const Portfolio& portfolio) const {
    std::ofstream ofs(out_dir_ + "/trade_log.csv");
    ofs << "entry_date,exit_date,symbol,entry_price,exit_price,shares,pnl\n";
    for (const auto& tr : portfolio.trade_log()) {
        ofs << tr.entry_date << "," << tr.exit_date << "," << tr.symbol << ","
            << tr.entry_price << "," << tr.exit_price << "," << tr.shares << "," << tr.pnl << "\n";
    }
    ofs.close();
}

void Reporting::write_equity_curve(const Portfolio& portfolio) const {
    std::ofstream ofs(out_dir_ + "/equity_curve.csv");
    ofs << "date,equity\n";
    for (const auto& pt : portfolio.equity_curve()) {
        ofs << pt.first << "," << std::fixed << std::setprecision(2) << pt.second << "\n";
    }
    ofs.close();
}

} // namespace backtester