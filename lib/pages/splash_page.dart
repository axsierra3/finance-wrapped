import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_finances_wrapped/app_theme.dart';
import 'package:flutter_finances_wrapped/nav_tab_manager.dart';
import 'package:flutter_finances_wrapped/user_handling/signup_page.dart';
import 'package:flutter_finances_wrapped/auth_wrapper.dart';

// SPLASH PAGE:
// animated logo intro screen
// plays once when app opens, then auto navigates
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState(); //each stateful widget needs to override createState w/ itself as a type paramter, we have it return our new _SplashPageState class
}

//single ticker provider mixin (extra functionality bolted on to the state class)
// gives us a ticker, aka a 60fps clock that AnimationController needs to update every fram
// single bc we only have 1 animation
class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {

  // drives the animation & tracks its progress from 0.0 to 1.0
  //every frame it updates and calles setState automatically
  late AnimationController _controller;

  // tracks whether the text for tagline / title should be visible
  // starts hidden, becomes true when animation finishes
  bool _showText = false;

  @override
  void initState() {
    super.initState();

    // create the controller with a 2.8 second duration
    // vsync: this connects it to the ticker from the mixin
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3800),
      vsync: this,
    );

    // addStatusListener starts when the animation finishes (listens to status of animation)
    // we use this to trigger the text fade-in AFTER drawing done
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showText = true;
        });

        

        // wait 1.2 seconds for text to show, then navigate to other page
        // gives the user a moment to read the tagline
        Future.delayed(const Duration(milliseconds: 3200), _navigate);
      }
    });

     // delay before animation starts — remove after recording!
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _controller.forward();
    });
  }

  // NAVIGATE AWAY FROM SPLASH (called after status listener delay)
  // after splash, figure out where to go based on stream builder
  void _navigate() {
  if (!mounted) return;
  // AuthWrapper has the StreamBuilder watching auth state
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => const AuthWrapper(),
    ),
  );
}
  // dispose is called when the widget is removed from screen
  // gotta clean up the controller or it'll leak memory
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

//widgets override build method to describe UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mint,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ANIMATED LOGO 
            // AnimatedBuilder rebuilds its child every frame
            // whenever the animation value changes
            // passing _controller as animation means it watches
            // _controller.value (which goes from 0.0  1.0)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(180, 180),
                  // pass the current progress value from controller above to the painter
                  // every frame this widget updates, painter redraws
                  painter: LogoPainter(progress: _controller.value),
                );
              },
            ),

            const SizedBox(height: 16),

            // TITLE & TAGLINE 
            // AnimatedOpacity smoothly fades between opacity values
            // when _showText becomes true, it fades from 0 → 1
            AnimatedOpacity(
              opacity: _showText ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 800),
              child: Column(
                children: [
                  const Text(
                    'Finance Wrapped',
                    style: TextStyle(
                      color: AppTheme.darkGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'your spending, decoded',
                    style: TextStyle(
                      color: AppTheme.mutedGreen,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
