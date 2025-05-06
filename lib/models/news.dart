//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/models/news.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Class to represent news articles
class News {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;

  //requirements for the constructor
  News({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
  });

  // Factory constructor to create an instance of News from a JSON object
  // Source: https://dart.dev/language/constructors
  // We use the JSON objects to store the data in the News class
  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? '',
      source: json['source']['name'] ?? 'Unknown Source',
    );
  }
}
