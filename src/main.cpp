#include "backtester/data_handler.h"
#include "backtester/strategy.h"
#include "backtester/execution.h"
#include "backtester/portfolio.h"
#include "backtester/reporting.h"

#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <filesystem>
#include <fstream>

#ifdef __has_include
#  if __has_include(<nlohmann/json.hpp>)
#    include <nlohmann/json.hpp>
#    define HAS_NLOHMANN
#  endif
#endif

using namespace backtester;

struct Config {
    double initial_capital = 100000.0;
    double position_size = 10000.0;
    double commission = 1.0;
    double slippage = 0.0005;
    int short_w = 50;
    int long_w = 200;
    std::string data_dir = "data";
    std::string symbol = "AAPL";
};

Config load_config_or_defaults(const std::string& path) {
    Config cfg;
#ifdef HAS_NLOHMANN
    try {
        std::ifstream ifs(path);
        if (!ifs) return cfg;
        nlohmann::json j; ifs >> j;
        if (j.contains("initial_capital")) cfg.initial_capital = j["initial_capital"].get<double>();
        if (j.contains("position_size")) cfg.position_size = j["position_size"].get<double>();
        if (j.contains("commission_per_trade")) cfg.commission = j["commission_per_trade"].get<double>();
        if (j.contains("slippage_pct")) cfg.slippage = j["slippage_pct"].get<double>();
        if (j.contains("short_window")) cfg.short_w = j["short_window"].get<int>();
        if (j.contains("long_window")) cfg.long_w = j["long_window"].get<int>();
        if (j.contains("data_dir")) cfg.data_dir = j["data_dir"].get<std::string>();
        if (j.contains("symbol")) cfg.symbol = j["symbol"].get<std::string>();
    } catch (...) {
        std::cerr << "Failed to parse config, using defaults.\n";
    }
#else
    (void)path; // silence unused
    std::cerr << "nlohmann::json not available — using built-in defaults. To enable config parsing, add nlohmann_json.\n";
#endif
    return cfg;
}

int main(int argc, char** argv) {
    std::cout << "Starting minimal backtester...\n";

    std::string config_path = "configs/default_config.json";
    Config cfg = load_config_or_defaults(config_path);

    // allow override symbol via arg
    if (argc > 1) cfg.symbol = argv[1];

    DataHandler dh(cfg.data_dir);
    auto bars = dh.load_csv(cfg.symbol);
    if (bars.empty()) {
        std::cerr << "No data loaded for symbol " << cfg.symbol << " in " << cfg.data_dir << "\n";
        return 1;
    }

    MovingAverageCrossover strat(cfg.short_w, cfg.long_w);
    ExecutionHandler exec(cfg.slippage, cfg.commission);
    Portfolio port(cfg.initial_capital, cfg.position_size);
    Reporting report(".");

    // event loop: iterate bars oldest -> newest
    for (const auto& bar : bars) {
        Signal sig = strat.on_new_bar(bar);

        // latest market snapshot map (single symbol)
        std::map<std::string, OHLCV> snapshot;
        snapshot[cfg.symbol] = bar;

        // If signal, execute
        if (sig == Signal::Buy) {
            exec.execute_order(cfg.symbol, sig, port, bar);
        } else if (sig == Signal::Sell) {
            exec.execute_order(cfg.symbol, sig, port, bar);
        }

        // update portfolio with market mark-to-market
        port.update_market(bar.date, snapshot);
    }

    // write outputs
    report.write_trade_log(port);
    report.write_equity_curve(port);

    std::cout << "Backtest finished. Equity: " << port.total_equity() << "\n";
    std::cout << "Trade log: ./trade_log.csv, equity curve: ./equity_curve.csv\n";
    return 0;
}