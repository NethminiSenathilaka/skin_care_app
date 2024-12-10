import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';
import '../models/spotelessyou_user.dart';

class SpotlessyouuserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SpotelessYouUser>> getDoctorsList() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('userRole', isEqualTo: 'doctor')
        .get();
    final doctors = querySnapshot.docs
        .map((doc) => SpotelessYouUser.fromFirestore(doc))
        .toList();
    return doctors;
  }

  Future<List<SpotelessYouUser>> getUsersList() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('userRole', isEqualTo: 'user')
        .get();
    final doctors = querySnapshot.docs
        .map((doc) => SpotelessYouUser.fromFirestore(doc))
        .toList();
    return doctors;
  }

  Future<void> updateUser(SpotelessYouUser spotlessYouUser) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersCollection.where('email', isEqualTo: spotlessYouUser.email).get();
    if (querySnapshot.docs.isNotEmpty) {
      final docRef = querySnapshot.docs.first.reference;
      await docRef.update(spotlessYouUser.toMap());
    } else {
      print('No user found with email: ${spotlessYouUser.email}');
    }
  }

  Future<SpotelessYouUser?> getUserByEmail(String email) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersCollection.where('email', isEqualTo: email).get();

    if (querySnapshot.docs.isNotEmpty) {
      return SpotelessYouUser.fromFirestore(querySnapshot.docs.first);
    } else {
      print('No user found with email: $email');
      return null;
    }
  }

  // Check if the user is logging in for the first time
  Future<bool> isFirstLogin(String email) async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersCollection.where('email', isEqualTo: email).get();

    if (querySnapshot.docs.isNotEmpty) {
      final userData = querySnapshot.docs.first.data();
      return userData['isFirstLogin'] ?? false; // Assuming 'isFirstLogin' is a boolean field
    } else {
      return false; // If no user found, consider it as the first login
    }
  }

// Stream<List<Message>> getMessages() {
  //   final collectionReference =
  //       FirebaseFirestore.instance.collection('messages');
  //   return collectionReference.snapshots().map((querySnapshot) =>
  //       querySnapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  // }
  //
  // Future<Message?> getMessageById(String id) async {
  //   final documentReference =
  //       FirebaseFirestore.instance.collection('messages').doc(id);
  //   final snapshot = await documentReference.get();
  //   if (snapshot.exists) {
  //     return Message.fromFirestore(snapshot);
  //   } else {
  //     return null;
  //   }
  // }
  //
  // Future<void> updateMessage(Message message) async {
  //   final documentReference =
  //       FirebaseFirestore.instance.collection('messages').doc(message.id);
  //   await documentReference.update(message.toMap());
  // }
  //
  // Future<void> deleteMessage(String id) async {
  //   final documentReference =
  //       FirebaseFirestore.instance.collection('messages').doc(id);
  //   await documentReference.delete();
  // }
}
