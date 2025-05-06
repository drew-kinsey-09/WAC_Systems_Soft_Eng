//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:home_screen.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Files that reference this file: login_screen.dart, search_screen.dart, news_screen.dart (See next line)
// portfolio_screen.dart, watchlist_summary.dart, top_headlines.dart, home_news_feed.dart

// home screen is just the home page of the app
// The general layout is the wathchlist summary on the left and the news feed on the right
// The bottom navigation bar has 4 items: Home, Portfolio, Search, and News

//imoprts for this file:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app_ver4/providers/auth_provider.dart';
import 'package:stock_app_ver4/screens/login_screen.dart';
import 'package:stock_app_ver4/screens/search_screen.dart';
import 'package:stock_app_ver4/screens/news_screen.dart';
import 'package:stock_app_ver4/screens/portfolio_screen.dart';
import 'package:stock_app_ver4/widgets/top_headlines.dart';
import 'package:stock_app_ver4/widgets/home_news_feed.dart';
import 'package:stock_app_ver4/widgets/watchlist_summary.dart';

// initializing the home screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // This is just for when a user is logged in and they try to access the portfolio screen
  // If they aren't logged in, they they will be prompted to log in
  void _onItemTapped(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (index == 1) {
      if (!authProvider.isAuthenticated) {
        _promptLogin(context);
        return;
      }
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // As the name suggests this function navigates to the login screen
  void _navigateToLogin() {
    // This is just a check to see if the widget is still mounted
    // mounted documentation: https://api.flutter.dev/flutter/widgets/State/mounted.html
    // When user clicks on login button, it will navigate to the login screen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // This function is the promtLogin function used on line 43
  // Like before just prompts the user to log in
  void _promptLogin(BuildContext context) {
    // Snackbar documentation: https://api.flutter.dev/flutter/material/SnackBar-class.html
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      // Shows a snackbar with a message and a button to log in
      SnackBar(
        content: const Text('Please log in to view your portfolio.'),
        action: SnackBarAction(label: 'Login', onPressed: _navigateToLogin),
      ),
    );
  }

  // initializing the state of the home screen
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    // This is customizing the app bar to have a candlestick chart icon on the left and a title on the right

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.candlestick_chart_outlined,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        leadingWidth: 56,
        title: Text(_getAppBarTitle(_selectedIndex)),
        centerTitle: false,
        actions: _buildAppBarActions(context, authProvider),
        elevation: 1.0,
      ),

      // body of the hoeme screen
      body: _buildCurrentScreen(_selectedIndex, authProvider),
      // bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          // Bottom navigation source: https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html
          // Source just helped me understand how to use the bottom navigation bar a little better
          // Home naviagtion on bottom bar
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),

          // Portfolio navigation on bottom bar
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),

          // Search navigation on bottom bar
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),

          // News navigation on bottom bar
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'News',
          ),
        ],
      ),
    );
  }

  // Bottom naviagation bar names
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Portfolio';
      case 2:
        return 'Search Stocks';
      case 3:
        return 'Market News';
      default:
        return 'Stock App';
    }
  }

  // Building app bar actions depending on if user is logged in or not
  List<Widget> _buildAppBarActions(
    BuildContext context,

    //checks if user is logged in or not
    AuthProvider authProvider,
  ) {
    // Shows the search icon if the user is not on the search screen
    final showSearchIcon = _selectedIndex != 2;

    List<Widget> actions = [];

    // If the user is not on the search screen, show the search icon
    // Adds a tool tip for accessibility
    if (showSearchIcon) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search Stocks',
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _selectedIndex = 2;
            });
          },
        ),
      );
    }

    // If the user is logged in, show the logout icon
    // Just so we don't always have to show the logout icon
    // Also adds a tool tip for accessibility
    if (authProvider.isAuthenticated) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            // Waits for user to log out and then sets the state of the app to show the home screen
            await authProvider.signOut();
            if (mounted) {
              setState(() {
                _selectedIndex = 0;
              });
            }
          },
        ),
      );

      // This is the else, if the user is not logged in, show the login button
    } else {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),

          // login button customization
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor:
                  Theme.of(context).appBarTheme.foregroundColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black),
            ),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
            onPressed: _navigateToLogin,
          ),
        ),
      );
    }
    return actions;
  }

  // This function builds the current screen depending on the index of the bottom navigation bar
  // This is just a switch statement that returns the appropriate screen for the index
  // Source for switch statement: https://api.flutter.dev/flutter/dart-core/Map/switch.html
  // This also helped me code this: https://stackoverflow.com/questions/59543365/flutter-dart-returning-value-from-switch-case
  Widget _buildCurrentScreen(int index, AuthProvider authProvider) {
    switch (index) {
      case 0:
        return _buildHomeLayout();
      case 1:
        return const PortfolioScreen();
      case 2:
        return const SearchScreen();
      case 3:
        return const NewsScreen();
      default:
        return _buildHomeLayout();
    }
  }

  // establoshing the home layout
  Widget _buildHomeLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double wideLayoutBreakpoint = 700.0;

        if (constraints.maxWidth > wideLayoutBreakpoint) {
          return const Row(
            children: [
              // placing our stock watchlist from watchlist_summary.dart on the left side of the screen
              SizedBox(width: 280, child: WatchlistSummary()),
              VerticalDivider(width: 1, thickness: 1),

              // placing our news feed from home_news_feed.dart on the right side of the screen
              Expanded(
                child: Column(
                  children: [
                    TopHeadlines(count: 3),
                    Expanded(child: HomeNewsFeed()),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Just showing news feed and smaller card under the headlines
          return const Column(
            children: [TopHeadlines(count: 3), Expanded(child: HomeNewsFeed())],
          );
        }
      },
    );
  }
}
