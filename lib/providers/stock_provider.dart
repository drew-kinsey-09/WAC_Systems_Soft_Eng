//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:stock_provider.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

//FILES this is imported into: home_screen.dart, stock_detail_screen.dart, watchlist_summary.dart, home_news_feed.dart, stock_card.dart

//imports for this file
import 'package:flutter/material.dart'; // For ChangeNotifier
import 'package:stock_app_ver4/models/historical_stock.dart'; // For HistoricalStock model
import 'package:stock_app_ver4/models/stock.dart'; // For Stock model
import 'package:stock_app_ver4/providers/portfolio_provider.dart'; // For PortfolioProvider
import 'package:stock_app_ver4/services/api_service.dart'; // For ApiService
import 'package:stock_app_ver4/services/stock_service.dart'; // For StockService
import 'dart:async'; // For DateTime

// provider handles stock data, including fetching quotes, profiles, and historical data.
class StockProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StockService _stockService = StockService();
  final PortfolioProvider? _portfolioProvider;

  // Caches for quote and profile data
  // The caches are used to store the results of API calls to avoid unnecessary network requests.
  // We do this becuase we only have so many API calls we can make in a given time period.
  // Source: https://finnhub.io/docs/api#stock-price-data
  final Map<String, ({Stock stock, DateTime timestamp})> _quoteCache = {};
  final Duration _quoteCacheDuration = const Duration(minutes: 2);
  final Map<String, ({Map<String, dynamic> profile, DateTime timestamp})>
  _profileCache = {};
  final Duration _profileCacheDuration = const Duration(hours: 24);

  // Caches for historical data
  // Error message if data is not available
  final Map<String, Map<String, List<HistoricalStock>>> _historicalData = {};
  bool _isLoadingHistorical = false;
  String? _historicalErrorMessage;

  // Error message for general errors
  String _error = '';

  // Getters for the provider
  // Source: https://pub.dev/packages/provider
  String get error => _error;
  ApiService get apiService => _apiService;
  double get currentCash => _portfolioProvider?.cash ?? 0.0;
  Map<String, Map<String, List<HistoricalStock>>> get historicalData =>
      _historicalData;
  bool get isLoadingHistoricalData => _isLoadingHistorical;
  String? get historicalDataErrorMessage => _historicalErrorMessage;

  StockProvider(this._portfolioProvider) {
    if (_portfolioProvider == null) {
      print(
        "Warning: StockProvider created without a PortfolioProvider instance.",
      );
    }
  }

  // future method to fetch stock data
  // using the Finnhub API
  // source: https://finnhub.io/docs/api#stock-price-data
  Future<String?> _getCachedOrFetchName(String symbol) async {
    final cachedProfile = _profileCache[symbol];
    final now = DateTime.now();

    if (cachedProfile != null &&
        now.difference(cachedProfile.timestamp) < _profileCacheDuration) {
      return cachedProfile.profile['name'] as String?;
    }

    // Check if the profile is already cached but expired
    // If so, we can try to fetch it again
    try {
      print("StockProvider: Fetching profile for $symbol name (Finnhub)");
      final profileData = await _apiService.getCompanyProfile(symbol);
      if (profileData.isEmpty) return null; // Handle empty profile response
      _profileCache[symbol] = (profile: profileData, timestamp: now);
      return profileData['name'] as String?;
    } catch (e) {
      print("StockProvider: Failed to fetch profile for $symbol name: $e");
      return null;
    }
  }

  // Fetches the stock quote and profile data for a given symbol
  Future<Stock?> getCachedOrFetchQuote(String symbol) async {
    final cachedData = _quoteCache[symbol];
    final now = DateTime.now();

    if (cachedData != null &&
        now.difference(cachedData.timestamp) < _quoteCacheDuration) {
      print("StockProvider: Using cached quote for $symbol");
      // If name is missing in cache, try fetching it again (less frequent)
      if (cachedData.stock.name == null) {
        final name = await _getCachedOrFetchName(symbol);
        if (name != null) {
          final updatedStock = Stock(
            symbol: cachedData.stock.symbol,
            name: name,
            price: cachedData.stock.price,
            change: cachedData.stock.change,
            changePercent: cachedData.stock.changePercent,
            previousClose: cachedData.stock.previousClose,
          );
          _quoteCache[symbol] = (
            stock: updatedStock,
            timestamp: cachedData.timestamp,
          );
          return updatedStock;
        }
      }
      return cachedData.stock;
    }

    print("StockProvider: Fetching fresh quote for $symbol (Finnhub)");
    try {
      // Fetch quote and profile concurrently
      final results = await Future.wait([
        _apiService.getStockQuote(symbol),
        _getCachedOrFetchName(symbol),
      ]);

      // Check if the results are valid
      final quoteData = results[0] as Map<String, dynamic>;
      final name = results[1] as String?;

      // Check for invalid quote data (Finnhub returns 0s)
      if (quoteData['c'] == 0 && quoteData['pc'] == 0 && quoteData['t'] == 0) {
        print(
          "StockProvider: Received zero values for $symbol quote, likely invalid symbol or no data.",
        );
        return null;
      }

      // Check if the quote data is empty
      // If so, return null
      final stock = Stock.fromJson(quoteData, symbolOverride: symbol);

      // Create final stock object with name
      final finalStock = Stock(
        symbol: stock.symbol,
        name: name,
        price: stock.price,
        change: stock.change,
        changePercent: stock.changePercent,
        previousClose: stock.previousClose,
      );

      // Check if the final stock object is valid
      // If so, cache it
      _quoteCache[symbol] = (stock: finalStock, timestamp: now);
      return finalStock;
    } catch (e) {
      print("StockProvider: Error fetching quote/profile for $symbol: $e");
      return null;
    }
  }

  // Future function is used to fetch stock data from the Finnhub API
  // Source: https://finnhub.io/docs/api#stock-price-data
  // its async because it takes time to fetch the data from the API
  // async source: https://dart.dev/codelabs/async-await#async-await
  Future<List<dynamic>> searchStocks(String query) async {
    try {
      _error = '';
      final results = await _apiService.searchStocks(query);
      // Map Finnhub response to the structure expected by SearchScreen
      return results.map((item) {
        return {'1. symbol': item['symbol'], '2. name': item['description']};
      }).toList();
    } catch (e) {
      _error = 'Error searching stocks: $e';
      print(_error);
      return [];
    }
  }

  // add a stock to the portfolio
  // this method is called when the user clicks the buy button on the stock detail screen
  Future<bool> addToPortfolio(Stock stock, int quantity) async {
    print(
      "StockProvider: addToPortfolio called for ${stock.symbol}, Qty: $quantity",
    );

    // Check if the stock is already in the portfolio
    // If so we add to the existing quantity
    if (_portfolioProvider == null) {
      _error = "Portfolio service is unavailable.";
      print("StockProvider Error: PortfolioProvider instance is NULL.");
      notifyListeners();
      return false;
    }
    _error = '';

    // using lots of print statements to debug the code
    print("StockProvider: Calling _portfolioProvider.buyStock...");
    bool success = await _portfolioProvider.buyStock(
      stock.symbol,
      quantity,
      stock.price,
    );
    print("StockProvider: _portfolioProvider.buyStock returned: $success");

    // Check if the purchase was successful
    if (success) {
      print("StockProvider: buyStock successful.");

      // Update cache with the stock (which now includes name if fetched)
      _quoteCache[stock.symbol] = (stock: stock, timestamp: DateTime.now());
      return true;
    } else {
      _error = _portfolioProvider.errorMessage ?? "Purchase failed.";
      print("StockProvider: buyStock failed. Error: $_error");
      notifyListeners();
      return false;
    }
  }

  // remove a stock from the portfolio
  // this method is called when the user clicks the sell button on the stock detail screen
  // source: https://finnhub.io/docs/api#stock-price-data
  // helpful link: https://www.freecodecamp.org/news/how-to-use-the-finnhub-api-with-flutter/
  // another: https://github.com/topics/financial-charting-library
  Future<void> fetchHistoricalData(String symbol, String timeframe) async {
    // Cache Check
    if (_historicalData[symbol]?[timeframe] != null && !_isLoadingHistorical) {
      print(
        "StockProvider: Using cached historical data for $symbol [$timeframe]",
      );
      // Clear error if data exists in cache
      if (_historicalErrorMessage != null &&
          _historicalErrorMessage!.contains(symbol)) {
        _historicalErrorMessage = null;
        // notifyListeners(); // Optional: Notify if UI needs to react to error clearing
      }
      return;
    }

    // Loading Check
    if (_isLoadingHistorical) {
      print(
        "StockProvider: Already loading historical data, skipping fetch for $symbol [$timeframe]",
      );
      return;
    }

    _isLoadingHistorical = true;
    _historicalErrorMessage =
        null; // Clear previous error for this fetch attempt
    notifyListeners(); // Notify UI: Loading started

    try {
      print(
        "StockProvider: Fetching historical data for $symbol [$timeframe] via StockService (AlphaVantage)",
      );
      // Call StockService which uses Alpha Vantage
      final data = await _stockService.getHistoricalData(
        symbol,
        timeframe: timeframe,
      );

      // Store fetched data
      _historicalData[symbol] ??= {};
      _historicalData[symbol]![timeframe] = data;

      // Handle empty data from service
      if (data.isEmpty) {
        print(
          "StockProvider: Received empty historical data for $symbol [$timeframe] from StockService.",
        );
        // Set error message if data is empty after successful fetch (e.g., API limit hit, no data available)
        _historicalErrorMessage =
            "No data available for $symbol [$timeframe]. May be API limit.";
      } else {
        print(
          "StockProvider: Successfully fetched ${data.length} historical data points for $symbol [$timeframe]",
        );
        // Clear error message on successful fetch with data
        _historicalErrorMessage = null;
      }
    } catch (e) {
      // Catch errors from StockService (e.g., API key missing, network error, API error note)
      print(
        "StockProvider: Error fetching historical data for $symbol [$timeframe]: $e",
      );
      _historicalErrorMessage = e.toString(); // Store the error message
      // Ensure data for this entry is cleared or set to empty on error
      _historicalData[symbol] ??= {};
      _historicalData[symbol]![timeframe] = [];
    } finally {
      _isLoadingHistorical = false;
      notifyListeners(); // Notify UI: Loading finished (success or error)
    }
  }
}
