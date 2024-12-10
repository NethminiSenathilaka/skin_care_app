import 'package:cloud_firestore/cloud_firestore.dart';
import 'spotelessyou_user.dart'; // Import the SpotelessYouUser model

class Message {
  final String id;
  final String user;
  final String text;
  final String title;
  final String description;
  final String status;
  final String imageurl;
  // final SpotelessYouUser doctor;
  final String timestamp;
  final String docname;
  final String docemail;
  String response;
  String feedback;

  Message({
    required this.id,
    required this.user,
    required this.text,
    required this.title,
    required this.description,
    required this.status,
    required this.imageurl,
    // required this.doctor,
    required this.timestamp,
    required this.docname,
    required this.docemail,
    required this.response,
    required this.feedback,
  });

  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return Message(
      id: snapshot.id,
      user: snapshot.data()!['user'],
      text: snapshot.data()!['text'],
      title: snapshot.data()!['title'],
      description: snapshot.data()!['description'],
      status: snapshot.data()!['status'],
      imageurl: snapshot.data()!['imageurl'],
      // doctor: SpotelessYouUser.fromFirestore(snapshot.data()!['doctor']),
      timestamp: snapshot.data()!['timestamp'],
      docname: snapshot.data()!['docname'],
      docemail: snapshot.data()!['docemail'],
      response: snapshot.data()!['response'],
      feedback: snapshot.data()!['feedback'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user': user,
      'text': text,
      'title': title,
      'description': description,
      'status': status,
      'imageurl': imageurl,
      // 'doctor': doctor.toMap(),
      'timestamp': timestamp,
      'docname': docname,
      'docemail': docemail,
      'response': response,
      'feedback': feedback,
    };
  }

  Message copyWith({
    String? id,
    String? user,
    String? text,
    String? title,
    String? description,
    String? status,
    String? imageurl,
    String? timestamp,
    String? docname,
    String? docemail,
    String? response,
    String? feedback,
  }) {
    return Message(
      id: id ?? this.id,
      user: user ?? this.user,
      text: text ?? this.text,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      imageurl: imageurl ?? this.imageurl,
      timestamp: timestamp ?? this.timestamp,
      docname: docname ?? this.docname,
      docemail: docemail ?? this.docemail,
      response: response ?? this.response,
      feedback: feedback ?? this.feedback,
    );
  }
}
