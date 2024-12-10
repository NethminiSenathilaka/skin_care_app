import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlessyou/services/message_service.dart';
import '../models/message.dart';
import '../provider/user_provider.dart';

class UserHistoryScreen extends StatefulWidget {
  UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  List<Message> messages = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userEmail = "";
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userEmail = _auth.currentUser!.email!;
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _auth.currentUser?.email;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Always prevent navigation
        return;
      },
      child: Scaffold(
        backgroundColor:Colors.pink[100],
        appBar: AppBar(
          backgroundColor: Colors.pink,
          title: Text('User History'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate to the user Dashboard
              Navigator.popAndPushNamed(context, '/userDashboard');
            },
          ),
        ),
        body: StreamBuilder<List<Message>>(
          stream: MessageService().getMessages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No messages found.'));
            }

            final filteredMessages = snapshot.data!
                .where((message) => message.user == userEmail)
                .toList();

            return ListView.builder(
              itemCount: filteredMessages.length,
              itemBuilder: (context, index) {
                final message = filteredMessages[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageurl.isNotEmpty)
                          Image.network(
                            message.imageurl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        const SizedBox(height: 10),
                        Text(
                          message.title,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(message.description),
                        const SizedBox(height: 12),
                        Text('Doctor : ${message.docname}'),
                        const SizedBox(height: 12),
                        Text('Doctor response: ${message.response}'),
                        const SizedBox(height: 12),
                        Text('Feedback: ${message.feedback}'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status: ${message.status}',
                              style: TextStyle(
                                color: Colors.redAccent,fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              message.timestamp,
                              style: TextStyle(
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (message.status == 'Complete' && message.feedback.isEmpty)
                          Column(
                            children: [
                              TextField(
                                controller: _feedbackController,
                                decoration: InputDecoration(
                                  labelText: 'Enter your Feedback',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  String feedback = _feedbackController.text;
                                  if (feedback.isNotEmpty) {
                                    final updatedMessage = message.copyWith(
                                        feedback: feedback);
                                    await MessageService()
                                        .updateMessage(updatedMessage);
                                    _feedbackController.clear();
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Feedback submitted successfully!'),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Please enter a feedback before submitting.'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.send),
                                label: const Text('Submit Feedback'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
