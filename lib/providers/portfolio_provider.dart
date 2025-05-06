//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: portfolio_provider.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Files that reference this file: portfolio_screen.dart, stock_transaction.dart, auth_provider.dart

// This provider manages the user's stock portfolio, including owned stocks, cash balance,

//imports for this file:
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_app_ver4/providers/auth_provider.dart';
import 'package:stock_app_ver4/models/stock_transaction.dart';

// initializes the PortfolioProvider class
class OwnedStock {
  final String symbol;
  // Stores a list of all buy and sell transactions for this stock.
  final List<StockTransaction> transactions;

  OwnedStock({required this.symbol, List<StockTransaction>? transactions})
    : transactions = transactions ?? [];

  // Calculates the total quantity of this stock currently owned.
  // It sums the quantities of all transactions (positive for buys, negative for sells).
  int get quantity {
    return transactions.fold(
      0,
      (sum, transaction) => sum + transaction.quantity,
    );
  }

  // Calculates the total cost basis for the currently held shares.
  double get totalCostBasis {
    return transactions.fold(
      0.0,
      (sum, transaction) =>
          sum + (transaction.quantity * transaction.pricePerShare),
    );
  }

  // Calculates the average buy price for the shares currently held.
  // If no shares are held (quantity <= 0), average buy price is 0.
  double get averageBuyPrice {
    final currentQuantity = quantity;
    if (currentQuantity <= 0) {
      return 0.0;
    }
    final currentCostBasis = totalCostBasis;
    if (currentCostBasis.isNaN || currentCostBasis.isInfinite) {
      return 0.0;
    }
    return currentCostBasis / currentQuantity;
  }

  // Converts this OwnedStock instance into a JSON map for storage.
  // Source: https://api.flutter.dev/flutter/dart-core/Map/Map.from.html
  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'transactions': transactions.map((tx) => tx.toJson()).toList(),
  };

  // Creates an OwnedStock instance from a JSON map (e.g., when loading from storage).
  factory OwnedStock.fromJson(Map<String, dynamic> json) {
    List<StockTransaction> loadedTransactions = [];
    if (json['transactions'] is List) {
      loadedTransactions =
          (json['transactions'] as List)
              .map(
                (txJson) =>
                    StockTransaction.fromJson(txJson as Map<String, dynamic>),
              )
              .toList();
    }
    return OwnedStock(
      // Provides a default 'UNKNOWN' symbol if not found in JSON, for robustness.
      symbol: json['symbol'] as String? ?? 'UNKNOWN',
      transactions: loadedTransactions,
    );
  }
}

// Manages the application's portfolio state using the ChangeNotifier pattern.
// Source for ChangeNotifier: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html
// Source for shared_preferences: https://pub.dev/packages/shared_preferences

class PortfolioProvider with ChangeNotifier {
  // AuthProvider is used to get a user-specific prefix for SharedPreferences keys.
  final AuthProvider? _authProvider;
  // SharedPreferences for storing and retrieving portfolio data.
  SharedPreferences? _prefs;

  double _cash = 10000.00; // Default starting cash (funny money)

  // Map storing owned stocks, with the stock symbol as the key.
  // Also provides an error in console for debugging.
  Map<String, OwnedStock> _portfolio = {};
  bool _isLoading = false;
  String? _errorMessage;

  PortfolioProvider(this._authProvider) {
    print(
      "PortfolioProvider initialized. AuthProvider is ${_authProvider == null ? 'NULL' : 'provided'}.",
    );
    // Initialize SharedPreferences when the provider is created.
    _initPrefs();
  }

  // Gets our funny money
  double get cash => _cash;
  // Returns an unmodifiable view of the portfolio to prevent direct external modification.
  // Source: https://api.flutter.dev/flutter/dart-core/Map/unmodifiable.html
  Map<String, OwnedStock> get portfolio => Map.unmodifiable(_portfolio);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initializes the SharedPreferences instance asynchronously.
  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      print("SharedPreferences initialized successfully.");
      // After initializing prefs, load the portfolio data.
      await loadPortfolio();
    } catch (e) {
      print("!!! Error initializing SharedPreferences: $e");
      _setError("Failed to initialize storage: $e");
    }
  }

  // Generates a user-specific prefix for SharedPreferences so each user has their own data.
  // Returns null if the user is not logged in.
  String? get _userSpecificPrefix {
    final userId = _authProvider?.user?.uid;
    if (userId == null || userId.isEmpty) {
      print("Warning: Cannot get user-specific prefix, user not logged in.");
      return null;
    }

    // prefix for the user specific keys
    // helpful source: https://docs.flutter.dev/cookbook/persistence/key-value
    // Another: https://pub.dev/packages/shared_preferences
    return 'user_${userId}_';
  }

  // Loads the user's portfolio (cash and stocks) from SharedPreferences.
  Future<void> loadPortfolio() async {
    // Ensure SharedPreferences is initialized before proceeding.
    if (_prefs == null) {
      print("loadPortfolio: Waiting for SharedPreferences initialization...");
      await _initPrefs();
      if (_prefs == null) {
        _setError("Storage not available. Cannot load portfolio.");
        return;
      }
    }

    // Get the user-specific prefix for keys.
    final prefix = _userSpecificPrefix;
    if (prefix == null) {
      print(
        "loadPortfolio: No user prefix available. Assuming logged out state.",
      );
      _resetLocalState(); // Clear any existing data if user logs out
      _setLoading(false); // Ensure loading is set to false
      notifyListeners(); // Notify UI of reset state
      return;
    }

    // debugging message
    print("Attempting to load portfolio for prefix '$prefix'...");
    _setLoading(true);
    _clearError();

    // load cash and portfolio data from SharedPreferences
    try {
      final loadedCash = _prefs?.getDouble('${prefix}cash');
      _cash = loadedCash ?? 10000.00;
      print(
        "loadPortfolio: Loaded cash = $_cash (Raw value from prefs: $loadedCash)",
      );

      // Retrieve the portfolio data as a JSON string.
      // source: https://medium.com/flutter-community/parsing-complex-json-in-flutter-747c46655f51
      final portfolioJson = _prefs?.getString('${prefix}portfolio');
      final logSnippet =
          portfolioJson == null
              ? 'NULL'
              : portfolioJson.substring(
                    0,
                    (portfolioJson.length > 100 ? 100 : portfolioJson.length),
                  ) +
                  (portfolioJson.length > 100 ? '...' : '');
      print("loadPortfolio: Raw portfolio JSON loaded: $logSnippet");

      if (portfolioJson != null && portfolioJson.isNotEmpty) {
        // Decode the JSON string into a list of dynamic objects, then parse into OwnedStock instances.
        // Source: https://api.flutter.dev/flutter/dart-convert/jsonDecode.html
        // helpful source: https://stackoverflow.com/questions/53001839/how-to-convert-response-json-to-object-in-flutter
        final List<dynamic> decodedList = jsonDecode(portfolioJson);
        // Using a Map comprehension for concise creation.
        _portfolio = {
          for (var item in decodedList)
            if (item is Map<String, dynamic> && item['symbol'] != null)
              item['symbol'] as String: OwnedStock.fromJson(item),
        };
        print(
          "loadPortfolio: Successfully parsed portfolio JSON. ${_portfolio.length} stock items loaded.",
        );
      } else {
        _portfolio = {}; // Reset portfolio if no data found
        print(
          "loadPortfolio: No saved portfolio data found or JSON was empty.",
        );
      }

      // kDebugMode allows adding test data during development without affecting release builds.
      // Source: https://api.flutter.dev/flutter/foundation/kDebugMode-constant.html
      if (kDebugMode) {
        if (!_portfolio.containsKey('AMZN')) {
          print("--- [Debug Mode] Adding temporary AMZN stock for testing ---");
          _portfolio['AMZN'] = OwnedStock(
            symbol: 'AMZN',
            transactions: [
              StockTransaction(
                quantity: 5,
                pricePerShare: 150.0,
                timestamp: DateTime.now().subtract(const Duration(days: 1)),
              ),
            ],
          );
        }
      }

      print(
        "✅ Portfolio loaded successfully for user prefix '$prefix': Cash=$_cash, Stocks=${_portfolio.length}",
      );

      // Catching general exceptions during loading to prevent app crashes and provide feedback.
    } catch (e, stackTrace) {
      _errorMessage = "Failed to load portfolio data: $e";
      print("!!! Error loading portfolio: $e");
      print("Stack Trace: $stackTrace");
      _resetLocalState(); // Reset state on critical load error
    } finally {
      _setLoading(false);
      print("loadPortfolio: Loading process finished.");
    }
  }

  // Saves the current portfolio (cash and stocks) to SharedPreferences.
  Future<void> _savePortfolio() async {
    if (_prefs == null) {
      // eror message if SharedPreferences is not initialized
      _setError("Storage not available. Cannot save portfolio.");
      print("!!! _savePortfolio Error: SharedPreferences not initialized.");
      return;
    }

    // Get the user-specific prefix for keys.
    final prefix = _userSpecificPrefix;
    if (prefix == null) {
      _setError("User not logged in. Cannot save portfolio.");
      print("!!! _savePortfolio Error: No user prefix available.");
      return;
    }

    // Clear previous errors before attempting to save
    print("Attempting to save portfolio for prefix '$prefix'...");
    _clearError();

    // Decode the JSON string into a list of dynamic objects, then parse into OwnedStock instances.
    // Source: https://api.flutter.dev/flutter/dart-convert/jsonDecode.html
    // helpful source: https://stackoverflow.com/questions/53001839/how-to-convert-response-json-to-object-in-flutter
    try {
      final List<Map<String, dynamic>> portfolioList =
          _portfolio.values.map((stock) => stock.toJson()).toList();
      final String portfolioJson = jsonEncode(portfolioList);

      print("savePortfolio: Saving Cash = $_cash");
      final logSnippet =
          portfolioJson.substring(
            0,
            (portfolioJson.length > 100 ? 100 : portfolioJson.length),
          ) +
          (portfolioJson.length > 100 ? '...' : '');
      print("savePortfolio: Saving Portfolio JSON = $logSnippet");

      // Use Future.wait to perform multiple asynchronous save operations concurrently for efficiency.
      // Source: https://api.flutter.dev/flutter/dart-async/Future/wait.html
      await Future.wait([
        _prefs!.setDouble('${prefix}cash', _cash),
        _prefs!.setString('${prefix}portfolio', portfolioJson),
      ]);
      print("✅ Portfolio saved successfully for user prefix '$prefix'");
    } catch (e, stackTrace) {
      _setError("Failed to save portfolio data: $e");
      print("!!! Error saving portfolio: $e");
      print("Stack Trace: $stackTrace");
    } finally {
      print("savePortfolio: Saving process finished.");
    }
  }

  // Buying a stock
  Future<bool> buyStock(
    // fetches the stock symbol, quantity, and price per share from the user
    String symbol,
    int quantity,
    double pricePerShare,
  ) async {
    print("buyStock: Initiated for $quantity $symbol @ $pricePerShare");
    _clearError();

    // making sure they can afford the stock
    if (quantity <= 0) {
      _setError("Quantity must be positive.");
      return false;
    }
    if (pricePerShare <= 0) {
      _setError("Price must be positive.");
      return false;
    }

    // error message for stock pruchase
    final transactionCost = quantity * pricePerShare;
    if (_cash < transactionCost) {
      _setError(
        "Not enough cash. Need \$${transactionCost.toStringAsFixed(2)}, have \$${_cash.toStringAsFixed(2)}.",
      );
      return false;
    }

    // subtracting from the funny money
    _cash -= transactionCost;

    // Create a new transaction record for this purchase.
    // doing this for shared preferences
    // Share preferences documentation: https://pub.dev/packages/shared_preferences
    final newTransaction = StockTransaction(
      quantity: quantity,
      pricePerShare: pricePerShare,
      timestamp: DateTime.now(), // Record the time of the transaction
    );

    // If stock already exists in portfolio, add transaction. Otherwise, create new OwnedStock entry.
    // so we don't add unecessary data to the portfolio
    if (_portfolio.containsKey(symbol)) {
      _portfolio[symbol]!.transactions.add(newTransaction);
    } else {
      _portfolio[symbol] = OwnedStock(
        symbol: symbol,
        transactions: [newTransaction], // Start list with this transaction
      );
    }

    // adding this message for debugging purposes
    print("buyStock: State updated in memory. Attempting to save...");
    await _savePortfolio();

    // Notify listeners (typically UI components) that the portfolio state has changed.
    // this is for users
    notifyListeners();
    print(
      'buyStock: Completed for $quantity $symbol. New avg cost: \$${_portfolio[symbol]?.averageBuyPrice.toStringAsFixed(2)}',
    );
    return true;
  }

  // Stock selling function
  Future<bool> sellStock(
    // fetches the stock symbol, quantity, and price per share from the user
    String symbol,
    int quantityToSell,
    double pricePerShare,
  ) async {
    print("sellStock: Initiated for $quantityToSell $symbol @ $pricePerShare");
    _clearError();

    // if we don't have the stock in the portfolio, we can't sell it
    if (!_portfolio.containsKey(symbol)) {
      _setError("Stock '$symbol' not found in portfolio.");
      return false;
    }
    final ownedStock = _portfolio[symbol]!;
    final currentQuantity = ownedStock.quantity;

    // if the user tries to sell more than they own, wthey can't do that
    if (quantityToSell <= 0) {
      _setError("Quantity to sell must be positive.");
      return false;
    }

    // also for quantity of the stock
    if (currentQuantity < quantityToSell) {
      // error message for selling too much stock
      _setError(
        "Not enough shares to sell. Trying to sell $quantityToSell, only own $currentQuantity of $symbol.",
      );
      print(
        "sellStock Error: Attempting to sell $quantityToSell, but only own $currentQuantity of $symbol.",
      );
      return false;
    }
    if (pricePerShare <= 0) {
      _setError("Sell price must be positive.");
      return false;
    }

    // adding to the funny money
    final totalProceeds = quantityToSell * pricePerShare;
    _cash += totalProceeds;

    // Create a new transaction record for this sale with a negative quantity.
    final sellTransaction = StockTransaction(
      quantity: -quantityToSell, // Negative quantity indicates a sale
      pricePerShare: pricePerShare, // Record the price at which it was sold
      timestamp: DateTime.now(),
    );
    ownedStock.transactions.add(sellTransaction);

    // Check if the net quantity of the stock has become zero or less after the sale.
    if (ownedStock.quantity <= 0) {
      print(
        'sellStock: Net quantity for $symbol is now zero or less after sale.',
      );
    }
    print(
      "sellStock: State updated in memory (added sell transaction). Attempting to save...",
    );
    await _savePortfolio();
    notifyListeners();
    print(
      'sellStock: Completed for $quantityToSell $symbol. Proceeds: \$${totalProceeds.toStringAsFixed(2)}.',
    );
    return true;
  }

  // Helper method to set the loading state and notify listeners.
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Helper method to set an error message and notify listeners.
  void _setError(String message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to clear any existing error message.
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  // Helper method to reset local state variables (e.g., on error or logout).
  void _resetLocalState() {
    _cash = 10000.00; // Reset to default cash
    _portfolio = {}; // Clear portfolio
    _isLoading = false; // Ensure loading is off
    _errorMessage = null; // Clear any errors
  }

  // Clears all user-specific portfolio data from SharedPreferences and resets local state.
  // Typically called on user logout.
  Future<void> clearUserData() async {
    print("Clearing user data...");
    final prefix = _userSpecificPrefix;
    if (_prefs != null && prefix != null) {
      try {
        await Future.wait([
          _prefs!.remove('${prefix}cash'),
          _prefs!.remove('${prefix}portfolio'),
        ]);
        print("User data cleared from SharedPreferences for prefix '$prefix'.");
      } catch (e) {
        print("!!! Error clearing user data from SharedPreferences: $e");
      }
    } else {
      print(
        "Warning: Cannot clear SharedPreferences data (prefs or prefix null).",
      );
    }

    // Reset the in-memory state regardless of SharedPreferences success
    _resetLocalState();
    notifyListeners();
    print("Local portfolio state reset.");
  }
}
