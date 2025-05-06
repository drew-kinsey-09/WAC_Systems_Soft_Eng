//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/widgets/home_news_feed.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// This files displays a general feed of news articles
// This widget is used on a home screen or a dedicated news section.
// It fetches news from the ApiService and presents each article as a tappable item
// that opens the full article in an external browser.
// Includes pull-to-refresh functionality.

//Helpful Sources:
// https://newsapi.org/docs
// https://pub.dev/packages/url_launcher
// https://pub.dev/packages/cached_network_image
// https://pub.dev/packages/timeago
// https://stackoverflow.com/questions/62755506/the-method-was-called-on-null-i-flutter-receiver-null-i-flutter-18112
// https://github.com/Arthur367/test

// imports for this file:
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/api_service.dart';

// intiializing the home news feed
class HomeNewsFeed extends StatefulWidget {
  const HomeNewsFeed({super.key});

  @override
  State<HomeNewsFeed> createState() => _HomeNewsFeedState();
}

// State class for HomeNewsFeed.
// Manages the fetching of news articles, their display, and error/loading states.
class _HomeNewsFeedState extends State<HomeNewsFeed> {
  // Future that holds the list of fetched news article data.
  late Future<List<dynamic>> _newsFuture;
  // Instance of ApiService to fetch news.
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchNews(); // Initial fetch of news articles.
  }

  // Fetches market news using the ApiService.
  // Updates the `_newsFuture` and triggers a UI rebuild if the widget is still mounted.
  void _fetchNews() {
    _newsFuture = _apiService.getMarketNews();
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

  // Builds the UI for the HomeNewsFeed widget.
  // Uses a RefreshIndicator for pull-to-refresh and a FutureBuilder for asynchronous data loading.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => _fetchNews(),
      child: FutureBuilder<List<dynamic>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          // Display a loading indicator while data is being fetched.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            // If there's an error or no data, display an error widget.
            print("HomeNewsFeed Error: ${snapshot.error}");
            return _buildErrorWidget(theme);
          } else {
            // If data is successfully fetched, process and display it.
            final newsArticles = snapshot.data!;
            if (newsArticles.isEmpty) {
              // If there are no articles, display an empty state widget.
              return _buildEmptyWidget(theme);
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: newsArticles.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final article = newsArticles[index];
                // Extract data from the article map, using Finnhub API field names.
                final String title = article['headline'] ?? 'No Headline';
                final String source = article['source'] ?? 'Unknown Source';
                final String? url = article['url'];
                final String publishedAgo = _formatDateRelative(
                  article['datetime'],
                );

                // --- REMOVED PRINT STATEMENT FOR IMAGE ---
                // print("HomeNewsFeed - Article: '$title', Image URL: $imageUrl");

                // --- Updated Layout: Text Only ---
                return InkWell(
                  onTap: url != null ? () => _launchURL(url) : null,
                  child: Column(
                    // Layout for each news item: Title, then Source & Time.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
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
                );
                // --- End Updated Layout ---
              },
            );
          }
        },
      ),
    );
  }

  // Helper widget to display an error message with a retry button.
  Widget _buildErrorWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: theme.colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text('Failed to Load News', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Check connection and pull down to refresh.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchNews, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  // Helper widget to display a message when no news articles are found.
  Widget _buildEmptyWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No news articles found.', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Pull down to check again.', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
