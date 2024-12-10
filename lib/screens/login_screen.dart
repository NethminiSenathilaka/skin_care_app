import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String _email = '';
  String _password = '';
  String _errorMessage = '';
  bool _isPasswordVisible = false; // Tracks password visibility

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 3), // Disappear after 3 seconds
        behavior: SnackBarBehavior.floating, // Makes the SnackBar float
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adds padding from edges
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Round edges
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final userCredential =
            await _authService.signInWithEmailAndPassword(_email, _password);
        final user = userCredential.user;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final userRole = userData['userRole'];

            print('User role: $userRole');
            if (userRole == 'admin') {
              Navigator.pushReplacementNamed(context, '/adminDashboard');
            } else if (userRole == 'user') {
              Navigator.pushReplacementNamed(context, '/userDashboard');
            } else if (userRole == 'doctor') {
              Navigator.pushReplacementNamed(context, '/doctorDashboard');
            } else {
              print('UserRole not found');
            }
          } else {
            print('User document not found');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User data not found')),
            );
          }
        } else {
          print('User is null');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication failed')),
          );
        }
      } on Exception catch (e) {
        _showError(e.toString());
      }
    }
  }

  Future<bool> showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Are you sure you want to exit the app?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm
            child: const Text("Yes"),
          ),
        ],
      ),
    ) ??
        false; // Default to false if the dialog is dismissed
    if (result) {
      SystemNavigator.pop(); // Exit the app gracefully
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
      if (didPop) {
        // If the pop was already completed, do nothing
        return;
      }

      /// Show confirmation dialog on back press
      await showExitConfirmationDialog();
    },
    child:Scaffold(
      // appBar: AppBar(
      //   title: const Text('Login'),
      // ),
      backgroundColor: Colors.pink[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/logo.png',
                    height: 200,
                  ),
                  const SizedBox(height: 30),
                  // Email TextField
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password TextField with visibility toggle
                  TextFormField(
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Text(_errorMessage,
                        style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        child: Text('Login',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // SignUp Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Colors.black)),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/userSignup'),
                        child: const Text(
                          'SignUp',
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
