//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: lib/models/historical_stock.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Class to represent historical stock data
// This class is used to parse the JSON response from Alpha Vantage API for historical stock data
class HistoricalStock {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  //requirements for the constructor
  HistoricalStock({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  //Factory constructor is used to create an instance of HistoricalStock from a JSON object
  //Source: https://dart.dev/language/constructors
  factory HistoricalStock.fromJson(Map<String, dynamic> json) {
    return HistoricalStock(
      date: DateTime.parse(json['date']),
      open: double.parse(json['1. open']),
      high: double.parse(json['2. high']),
      low: double.parse(json['3. low']),
      close: double.parse(json['4. close']),
      volume: int.parse(json['5. volume']),
    );
  }
}
