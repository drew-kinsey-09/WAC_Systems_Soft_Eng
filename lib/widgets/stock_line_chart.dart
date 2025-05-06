//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:lib/providers/news_provider.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// This file creates the stock chart for our stock details page

// imports for this file:
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:stock_app_ver4/models/historical_stock.dart';
import 'package:stock_app_ver4/services/alpha_vantage_service.dart';

// initizlizing the stock line chart widget
class StockLineChart extends StatefulWidget {
  final String symbol;

  const StockLineChart({required this.symbol, super.key});

  @override
  State<StockLineChart> createState() => _StockLineChartState();
}

class _StockLineChartState extends State<StockLineChart> {
  bool _isLoading = true;
  String? _errorMsg;
  List<HistoricalStock> _chartData = [];

  // api timeframe
  // alpha vantage api timeframes
  // source: https://www.alphavantage.co/documentation/#time-series-data
  String _selectedTimeframe = '1y'; // Default timeframe
  List<FlSpot> _spots = [];
  double _minX = 0, _maxX = 0, _minY = 0, _maxY = 0;
  Color _lineColor = Colors.grey;
  List<Color> _gradientColors = [Colors.grey, Colors.grey.withOpacity(0.1)];

  // Aplha Vantage timeframes
  final Map<String, String> _timeframeLabels = {
    '1d': '1D',
    '1w': '1W',
    '1m': '1M',
    '3m': '3M',
    '6m': '6M',
    '1y': '1Y',
    'max': 'Max',
  };

  // api service
  final AlphaVantageService _alphaVantageService = AlphaVantageService();

  @override
  void initState() {
    super.initState();
    // Fetch initial data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchChartData(_selectedTimeframe);
      }
    });
  }

  // Future functuon to fetch the chart data
  Future<void> _fetchChartData(String timeframe) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true; // Set loading state
      _errorMsg = null; // Clear previous error
    });

    try {
      // Call the new service directly
      final data = await _alphaVantageService.getHistoricalData(
        widget.symbol,
        timeframe: timeframe,
      );

      if (mounted) {
        setState(() {
          _chartData = data; // Store fetched data
          _isLoading = false; // Clear loading state
          if (data.isEmpty) {
            _errorMsg =
                "No data available for this timeframe."; // Set specific message for empty data
          }
        });
        _prepareChartData(data); // Prepare spots after data is fetched
      }
    } catch (e) {
      // Catch errors thrown by the service
      //source: https://dart.dev/language/error-handling
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString();
          _chartData = [];
        });
        _prepareChartData([]);
      }
    }
  }

  // Prepare the chart data based on the fetched data
  // Using Alpha Vantage data to prepare the chart data
  // source: https://www.alphavantage.co/documentation/#time-series-data

  void _prepareChartData(List<HistoricalStock> data) {
    if (data.isEmpty) {
      if (mounted) {
        setState(() {
          _spots = [];
          _minX = 0;
          _maxX = 0;
          _minY = 0;
          _maxY = 0;
          _lineColor = Colors.grey;
          _gradientColors = [Colors.grey, Colors.grey.withOpacity(0.1)];
        });
      }
      return;
    }

    // Prepare the spots for the chart
    // source: https://pub.dev/packages/fl_chart
    List<FlSpot> spots = [];
    double minY = double.maxFinite;
    double maxY = double.minPositive;

    // Iterate through the data and create FlSpot objects
    // source: https://pub.dev/packages/fl_chart
    for (var stockData in data) {
      final x = stockData.date.millisecondsSinceEpoch.toDouble();
      final y = stockData.close;
      spots.add(FlSpot(x, y));
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    // Set the min and max values for the chart
    // setting line color based on the data
    Color lineColor = Colors.grey;
    if (data.length > 1) {
      lineColor =
          data.last.close >= data.first.close ? Colors.green : Colors.red;
    }

    if (mounted) {
      setState(() {
        _spots = spots;
        _minX = spots.first.x;
        _maxX = spots.last.x;
        _minY = minY * 0.98;
        _maxY = maxY * 1.02;
        _lineColor = lineColor;
        _gradientColors = [lineColor, lineColor.withOpacity(0.1)];
      });
    }
  }

  // Build the timeframe selector widget
  // allowing users to select from 1 year, 3 months, 6 months, and max timeframes
  // mostly using already built in widgets from the fl_chart package
  // and alphavantage api source: https://www.alphavantage.co/documentation/#time-series-data
  Widget _buildTimeframeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            _timeframeLabels.entries.map((entry) {
              final key = entry.key;
              final label = entry.value;
              final isSelected = _selectedTimeframe == key;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && mounted) {
                      // Check mounted
                      setState(() {
                        _selectedTimeframe = key;
                      });
                      // Call local fetch method
                      _fetchChartData(key);
                    }
                  },
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.8),
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
      ),
    );
  }

  // Build the chart widget using the fl_chart package UI this time
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTimeframeSelector(),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Use local _spots list
              if (_spots.isNotEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 16.0,
                    top: 10,
                    bottom: 10,
                  ),
                  child: LineChart(
                    // axis data for the chart
                    LineChartData(
                      minX: _minX,
                      maxX: _maxX,
                      minY: _minY,
                      maxY: _maxY,

                      // Using local _lineColor and _gradientColors
                      // Grid data for the chart
                      // Very helpful source: https://github.com/topics/financial-charting-library
                      // and https://github.com/stock-chart
                      // UI sourcing from fl_chart package source: https://pub.dev/packages/fl_chart
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: (_maxY - _minY) / 4,
                        verticalInterval: (_maxX - _minX) / 4,
                        getDrawingHorizontalLine:
                            (value) => FlLine(
                              color: Colors.grey.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                        getDrawingVerticalLine:
                            (value) => FlLine(
                              color: Colors.grey.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: (_maxX - _minX) / 4,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt(),
                              );

                              // changing the date format based on the timeframe selected
                              String text = '';
                              if (_selectedTimeframe == '1d' ||
                                  _selectedTimeframe == '1w') {
                                text = DateFormat('d MMM').format(date);
                              } else if (_selectedTimeframe == '1m' ||
                                  _selectedTimeframe == '3m') {
                                text = DateFormat('MMM').format(date);
                              } else {
                                text = DateFormat('yyyy').format(date);
                              }

                              return SideTitleWidget(
                                meta: meta, // Pass the required meta argument
                                space: 4,
                                child: Text(
                                  text,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                              // ---------------------------------
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: (_maxY - _minY) / 4,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta, // Pass the required meta argument
                                // Removed axisSide as it is not a valid parameter
                                space: 4,
                                child: Text(
                                  '\$${value.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                              // ---------------------------------
                            },
                          ),
                        ),
                      ),

                      //using more fl chart package UI
                      // source: https://pub.dev/packages/fl_chart
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots, // Use local _spots
                          isCurved: true,
                          gradient: LinearGradient(
                            colors:
                                _gradientColors, // Use local _gradientColors
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors:
                                  _gradientColors // Use local _gradientColors
                                      .map((color) => color.withOpacity(0.3))
                                      .toList(),
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],

                      // Using local _lineColor
                      // source: https://pub.dev/packages/fl_chart
                      // this is the line color for the chart
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                spot.x.toInt(),
                              );
                              final dateString = DateFormat(
                                'MMM d, yyyy',
                              ).format(date);
                              return LineTooltipItem(
                                '$dateString\n\$${spot.y.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                      ),
                    ),
                  ),
                ),

              if (_isLoading) const CircularProgressIndicator(),

              // error message for the chart
              // mostly for debugging purposes
              if (!_isLoading && _errorMsg != null && _spots.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Error loading chart data:\n$_errorMsg', // Display local error
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              if (!_isLoading && _errorMsg == null && _spots.isEmpty)
                const Text(
                  'No historical data available.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
    // --- End Removed Selector ---
  }
}
