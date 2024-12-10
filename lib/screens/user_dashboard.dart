import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:spotlessyou/services/spotlessyouuser_service.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/spotelessyou_user.dart';

class UserDashboard extends StatefulWidget {
  UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  File? _image;
  String? _imageUrl;
  bool _isUploading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userEmail = "";
  late Future<SpotelessYouUser?> spotelessYouUser;

  @override
  void initState() {
    super.initState();
    userEmail = _auth.currentUser!.email!;
    spotelessYouUser = SpotlessyouuserService().getUserByEmail(userEmail);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        if (!mounted) return; // Check if the widget is still mounted
        setState(() {
          _image = File(pickedFile.path);
          _isUploading = true;
        });

        final storage = FirebaseStorage.instance;
        final imageRef = storage
            .ref()
            .child('uploads/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await imageRef.putFile(_image!);
        final downloadUrl = await imageRef.getDownloadURL();

        if (!mounted) return;
        setState(() {
          _imageUrl = downloadUrl;
          _isUploading = false;
        });

        print('Image uploaded successfully! URL: $downloadUrl');
      } else {
        print('No image selected.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      print('Error uploading image: $e');
    }
  }

  void _runModel() async {
    try {
      // Load the TFLite model using tflite_flutter's Interpreter
      final interpreter = await Interpreter.fromAsset(
        'assets/mlmodel/acne_severity_classification_model.tflite',
      );

      // Get input and output tensor details
      final inputDetails = interpreter.getInputTensors();
      final outputDetails = interpreter.getOutputTensors();

      // Extract input shape: [1, height, width, channels] (e.g., [1, 224, 224, 3])
      final inputShape = inputDetails[0].shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];
      final inputChannels = inputShape[3];

      // Load and preprocess the image
      var inputImage = _image!.readAsBytesSync(); // Get image bytes from the file
      img.Image? image = img.decodeImage(inputImage); // Decode the image using package:image/image.dart

      if (image == null) throw Exception("Failed to decode image");

      // Resize the image to the model's expected input size
      img.Image resizedImage = img.copyResize(image, width: inputWidth, height: inputHeight);

      // Normalize the image data to [0, 1]
      var input = _preprocessImage(resizedImage, inputHeight, inputWidth, inputChannels);

      // Define the output array
      final output = List.filled(outputDetails[0].shape.reduce((a, b) => a * b), 0.0)
          .reshape(outputDetails[0].shape);

      // Run inference
      interpreter.run(input, output);

      // Define the categories (as per your model)
      List<String> categories = ['Mild', 'Moderate', 'Severe'];

      // Map the output to categories
      List<Map<String, dynamic>> results = [];
      for (int i = 0; i < output[0].length; i++) {
        results.add({
          'label': categories[i],
          'confidence': output[0][i],
        });
      }

      // Print the output
      print('Model output: $results');

      // Navigate to the result screen with the model's output
      Navigator.pushNamed(
        context,
        '/userResultScreen',
        arguments: {'results': results, 'imageUrl': _imageUrl},
      );
    } catch (e) {
      // Handle errors gracefully
      print('Error running model: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error running AI model: $e')),
      );
    }
  }

// Helper function to preprocess the image
  List<List<List<List<double>>>> _preprocessImage(
      img.Image image, int height, int width, int channels) {
    // Convert the image to a 4D array: [1, height, width, channels]
    var input = List.generate(
      1,
          (_) => List.generate(
        height,
            (y) => List.generate(
          width,
              (x) => List.generate(
            channels,
                (c) {
              int pixel = image.getPixel(x, y);
              double channelValue;
              if (c == 0) {
                channelValue = img.getRed(pixel).toDouble();
              } else if (c == 1) {
                channelValue = img.getGreen(pixel).toDouble();
              } else {
                channelValue = img.getBlue(pixel).toDouble();
              }
              return channelValue; // Normalize to [0, 1]
            },
          ),
        ),
      ),
    );

    return input;
  }

  void _showEditProfileModal(SpotelessYouUser spotlessYouUser) {
    // Ensure data from the user object is passed to controllers
    var nameController = TextEditingController(text: spotlessYouUser.name);
    var mobileController = TextEditingController(text: spotlessYouUser.mobile);
    var bioController = TextEditingController(text: spotlessYouUser.bio);

    print('Updating user with email: ${spotlessYouUser.name}');
    print('Updating user with email: ${spotlessYouUser.mobile}');
    print('Updating user with email: ${spotlessYouUser.bio}');

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
          child: SingleChildScrollView(
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
                    // Create updated user object
                    var updatedUser = spotlessYouUser.copyWith(
                      name: nameController.text,
                      mobile: mobileController.text,
                      bio: bioController.text,
                    );

                    // Update user details in Firebase
                    await SpotlessyouuserService().updateUser(updatedUser);

                    // Notify user and refresh the UI
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully!')),
                    );
                    Navigator.pop(context); // Close the modal
                    setState(() {
                      spotelessYouUser = SpotlessyouuserService()
                          .getUserByEmail(userEmail); // Refresh the user data
                    });
                  },
                  child: const Text('Save Changes'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
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
        backgroundColor: Colors.pink[100],
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          title: const Text('User Dashboard'),
          automaticallyImplyLeading: false, // Remove the back button
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/userHistoryScreen'),
              icon: const Icon(Icons.history),
            ),
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
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 200,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Get an Acne Diagnosis',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Capture Image'),
                              onTap: () {
                                Navigator.pop(context); // Close the bottom sheet
                                _pickImage(ImageSource.camera); // Open the camera
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo),
                              title: const Text('Select from Gallery'),
                              onTap: () {
                                Navigator.pop(context); // Close the bottom sheet
                                _pickImage(ImageSource.gallery); // Open the gallery
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Upload Image'),
                ),
                const SizedBox(height: 20),
                if (_isUploading)
                  Column(
                    children: const [
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                    ],
                  ),
                if (_imageUrl != null)
                  Container(
                    height: 300,
                    child: Image.network(_imageUrl!),
                  ),
                const SizedBox(height: 50),
                ElevatedButton.icon(
                  onPressed: _imageUrl != null
                      ? () {
                          _runModel();
                        }
                      : null,
                  icon: const Icon(Icons.sync),
                  label: const Text('Check With AI'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
