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

      if value_difference > 0
        # Positive difference: The current value is LESS than the target.
        # We need to BUY.
        recommendations[:buy][symbol] = {
          shares: shares_to_transact,
          amount: value_difference.round(2)
        }
      elsif value_difference < 0
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


# --- DYNAMIC USAGE EXAMPLE ---

# Hashes to store the information entered by the user.
all_stocks = {}
current_holdings = {}
target = {}

puts '--- Portfolio Setup ---'
puts 'Please enter the stocks that make up your portfolio.'

# 1. Get stock information (symbol and price)
loop do
  print 'Enter the stock symbol (e.g., AAPL) or type "done" to finish: '
  symbol = gets.chomp.upcase
  break if symbol == 'DONE'

  print "Enter the current price for #{symbol}: "
  price = gets.chomp.to_f

  all_stocks[symbol] = Stock.new(symbol, price)
  puts "#{symbol} added with price $#{price}."
  puts '---------------------------------'
end

# If no stocks were added, we cannot continue.
if all_stocks.empty?
  puts 'No stocks were entered. The program will now exit.'
  exit
end

puts "\n--- Defining Current Holdings ---"
# 2. Get the current holdings for each stock
all_stocks.each_key do |symbol|
  print "Enter the number of shares you own of #{symbol}: "
  quantity = gets.chomp.to_i
  current_holdings[symbol] = quantity if quantity > 0
end

puts "\n--- Defining Target Allocation ---"
# 3. Get the target allocation
total_percentage = 0
all_stocks.each_key do |symbol|
  remaining = 100 - total_percentage
  print "Enter the target percentage for #{symbol} (remaining: #{remaining}%): "
  percent = gets.chomp.to_f

  # Validate that 100% is not exceeded
  if total_percentage + percent > 100
    puts "The total percentage cannot exceed 100. The remainder (#{remaining}%) will be assigned."
    target[symbol] = remaining / 100.0
    total_percentage = 100
    break
  end

  target[symbol] = percent / 100.0
  total_percentage += percent
end

# If the total is not 100%, the user is notified.
if total_percentage < 100
  puts "\n Warning: The sum of percentages is #{total_percentage}%, not 100%."
  puts 'The calculation will be based on this distribution.'
end

# 4. Create the portfolio instance with the dynamic data.
my_portfolio = Portfolio.new(current_holdings, target, all_stocks)

# 5. Request the rebalancing recommendations.
rebalance_plan = my_portfolio.rebalance

# --- DISPLAY RESULTS ---
puts "\n\n======================================"
puts 'Portfolio Rebalancing Plan:'
puts '======================================'

if rebalance_plan[:buy].empty? && rebalance_plan[:sell].empty?
  puts "\n Your portfolio is already balanced according to your targets!"
else
  unless rebalance_plan[:buy].empty?
    puts "\n Stocks to BUY:"
    rebalance_plan[:buy].each do |symbol, data|
      puts "   - #{symbol}: Buy #{data[:shares]} shares (approximately $#{data[:amount]})"
    end
  end

  unless rebalance_plan[:sell].empty?
    puts "\n Stocks to SELL:"
    rebalance_plan[:sell].each do |symbol, data|
      puts "   - #{symbol}: Sell #{data[:shares]} shares (approximately $#{data[:amount]})"
    end
  end
end
