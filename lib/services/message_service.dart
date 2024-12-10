import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';

class MessageService {
  Future<void> createMessage(Message message) async {
    final collectionReference =
        FirebaseFirestore.instance.collection('messages');
    await collectionReference.add(message.toMap());
  }

  Stream<List<Message>> getMessages() {
    final collectionReference =
        FirebaseFirestore.instance.collection('messages');
    return collectionReference.snapshots().map((querySnapshot) =>
        querySnapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<Message?> getMessageById(String id) async {
    final documentReference =
        FirebaseFirestore.instance.collection('messages').doc(id);
    final snapshot = await documentReference.get();
    if (snapshot.exists) {
      return Message.fromFirestore(snapshot);
    } else {
      return null;
    }
  }

  Future<void> updateMessage(Message message) async {
    final documentReference =
        FirebaseFirestore.instance.collection('messages').doc(message.id);
    await documentReference.update(message.toMap());
  }

  Future<void> deleteMessage(String id) async {
    final documentReference =
        FirebaseFirestore.instance.collection('messages').doc(id);
    await documentReference.delete();
  }

  Future<List<Message>> getMessagesFutureList() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('messages').get();
    return querySnapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .toList();
  }
}
