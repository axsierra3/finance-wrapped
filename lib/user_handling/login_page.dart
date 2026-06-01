import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_finances_wrapped/app_theme.dart';
import 'package:flutter_finances_wrapped/nav_tab_manager.dart';

//Login page Widget supporting state changes
class LoginPage extends StatefulWidget {
  //instance of login page, with key for state management
  const LoginPage({super.key});

  //create state for login page
  @override
  State<LoginPage> createState() => _LoginPageState();
}

//state for login page (data and behavior)
class _LoginPageState extends State<LoginPage> {

//2 controller objects for text fields to capture and track user input for username and password
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

//message for user (says login success or error)
  String message = "";

//login function to authenticate user using Firebase auth
//returns a Future<void>, and is marked async bc it performs async/await operations with Firebase
  Future<void> login() async {
    try {
      String fakeEmail = "${usernameController.text.trim()}@financewrapped.app";

//uses Firbase Auth to sign in user with email and password
//sends to backkend, validates credentials, if acct exists in firbase proj
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: fakeEmail,
        password: passwordController.text.trim(),
      );

//success!
        setState(() {
          message = "You are logged in!";
          });
          if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const NavTabManager()),
                (route) => false,
              );
}
          } on FirebaseAuthException catch (error) {
          if (error.code == 'user-not-found') {
            setState (() {
              message = "No account found for that username";
            });
          } else if (error.code == 'wrong-password') {
            setState(() {
              message = "Incorrect password";
            });
          } else {
            setState(() {
              message = "Error: ${error.message}";
            });
          }
        }
      }

//same helper methods for building labels and text fields as in signup page
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
          fillColor: Colors.white.withValues(alpha: 0.45),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
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
      @override 
      Widget build(BuildContext context) {
        return Scaffold(
          backgroundColor: AppTheme.mint,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ── LOGO ────────────────────────────────
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: LogoPainter(progress: 1.0),
                    ),
                    const SizedBox(height: 12),

                    // ── TITLE — different from signup ───────
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: AppTheme.darkGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'sign in to continue',
                      style: TextStyle(
                        color: AppTheme.mutedGreen,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── USERNAME FIELD ──────────────────────
                    _buildLabel('USERNAME'),
                    const SizedBox(height: 4),
                    _buildField(
                      controller: usernameController,
                      hint: 'your username',
                    ),
                    const SizedBox(height: 12),

                    // ── PASSWORD FIELD ──────────────────────
                    _buildLabel('PASSWORD'),
                    const SizedBox(height: 4),
                    _buildField(
                      controller: passwordController,
                      hint: 'your password',
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),

                    // ── LOG IN BUTTON ───────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,
                          foregroundColor: AppTheme.mint,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── SIGNUP LINK ─────────────────────────
                    TextButton(
                      onPressed: () {
                        // pop goes BACK to signup instead of pushing
                        // a new screen on top — cleaner navigation
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'New here? Create an account',
                        style: TextStyle(
                          color: AppTheme.forestGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // ── ERROR MESSAGE ───────────────────────
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: TextStyle(
                          color: message.contains("Error") || message.contains("No account") || message.contains("Incorrect")
                              ? const Color(0xFFB42318)
                              : AppTheme.forestGreen,
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







