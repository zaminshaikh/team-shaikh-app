import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/authenticate/login/login.dart'; // Adjust the import path as necessary
import 'package:team_shaikh_app/screens/authenticate/create_account.dart';
import 'package:local_auth/local_auth.dart';



class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(_fadeAnimationController);

    _slideAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from slightly below the final position
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));

    // Listen to the status of the slide animation
    _slideAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Start the fade animation once the slide animation is complete
        _fadeAnimationController.forward();

      }
    });

    // Start the slide animation
    _slideAnimationController.forward();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 40, right: 40),
        child: Center( // This centers the content horizontally.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // This centers the content vertically.
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: Image.asset(
                  'assets/icons/team_shaikh_transparent.png',
                  height: 150,
                ),
              ),
              const SizedBox(height: 10), 
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Welcome to Team Shaikh!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('Please log in or create a new account to continue.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
                    SizedBox(height: 30),
                    GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to the Log In page
                          );
                        },
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 7, 48, 89),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 10), // Provides spacing between the buttons
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateAccountPage()), // Navigate to the Sign Up page
                        );
                      },
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 12, 76, 140),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Center(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ),
                        ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}