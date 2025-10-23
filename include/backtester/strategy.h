#pragma once
#include "backtester/data_handler.h"
#include <deque>

namespace backtester {

enum class Signal { None, Buy, Sell };

class MovingAverageCrossover {
public:
    MovingAverageCrossover(int short_window, int long_window);
    // call for each new bar; returns signal if generated for this bar
    Signal on_new_bar(const OHLCV& bar);
private:
    int short_w_, long_w_;
    std::deque<double> short_queue_, long_queue_;
    double short_sum_=0.0, long_sum_=0.0;
    bool has_position_=false; // used for simple stateful behavior
    double prev_short_ma_=0.0, prev_long_ma_=0.0;
};

} 