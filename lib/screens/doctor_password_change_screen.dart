import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorPasswordChangeScreen extends StatefulWidget {
  const DoctorPasswordChangeScreen({super.key});

  @override
  State<DoctorPasswordChangeScreen> createState() =>
      _DoctorPasswordChangeScreenState();
}

class _DoctorPasswordChangeScreenState
    extends State<DoctorPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _newPassword = '';
  String _confirmPassword = '';
  String _errorMessage = '';
  String _currentPassword = '';
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _handlePasswordChange() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_newPassword != _confirmPassword) {
        _showError('Passwords do not match');
        return;
      }
      try {
        final user = await _authService.getCurrentUser(); // Get current logged-in user
        if (user != null) {
          // Update the password in Firebase Auth
          await _authService.updatePassword(_newPassword);

          // Optionally update Firestore if needed (e.g., remove 'isFirstLogin')
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({
            'isFirstLogin': false, // Update the user's 'isFirstLogin' to false
            'password': _newPassword // Optionally update the password in Firestore
          });

          // Navigate to doctor dashboard after successful password change
          Navigator.pushReplacementNamed(context, '/doctorDashboard');
        }
      } on Exception catch (e) {
        _showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Always prevent navigation
        return;
      },
      child: Scaffold(
        backgroundColor: Colors.pink[100],
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          title: const Text('Change Password'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 30),
                    TextFormField(
                      obscureText: !_isNewPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isNewPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your new password';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        print('onSaved: New Password: $value'); // Debug print
                        _newPassword = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        print('onSaved: Confirm Password: $value');
                        _confirmPassword = value!;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage.isNotEmpty)
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handlePasswordChange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          child: Text('Change Password', style: TextStyle(color: Colors.white)),
                        ),
                      ),
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
