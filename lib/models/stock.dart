//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:stock.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

//Files this is imported in: stock_service.dart, stock_provider.dart, stock_screen.dart, watchlist_screen.dart, portfolio_screen.dart, stock_detail_screen.dart, news_screen.dart, home_screen.dart

//class establishment for a stock using the Finnhub API
//This class is used to represent a stock and its attributes w/ symbol, name, price, change, change percent, and previous close
class Stock {
  final String symbol;
  final String? name;
  final double price;
  final double change;
  final double changePercent;
  final double previousClose;

  // Constructor for Stock class
  Stock({
    required this.symbol,
    this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.previousClose,
  });

  // Factory constructor to create Stock instance from Finnhub JSON
  // Finnhub quote keys: c, d, dp, h, l, o, pc, t
  // Source: https://finnhub.io/docs/api/quote
  factory Stock.fromJson(Map<String, dynamic> json, {String? symbolOverride}) {
    // Helper function to safely parse double values
    // source: https://stackoverflow.com/questions/70319500/how-to-parse-dynamic-to-double-in-dart
    double safeParseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Extracting values from JSON
    // Source: https://finnhub.io/docs/api/quote
    final currentPrice = safeParseDouble(json['c']);
    final previousClosePrice = safeParseDouble(json['pc']);

    // this double value is the change in price from the previous close to the current price
    // if the previous close is 0, we set it to 0.0 to avoid division by zero
    final double changeValue =
        json['d'] != null
            ? safeParseDouble(json['d'])
            : (currentPrice != 0.0 && previousClosePrice != 0.0
                ? currentPrice - previousClosePrice
                : 0.0);

    // this double value is the percent change in price from the previous close to the current price
    double percentChangeValue =
        json['dp'] != null
            ? safeParseDouble(json['dp'])
            : (previousClosePrice != 0.0
                ? (changeValue / previousClosePrice) * 100.0
                : 0.0);

    // Stock object creation
    // Used in other files: stock_service.dart, stock_provider.dart, and stock_screen.dart
    return Stock(
      symbol: symbolOverride ?? 'UNKNOWN',
      name: null,
      price: currentPrice,
      change: changeValue,
      changePercent: percentChangeValue,
      previousClose: previousClosePrice,
    );
  }

  // Method to convert Stock object to JSON
  // We do this to store the stock object in a database or send it to an API
  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'price': price,
    'change': change,
    'changePercent': changePercent,
    'previousClose': previousClose,
  };
}
