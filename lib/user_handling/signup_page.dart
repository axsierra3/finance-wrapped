import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_finances_wrapped/app_theme.dart';
import 'login_page.dart';

//Signup page Widget supporting stage changes
class SignUpPage extends StatefulWidget {
  //instance of signup page, with identity key for state management
  const SignUpPage({super.key});

  //create state for signup page
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

//state for signup page (the changing data and behavior of the screen), extending SignUpPage state
class _SignUpPageState extends State<SignUpPage> {

//2 controller objects for text fields to capture and track user input for display name, username and password
  final TextEditingController nameController = TextEditingController();   
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

//message to user (later used to display account creation success or error messages)
  String message = "";

//signup function to create account using Firebase auth
//returns a Futue<void>, and is marked async bc it perfroms async/await operations with Firebase
  Future<void> signUp() async {
     // make sure name isn't blank
    if (nameController.text.trim().isEmpty) {
      setState(() { message = "Please enter your name"; });
      return;
    }

    try {

      // convert username to fake email for firebasw auth (firebase requires email)
      //gets username from usernameController, trims whitespace, and appends a fake @
      String fakeEmail = "${usernameController.text.trim()}@financewrapped.app";

// uses FirebaseAuth to create user with email and password, using the fake email and password from passwordController
//sends to Google's auth servers, handling duplicates, & hashes passwords
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: passwordController.text.trim(),
      );

       // save their name to Firebase right after creating the account  
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        nameController.text.trim(),
      );

// success! update message to user
      setState(() {
        message = "Account created!";
      });


//catches any Firebase auth exceptions
    } on FirebaseAuthException catch (error) {

      if (error.code == 'email-already-in-use') {
        setState(() {
          message = "Username already taken";
        });
      } else if (error.code == 'weak-password') {
        setState(() {
          message = "Password must be at least 6 characters";
        });
      } else {
        setState(() {
          message = "Error: ${error.message}";
        });
      }

    }
  }

// ── HELPER: field label ───
  // the small "FIRST NAME" / "USERNAME" labels above inputs
  // takes label text and returns w/ consistent styling
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.forestGreen,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }


  // ── HELPER: styled input field ───────
  // the frosted glass text fields with mint borders
  // takes controller to track user input from build, and custom hint text
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(
        color: AppTheme.darkGreen,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppTheme.forestGreen.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        filled: true,
        // semi-transparent white = frosted glass look
        fillColor: Colors.white.withValues(alpha: 0.45),
        // border when NOT focused
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        // border when focused/typing
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.forestGreen,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12,
        ),
      ),
    );
  }



//build function to return the UI of signup page as a Widget that updates based on state changes
//uses Scaffold for page frame/layout template
@override
  Widget build(BuildContext context) {
    return Scaffold(
      // mint background
      backgroundColor: AppTheme.mint,
      body: SafeArea(
        child: Center(
          // SingleChildScrollView prevents overflow on small screens it allows the content to scroll if it doesnt fit
          // keyboard pushing content up won't cause yellow/black stripes
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // LOGO (static, fully drawn bersion): so progress is at 1.0. no animation
                // CustomPaint is a widget allowing to draw custom shapes,uses our LogoPainter from app_theme.dart
                CustomPaint(
                  size: const Size(120, 120),
                  painter: LogoPainter(progress: 1.0),
                ),
                const SizedBox(height: 12),

                // TITLE + TAGLINE 
                const Text(
                  'Finance Wrapped',
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4), 
                const Text(
                  'your spending, decoded',
                  style: TextStyle(
                    color: AppTheme.mutedGreen,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 28),

                //  NAME FIELD ---
                // _buildLabel and _buildField are helper methods that return styled widgets for labels and text fields
                _buildLabel('FIRST NAME'),
                const SizedBox(height: 4),
                _buildField(
                  controller: nameController,
                  hint: 'your first name', //hints are text before user starts typing
                ),
                const SizedBox(height: 12),

                // USERNAME FIELD ───
                _buildLabel('USERNAME'),
                const SizedBox(height: 4),
                _buildField(
                  controller: usernameController,
                  hint: 'choose a username',
                ),
                const SizedBox(height: 12),

                // PASSWORD FIELD ───
                _buildLabel('PASSWORD'),
                const SizedBox(height: 4),
                _buildField(
                  controller: passwordController,
                  hint: 'at least 6 characters',
                  isPassword: true,
                ),
                const SizedBox(height: 20),

                // CREATE ACCOUNT BUTTON ────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestGreen,
                      foregroundColor: AppTheme.mint,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0, // flat, no shadow 
                    ),
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── LOGIN LINK ───
                TextButton(
                  onPressed: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const LoginPage()), //take to login page on push
                    );
                  },
                  child: const Text(
                    'Already have an account? Log in',
                    style: TextStyle(
                      color: AppTheme.forestGreen,
                      fontSize: 12,
                    ),
                  ),
                ),

                // ── ERROR/SUCCESS MESSAGE ────
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      color: message.contains("Error") || message.contains("already") || message.contains("Password") || message.contains("Please")
                          ? const Color(0xFFB42318) // red for errors
                          : AppTheme.forestGreen,   // green for success
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}