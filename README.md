# Fintual-test
Fintual test from Getonbrd

# Portfolio Rebalancing Calculator

This project provides a simple Ruby implementation for calculating the trades (buy/sell actions) required to rebalance an investment portfolio according to a target asset allocation.

It determines which stocks to buy or sell to align the portfolio's current holdings (e.g., 10 shares of AAPL, 2 of META) with a target allocation (e.g., 60% AAPL, 40% META).

## Core Logic

The solution is built around two main classes:

* `Stock`: A simple data class that holds the `symbol` (e.g., "AAPL") and `quantity` (e.g., 10.0) of a stock.
* `Portfolio`: The main class that contains the rebalancing logic.
    * It is initialized with the current holdings (a collection of `Stock` objects) and the target allocation (a Hash like `{"AAPL" => 0.6, "META" => 0.4}`).
    * It has a `rebalance(prices)` method that takes the current market prices and returns a list of actions (buy/sell) needed to match the target.

## How to Run

This repository includes two different scripts to demonstrate the `Portfolio` logic. Both files use the same core classes, but they differ in how they receive their data.

### 1. Static Version (`static_rebalancer.rb`)

This script contains **hardcoded values** for the portfolio holdings, target allocation, and current market prices. It is a straightforward example of how to instantiate and use the `Portfolio` class directly in your code.

**To run:**
```bash
ruby static_rebalancer.rb
```

### 2. Dynamic Version (dynamic_rebalancer.rb)

This script provides an interactive command-line interface (CLI). It will prompt the user to enter all the necessary information one by one.

**To run:**
```bash
ruby dynamic_rebalancer.rb
```
