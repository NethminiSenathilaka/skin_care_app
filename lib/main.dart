import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotlessyou/firebase_options.dart';
import 'package:spotlessyou/provider/user_provider.dart';
import 'package:spotlessyou/screens/admin_dashboard.dart';
import 'package:spotlessyou/screens/doctor_dashboard.dart';
import 'package:spotlessyou/screens/doctor_password_change_screen.dart';
import 'package:spotlessyou/screens/doctor_signup_screen.dart';
import 'package:spotlessyou/screens/home_screen.dart';
import 'package:spotlessyou/screens/login_screen.dart';
import 'package:spotlessyou/screens/user_dashboard.dart';
import 'package:spotlessyou/screens/user_history_screen.dart';
import 'package:spotlessyou/screens/user_result_screen.dart';
import 'package:spotlessyou/screens/user_signup_screen.dart';
import 'package:spotlessyou/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Spotless You",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      // home: const SplashScreen(),
      initialRoute: "/",
      // initialRoute: '/userDashboard',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/userSignup': (context) => const UserSignUpScreen(),
        '/doctorSignup': (context) => const DoctorSignUpScreen(),
        '/doctorPasswordChange': (context) => const DoctorPasswordChangeScreen(),
        '/userDashboard': (context) => UserDashboard(),
        '/adminDashboard': (context) => AdminDashboard(),
        '/doctorDashboard': (context) => DoctorDashboard(),
        '/userResultScreen': (context) => UserResultScreen(),
        '/userHistoryScreen': (context) => UserHistoryScreen(),
      },
    );
  }
}
