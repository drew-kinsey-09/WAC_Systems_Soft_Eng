//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/widgets/watchlist_summary.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// This file is a:
// StatefulWidget that displays a summary of stocks in a user's watchlist.
// It fetches stock data for a predefined list of symbols and displays
// their current price and percentage change.
// Tapping on a stock in the watchlist navigates to the StockDetailScreen.
// Includes functionality to refresh the watchlist data.

// Lots of sources that helped to write this file:
// Source: https://github.com/21satvik/F-square-media-ios
// Source: https://github.com/RabbitRk/dribbble_challenges
// Source: https://github.com/0r0loo/flutter-study-calendar
// Source: https://github.com/PhucDevbu/coin_tracking
// Source: https://stackoverflow.com/questions/74078755/how-to-draw-polyline-in-google-maps-flutter-between-user-location-and-a-marker-i

// imports for this file:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app_ver4/models/stock.dart';
import 'package:stock_app_ver4/providers/stock_provider.dart';
import 'package:stock_app_ver4/screens/stock_detail_screen.dart';
import 'dart:async';
import 'package:intl/intl.dart';

// initializing the Watchlist Summary
class WatchlistSummary extends StatefulWidget {
  const WatchlistSummary({super.key});

  @override
  State<WatchlistSummary> createState() => _WatchlistSummaryState();
}

// State class for WatchlistSummary.
// Manages the list of watchlist symbols, fetched stock data, loading state, and error handling.
class _WatchlistSummaryState extends State<WatchlistSummary> {
  // A predefined list of stock symbols for the watchlist.
  // In a real application, this would likely be user-configurable and persisted.
  final List<String> _watchlistSymbols = [
    'AAPL',
    'GOOGL',
    'TSLA',
    'MSFT',
    'NVDA',
  ];

  // Holds the fetched stock data, mapping symbol to Stock object.
  Map<String, Stock> _watchlistData = {};
  // Indicates if data is currently being fetched.
  bool _isLoading = false;
  // Stores any error message that occurred during data fetching.
  String? _error;

  // Formatter for displaying percentage changes.
  final percentFormatter = NumberFormat("#,##0.00'%'", "en_US");
  // Formatter for displaying currency values.
  final currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  @override
  void initState() {
    super.initState();
    // Fetch data after the first frame is rendered to ensure context is available
    // and to avoid doing heavy work during the initial build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchWatchlistData();
      }
    });
  }

  // Asynchronously fetches stock data for all symbols in the watchlist.
  // Uses StockProvider to get cached or fetch new data.
  // Updates the state with fetched data or an error message.
  Future<void> _fetchWatchlistData() async {
    if (!mounted || _isLoading) {
      return; // Prevent multiple simultaneous fetches or fetches if widget is disposed.
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    Map<String, Stock> fetchedData = {};
    String? firstError;

    for (final symbol in _watchlistSymbols) {
      if (!mounted) break;
      // Attempt to fetch data for each symbol.
      try {
        print("Watchlist: Getting quote for $symbol (may use cache)");
        final stock = await stockProvider.getCachedOrFetchQuote(symbol);
        if (!mounted) break;
        if (stock != null) {
          fetchedData[symbol] = stock;
        } else {
          // Store the first error encountered to display to the user.
          firstError ??= 'Failed to load $symbol';
          print(
            'Watchlist: Failed to get quote for $symbol from StockProvider.',
          );
        }
      } catch (e) {
        // Handle network or other exceptions during fetching.
        if (!mounted) break;
        firstError ??= 'Network error';
        print("Watchlist: Error getting quote for $symbol: $e");
      }
    }

    if (mounted) {
      // Update the state with the fetched data and reset loading/error states.
      setState(() {
        _watchlistData = {..._watchlistData, ...fetchedData};
        _isLoading = false;
        _error = firstError;
      });
    }
  }

  // Builds the UI for the watchlist summary.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Watchlist Header ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Watchlist',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Show refresh button or loading indicator.
              if (!_isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh Watchlist',
                  onPressed: _fetchWatchlistData,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        // Display an error message if one occurred and not currently loading.
        if (_error != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Text(
              "Note: $_error",
              style: TextStyle(color: Colors.orange[700], fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // --- Watchlist Body ---
        Expanded(
          child: Builder(
            // Builder is used here to ensure the context for ListView is correct.
            builder: (context) {
              // Display loading indicator if loading and no data is yet available.
              if (_isLoading && _watchlistData.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              } else if (!_isLoading &&
                  _watchlistData.isEmpty &&
                  _watchlistSymbols.isNotEmpty) {
                // Display error widget if loading failed and watchlist is supposed to have items.
                return _buildErrorWidget(
                  'Could not load watchlist data.',
                  theme,
                );
              } else if (_watchlistSymbols.isEmpty) {
                return const Center(
                  child: Text(
                    // Message for an empty watchlist.
                    'Watchlist is empty.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              } else {
                // --- Watchlist ListView ---
                return ListView.separated(
                  itemCount: _watchlistSymbols.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  separatorBuilder:
                      (_, __) => const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final symbol = _watchlistSymbols[index];
                    final stock = _watchlistData[symbol];

                    // Display logic for each watchlist item.
                    if (stock == null) {
                      // Show placeholder if stock data hasn't loaded yet or failed for this specific stock.
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                        ),
                        title: Text(
                          symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Text(
                          _isLoading ? '...' : 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: null,
                      );
                    } else {
                      // Display the actual stock data if available.
                      final color =
                          stock.change >= 0 ? Colors.green : Colors.red;
                      final String formattedPercent = percentFormatter.format(
                        stock.changePercent / 100,
                      );
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                        ),
                        title: Text(
                          stock.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        // Display stock name if available.
                        subtitle:
                            stock.name != null
                                ? Text(
                                  stock.name!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                )
                                : null,
                        // Display stock price and percentage change.
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormatter.format(stock.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedPercent,
                              style: TextStyle(color: color, fontSize: 12),
                            ),
                          ],
                        ),
                        // Navigate to StockDetailScreen on tap.
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      StockDetailScreen(symbol: stock.symbol),
                            ),
                          );
                        },
                      );
                    }
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // Helper widget to display an error message with a retry button.
  Widget _buildErrorWidget(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 30),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchWatchlistData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
