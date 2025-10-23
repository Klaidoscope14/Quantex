#include "backtester/data_handler.h"
#include <fstream>
#include <sstream>
#include <iostream>
#include <algorithm>

namespace backtester {

DataHandler::DataHandler(const std::string& data_dir) : data_dir_(data_dir) {}

std::vector<OHLCV> DataHandler::load_csv(const std::string& symbol) const {
    std::vector<OHLCV> rows;
    std::string path = data_dir_ + "/" + symbol + ".csv";
    std::ifstream ifs(path);
    if (!ifs.is_open()) {
        std::cerr << "Failed to open CSV: " << path << "\n";
        return rows;
    }

    std::string line;
    // read header
    if (!std::getline(ifs, line)) return rows;

    while (std::getline(ifs, line)) {
        if (line.empty()) continue;
        std::stringstream ss(line);
        std::string token;
        OHLCV r;

        // Expected CSV: Date,Open,High,Low,Close,Adj Close,Volume
        std::getline(ss, r.date, ',');
        std::getline(ss, token, ','); r.open = token.empty() ? 0.0 : std::stod(token);
        std::getline(ss, token, ','); r.high = token.empty() ? 0.0 : std::stod(token);
        std::getline(ss, token, ','); r.low = token.empty() ? 0.0 : std::stod(token);
        std::getline(ss, token, ','); r.close = token.empty() ? 0.0 : std::stod(token);
        std::getline(ss, token, ','); r.adj_close = token.empty() ? r.close : std::stod(token);
        std::getline(ss, token, ','); 
        if (token.empty()) {
            // If volume is missing, attempt to read last token
            if (std::getline(ss, token, ',')) {
                r.volume = token.empty() ? 0 : std::stol(token);
            } else {
                r.volume = 0;
            }
        } else {
            r.volume = std::stol(token);
        }
        rows.push_back(r);
    }

    // Ensure chronological order ascending (oldest -> newest)
    std::reverse(rows.begin(), rows.end());
    return rows;
}

} 