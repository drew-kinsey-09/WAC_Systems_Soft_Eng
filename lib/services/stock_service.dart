//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/services/stock_service.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Service class dedicated to fetching historical stock data from Alpha Vantage.
// maps application-specific timeframes to Alpha Vantage API functions, and processes the JSON response into a list of HistoricalStock objects.
// Alpha Vantage API documentation: https://www.alphavantage.co/documentation/
// the API key can be found in the .env file
// helpful sources: https://www.google.com/search?client=opera-gx&q=alpha+vantage+api+stock+chart+dart&sourceid=opera&ie=UTF-8&oe=UTF-8
// https://github.com/ferrerj/AlphaVantageDartLibrary
// https://pub.dev/packages/http
// https://github.com/topics/financial-charting-library
// https://github.com/topics/alphavantage-api
// https://github.com/xmartlabs/stock/blob/main/lib/src/stock.dart
// https://github.com/NadiaAqmarina/movies_list

// imports for this file:
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stock_app_ver4/models/historical_stock.dart';

// initializing the Stock Service
class StockService {
  // Base URL for all Alpha Vantage API endpoints.
  static const String _avBaseUrl = 'https://www.alphavantage.co/query';
  // API key for Alpha Vantage, loaded from the .env file (ALPHA_VANTAGE_API_KEY).
  final String? _avApiKey = dotenv.env['ALPHA_VANTAGE_API_KEY'];

  // Private helper method to construct an Alpha Vantage API URL.
  // It takes API parameters and appends the API key.
  // Throws an Exception if the API key is not found in the .env file.
  Uri _buildAlphaVantageUrl(Map<String, String> parameters) {
    if (_avApiKey == null || _avApiKey.isEmpty) {
      throw Exception(
        'Alpha Vantage API key is missing. Please add ALPHA_VANTAGE_API_KEY to your .env file.',
      );
    }
    parameters['apikey'] = _avApiKey;
    return Uri.parse(_avBaseUrl).replace(queryParameters: parameters);
  }

  // Maps user-friendly timeframes (e.g., '1d', '1y') to specific Alpha Vantage API function names.
  // This is necessary because Alpha Vantage uses different 'function' parameters
  // for daily, weekly, and monthly time series data.
  String _mapTimeframeToAVFunction(String timeframe) {
    //Source: https://www.alphavantage.co/documentation/
    switch (timeframe) {
      case '1d':
      case '1w':
      case '1m':
      case '3m':
        return 'TIME_SERIES_DAILY_ADJUSTED'; // Use daily for up to 3m
      case '6m':
      case '1y':
        return 'TIME_SERIES_WEEKLY_ADJUSTED'; // Use weekly for 6m/1y
      case 'max':
        return 'TIME_SERIES_MONTHLY_ADJUSTED'; // Use monthly for max
      default:
        return 'TIME_SERIES_DAILY_ADJUSTED';
    }
  }

  // Fetches historical stock data for a given symbol and timeframe from Alpha Vantage.
  // Returns a list of `HistoricalStock` objects, sorted by date in ascending order.
  // Returns an empty list if data is unavailable, an API error occurs, or parsing fails.
  // Throws an Exception if the API key is missing or if a critical API error occurs (e.g., limit reached).
  Future<List<HistoricalStock>> getHistoricalData(
    String symbol, {
    String timeframe = '1y',
  }) async {
    final avFunction = _mapTimeframeToAVFunction(timeframe);
    final Map<String, String> parameters = {
      'function': avFunction,
      'symbol': symbol,
    };

    // Adjust outputsize based on timeframe for potentially more data
    if (['6m', '1y', 'max'].contains(timeframe)) {
      parameters['outputsize'] = 'full';
    } else {
      parameters['outputsize'] = 'compact'; // Compact for daily views
    }

    final url = _buildAlphaVantageUrl(parameters);
    print("StockService (AlphaVantage): Fetching Historical URL: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for specific Alpha Vantage API error messages or notes in the response.
        if (data['Error Message'] != null) {
          print("StockService (AlphaVantage) Error: ${data['Error Message']}");
          throw Exception("API Error: ${data['Error Message']}");
        }
        if (data['Note'] != null) {
          print("StockService (AlphaVantage) Note: ${data['Note']}");
          // This often indicates hitting the API call limit on free tiers.
          throw Exception("API Limit Note: ${data['Note']}");
        }

        // Determine the correct key for time series data
        String timeSeriesKey;
        if (avFunction == 'TIME_SERIES_DAILY_ADJUSTED') {
          timeSeriesKey = 'Time Series (Daily)';
        } else if (avFunction == 'TIME_SERIES_WEEKLY_ADJUSTED') {
          timeSeriesKey = 'Weekly Adjusted Time Series';
        } else if (avFunction == 'TIME_SERIES_MONTHLY_ADJUSTED') {
          timeSeriesKey = 'Monthly Adjusted Time Series';
        } else {
          throw Exception('Unknown Alpha Vantage function mapping.');
        }

        if (data[timeSeriesKey] == null) {
          print(
            "StockService (AlphaVantage) Warning: '$timeSeriesKey' key not found in response for $symbol.",
          );
          return []; // Return empty if the expected data key is missing
        }

        final Map<String, dynamic> timeSeries = data[timeSeriesKey];
        List<HistoricalStock> historicalData = [];
        bool parsingErrorOccurred = false;

        timeSeries.forEach((dateString, values) {
          try {
            final date = DateTime.parse(dateString);
            final adjustedClose =
                double.tryParse(values['5. adjusted close'] ?? '0.0') ?? 0.0;
            final volume = int.tryParse(values['6. volume'] ?? '0') ?? 0;
            final open = double.tryParse(values['1. open'] ?? '0.0') ?? 0.0;
            final high = double.tryParse(values['2. high'] ?? '0.0') ?? 0.0;
            final low = double.tryParse(values['3. low'] ?? '0.0') ?? 0.0;

            historicalData.add(
              HistoricalStock(
                date: date,
                open: open,
                high: high,
                low: low,
                close:
                    adjustedClose, // Adjusted close is typically used for plotting.
                volume: volume,
              ),
            );
          } catch (parseError) {
            parsingErrorOccurred = true;
            print(
              "StockService (AlphaVantage): Error parsing data for date $dateString: $parseError",
            );
          }
        });

        if (parsingErrorOccurred) {
          print(
            "StockService (AlphaVantage): Parsing errors occurred. Returning ${historicalData.length} successfully parsed points.",
          );
        } else {
          print(
            "StockService (AlphaVantage): Successfully parsed ${historicalData.length} data points for $symbol [$timeframe].",
          );
        }

        // Alpha Vantage API returns data with the newest date first.
        // Sort the data by date in ascending order (oldest first) for chart display.
        historicalData.sort((a, b) => a.date.compareTo(b.date));
        return historicalData;
      } else {
        print(
          "StockService Error (AlphaVantage): Status Code ${response.statusCode}, Body: ${response.body}",
        );
        return []; // Return an empty list on HTTP errors to allow the UI to handle it gracefully.
      }
    } catch (e) {
      print("StockService Error (AlphaVantage): Exception: $e");
      // Depending on the error, re-throwing might be appropriate if the caller needs to know.
      return []; // Return an empty list on general exceptions.
    }
  }
}
