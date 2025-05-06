//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:alpha_vantage_service.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// This is the api we use for the stock charts
// the API key can be found in the .env file
// helpful sources: https://www.google.com/search?client=opera-gx&q=alpha+vantage+api+stock+chart+dart&sourceid=opera&ie=UTF-8&oe=UTF-8
// https://www.alphavantage.co/documentation/
// https://github.com/ferrerj/AlphaVantageDartLibrary
// https://pub.dev/packages/http
// https://github.com/topics/financial-charting-library
// https://github.com/topics/alphavantage-api
// the above sources were great inspiration and assitance in coding this

// imports for this file:
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stock_app_ver4/models/historical_stock.dart';

class AlphaVantageService {
  // --- Alpha Vantage Base URL and API Key ---
  static const String _avBaseUrl = 'https://www.alphavantage.co/query';

  // Load the API key directly here
  final String? _avApiKey = dotenv.env['ALPHA_VANTAGE_API_KEY'];

  // Helper to build Alpha Vantage authenticated URLs

  Uri _buildAlphaVantageUrl(Map<String, String> parameters) {
    if (_avApiKey == null || _avApiKey.isEmpty) {
      print("ERROR: Alpha Vantage API key is missing!");
      throw Exception(
        'Alpha Vantage API key is missing. Please add ALPHA_VANTAGE_API_KEY to your .env file.',
      );
    }
    parameters['apikey'] = _avApiKey;
    return Uri.parse(_avBaseUrl).replace(queryParameters: parameters);
  }

  // Map App Timeframes to Alpha Vantage Functions
  String _mapTimeframeToAVFunction(String timeframe) {
    switch (timeframe) {
      case '1d': // Use Daily as free tier intraday is limited
      case '1w':
      case '1m':
      case '3m':
        return 'TIME_SERIES_DAILY_ADJUSTED';
      case '6m':
      case '1y':
        return 'TIME_SERIES_WEEKLY_ADJUSTED';
      case 'max':
        return 'TIME_SERIES_MONTHLY_ADJUSTED';
      default:
        return 'TIME_SERIES_DAILY_ADJUSTED';
    }
  }

  // Get Historical Data (Using Alpha Vantage - Refined)
  Future<List<HistoricalStock>> getHistoricalData(
    String symbol, {
    String timeframe = '1y',
  }) async {
    final avFunction = _mapTimeframeToAVFunction(timeframe);
    final Map<String, String> parameters = {
      'function': avFunction,
      'symbol': symbol,
    };

    // Adjust outputsize based on timeframe
    if (['6m', '1y', 'max'].contains(timeframe)) {
      parameters['outputsize'] = 'full';
    } else {
      parameters['outputsize'] = 'compact';
    }

    final url = _buildAlphaVantageUrl(parameters);
    print("AlphaVantageService: Fetching Historical URL: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Robust Check for Alpha Vantage API errors/notes
        if (data == null || data is! Map<String, dynamic>) {
          print(
            "AlphaVantageService Error: Invalid response format (not a Map). Body: ${response.body}",
          );
          throw Exception("Invalid API response format.");
        }
        if (data.containsKey('Error Message')) {
          final errorMessage = data['Error Message'] as String;
          print("AlphaVantageService API Error: $errorMessage");
          throw Exception("API Error: $errorMessage");
        }
        if (data.containsKey('Note')) {
          final noteMessage = data['Note'] as String;
          print("AlphaVantageService API Note: $noteMessage");
          throw Exception("API Limit Reached: $noteMessage");
        }

        // Determine the correct key for time series data
        String? timeSeriesKey;
        if (avFunction == 'TIME_SERIES_DAILY_ADJUSTED') {
          timeSeriesKey = 'Time Series (Daily)';
        } else if (avFunction == 'TIME_SERIES_WEEKLY_ADJUSTED') {
          timeSeriesKey = 'Weekly Adjusted Time Series';
        } else if (avFunction == 'TIME_SERIES_MONTHLY_ADJUSTED') {
          timeSeriesKey = 'Monthly Adjusted Time Series';
        }

        if (timeSeriesKey == null ||
            !data.containsKey(timeSeriesKey) ||
            data[timeSeriesKey] == null) {
          print(
            "AlphaVantageService Warning: '$timeSeriesKey' key not found or null in response for $symbol. Response keys: ${data.keys}",
          );
          return []; // Return empty if the expected data key is missing or null
        }

        if (data[timeSeriesKey] is! Map<String, dynamic>) {
          print(
            "AlphaVantageService Warning: '$timeSeriesKey' data is not a Map. Actual type: ${data[timeSeriesKey].runtimeType}",
          );
          return [];
        }

        final Map<String, dynamic> timeSeries = data[timeSeriesKey];
        if (timeSeries.isEmpty) {
          print(
            "AlphaVantageService Warning: '$timeSeriesKey' map is empty for $symbol.",
          );
          return [];
        }

        List<HistoricalStock> historicalData = [];
        bool parsingErrorOccurred = false;

        timeSeries.forEach((dateString, values) {
          if (values is! Map<String, dynamic>) {
            print(
              "AlphaVantageService: Skipping invalid value type for date $dateString. Expected Map, got ${values.runtimeType}",
            );
            parsingErrorOccurred = true;
            return;
          }
          try {
            final date = DateTime.parse(dateString);
            final adjustedClose =
                double.tryParse(
                  values['5. adjusted close']?.toString() ?? '0.0',
                ) ??
                0.0;
            final volume =
                int.tryParse(values['6. volume']?.toString() ?? '0') ?? 0;
            final open =
                double.tryParse(values['1. open']?.toString() ?? '0.0') ?? 0.0;
            final high =
                double.tryParse(values['2. high']?.toString() ?? '0.0') ?? 0.0;
            final low =
                double.tryParse(values['3. low']?.toString() ?? '0.0') ?? 0.0;

            historicalData.add(
              HistoricalStock(
                date: date,
                open: open,
                high: high,
                low: low,
                close: adjustedClose,
                volume: volume,
              ),
            );
          } catch (parseError) {
            parsingErrorOccurred = true;
            print(
              "AlphaVantageService: Error parsing data for date $dateString: $parseError. Values: $values",
            );
          }
        });

        if (parsingErrorOccurred) {
          print(
            "AlphaVantageService: Parsing errors occurred. Returning ${historicalData.length} successfully parsed points.",
          );
        } else {
          print(
            "AlphaVantageService: Successfully parsed ${historicalData.length} data points for $symbol [$timeframe].",
          );
        }

        historicalData.sort((a, b) => a.date.compareTo(b.date));
        return historicalData;
      } else {
        print(
          "AlphaVantageService Error: Status Code ${response.statusCode}, Body: ${response.body}",
        );
        throw Exception('Failed to fetch data (HTTP ${response.statusCode})');
      }
    } catch (e) {
      print("AlphaVantageService Error: Exception during fetch/parse: $e");
      // Re-throw so the caller (chart) knows about the error
      throw Exception('Failed to load historical data: $e');
    }
  }
}
