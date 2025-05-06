//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:stock_detail_screen.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// These sources are not used verbatim, rather they are cited and used as inspiration for code
// helpful sources: https://www.google.com/search?client=opera-gx&q=alpha+vantage+api+stock+chart+dart&sourceid=opera&ie=UTF-8&oe=UTF-8
// https://github.com/ferrerj/AlphaVantageDartLibrary
// https://pub.dev/packages/http
// https://github.com/topics/financial-charting-library
// https://github.com/topics/alphavantage-api
// https://github.com/xmartlabs/stock/blob/main/lib/src/stock.dart

// imports for this file:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app_ver4/models/stock.dart';
import 'package:stock_app_ver4/providers/stock_provider.dart';
import 'package:stock_app_ver4/widgets/stock_line_chart.dart';
import 'package:intl/intl.dart';

//initializing the StockDetailScreen widget
class StockDetailScreen extends StatefulWidget {
  final String symbol;
  const StockDetailScreen({required this.symbol, super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

// initializing the _StockDetailScreenState class
class _StockDetailScreenState extends State<StockDetailScreen> {
  Future<Stock?>? _stockDetailsFuture;
  final int _quantity = 1;
  final percentFormatter = NumberFormat("#,##0.00'%'", "en_US");

  @override
  void initState() {
    super.initState();
    _fetchStockDetails();
  }

  /// Fetch stock details when the screen is initialized
  void _fetchStockDetails() {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    setState(() {
      _stockDetailsFuture = stockProvider.getCachedOrFetchQuote(widget.symbol);
    });
  }

  /// Increment and decrement quantity for buying stocks
  void _incrementQuantity() {
    /* ... no change ... */
  }
  void _decrementQuantity() {
    /* ... no change ... */
  }
  Future<void> _buyStock(Stock stock) async {
    /* ... no change ... */
  }

  // build method for the StockDetailScreen widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.symbol)),
      body: FutureBuilder<Stock?>(
        future: _stockDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              (snapshot.connectionState == ConnectionState.done &&
                  !snapshot.hasData)) {
            return Center(/* ... Error Widget ... */);
          } else {
            final stock = snapshot.data!;
            final Color priceColor =
                stock.change >= 0 ? Colors.green : Colors.red;
            final double totalCost = stock.price * _quantity;
            final String formattedPercent = percentFormatter.format(
              stock.changePercent / 100,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Text(
                    stock.name ?? 'Unknown Stock',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${stock.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stock.change >= 0 ? '+' : ''}${stock.change.toStringAsFixed(2)} ($formattedPercent)',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: priceColor),
                  ),
                  const SizedBox(height: 24),

                  // --- Stock Chart ---
                  Text(
                    'Performance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  // --- Wrap Chart in SizedBox ---
                  SizedBox(
                    height: 250.0, // Give the chart a fixed height
                    child: StockLineChart(symbol: stock.symbol),
                  ),
                  // --- End Wrap ---
                  const SizedBox(height: 24),

                  // --- Buy Controls ---
                  Text('Trade', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(/* ... Quantity Row ... */),
                  const SizedBox(height: 8),
                  Row(/* ... Est. Cost Row ... */),
                  const SizedBox(height: 20),
                  Center(/* ... Buy Button ... */),
                  const SizedBox(height: 24),

                  // --- Other Details ---
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Symbol:', stock.symbol),
                  _buildDetailRow('Name:', stock.name ?? 'N/A'),
                  _buildDetailRow(
                    'Price:',
                    '\$${stock.price.toStringAsFixed(2)}',
                  ),
                  _buildDetailRow(
                    'Change:',
                    '${stock.change.toStringAsFixed(2)} ($formattedPercent)',
                  ),
                  _buildDetailRow(
                    'Prev. Close:',
                    '\$${stock.previousClose.toStringAsFixed(2)}',
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // --- Helper Method to Build Detail Row ---
  Widget _buildDetailRow(String label, String value) {
    // ... (no change) ...
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
