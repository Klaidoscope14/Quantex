#include "backtester/strategy.h"
#include <cassert>

namespace backtester {

MovingAverageCrossover::MovingAverageCrossover(int short_window, int long_window)
    : short_w_(short_window), long_w_(long_window) {
    assert(short_w_ > 0 && long_w_ > 0 && short_w_ < long_w_);
}

Signal MovingAverageCrossover::on_new_bar(const OHLCV& bar) {
    double price = bar.close;

    // update short MA
    short_queue_.push_back(price);
    short_sum_ += price;
    if ((int)short_queue_.size() > short_w_) {
        short_sum_ -= short_queue_.front();
        short_queue_.pop_front();
    }

    // update long MA
    long_queue_.push_back(price);
    long_sum_ += price;
    if ((int)long_queue_.size() > long_w_) {
        long_sum_ -= long_queue_.front();
        long_queue_.pop_front();
    }

    if ((int)short_queue_.size() < short_w_ || (int)long_queue_.size() < long_w_) {
        // not enough data yet
        prev_short_ma_ = (short_queue_.empty() ? 0.0 : short_sum_/short_queue_.size());
        prev_long_ma_ = (long_queue_.empty() ? 0.0 : long_sum_/long_queue_.size());
        return Signal::None;
    }

    double short_ma = short_sum_ / short_w_;
    double long_ma  = long_sum_ / long_w_;

    Signal signal = Signal::None;
    // detect crossover: previous short <= previous long and new short > new long => buy
    if (prev_short_ma_ <= prev_long_ma_ && short_ma > long_ma) {
        signal = Signal::Buy;
        has_position_ = true;
    }
    // short crosses below long => sell/exit
    else if (prev_short_ma_ >= prev_long_ma_ && short_ma < long_ma) {
        signal = Signal::Sell;
        has_position_ = false;
    }

    prev_short_ma_ = short_ma;
    prev_long_ma_  = long_ma;
    return signal;
}

} 