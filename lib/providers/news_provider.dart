//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/providers/news_provider.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Files that reference this: news_screen.dart, news_detail_screen.dart, home_screen.dart

// This file is used to fetch news articles from the News API and provide them to the app

// imports for this file:
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/news.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// establish a NewsProvider class
// source for new api: https://newsapi.org/docs/endpoints/everything
class NewsProvider with ChangeNotifier {
  List<News> _newsList = [];
  bool _isLoading = false;
  String? _error;

  List<News> get newsList => _newsList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Future async function to fetch news articles from the News API
  // News API key is stored in the .env file
  Future<void> fetchNews() async {
    try {
      _isLoading = true;

      // notifyListeners is a function that notifies other widgets that the state has changed
      // source: https://api.flutter.dev/flutter/foundation/ChangeNotifier/notifyListeners.html
      // its from the html package
      notifyListeners();

      // dotenv is used to load the .env file and get the API key
      // source: https://pub.dev/packages/flutter_dotenv
      final response = await http.get(
        Uri.parse(
          'https://newsapi.org/v2/top-headlines?country=us&apiKey=${dotenv.env['NEWS_API_KEY']}',
        ),
      );

      // check if the response is successful
      // assist code: https://stackoverflow.com/questions/71786264/flutter-status-code-200-when-i-use-http-post
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<News> loadedNews = [];

        for (var item in data['articles']) {
          loadedNews.add(News.fromJson(item));
        }

        _newsList = loadedNews;
      } else {
        _error = 'Failed to load news';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
