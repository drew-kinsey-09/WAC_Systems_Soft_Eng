//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
//Authors: Paul Hazlehurst & Drew Kinsey Date: 2025-05-04 File: dart:login_screen.dart
//+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

// Files that reference this file:
//

// this is login screen file, just uses firebase among other things to authenticate users

// imports for this file:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app_ver4/providers/auth_provider.dart';

// initializing the login screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// establishing the state and login screen class
class _LoginScreenState extends State<LoginScreen> {
  // _formKey is used to validate the form and save the data
  final _formKey = GlobalKey<FormState>();
  // _emailController, _passwordController, and _confirmPasswordController are used to get the text from the text fields
  final _emailController = TextEditingController(); // get email
  final _passwordController = TextEditingController(); // get password
  final _confirmPasswordController =
      TextEditingController(); // confirm password
  bool _isLogin = true;

  // this dispose function just removes the controllers see above after usage,
  // assuring that we are not breaching the privacy of the user
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // swithches between login and sign up modes
  void _switchAuthMode() {
    Provider.of<AuthProvider>(context, listen: false).clearError();
    setState(() {
      _isLogin = !_isLogin;

      // clears the text fields when switching between login and sign up modes
      // Just in case a user enters any text in login screen and then switches to sign up screen
      // .reset source: https://api.flutter.dev/flutter/widgets/FormState/reset.html
      // helped to inspire this code: https://andiysrn.medium.com/flutter-toggle-view-between-ui-login-and-register-cc9698d9f6a6
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  // _submitForm is used to submit the form and authenticate the user
  // async is used to make sure that the function is not blocking the main thread
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    // clear any previous error messages
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success = false;
    try {
      if (_isLogin) {
        // if the user is logging in (Called by _islogin) then call the signIn function from authProvider
        success = await authProvider.signIn(email, password);
      } else {
        // when user goes to sign up, call the .signUp function from authProvider
        success = await authProvider.signUp(email, password);
      }

      // catch (e): Used to catch errors that occur during sign in/up
      // Source: https://dart.dev/language/error-handling
    } catch (e) {
      print("Auth Error in _submitForm: $e");
      success = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // general error message on snack bar to ecnourage user to try again
            content: Text("An unexpected error occurred. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // check if the user is logged in and if the widget is still mounted
    // mounted documentation: https://api.flutter.dev/flutter/widgets/State/mounted.html
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  // Sources that helped with the UI design:https://www.youtube.com/watch?v=Dh-cTQJgM-Q&ab_channel=MitchKoko
  // https://medium.com/@rohan.surve5/building-a-simple-login-screen-in-flutter-my-comeback-to-ui-development-60ebf1cd4bdc
  // https://www.geeksforgeeks.org/flutter-design-login-page-ui/
  // Login screen UI baby, everyone loves UI
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final theme = Theme.of(context);

        // loading to show user that app is loading for accessibility reasons
        final isLoading = authProvider.isLoading;
        final errorMessage = authProvider.errorMessage;

        // UI scagffolding creation
        // Scaffolding documentation: https://api.flutter.dev/flutter/material/Scaffold-class.html
        // Helps a bit but learned most of this from object oriented programming
        return Scaffold(
          appBar: AppBar(
            title: Text(_isLogin ? 'Login' : 'Sign Up'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: theme.textTheme.bodyLarge?.color,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon to show the user that this is a candlestick chart app
                    // Icon documentation: https://api.flutter.dev/flutter/material/Icon-class.html
                    Icon(
                      Icons.candlestick_chart_outlined,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 30),

                    // If you are logged in, show the welcome back message
                    // If you are signing up, show the create your account message
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Create Your Account',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Into the login screen now
                    // Asking user for an email adress
                    TextFormField(
                      controller: _emailController,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText:
                            'Email Address', // label text for the email field
                        hintText:
                            'you@example.com', // hint text for the email field
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: theme.hintColor.withOpacity(0.7),
                        ),

                        // outlines and borders for the text fields
                        // Border documentation: https://api.flutter.dev/flutter/material/OutlineInputBorder-class.html
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        // validate the email address
                        // Essentially if the email doesn't contain an @ symbol then it is not valid
                        if (value == null ||
                            value.trim().isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // exaclty what we did above but for the password field
                    TextFormField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText:
                            'Password', // label text for the password field
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: theme.hintColor.withOpacity(0.7),
                        ),

                        // outlines and borders for the text fields
                        // Border documentation: https://api.flutter.dev/flutter/material/OutlineInputBorder-class.html
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        // validate the password
                        // if the inputted password is null, empty or less than 6 characters then it is invalid
                        // will show a message to the user to let them know
                        if (value == null ||
                            value.isEmpty ||
                            value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // This is for the sign up screen only
                    if (!_isLogin)
                      TextFormField(
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText:
                              'Confirm Password', // label text for the confirm password field
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: theme.hintColor.withOpacity(0.7),
                          ),

                          // outlines and borders for the text fields
                          // Border documentation: https://api.flutter.dev/flutter/material/OutlineInputBorder-class.html
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        obscureText: true,

                        // we ask the user to re input the password to confirm it
                        // if the password is null, empty or less than 6 characters then it is invalid
                        // if the seconf password does not match the first password then it is invalid
                        validator: (value) {
                          if (!_isLogin && value != _passwordController.text) {
                            return 'Passwords do not match'; // error message
                          }
                          return null;
                        },
                      ),
                    if (!_isLogin) const SizedBox(height: 24),
                    if (_isLogin) const SizedBox(height: 10),

                    // cool little AnimatedOpacity widget to show the error message if there is one
                    // AnimatedOpacity documentation: https://api.flutter.dev/flutter/widgets/AnimatedOpacity-class.html
                    AnimatedOpacity(
                      opacity: errorMessage != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          errorMessage ?? '',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Creates a button to submit the form and login or sign up the user
                    // SizedBox documentation: https://api.flutter.dev/flutter/widgets/SizedBox-class.html
                    SizedBox(
                      height: 50,
                      child:
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // Shows a button tip to the user to let them know what they are doing
                                child: Text(_isLogin ? 'Login' : 'Sign Up'),
                              ),
                    ),
                    const SizedBox(height: 20),

                    // text button creation to switch between login and sign up modes
                    TextButton(
                      onPressed: isLoading ? null : _switchAuthMode,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        _isLogin
                            //button tips that assist the user in knowing what they are doing
                            ? 'Need an account? Sign Up'
                            : 'Have an account? Login',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
