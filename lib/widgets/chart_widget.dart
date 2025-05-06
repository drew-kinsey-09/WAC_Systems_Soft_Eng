//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: chart_widget.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// FILES that reference this file: stock_detail_page.dart, stock_list_page.dart, api_service.dart

// This file is used to create a chart four our stocks

// imports for this file:
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Syncfusion chart library (IMPORTANT)
import '../models/stock.dart';

// initializing the chart widget
class ChartWidget extends StatelessWidget {
  final Stock stock;

  const ChartWidget({super.key, required this.stock});

  // Constructor to accept a Stock object
  @override
  Widget build(BuildContext context) {
    // Sample daily data for the chart
    final List<ChartData> chartData = [
      ChartData('Mon', 100),
      ChartData('Tue', 102),
      ChartData('Wed', 105),
      ChartData('Thu', 103),
      ChartData('Fri', 107),
    ];

    // Using syncfusion_flutter_charts to create a line chart
    // Source: https://pub.dev/packages/syncfusion_flutter_charts
    return SfCartesianChart(
      // Chart title and axis titles
      // Source: https://pub.dev/documentation/syncfusion_flutter_charts/latest/charts/SfCartesianChart-class.html
      title: ChartTitle(
        text: 'Stock Price Over Time',
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),

      // X-axis settings
      // Source: https://pub.dev/documentation/syncfusion_flutter_charts/latest/charts/CategoryAxis-class.html
      primaryXAxis: CategoryAxis(
        title: AxisTitle(
          text: 'Day',
          textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        labelRotation: -45, // Rotate labels to prevent overlap
      ),

      // Y-axis settings
      // Source: https://pub.dev/documentation/syncfusion_flutter_charts/latest/charts/NumericAxis-class.html
      primaryYAxis: NumericAxis(
        title: AxisTitle(
          text: 'Price',
          textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0),
      ),

      // Grid settings
      // Source: https://pub.dev/documentation/syncfusion_flutter_charts/latest/charts/GridLines-class.html
      plotAreaBorderWidth: 0,
      series: <CartesianSeries<ChartData, String>>[
        LineSeries<ChartData, String>(
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.day,
          yValueMapper: (ChartData data, _) => data.price,

          //Color for the line and marker to reflect stock price change
          color: stock.change >= 0 ? Colors.green : Colors.red,
          width: 2,
          markerSettings: MarkerSettings(
            isVisible: true,
            color: Colors.white,
            borderColor: stock.change >= 0 ? Colors.green : Colors.red,
            borderWidth: 2,
            shape: DataMarkerType.circle,
          ),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: Colors.black, fontSize: 10),
          ),
        ),
      ],

      // Tooltip setting for accessibility
      tooltipBehavior: TooltipBehavior(
        enable: true,
        tooltipPosition: TooltipPosition.pointer,
      ),
    );
  }
}

// Class to represent the data for the chart
class ChartData {
  final String day;
  final double price;

  ChartData(this.day, this.price);
}
