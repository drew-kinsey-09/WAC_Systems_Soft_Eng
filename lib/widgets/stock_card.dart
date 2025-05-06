//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:stock_app_ver4/widgets/stock_card.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// FILES this is referenced in: home_screen.dart, stock_detail_screen.dart, watchlist_summary.dart
// This files is used to create a card for each stock in the watchlist, stock detail screen and home screen

// imports for this file:
import 'package:flutter/material.dart'; // Flutter Material Design library
import '../models/stock.dart'; // Gives stock information to the card

// initializing the StockCard widget
class StockCard extends StatelessWidget {
  final Stock stock;

  const StockCard({super.key, required this.stock});

  // card allignment and design
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stock.symbol,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${stock.price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),

            // Getting stock name, if it is null, show 'Unknown'
            SizedBox(height: 8),
            Text(stock.name ?? 'Unknown', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Row(
              children: [
                // Checking if the change is positive or negative to determine the icon color
                Icon(
                  // Giving an arrow and color depending on the change in price
                  stock.change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: stock.change >= 0 ? Colors.green : Colors.red,
                ),

                // Using data from stock.dart to show the change in price and percent change
                Text(
                  '${stock.change.toStringAsFixed(2)} (${stock.changePercent.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    // Change in price is going to be represented in green or red depending on the value
                    color: stock.change >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
