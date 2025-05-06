//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:main.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Main entry point for the Stock App
// This file initializes Firebase, loads environment variables, and sets up the main app widget with providers.

// imports for this file
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:stock_app_ver4/providers/stock_provider.dart';
import 'package:stock_app_ver4/providers/auth_provider.dart';
import 'package:stock_app_ver4/providers/portfolio_provider.dart';
import 'package:stock_app_ver4/screens/home_screen.dart';
import 'package:stock_app_ver4/screens/login_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Main function to run the app
// dotenv is used to load environment variables from the .env file
// source: https://pub.dev/packages/flutter_dotenv
// Firebase is initialized with the options from firebase_options.dart
// source: https://firebase.flutter.dev/docs/overview#initializing-flutterfire
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Main app widget that sets up the providers and the MaterialApp
// Using a MultiProvider to manage state across the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This is the root build method of the app
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Using MultiProvider to provide multiple providers to the widget tree
      // Source: https://pub.dev/packages/provider#multifunctional-provider
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        //ChangeNotifierProvider is used to create an instance of AuthProvider
        // Source: https://pub.dev/packages/provider#changenotifierprovider\
        ChangeNotifierProxyProvider<AuthProvider, PortfolioProvider>(
          create: (context) {
            print("MAIN: Creating initial PortfolioProvider.");

            // initializing PortfolioProvider with AuthProvider
            // Authprovider is used to check if the user is authenticated
            // Source: https://pub.dev/packages/provider#changenotifierproxyprovider
            return PortfolioProvider(
              Provider.of<AuthProvider>(context, listen: false),
            )..loadPortfolio();
          },
          update: (context, authProvider, previousPortfolioProvider) {
            print(
              "MAIN: Updating PortfolioProvider due to AuthProvider change. User Authenticated: ${authProvider.isAuthenticated}",
            );
            final newPortfolioProvider = PortfolioProvider(authProvider);
            newPortfolioProvider.loadPortfolio();
            return newPortfolioProvider;
          },
        ),

        // StockProvider is created using ChangeNotifierProxyProvider whiich allows it to depend on PortfolioProvider
        ChangeNotifierProxyProvider<PortfolioProvider, StockProvider>(
          create: (context) {
            print("MAIN: Creating initial StockProvider.");
            return StockProvider(
              Provider.of<PortfolioProvider>(context, listen: false),
            );
          },
          update: (context, portfolioProvider, previousStockProvider) {
            print(
              "MAIN: Updating StockProvider with latest PortfolioProvider.",
            );
            // Always create a new StockProvider instance when PortfolioProvider updates.
            // This ensures it always holds a reference to the *current* PortfolioProvider.
            // Source: https://pub.dev/packages/provider#changenotifierproxyprovider
            return StockProvider(portfolioProvider);
          },
        ),
      ],
      // App theme providing light and dark themes
      // I love the dark theme, we had the light theme before and it wasn't good
      child: MaterialApp(
        title: 'Stock App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),

        // initialize the login screen route
        routes: {'/login': (context) => const LoginScreen()},
      ),
    );
  }
}
