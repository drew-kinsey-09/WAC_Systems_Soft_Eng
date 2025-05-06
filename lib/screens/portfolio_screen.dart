//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart: portfolio_screen.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// This is the file for the actual protfolio screen, and one of the most important files in the app.
// this file was highly importnat in class and as such has the most comments and code

// imports for this file:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stock_app_ver4/providers/portfolio_provider.dart';
import 'package:stock_app_ver4/providers/stock_provider.dart';
import 'package:stock_app_ver4/screens/stock_detail_screen.dart';
import 'dart:async';

//initalizing the portfolio screen
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  // Stores the latest fetched prices for stocks in the portfolio. Key: Symbol, Value: Price.
  Map<String, double> _currentPrices = {};
  Map<String, String?> _fetchErrors = {};
  bool _isLoadingPrices = false;

  // Timer object for scheduling periodic price refreshes. Nullable because it's initialized later.
  // Source: https://api.flutter.dev/flutter/dart-async/Timer-class.html
  Timer? _refreshTimer;

  // this is just a formatting function for the currency, number, and percent values
  // source: https://api.flutter.dev/flutter/intl/NumberFormat-class.html
  final currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  );
  final numberFormatter = NumberFormat("#,##0.00", "en_US");
  final percentFormatter = NumberFormat("+#,##0.00%;-#,##0.00%", "en_US");

  // Initializeing the state of the portfolio screen
  @override
  void initState() {
    super.initState();

    // Fetches initial prices and starts the auto-refresh timer *after* the first frame is built.
    // This ensures that the context is available and providers can be accessed safely.
    // Source: https://api.flutter.dev/flutter/widgets/WidgetsBinding/addPostFrameCallback.html
    // We add this because we want to show the percentage change of our stock

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the widget is still mounted before proceeding, especially important in async callbacks.
      // Source: https://api.flutter.dev/flutter/widgets/State/mounted.html
      if (mounted) {
        final portfolioProvider = Provider.of<PortfolioProvider>(
          context,
          listen: false,
        );
        // Fetch prices only if the portfolio isn't loading and actually contains stocks.
        if (!portfolioProvider.isLoading &&
            portfolioProvider.portfolio.isNotEmpty) {
          _fetchCurrentPrices();
        }
        // Start the timer for automatic background refreshes.
        _startAutoRefresh();
      }
    });
  }

  @override
  void dispose() {
    // Cancel the auto-refresh timer when the widget is removed from the tree
    // to prevent memory leaks and unnecessary background work.
    _refreshTimer?.cancel();
    super.dispose();
  }

  // auto-refresh function for the portfolio screen
  void _startAutoRefresh() {
    _refreshTimer?.cancel();

    // Creates a timer that fires every 1 minute.
    // Source: https://api.flutter.dev/flutter/dart-async/Timer/Timer.periodic.html
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      print("Auto-refresh triggered...");
      if (mounted) {
        // Fetch prices. `force: false` respects the provider's caching mechanism.
        // We don't want background refreshes to necessarily bypass the cache unless needed.
        _fetchCurrentPrices(force: false);
      } else {
        timer.cancel();
      }
    });
  }

  // Fetches the current market prices for all stocks held in the portfolio.
  // using the StockProvider to handle the actual API calls and caching logic.
  // finnhub api source: https://finnhub.io/docs/api/quote
  // ui source: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
  Future<void> _fetchCurrentPrices({bool force = false}) async {
    if (!mounted || (_isLoadingPrices && !force)) return;

    if (force) {
      // setState triggers a rebuild to show the loading indicator if needed.
      // Source: https://api.flutter.dev/flutter/widgets/State/setState.html
      setState(() {
        _isLoadingPrices = true;
        _fetchErrors = {}; // Clear previous errors on a new fetch attempt.
      });
    } else {
      _isLoadingPrices = true;
      _fetchErrors = {};
    }

    // Access providers using Provider.of with listen: false, as we don't need this function
    // to rebuild if the provider data changes *during* the fetch operation.
    final portfolioProvider = Provider.of<PortfolioProvider>(
      context,
      listen: false,
    );
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    // Get the list of symbols the user owns.
    final symbols = portfolioProvider.portfolio.keys.toList();

    // If the portfolio is empty, no need to fetch prices.
    if (symbols.isEmpty) {
      if (mounted) {
        setState(
          () => _isLoadingPrices = false,
        ); // Ensure loading state is reset.
      }
      return;
    }

    // Temporary maps to hold results for this fetch operation.
    Map<String, double> fetchedPrices = {};
    Map<String, String?> fetchErrors = {};

    // Loop through each symbol and fetch its quote.
    for (int i = 0; i < symbols.length; i++) {
      final symbol = symbols[i];
      // If the widget was disposed during the loop (e.g., user navigated away), stop fetching.
      if (!mounted) break;

      // Using try-catch to handle potential network or API errors during fetching.
      // Source: https://dart.dev/language/error-handling
      // finnhub api source: https://finnhub.io/docs/api/quote

      try {
        print("PortfolioScreen: Getting quote for $symbol (force=$force)");
        final stock = await stockProvider.getCachedOrFetchQuote(symbol);
        // Re-check `mounted` after the `await` call
        // Mounted source: https://api.flutter.dev/flutter/widgets/State/mounted.html
        if (!mounted) break;

        if (stock != null) {
          fetchedPrices[symbol] = stock.price; // Store successful price fetch.
        } else {
          fetchErrors[symbol] =
              'Price N/A'; // Mark as unavailable if provider returned null.
          print(
            "PortfolioScreen: Failed to get quote for $symbol from StockProvider.",
          );
        }
      } catch (e) {
        // If an exception occurred during the fetch for a specific symbol.
        if (!mounted) break;
        fetchErrors[symbol] = 'Error';
        print("PortfolioScreen: Error getting quote for $symbol: $e");
      }
    }

    if (mounted) {
      setState(() {
        // Merge the newly fetched prices and errors with the existing state.
        // Using the spread operator (...) for concise map merging.
        // Source: https://dart.dev/language/collections#spread-operators
        // Very helpful source: https://stackoverflow.com/questions/73402699/dart-how-to-combine-the-values-of-a-mapdynamic-int-with-iterabledynamic-and
        // And this one: https://community.flutterflow.io/ask-the-community/post/combining-two-jsons-DDgAxzaSlsEGoQd
        _currentPrices = {..._currentPrices, ...fetchedPrices};
        _fetchErrors = {..._fetchErrors, ...fetchErrors};
        _isLoadingPrices = false;
      });
    } else {
      _isLoadingPrices = false;
    }
  }

  // Calculates the total current market value of all stocks in the portfolio.
  double _calculateTotalStockValue(
    Map<String, OwnedStock> portfolio,
    Map<String, double> currentPrices,
  ) {
    double stockValue = 0.0;

    // Iterates through each stock in the portfolio.
    // Source: https://api.flutter.dev/flutter/dart-core/Map/forEach.html
    portfolio.forEach((symbol, stock) {
      final currentPrice = currentPrices[symbol];

      // If a valid current price is available, use it for calculation.
      if (currentPrice != null && currentPrice > 0) {
        stockValue += stock.quantity * currentPrice;
      } else {
        // Fallback: If the current price isn't available (e.g., due to fetch error),
        // use the stock's total cost basis as a placeholder value to avoid showing 0.
        stockValue += stock.totalCostBasis;
      }
    });
    return stockValue;
  }

  // Calculates the total amount of money initially invested across all stocks.
  double _calculateTotalCostBasis(Map<String, OwnedStock> portfolio) {
    double totalCost = 0.0;
    portfolio.forEach((symbol, stock) {
      totalCost += stock.totalCostBasis;
    });
    return totalCost;
  }

  // Shows a dialog to confirm selling a specified quantity of a stock.
  void _showSellDialog(String symbol, int maxQuantity, double currentPrice) {
    // Controller to manage the text input for quantity.
    // Source: https://api.flutter.dev/flutter/widgets/TextEditingController-class.html

    final quantityController = TextEditingController(text: '1');
    final portfolioProvider = Provider.of<PortfolioProvider>(
      context,
      listen: false,
    );
    double estimatedProceeds = currentPrice;

    // Displays a standard Material dialog.
    // Source: https://api.flutter.dev/flutter/material/showDialog.html
    showDialog(
      context: context,
      builder: (ctx) {
        // StatefulBuilder is used here to allow the dialog's content (specifically the
        // estimated proceeds text) to update when the quantity changes, without needing
        // to rebuild the entire PortfolioScreen.
        // Source: https://api.flutter.dev/flutter/widgets/StatefulBuilder-class.html
        // another helpful source: https://www.youtube.com/watch?v=syvT63CosNE
        // Community noted: https://widgettricks.substack.com/p/statefulbuilder-notes

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // AlertDialog is a Material Design dialog that can display a title, content, and actions.
              // Source: https://api.flutter.dev/flutter/material/AlertDialog-class.html
              title: Text('Sell $symbol'),
              content: Column(
                mainAxisSize: MainAxisSize.min, // Keep dialog height minimal.
                children: [
                  Text(
                    'Current Price: ${currencyFormatter.format(currentPrice)}',
                  ),
                  Text('Owned: $maxQuantity Shares'),
                  const SizedBox(height: 16),
                  TextField(
                    // TextField is a Material Design text input field.
                    // Source: https://api.flutter.dev/flutter/material/TextField-class.html
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity to Sell',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,

                    // Ensures only digits can be entered.
                    // Source: https://api.flutter.dev/flutter/services/FilteringTextInputFormatter-class.html
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 0;
                      setDialogState(() {
                        estimatedProceeds = quantity * currentPrice;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Est. Proceeds: ${currencyFormatter.format(estimatedProceeds)}',
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(), // Close the dialog.
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Confirm Sell'),
                  onPressed: () async {
                    final quantity = int.tryParse(quantityController.text);
                    if (quantity == null || quantity <= 0) {
                      Navigator.of(ctx).pop();

                      // Show feedback using ScaffoldMessenger.
                      // Source: https://api.flutter.dev/flutter/material/ScaffoldMessenger-class.html
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          // Source: https://api.flutter.dev/flutter/material/SnackBar-class.html
                          content: Text('Please enter a valid quantity.'),
                        ),
                      );
                      return;
                    }

                    // this just checks to see if the user is trying to sell more shares than they own
                    if (quantity > maxQuantity) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You do not own enough shares.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop();
                    // Call the provider method to handle the sell logic.
                    final success = await portfolioProvider.sellStock(
                      symbol,
                      quantity,
                      currentPrice,
                    );

                    // Check `mounted` again after the `await` before showing SnackBar.
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Sell successful!'
                                : 'Sell failed: ${portfolioProvider.errorMessage ?? 'Unknown error'}',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      // Refresh the portfolio screen's prices if the sell was successful.
                      if (success) _fetchCurrentPrices(force: true);
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

  // Shows a dialog to confirm buying more shares of an existing stock.
  // Structure is very similar to _showSellDialog, using StatefulBuilder for local state updates.
  void _showBuyMoreDialog(String symbol, double currentPrice) {
    final quantityController = TextEditingController(text: '1');
    final portfolioProvider = Provider.of<PortfolioProvider>(
      context,
      listen: false,
    );
    double estimatedCost = currentPrice; // Initial estimate for 1 share

    // this is a formatting function for the currency, number, and percent values
    // Helpful sources: https://stackoverflow.com/questions/74597165/trendingviewpine-script-percentage-change-how-to-show-the-change-betwe
    // ANother: https://github.com/flutter/flutter/blob/master/dev/benchmarks/test_apps/stocks/lib/stock_data.dart
    // Ui help source: https://www.youtube.com/watch?app=desktop&v=ql-BTwMslxQ
    // https://github.com/Karanjot-singh/Flutter-StockPlus
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Buy More $symbol'),
              content: Column(
                mainAxisSize: MainAxisSize.min,

                // Current price and available cash are displayed here.
                children: [
                  Text(
                    'Current Price: ${currencyFormatter.format(currentPrice)}',
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 0;
                      setDialogState(() {
                        estimatedCost = quantity * currentPrice;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Est. Cost: ${currencyFormatter.format(estimatedCost)}'),
                ],
              ),
              actions: <Widget>[
                // Text buttons for canceling or confirming the buy action.
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Confirm Buy'),
                  onPressed: () async {
                    final quantity = int.tryParse(quantityController.text);

                    // Check if the quantity is valid and greater than 0.
                    if (quantity == null || quantity <= 0) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid quantity.'),
                        ),
                      );
                      return;
                    }

                    // Check if the user is trying to buy more shares than they can afford.
                    if (estimatedCost > portfolioProvider.cash) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Not enough cash for this purchase.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(
                      ctx,
                    ).pop(); // Close dialog before async operation.
                    // Call the provider method to handle the buy logic.
                    final success = await portfolioProvider.buyStock(
                      symbol,
                      quantity,
                      currentPrice,
                    );

                    // Check `mounted` after `await`.
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Purchase successful!'
                                : 'Purchase failed: ${portfolioProvider.errorMessage ?? 'Unknown error'}',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      // Refresh prices on successful buy.
                      if (success) _fetchCurrentPrices(force: true);
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

  @override
  Widget build(BuildContext context) {
    // The build method is where the UI is constructed. It uses the Provider package to access the portfolio data.
    // Source: https://pub.dev/packages/provider#selector
    // Source: https://dart.dev/language/records
    return Selector<
      PortfolioProvider,
      ({Map<String, OwnedStock> portfolio, double cash, bool isLoading})
    >(
      // The selector function defines *what* data to extract from the provider.
      // Loading state for the portfolio itself (not prices).
      // loading cash and portfolio data from the provider
      selector:
          (_, provider) => (
            portfolio: provider.portfolio,
            cash: provider.cash,
            isLoading: provider.isLoading,
          ),

      // The builder function receives the selected data and rebuilds the UI accordingly.
      builder: (context, portfolioData, child) {
        final portfolio = portfolioData.portfolio;
        final cash = portfolioData.cash;
        final isLoadingPortfolio = portfolioData.isLoading;

        // Show a loading indicator if the portfolio data itself is loading (e.g., initial load from storage).
        if (isLoadingPortfolio) {
          return const Center(child: CircularProgressIndicator());
        }

        // Calculate values
        // Total cost basis is the total amount of money invested in the portfolio.
        final totalCostBasis = _calculateTotalCostBasis(portfolio);
        final totalStockValue = _calculateTotalStockValue(
          portfolio,
          _currentPrices,
        );

        // Overall gain/loss is the difference between the current value of the portfolio and the total cost basis.
        final overallGainLoss = totalStockValue - totalCostBasis;

        // Calculate percentage gain/loss, avoiding division by zero.
        final double overallGainLossPercent =
            (totalCostBasis != 0) ? (overallGainLoss / totalCostBasis) : 0.0;

        // Determine color for gain/loss display (green for profit/break-even, red for loss).
        final overallGainLossColor =
            overallGainLoss >= 0 ? Colors.green : Colors.red;

        // Finally, we are the UI for the portfolio screen
        // A bunch of sources for this screen: https://api.flutter.dev/flutter/material/Scaffold-class.html
        // Source: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
        // Source: https://api.flutter.dev/flutter/widgets/CustomScrollView-class.html
        // Source: https://api.flutter.dev/flutter/material/SliverAppBar-class.html
        // Source: https://api.flutter.dev/flutter/material/FlexibleSpaceBar-class.html
        // Comparable app source for inspiration: https://github.com/Karanjot-singh/Flutter-StockPlus
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => _fetchCurrentPrices(force: true),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: 100.0,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    centerTitle: false,
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // stock vlaue and gain/loss percentage
                        Text(
                          'Stocks Value',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          // Display loading dots '...' if prices are loading and value is still 0, otherwise show formatted value.
                          _isLoadingPrices && totalStockValue == 0
                              ? '...'
                              : currencyFormatter.format(totalStockValue),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),

                        // Show overall gain/loss percentage only if there's an investment.
                        if (totalCostBasis != 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              // Show placeholder if prices are loading, otherwise formatted percentage.
                              _isLoadingPrices
                                  ? '--.--%'
                                  : percentFormatter.format(
                                    overallGainLossPercent,
                                  ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,

                                // Use grey if loading, otherwise gain/loss color.
                                color:
                                    _isLoadingPrices
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withOpacity(0.7)
                                        : overallGainLossColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Amount invested and available cash rows.
                // SliverToBoxAdapter bridges between sliver context and regular box widgets.
                // Source: https://api.flutter.dev/flutter/widgets/SliverToBoxAdapter-class.html
                // Source: https://api.flutter.dev/flutter/widgets/Row-class.html
                // UI creativitiy and colors inspired by: https://www.youtube.com/watch?v=INxNB1-T2As&ab_channel=SanskarTiwari
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Shows total amount of money invested in the portfolio.
                        Text(
                          'Invested',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        Text(
                          currencyFormatter.format(totalCostBasis),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                // Shows the total available cash for buying stocks.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cash',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        Text(
                          currencyFormatter.format(cash),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Divider(
                    // Visual separator for the UI
                    // Source: https://api.flutter.dev/flutter/material/Divider-class.html
                    height: 16,
                    thickness: 1,
                    indent: 16, // Indent from the left edge.
                    endIndent: 16, // Indent from the right edge.
                  ),
                ),

                // Show loading indicator specifically when fetching initial prices for a non-empty portfolio.
                if (_isLoadingPrices &&
                    portfolio.isNotEmpty &&
                    _currentPrices.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // Show message if the portfolio is confirmed empty and not loading.
                if (portfolio.isEmpty && !isLoadingPortfolio)
                  // SliverFillRemaining takes up the remaining space in the viewport.
                  // Source: https://api.flutter.dev/flutter/widgets/SliverFillRemaining-class.html
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Your portfolio is empty.\nBuy stocks from the Search screen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),

                // Display the list of owned stocks if the portfolio is not empty.
                if (portfolio.isNotEmpty)
                  // SliverList efficiently builds list items as they scroll into view.
                  // Source: https://api.flutter.dev/flutter/widgets/SliverList-class.html
                  SliverList(
                    // SliverChildBuilderDelegate builds items lazily.
                    // Source: https://api.flutter.dev/flutter/widgets/SliverChildBuilderDelegate-class.html
                    delegate: SliverChildBuilderDelegate((context, index) {
                      // Get data for the current stock item.
                      final symbol = portfolio.keys.elementAt(index);
                      final ownedStock = portfolio[symbol]!;
                      final currentPrice = _currentPrices[symbol];
                      final fetchError = _fetchErrors[symbol];

                      // Caluculating vlaues for the stock item
                      double currentValue = 0;
                      double gainLoss = 0;
                      double gainLossPercent = 0;

                      // Determine if a valid price is available for display and calculations.
                      bool priceAvailable =
                          currentPrice != null && fetchError == null;

                      if (priceAvailable) {
                        currentValue = ownedStock.quantity * currentPrice;
                        gainLoss = currentValue - ownedStock.totalCostBasis;
                        if (ownedStock.totalCostBasis != 0) {
                          // Calculate percentage gain/loss. Multiplying by 100 is not needed
                          // as the `percentFormatter` handles the percentage conversion.
                          gainLossPercent =
                              gainLoss / ownedStock.totalCostBasis;
                        }
                      } else {
                        // Fallback value if price is unavailable.
                        currentValue = ownedStock.totalCostBasis;
                      }

                      // Determine color for gain/loss text.
                      final gainLossColor =
                          gainLoss >= 0 ? Colors.green : Colors.red;

                      // Card for each stock item in the portfolio.
                      return Card(
                        // Source for the card: https://api.flutter.dev/flutter/material/Card-class.html
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 1,
                        child: ListTile(
                          // Standard list item layout.
                          // Source: https://api.flutter.dev/flutter/material/ListTile-class.html
                          contentPadding: const EdgeInsets.only(
                            left: 16.0,
                            right: 4.0,
                          ),
                          title: Text(
                            symbol,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            // Display stock quantity and average cost.
                            '${ownedStock.quantity} Share${ownedStock.quantity > 1 ? 's' : ''} • Avg Cost: ${currencyFormatter.format(ownedStock.averageBuyPrice)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Gain/Loss Info
                              SizedBox(
                                width: 90,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      priceAvailable
                                          ? currencyFormatter.format(
                                            currentValue,
                                          )
                                          : (fetchError ?? '...'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,

                                        // Use orange for errors to distinguish from loss (red).
                                        color:
                                            fetchError != null
                                                ? Colors.orange
                                                : null,
                                        fontSize:
                                            fetchError != null ? 12 : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),

                                    // Display Gain/Loss Info only if price is available.
                                    if (priceAvailable)
                                      Text(
                                        // Use percentFormatter which handles +/- signs and %.
                                        '${gainLoss >= 0 ? '+' : ''}${currencyFormatter.format(gainLoss)} (${percentFormatter.format(gainLossPercent)})',
                                        style: TextStyle(
                                          color: gainLossColor,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else
                                      const Text(
                                        '-',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),

                              // Buy and Sell buttons
                              // Source: https://api.flutter.dev/flutter/material/TextButton-class.html
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(50, 30),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                                onPressed:
                                    priceAvailable
                                        ? () => _showBuyMoreDialog(
                                          symbol,
                                          currentPrice,
                                        )
                                        : null,
                                child: const Text('Buy'),
                              ),
                              const SizedBox(
                                width: 4,
                              ), // Spacing between buttons.
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(50, 30),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                                // Disable button if price is not available.
                                onPressed:
                                    priceAvailable
                                        ? () => _showSellDialog(
                                          symbol,
                                          ownedStock.quantity,
                                          currentPrice,
                                        )
                                        : null,
                                child: const Text('Sell'),
                              ),
                            ],
                          ),
                          // Navigate to the detail screen when the list tile is tapped.
                          onTap: () {
                            // Source: https://api.flutter.dev/flutter/widgets/Navigator-class.html
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // Source: https://api.flutter.dev/flutter/material/MaterialPageRoute-class.html
                                builder:
                                    (context) =>
                                        StockDetailScreen(symbol: symbol),
                              ),
                            );
                          },
                        ),
                      );
                    }, childCount: portfolio.length), // Number of items in the list.
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
