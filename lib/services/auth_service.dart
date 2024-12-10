import 'dart:ffi';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/spotelessyou_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    print(email);
    print(password);
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> createUserWithEmailAndPassword(String email, String password,
      String userRole, String name, String age, String district, String gender, String mobile, String bio) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'password': password,
        'userRole': userRole,
        'name': name,
        'age': age,
        'district': district,
        'gender': gender,
        'mobile': mobile,
        'bio': bio
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> createDoctorWithEmailAndPassword(
  String name, String email, String password , String mobile, String bio, String userRole, bool isFirstLogin ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'password': password,
        'mobile': mobile,
        'bio': bio,
        'userRole': userRole,
        'isFirstLogin': true,
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<SpotelessYouUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      return SpotelessYouUser.fromFirestore(docSnapshot);
    } else {
      return null;
    }
  }

  Future<String?> getPasswordFromFirestore(String userId) async {
    try {
      // Fetch the document from the 'users' collection in Firestore
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        // Assuming you stored the password in the 'password' field (again, not recommended)
        return docSnapshot['password'] as String?;
      }
      return null;
    } catch (e) {
      print('Error retrieving password: $e');
      return null;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      print('New Password : $newPassword');
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email!; // Get the user's email
        String? password = await getPasswordFromFirestore(user.uid); // Retrieve the password from Firestore
        print('Existing Password : $password');

        if (password != null) {
          // Reauthenticate the user using their current password
          final credential = EmailAuthProvider.credential(email: email, password: password);
          await user.reauthenticateWithCredential(credential);

          // Update password in Firebase Auth
          await user.updatePassword(newPassword);

          // Optionally update password in Firestore (again, not recommended to store it)
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'password': newPassword, // Update the password in Firestore (not recommended)
          });
        } else {
          print('Password not found in Firestore');
        }
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error updating password: $e');
    }
  }
}