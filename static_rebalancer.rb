# frozen_string_literal: true

# The Stock class represents an individual asset.
# Its purpose is simple: to hold the information of a symbol (e.g., 'AAPL')
# and its current price.
class Stock
  attr_reader :symbol, :price

  # Each stock is initialized with a symbol and a price.
  # - symbol: The unique identifier for the stock (e.g., 'AAPL', 'META').
  # - price: The current market price for one share.
  def initialize(symbol, price)
    @symbol = symbol
    @price = price
  end

  # The requested 'current_price' method. It simply returns the price
  # with which the object was initialized or updated.
  def current_price
    @price
  end
end

# ------------------------------------------------------------------------------

# The Portfolio class manages a collection of stocks and their desired distribution.
# Its main responsibility is to calculate how to rebalance the current holdings
# to match the allocation targets.
class Portfolio
  # - holdings: A Hash representing the stocks you actually own.
  #             Format: { 'SYMBOL' => number_of_shares }
  #             Example: { 'AAPL' => 50, 'META' => 20 }
  # - target_allocation: A Hash that defines the desired percentage distribution.
  #                      The sum of the values should be 1.0 (or 100%).
  #                      Format: { 'SYMBOL' => percentage }
  #                      Example: { 'AAPL' => 0.6, 'META' => 0.4 }
  # - stocks: A Hash that maps symbols to Stock objects to access their prices.
  #           Format: { 'SYMBOL' => <Stock Object> }
  def initialize(holdings, target_allocation, stocks)
    @holdings = holdings
    @target_allocation = target_allocation
    @stocks = stocks
  end

  # The rebalance method is the core of the logic.
  # It calculates which stocks to buy or sell to reach the target allocation.
  # It does not modify the portfolio, it only returns the recommendations.
  def rebalance
    # --- STEP 1: Calculate the current total value of the portfolio ---
    # To know what each position should be worth (e.g., 60% of what?),
    # we first need to know the total value of everything we own.
    total_portfolio_value = calculate_total_value

    # We prepare a Hash to store the final recommendations.
    recommendations = { buy: Hash.new { |hash, key| hash[key] = {} }, sell: Hash.new { |hash, key| hash[key] = {} } }

    # --- STEP 2: Iterate over each asset in our target allocation ---
    @target_allocation.each do |symbol, target_percent|
      stock = @stocks[symbol]
      # If for some reason we don't have price information for a stock, we skip it.
      next unless stock

      # --- STEP 3: Calculate the target value vs. the current value for each stock ---
      # Target value: How much money we should have invested in this stock
      # according to the desired percentage.
      target_value = total_portfolio_value * target_percent

      # Current value: How much money we actually have invested in this stock.
      # We use `|| 0` to handle the case where we own none of a target stock.
      current_quantity = @holdings[symbol] || 0
      current_value = current_quantity * stock.current_price

      # --- STEP 4: Determine the difference and generate the recommendation ---
      # The difference tells us if we need more or less money in this position.
      value_difference = target_value - current_value

      # We calculate how many shares that money difference represents.
      shares_to_transact = (value_difference / stock.current_price).abs.round(2)

      if value_difference.positive?
        # Positive difference: The current value is LESS than the target.
        # We need to BUY.
        recommendations[:buy][symbol] = {
          shares: shares_to_transact,
          amount: value_difference.round(2)
        }
      elsif value_difference.negative?
        # Negative difference: The current value is GREATER than the target.
        # We need to SELL.
        recommendations[:sell][symbol] = {
          shares: shares_to_transact,
          amount: value_difference.abs.round(2)
        }
      end
      # If the difference is 0, nothing is done for this stock.
    end

    recommendations
  end

  private

  # Helper method to calculate the total value of the portfolio.
  # It sums the value of all holdings (quantity * price).
  def calculate_total_value
    @holdings.sum do |symbol, quantity|
      stock = @stocks[symbol]
      # If the stock exists in our holdings but not in the price list,
      # its value for the calculation is 0.
      stock ? quantity * stock.current_price : 0
    end
  end
end

# --- USAGE EXAMPLE ---

# 1. Create instances of stocks with their current prices.
apple_stock = Stock.new('AAPL', 150.0) # Apple price: $150
meta_stock = Stock.new('META', 300.0)  # Meta price: $300
google_stock = Stock.new('GOOG', 130.0) # Google price: $130

# Group the stocks in a Hash for easy access to their prices.
all_stocks = {
  'AAPL' => apple_stock,
  'META' => meta_stock,
  'GOOG' => google_stock
}

# 2. Define the current state of our portfolio.
# We have 10 shares of Apple and 30 of Meta. We don't have Google.
current_holdings = {
  'AAPL' => 10, # 10 * $150 = $1,500
  'META' => 30  # 30 * $300 = $9,000
}
# Total value = $1,500 + $9,000 = $10,500

# 3. Define the allocation we WANT to have.
# We want our portfolio to be 60% Apple, 30% Meta, and 10% Google.
target = {
  'AAPL' => 0.60, # Target for AAPL: $10,500 * 0.6 = $6,300
  'META' => 0.30, # Target for META: $10,500 * 0.3 = $3,150
  'GOOG' => 0.10  # Target for GOOG: $10,500 * 0.1 = $1,050
}

# 4. Create the portfolio instance.
my_portfolio = Portfolio.new(current_holdings, target, all_stocks)

# 5. Request the rebalancing recommendations.
rebalance_plan = my_portfolio.rebalance

# --- DISPLAY RESULTS ---
puts 'Portfolio Rebalancing Plan:'
puts '---------------------------------'

puts "\n Stocks to BUY:"
rebalance_plan[:buy].each do |symbol, data|
  puts "   - #{symbol}: Buy #{data[:shares]} shares (approximately $#{data[:amount]})"
end

puts "\n Stocks to SELL:"
rebalance_plan[:sell].each do |symbol, data|
  puts "   - #{symbol}: Sell #{data[:shares]} shares (approximately $#{data[:amount]})"
end
