//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/widgets/top_headlines.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// this file displays a list of the top news articles
// It fetches a specified number of headlines from the ApiService
// and displays them in a compact list format.
// Each headline is tappable and opens the article in an external browser.

// Helpful sources that are cited or inspired code:
// https://newsapi.org/docs
// https://pub.dev/packages/url_launcher
// https://pub.dev/packages/cached_network_image
// https://pub.dev/packages/timeago
// https://stackoverflow.com/questions/62755506/the-method-was-called-on-null-i-flutter-receiver-null-i-flutter-18112
// https://github.com/Arthur367/test

// imports for this file
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/api_service.dart';

// initializing the top headlines file
class TopHeadlines extends StatefulWidget {
  // The number of headlines to display. Defaults to 3.
  // meaning we only display three large headlines
  final int count;
  const TopHeadlines({this.count = 3, super.key});

  @override
  State<TopHeadlines> createState() => _TopHeadlinesState();
}

// State class for TopHeadlines.
// Manages the fetching and display of news headlines.
class _TopHeadlinesState extends State<TopHeadlines> {
  // Future that holds the list of fetched headline data.
  late Future<List<dynamic>> _headlinesFuture;
  // Instance of ApiService to fetch news.
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchHeadlines();
  }

  // Fetches the top headlines from the ApiService.
  // It takes the number of headlines specified by `widget.count`.
  // Updates the state to rebuild the widget with the fetched data.
  void _fetchHeadlines() {
    _headlinesFuture = _apiService.getMarketNews().then((allNews) {
      // Take only the number of headlines specified by the widget's count.
      return allNews.take(widget.count).toList();
    });
    // If the widget is still mounted, trigger a rebuild to reflect the new future.
    if (mounted) {
      setState(() {});
    }
  }

  // Launches the given URL string in an external application (typically a browser).
  // Shows a SnackBar if the URL cannot be launched.
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article link.')),
        );
      }
    }
  }

  // Formats a date value (Unix timestamp in seconds or ISO 8601 string)
  // into a relative time string (e.g., "2 hours ago").
  // Handles potential parsing errors and returns a fallback string.
  String _formatDateRelative(dynamic dateValue) {
    if (dateValue == null) return 'Date unavailable';
    try {
      DateTime dateTime;
      if (dateValue is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
      } else if (dateValue is String) {
        dateTime = DateTime.parse(dateValue);
      } else {
        return 'Invalid date';
      }
      return timeago.format(dateTime);
    } catch (e) {
      print("Error formatting date: $e, Value: $dateValue");
      return dateValue.toString();
    }
  }

  // Builds the UI for the TopHeadlines widget.
  // Uses a FutureBuilder to handle the asynchronous loading of headlines.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<dynamic>>(
      future: _headlinesFuture,
      builder: (context, snapshot) {
        // Display a loading indicator while data is being fetched.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0), // Added required padding
            child: Center(child: CircularProgressIndicator()), // Example loader
          );
        } else if (snapshot.hasError ||
            // Display a message if there's an error, no data, or data is empty.
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No headlines available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          );
        } else {
          // If data is successfully fetched, display the headlines.
          final headlines = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text('Top Headlines', style: theme.textTheme.titleLarge),
              ),
              ...headlines.map((article) => _buildHeadlineItem(article, theme)),
              const Divider(height: 16, thickness: 1),
            ],
          );
        }
      },
    );
  }

  // Builds a single headline item widget.
  // Takes the article data and the current theme.
  Widget _buildHeadlineItem(Map<String, dynamic> article, ThemeData theme) {
    // Extract data from the article map, using Finnhub API field names.
    final String title = article['headline'] ?? 'No Headline';
    final String source = article['source'] ?? 'Unknown';
    final String? url = article['url'];
    final String publishedAgo = _formatDateRelative(article['datetime']);
    final String? imageUrl = article['image'];

    print("TopHeadlines - Article: '$title', Image URL: $imageUrl");

    return InkWell(
      onTap: url != null ? () => _launchURL(url) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the article image if available.
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder:
                        (c, u) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                        ),
                    errorWidget:
                        (c, u, e) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                  ),
                ),
              ),
            // Display the article title, source, and publication time.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$source • $publishedAgo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
