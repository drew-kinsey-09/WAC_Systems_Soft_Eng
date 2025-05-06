//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:search_screen.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

//this is the file for searching for stocks by name or symbol

// imports for this file:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stock_app_ver4/models/stock.dart';
import 'package:stock_app_ver4/providers/stock_provider.dart';
import 'package:stock_app_ver4/providers/portfolio_provider.dart';
import 'package:stock_app_ver4/screens/stock_detail_screen.dart';
import 'dart:async';

// initializing the SearchScreen
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Controller for the search input TextField.
  // Allows reading the text and clearing it.
  // See: https://api.flutter.dev/flutter/widgets/TextEditingController-class.html

  final TextEditingController _searchController = TextEditingController();

  // List to hold the search results fetched from the API.
  // It's dynamic because the API might return a list of maps.
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  // String to store any error message that occurs during search.
  // If not null, this message is displayed to the user.
  String? _errorMessage;

  // Timer used to implement debouncing for the search input.
  // Debouncing delays the execution of the search API call until the user
  // has stopped typing for a specified duration, reducing API load.
  // See: https://api.flutter.dev/flutter/dart-async/Timer-class.html
  Timer? _debounce;

  // Map to store the desired purchase quantity for each stock symbol found in search results.
  // Key: Stock symbol (String), Value: Quantity (int)
  final Map<String, int> _searchQuantities = {};

  // Formatter for displaying currency values in a user-friendly format (e.g., $1,234.56).
  // Source: https://pub.dev/packages/intl
  final currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );

  @override
  void dispose() {
    // It's crucial to dispose of controllers and cancel timers when the State object
    // is removed from the tree permanently to prevent memory leaks.
    // See: https://api.flutter.dev/flutter/widgets/State/dispose.html

    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Seach input change handler.
  // source: https://api.flutter.dev/flutter/material/TextField/onChanged.html
  void _onSearchChanged(String query) {
    // If a debounce timer is already active, cancel it.
    // This ensures that we only act on the latest state of the input after a pause.
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start a new timer. The search will be performed after 500ms if the user stops typing.
    // we do this to give lively feedback to the user while they are typing.
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Check if the widget is still mounted before proceeding, especially after an async delay.
      // Source: https://api.flutter.dev/flutter/widgets/State/mounted.html
      if (query.isNotEmpty && mounted) {
        _performSearch(query);
      } else if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
          _errorMessage = null;
          _searchQuantities.clear();
        });
      }
    });
  }

  //Performs the actual stock search using the `StockProvider`.
  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchQuantities.clear();
    });

    try {
      // Fetch the search results from the StockProvider.
      // Source: https://pub.dev/packages/provider#providerofcontext-listen-false
      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final results = await stockProvider.searchStocks(query);

      // Check `mounted` again after the asynchronous API call.
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          if (results.isEmpty) {
            _errorMessage = "No results found for '$query'.";
          } else {
            for (var result in results) {
              // The API returns results with keys like '1. symbol'.
              // finnhub API source: https://finnhub.io/docs/api/stock-symbols

              final String symbol = result['1. symbol'] ?? 'N/A';
              if (symbol != 'N/A') {
                _searchQuantities[symbol] = 1;
              }
            }
          }
        });
      }
    } catch (e) {
      // If an error occurs during the search.
      // source: https://dart.dev/language/error-handling
      if (mounted) {
        setState(() {
          _errorMessage = 'Error searching: ${e.toString()}';
          _isLoading = false;
          _searchResults = [];
          _searchQuantities.clear();
        });
      }
    }
  }

  // search quantity control function
  void _incrementSearchQuantity(String symbol) {
    setState(() {
      // it defaults to 1 before incrementing.
      _searchQuantities[symbol] = (_searchQuantities[symbol] ?? 1) + 1;
    });
  }

  // Decrements the quantity for a given stock symbol, ensuring it doesn't go below 1.
  void _decrementSearchQuantity(String symbol) {
    // Only decrement if the current quantity is greater than 1.
    if ((_searchQuantities[symbol] ?? 1) > 1) {
      setState(() {
        _searchQuantities[symbol] = (_searchQuantities[symbol] ?? 1) - 1;
      });
    }
  }

  // Buy dialog function
  Future<void> _showSearchBuyDialog(String symbol, String name) async {
    // Show a loading indicator immediately while fetching the current stock price.
    // `barrierDismissible: false` prevents the user from closing the dialog by tapping outside.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(
      context,
      listen: false,
    );

    // Fetch the latest quote for the stock. This might involve an API call.
    final Stock? stock = await stockProvider.getCachedOrFetchQuote(symbol);
    Navigator.of(context).pop();
    if (!mounted) return;
    if (stock == null) {
      // If fetching the stock price failed, show an error message.
      // good for debugging and user experience.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch current price. Please try again.'),
          backgroundColor: Colors.orange, // Use a warning color.
        ),
      );
      return;
    }

    // Get the quantity pre-selected by the user in the search list, or default to 1.
    final int initialQuantity = _searchQuantities[symbol] ?? 1;
    // Controller for the quantity TextField within the dialog.
    final quantityController = TextEditingController(text: '$initialQuantity');
    // Calculate initial estimated cost.
    double estimatedCost = stock.price * initialQuantity;

    // Show the actual buy confirmation dialog.
    showDialog(
      context: context,
      builder: (ctx) {
        // `StatefulBuilder` is used here to manage state local to the dialog (estimatedCost)
        // without needing a separate StatefulWidget for the dialog content.
        // This allows the 'Est. Cost' to update as the user types in the quantity.
        // See: https://api.flutter.dev/flutter/widgets/StatefulBuilder-class.html
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Buy $symbol'),
              content: Column(
                mainAxisSize:
                    MainAxisSize
                        .min, // So the column takes minimum vertical space.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Current Price: ${currencyFormatter.format(stock.price)}',
                  ),
                  Text(
                    'Available Cash: ${currencyFormatter.format(portfolioProvider.cash)}',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity to Buy',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    // `FilteringTextInputFormatter.digitsOnly` ensures only numbers can be entered.
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 0;
                      // Update the dialog's local state (estimatedCost) when quantity changes.
                      setDialogState(() {
                        estimatedCost = quantity * stock.price;
                      });
                      // Also update the underlying `_searchQuantities` map for consistency
                      // if the user changes quantity in the dialog.
                      if (quantity > 0) {
                        // This ensures that if the dialog is cancelled, the quantity
                        // selected in the dialog persists in the search list item.
                        _searchQuantities[symbol] = quantity;
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Est. Cost: ${currencyFormatter.format(estimatedCost)}'),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed:
                      () =>
                          Navigator.of(
                            ctx,
                          ).pop(), // Use dialog's context `ctx`.
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Visual cue for a positive action.
                  ),
                  child: const Text('Confirm Buy'),
                  onPressed: () async {
                    final quantity = int.tryParse(quantityController.text);

                    // Validate quantity.
                    if (quantity == null || quantity <= 0) {
                      Navigator.of(ctx).pop(); // Close dialog.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid quantity.'),
                        ),
                      );
                      return;
                    }

                    // Validate if user has enough cash.
                    if (estimatedCost > portfolioProvider.cash) {
                      Navigator.of(ctx).pop(); // Close dialog.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Not enough cash.')),
                      );
                      return;
                    }

                    // Close the dialog *before* the async purchase operation.
                    // This provides immediate feedback to the user.
                    Navigator.of(ctx).pop();

                    // Perform the purchase operation using the StockProvider.
                    final success = await stockProvider.addToPortfolio(
                      stock, // The fetched Stock object with current price.
                      quantity,
                    );

                    // Check `mounted` again after the async operation.
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Purchase successful!'
                                : 'Purchase failed: ${stockProvider.error}',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      // If purchase was successful, reset the quantity for this symbol
                      // in the search list back to 1 (or a preferred default).
                      if (success) {
                        setState(() {
                          _searchQuantities[symbol] = 1;
                        });
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  // --- End Buy Dialog ---

  @override
  Widget build(BuildContext context) {
    // The Scaffold provides the basic structure for a Material Design screen.
    // See: https://api.flutter.dev/flutter/material/Scaffold-class.html
    return Scaffold(
      // Using a Column to arrange the search bar at the top and results below.
      body: Column(
        children: <Widget>[
          // Search input field.
          Padding(
            padding: const EdgeInsets.all(16.0), // Standard padding.
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by symbol or name',
                hintText: 'e.g., AAPL or Apple',
                prefixIcon: const Icon(
                  Icons.search,
                ), // Icon inside the TextField.
                // Show a clear button (suffixIcon) only if there's text.
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear(); // Clear the text.
                            _onSearchChanged(
                              '',
                            ); // Trigger search with empty query to clear results.
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  // Rounded corners for the border.
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _onSearchChanged, // Callback for text changes.
            ),
          ),

          // Conditional UI rendering based on state:
          if (_isLoading)
            // Show a loading indicator if a search is in progress.
            // `Expanded` ensures it takes available space if other elements are small.
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            // Show an error message if one exists.
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!, // `!` is safe due to the `_errorMessage != null` check.
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ), // Subdued color for error.
                  ),
                ),
              ),
            )
          else
            // Display the search results in a ListView.
            // `Expanded` makes the ListView take up the remaining vertical space.
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  // Safely access properties from the search result map.
                  // The API returns data with specific keys like '1. symbol'.
                  final String symbol = result['1. symbol'] ?? 'N/A';
                  final String name = result['2. name'] ?? 'Unknown Name';

                  // Get the current quantity selected for this item from our local state map.
                  final int currentQuantity = _searchQuantities[symbol] ?? 1;

                  return ListTile(
                    title: Text(symbol),
                    subtitle: Text(name),
                    // --- MODIFIED TRAILING WIDGET ---
                    // A Row widget to hold quantity controls and the buy button.
                    // `mainAxisSize: MainAxisSize.min` makes the Row take up only as much
                    // horizontal space as its children need.
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Quantity Decrement Button
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20, // Smaller icon size.
                          ),
                          // `visualDensity: VisualDensity.compact` reduces padding around the icon.
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero, // Remove default padding.
                          onPressed:
                              symbol != 'N/A'
                                  ? () => _decrementSearchQuantity(symbol)
                                  : null, // Disable if symbol is invalid.
                          // Change color to grey if quantity is 1 (cannot decrement further).
                          color:
                              currentQuantity <= 1
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                        ),
                        // Display Current Quantity
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            '$currentQuantity',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        // Quantity Increment Button
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed:
                              symbol != 'N/A'
                                  ? () => _incrementSearchQuantity(symbol)
                                  : null, // Disable if symbol is invalid.
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8), // Spacing
                        // Buy Button
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.green, // Text color for the button.
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ), // Custom padding.
                            minimumSize: const Size(
                              50,
                              30,
                            ), // Ensure a minimum tappable area.
                            textStyle: const TextStyle(
                              fontSize: 13,
                            ), // Smaller font size.
                          ),
                          onPressed:
                              symbol != 'N/A'
                                  ? () => _showSearchBuyDialog(symbol, name)
                                  : null, // Disable if symbol is invalid.
                          child: const Text('Buy'),
                        ),
                      ],
                    ),
                    // --- END MODIFIED TRAILING WIDGET ---
                    onTap: () {
                      // Navigate to StockDetailScreen when the list tile (excluding trailing buttons) is tapped.
                      if (symbol != 'N/A') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => StockDetailScreen(symbol: symbol),
                          ),
                        );
                      } else {
                        // Show a message if the symbol is invalid (should be rare).
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid stock symbol.'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
