import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spotlessyou/models/message.dart';
import 'package:spotlessyou/services/message_service.dart';
import 'package:spotlessyou/services/spotlessyouuser_service.dart';

import '../models/spotelessyou_user.dart';

class UserResultScreen extends StatefulWidget {
  UserResultScreen({Key? key}) : super(key: key);

  @override
  State<UserResultScreen> createState() => _UserResultScreenState();
}

class _UserResultScreenState extends State<UserResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageService = MessageService();
  final _spotlessyouUserService = SpotlessyouuserService();
  final TextEditingController _aiTextController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String imageUrl = "";
  String aiPredictedText = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showInputFields = false;

  List<SpotelessYouUser> _doctorsList = [];
  SpotelessYouUser? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _fetchDoctorsList();
  }

  Future<void> _fetchDoctorsList() async {
    try {
      final doctors = await _spotlessyouUserService.getDoctorsList();
      setState(() {
        _doctorsList = doctors;
      });
    } catch (e) {
      print('Error fetching doctors list: $e');
    }
  }

  String _getCurrentTime() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedDoctor != null) {
      try {
        final userEmail = _auth.currentUser?.email;
        print(userEmail);
        final message = Message(
          timestamp: _getCurrentTime(),
          user: userEmail.toString(),
          text: _aiTextController.text,
          title: _titleController.text,
          description: _descriptionController.text,
          status: 'Pending',
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              Random().nextInt(1000).toString(),
          imageurl: imageUrl,
          docname: _selectedDoctor!.name,
          docemail: _selectedDoctor!.email,
          response: '', feedback: ''
          // doctor: _selectedDoctor!,
        );
        await _messageService.createMessage(message);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message Send to Doctor Successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/userDashboard');
      } catch (e) {
        print('Error creating message: $e');
      }
    }
  }

  void _toggleInputFields() {
    setState(() {
      _showInputFields = !_showInputFields;
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = _auth.currentUser;

    final Map<String, dynamic>? args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final aiResults = args?['results'] as List<Map<String, dynamic>>;
    imageUrl = args?['imageUrl'] as String;

    // Extract the confidence values for each category
    double mildConfidence = 0.0;
    double moderateConfidence = 0.0;
    double severeConfidence = 0.0;

    for (var result in aiResults) {
      switch (result['label']) {
        case 'Mild':
          mildConfidence = result['confidence'];
          break;
        case 'Moderate':
          moderateConfidence = result['confidence'];
          break;
        case 'Severe':
          severeConfidence = result['confidence'];
          break;
      }
    }

    // Determine the AI-predicted category
    String aiPredictedText = "";
    if (mildConfidence > moderateConfidence && mildConfidence > severeConfidence) {
      aiPredictedText = "Mild with ${(mildConfidence * 100).toStringAsFixed(2)}% confidence";
    } else if (moderateConfidence > mildConfidence &&
        moderateConfidence > severeConfidence) {
      aiPredictedText = "Moderate with ${(moderateConfidence * 100).toStringAsFixed(2)}% confidence";
    } else if (severeConfidence > mildConfidence &&
        severeConfidence > moderateConfidence) {
      aiPredictedText = "Severe with ${(severeConfidence * 100).toStringAsFixed(2)}% confidence";
    }
    _aiTextController.text = aiPredictedText;
    print(username?.email.toString());
    print(imageUrl);
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
          title: const Text('User Result Dashboard'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/userHistoryScreen'),
              icon: const Icon(Icons.history),
            ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    imageUrl,
                    height: 200,
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'AI Predicted Result',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          controller: _aiTextController,
                        ),
                        const SizedBox(height: 30),
                        Visibility(
                          visible: _showInputFields,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _titleController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _descriptionController,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Please enter Description';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),
                              DropdownButtonFormField<SpotelessYouUser>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Doctor',
                                  border: OutlineInputBorder(),
                                ),
                                items: _doctorsList.map((doctor) {
                                  return DropdownMenuItem<SpotelessYouUser>(
                                    value: doctor,
                                    child: Text(doctor.name),
                                  );
                                }).toList(),
                                onChanged: (SpotelessYouUser? value) {
                                  setState(() {
                                    _selectedDoctor = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a doctor';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Visibility(
                        visible: !_showInputFields,
                        child: ElevatedButton.icon(
                          onPressed: _toggleInputFields,
                          icon: const Icon(Icons.health_and_safety),
                          label: const Text('Contact Doctor'),
                        ),
                      ),
                      Visibility(
                        visible: _showInputFields,
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.send),
                          label: const Text('Direct to Doctor'),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/userDashboard'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
