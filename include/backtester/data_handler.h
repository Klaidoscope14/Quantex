#pragma once
#include <string>
#include <vector>

namespace backtester {

struct OHLCV {
    std::string date; // YYYY-MM-DD
    double open=0.0, high=0.0, low=0.0, close=0.0, adj_close=0.0;
    long volume=0;
};

class DataHandler {
public:
    explicit DataHandler(const std::string& data_dir);
    std::vector<OHLCV> load_csv(const std::string& symbol) const;
private:
    std::string data_dir_;
};

} 