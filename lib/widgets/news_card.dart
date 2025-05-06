//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: news_card.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// FILES that reference this file: news_card.dart, home_news_feed.dart

// this file is a widget that creates a display card for a news article

// imports for this file:
import 'package:flutter/material.dart';
import '../models/news.dart';

// initializing the NewsCard class
class NewsCard extends StatelessWidget {
  final News news;

  // requiring a news object from out models/news.dart file
  const NewsCard({super.key, required this.news});

  // Builds a simple card with a title, image, and source
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        leading:
            news.imageUrl.isEmpty
                ? Icon(Icons.image, size: 50)
                : Image.network(news.imageUrl, width: 50, fit: BoxFit.cover),
        title: Text(news.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(news.source),
        isThreeLine: true,

        // opens the article in a webview when tapped
        onTap: () {},
      ),
    );
  }
}
