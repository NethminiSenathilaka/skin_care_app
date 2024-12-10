import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlessyou/services/message_service.dart';
import '../models/message.dart';
import '../models/spotelessyou_user.dart';
import '../provider/user_provider.dart';
import '../services/spotlessyouuser_service.dart';

class DoctorDashboard extends StatefulWidget {
  DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<Message> messages = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String docemail = "";
  final TextEditingController _responseController =
  TextEditingController();  // Move controller here
  late Future<SpotelessYouUser?> spotelessYouUser;
  late Future<bool> isFirstLogin;

  @override
  void initState() {
    super.initState();
    docemail = _auth.currentUser!.email!;
    spotelessYouUser = SpotlessyouuserService().getUserByEmail(docemail);
    isFirstLogin = SpotlessyouuserService().isFirstLogin(docemail);

    // Check if it's the first login and navigate to the password change screen
    isFirstLogin.then((firstLogin) {
      if (firstLogin) {
        // Trigger navigation to password change screen
        Navigator.pushReplacementNamed(context, '/doctorPasswordChange');
      }
    });
  }

  void _showEditProfileModal(SpotelessYouUser spotlessYouUser) {
    print(spotlessYouUser.password);
    var nameController = TextEditingController(text: spotlessYouUser.name);
    var mobileController = TextEditingController(text: spotlessYouUser.mobile);
    var bioController = TextEditingController(text: spotlessYouUser.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  var updatedUser = spotlessYouUser.copyWith(
                    name: nameController.text,
                    mobile: mobileController.text,
                    bio: bioController.text,
                  );
                  await SpotlessyouuserService().updateUser(updatedUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully!')));
                  Navigator.pop(context); // Close the modal
                  setState(() {
                    spotelessYouUser = SpotlessyouuserService().getUserByEmail(docemail);
                  });
                },
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final docemail = _auth.currentUser?.email;

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
          title: Text('Doctor Dashboard'),
          automaticallyImplyLeading: false,
          actions: [
            FutureBuilder<SpotelessYouUser?>(
              future: spotelessYouUser,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Icon(Icons.error);
                } else if (!snapshot.hasData) {
                  return const Icon(Icons.warning, color: Colors.red);
                } else {
                  final user = snapshot.data!;
                  return IconButton(
                    onPressed: () => _showEditProfileModal(user),
                    icon: const Icon(Icons.edit),
                  );
                }
              },
            ),
            IconButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              icon: const Icon(Icons.logout),
            ),
          ],
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
                .where((message) => message.docemail == docemail)
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(message.description),
                        const SizedBox(height: 10),
                        Text('Doctor : ${message.docname}'),
                        const SizedBox(height: 10),
                        Text('Doctor response: ${message.response}'),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status: ${message.status}',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 10),
                        TextField(
                          controller: _responseController,
                          decoration: InputDecoration(
                            labelText: 'Enter your response',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            String response = _responseController.text;
                            if (response.isNotEmpty) {
                              final updatedMessage = message.copyWith(
                                  response: response, status: 'Complete');
                              await MessageService()
                                  .updateMessage(updatedMessage);
                              _responseController.clear();
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Response submitted successfully!'),
                              ));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    'Please enter a response before submitting.'),
                              ));
                            }
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Submit Response'),
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