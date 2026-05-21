import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'user_handling/firebase_options.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Finance Wrapped',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ), //let splash page run on app launch and decide where to go originally (signup or navtabmanager), for logout manually go back to signup
        home: const SplashPage(),
    );
  }
}