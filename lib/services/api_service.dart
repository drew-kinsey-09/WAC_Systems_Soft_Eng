//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/services/api_service.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// This service handles fetching stock quotes, searching for stocks,
// retrieving market news, and getting company profiles.
// the API key can be found in the .env file
// helpful sources: https://www.google.com/search?client=opera-gx&q=alpha+vantage+api+stock+chart+dart&sourceid=opera&ie=UTF-8&oe=UTF-8
// Finnhub API documentation: https://finnhub.io/docs/api
// https://github.com/ferrerj/AlphaVantageDartLibrary
// https://pub.dev/packages/http
// https://github.com/topics/financial-charting-library
// https://github.com/topics/alphavantage-api
// the above sources were great inspiration and assitance in coding this

// imports for this file:
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// initializing the API service
class ApiService {
  // Base URL for all Finnhub API endpoints.
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  // API key for Finnhub, loaded from the .env file (FINNHUB_API_KEY).
  final String? _apiKey = dotenv.env['FINNHUB_API_KEY'];

  // Private helper method to construct a Finnhub API URL.
  // It takes an endpoint and parameters, then appends the API key.
  // Throws an Exception if the API key is not found in the .env file.
  Uri _buildUrl(String endpoint, Map<String, String> parameters) {
    if (_apiKey == null || _apiKey.isEmpty) {
      throw Exception(
        'Finnhub API key is missing. Please add FINNHUB_API_KEY to your .env file.',
      );
    }
    parameters['token'] = _apiKey;
    return Uri.parse('$_baseUrl$endpoint').replace(queryParameters: parameters);
  }

  // Fetches the current stock quote for a given symbol from Finnhub.
  // Returns a map containing quote data (e.g., current price, previous close).
  // Throws an Exception if the symbol is invalid (e.g., price data is zero) or if the API request fails.
  Future<Map<String, dynamic>> getStockQuote(String symbol) async {
    final url = _buildUrl('/quote', {'symbol': symbol});
    print("ApiService: Fetching Finnhub Quote URL: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("ApiService: Finnhub Quote Response for $symbol: $data");
        // Finnhub returns 0 for fields like 'c' if symbol is invalid
        if (data is Map<String, dynamic> && data['c'] == 0 && data['pc'] == 0) {
          throw Exception('Invalid symbol or no data available from Finnhub.');
        }
        return data as Map<String, dynamic>;
      } else {
        print(
          "ApiService Error (getStockQuote): Status Code ${response.statusCode}, Body: ${response.body}",
        );
        throw Exception(
          'Failed to load quote data (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      print("ApiService Error (getStockQuote): Exception: $e");
      throw Exception('Failed to load quote data: $e');
    }
  }

  // Searches for stock symbols using a query string via the Finnhub API.
  // Returns a list of search results, typically containing symbol and description.
  // Returns an empty list if the response format is unexpected.
  // Throws an Exception if the API request fails.
  Future<List<dynamic>> searchStocks(String query) async {
    final url = _buildUrl('/search', {'q': query});
    print("ApiService: Fetching Finnhub Search URL: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("ApiService: Finnhub Search Response for '$query': $data");
        if (data is Map<String, dynamic> && data.containsKey('result')) {
          return data['result'] as List<dynamic>;
        } else {
          print(
            "ApiService Warning (searchStocks): Unexpected response format - 'result' key missing.",
          );
          return [];
        }
      } else {
        print(
          "ApiService Error (searchStocks): Status Code ${response.statusCode}, Body: ${response.body}",
        );
        throw Exception(
          'Failed to search stocks (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      print("ApiService Error (searchStocks): Exception: $e");
      throw Exception('Failed to search stocks: $e');
    }
  }

  // Fetches general market news from the Finnhub API.
  // Returns a list of news articles.
  // Returns an empty list if the response format is unexpected (e.g., not a List).
  // Throws an Exception if the API request fails.
  Future<List<dynamic>> getMarketNews() async {
    final url = _buildUrl('/news', {'category': 'general'});
    print("ApiService: Fetching Finnhub News URL: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          print(
            "ApiService: Finnhub News Response: ${data.length} articles received.",
          );
          return data;
        } else {
          print(
            "ApiService Warning (getMarketNews): Unexpected response format - Expected a List.",
          );
          return [];
        }
      } else {
        print(
          "ApiService Error (getMarketNews): Status Code ${response.statusCode}, Body: ${response.body}",
        );
        throw Exception(
          'Failed to load market news (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      print("ApiService Error (getMarketNews): Exception: $e");
      throw Exception('Failed to load market news: $e');
    }
  }

  // Fetches the company profile for a given stock symbol from Finnhub.
  // Returns a map containing company profile data.
  // Returns an empty map if the profile is not found or the response is empty, allowing the caller to handle this.
  // Throws an Exception if the API request fails.
  Future<Map<String, dynamic>> getCompanyProfile(String symbol) async {
    final url = _buildUrl('/stock/profile2', {'symbol': symbol});
    print("ApiService: Fetching Finnhub Profile URL: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("ApiService: Finnhub Profile Response for $symbol: $data");
        if (data is Map<String, dynamic> && data.isNotEmpty) {
          return data;
        } else {
          print(
            "ApiService Warning (getCompanyProfile): Profile not found or empty for $symbol.",
          );
          return {};
        }
      } else {
        print(
          "ApiService Error (getCompanyProfile): Status Code ${response.statusCode}, Body: ${response.body}",
        );
        throw Exception(
          'Failed to load company profile (Status code: ${response.statusCode})',
        );
      }
    } catch (e) {
      print("ApiService Error (getCompanyProfile): Exception: $e");
      throw Exception('Failed to load company profile: $e');
    }
  }
}
