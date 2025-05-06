//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/providers/news_provider.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Files that reference this file: news_detail_screen.dart, home_screen.dart

// This is the news screen that displays the news articles from the API, we already have a news screen on the home screen
// However, this is a one stop shop for all the news articles from the API
// new api documentation: https://newsapi.org/docs

// imports for this file:
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/api_service.dart';

// initialize the news screen
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // late variable to hold the news articles
  // source for late: https://dart.dev/null-safety/understanding-null-safety#late-variables
  late Future<List<dynamic>> _newsFuture;

  // using api_service.dart to fetch the news articles
  final ApiService _apiService = ApiService();

  // fetches news articles from the API
  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  // function that is seen above
  // uses the api_service.dart to fetch the news articles
  void _fetchNews() {
    _newsFuture = _apiService.getMarketNews();
    if (mounted) {
      setState(() {});
    }
  }

  // Using a future function to launch the URL in the default browser
  // source: https://pub.dev/packages/url_launcher
  // I thought this was a good idea because we can allow the user to open the link in the default browser
  // However, we run into issues with the actual aticles and pay walls
  Future<void> _launchURL(String urlString) async {
    // parses the url string into a Uri object
    final Uri url = Uri.parse(urlString);
    try {
      // writing an error message for the console if the url is not valid
      // helps with debugging
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        // this one is for the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the article link.')),
        );
      }
    }
  }

  // taking the date value from the api
  // code below formats it for the user and the article
  String _formatDateRelative(dynamic dateValue) {
    if (dateValue == null) return 'Date unavailable';
    try {
      // gets the date value and makes it a DateTime object
      // source for DateTime: https://api.flutter.dev/flutter/dart-core/DateTime/DateTime.fromMillisecondsSinceEpoch.html
      DateTime dateTime;
      if (dateValue is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
      } else if (dateValue is String) {
        dateTime = DateTime.parse(dateValue);
      } else {
        // error message
        return 'Invalid date';
      }
      return timeago.format(dateTime);

      // we used catch e elsewhere, its just for general error handling
      // source for catch (e): https://dart.dev/language/error-handling
      // Another helpful source: https://stackoverflow.com/questions/56803689/flutter-and-dart-try-catch-catch-does-not-fire
    } catch (e) {
      print("Error formatting date: $e, Value: $dateValue");
      return dateValue.toString();
    }
  }

  // UI build for the news screen
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // refresh indicator is a cool widget that allows the user to pull down to refresh the screen
      // source: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
      body: RefreshIndicator(
        // When we refresh we fetch the news articles again
        onRefresh: () async => _fetchNews(),
        child: FutureBuilder<List<dynamic>>(
          future: _newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData) {
              // error message for the cosnsole
              // snapshot.error is the error message from the API
              // news api documentation: https://newsapi.org/docs/endpoints/everything
              print("News Screen Error: ${snapshot.error}");
              return Center(/* ... Keep existing error widget ... */);
            } else {
              final newsArticles = snapshot.data!;
              if (newsArticles.isEmpty) {
                return Center(/* ... Keep existing empty widget ... */);
              }

              // ListView.separated allows to create a list that has seperators between the items
              // I used this because it looks better than them touching each other
              // doucmentation: https://api.flutter.dev/flutter/widgets/ListView/ListView.separated.html
              // This ne handles the news articles and displays them in a card format
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
                itemCount: newsArticles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),

                // displays the articles: image, title, source, and time since published
                itemBuilder: (context, index) {
                  final article = newsArticles[index];
                  final String? imageUrl = article['image'];
                  final String title = article['headline'] ?? 'No Headline';
                  final String source = article['source'] ?? 'Unknown Source';
                  final String? url = article['url'];
                  final String publishedAgo = _formatDateRelative(
                    article['datetime'],
                  );

                  // card widget that displays the article
                  // source for cards in case you don't know it: https://api.flutter.dev/flutter/material/Card-class.html
                  // learned this in object oriented programming
                  return Card(
                    elevation: 3.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),

                    // clip behavior is used to clip the image to the card shape (using htis for clean imaging)
                    // source: https://api.flutter.dev/flutter/material/ClipBehavior-class.html
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: url != null ? () => _launchURL(url) : null,
                      splashColor: theme.primaryColor.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // using the CachedNetworkImage package to display the image (this is a package for caching images)
                          // source: https://pub.dev/packages/cached_network_image
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) =>
                                      Container(/* ... placeholder ... */),
                              errorWidget:
                                  (context, url, error) =>
                                      Container(/* ... error widget ... */),
                              fadeInDuration: const Duration(milliseconds: 300),
                            )
                          else
                            Container(/* ... placeholder if no image ... */),

                          // placing the image in the card
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),

                                // placing the card on the page
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        source.toUpperCase(),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      publishedAgo,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
