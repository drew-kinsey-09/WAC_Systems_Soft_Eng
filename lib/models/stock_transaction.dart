//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart: lib/models/stock_transaction.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

//class to establish a stock transaction model
//model is used to represent a stock transaction: the quantity of shares, price per share, and timestamp of the transaction.
//used to help track stock transactions in the app
class StockTransaction {
  final int quantity;
  final double pricePerShare;
  final DateTime timestamp;

  //required pieces of the transaction
  //constructor
  StockTransaction({
    required this.quantity,
    required this.pricePerShare,
    required this.timestamp,
  });

  //Converts the StockTransaction object to a JSON map
  //Source for help: https://stackoverflow.com/questions/29294019/dart-convert-map-to-json-with-all-elements-quoted
  Map<String, dynamic> toJson() => {
    'quantity': quantity,
    'pricePerShare': pricePerShare,
    // Store timestamp as ISO 8601 string for reliable serialization
    // Source: https://api.flutter.dev/flutter/dart-core/DateTime/toIso8601String.html#:~:text=The%20format%20is%20yyyy-MM,digit%20representation%20of%20the%20year.
    'timestamp': timestamp.toIso8601String(),
  };

  // Create Transaction from JSON
  // Factory constructor to create a StockTransaction instance from JSON
  // Source: https://dart.dev/language/constructors
  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      quantity: json['quantity'] as int? ?? 0,
      pricePerShare: (json['pricePerShare'] as num?)?.toDouble() ?? 0.0,
      // Parse ISO 8601 string back to DateTime
      //Source: https://api.flutter.dev/flutter/dart-core/DateTime/DateTime.parse.html#:~:text=The%20format%20is%20yyyy-MM,digit%20representation%20of%20the%20year.
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
