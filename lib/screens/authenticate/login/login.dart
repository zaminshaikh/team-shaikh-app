// Importing Flutter Library & Google button Library
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:custom_signin_buttons/custom_signin_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_shaikh_app/screens/authenticate/create_account.dart';
import 'package:team_shaikh_app/screens/authenticate/login/forgot_password.dart';
import 'package:team_shaikh_app/utilities.dart';


// Creating a stateful widget for the Login page
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

// State class for the LoginPage
class _LoginPageState extends State<LoginPage> {

  // Boolean variable to set password visibility to hidden
  bool hidePassword = true;
  // Boolean variable to set the remember me checkbox to unchecked, and initializing that the user does not want the app to remember them
  bool rememberMe = false;
  
  // Controllers to store login email and password
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Sign user in method
  void signUserIn(context) async {
    // try login
    try {
      // Create a new UserCredential from Firebase with given details 
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // Successfully signed in, you can navigate to the next screen or perform other actions.
      log('login.dart: Signed in user ${userCredential.user!.uid}');
      // await userCredential.user!.reload(); // Trigger the stream to update in wrapper.dart
      // Trigger the stream to update in wrapper.dart

    } on FirebaseAuthException catch (e) {
      // Handle errors and show an error message.
      String errorMessage = '';
        // Check if the error is due to the email not being found
      if (e.code == 'user-not-found') {
        errorMessage = 'Email not found. Please check your email or sign up for a new account.';
      } else {
        errorMessage = 'Error signing in. Please check your email and password. $e';
      }
      // Display the error message using a dialog.
      await CustomAlertDialog.showAlertDialog(context, 'Error logging in', errorMessage);
    }
  }


  // The build method for the login screen widget
  @override
  Widget build(BuildContext context) => Scaffold(
    // Padding for the overall layout
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        // Column to arrange UI elements vertically
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo and branding
            const SizedBox(height: 40.0),
            Align(
              alignment: const Alignment(-1.0, -1.0),
              child: Image.asset(
              'assets/icons/team-shaikh-transparent.png',
              height: 100,
            ),
            ),
            // Spacing
            const SizedBox(height: 60.0),
            
            // Title for the login section
            const Text(
              'Login to Your Account',
              style: TextStyle(
                fontSize: 26, 
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontFamily: 'Titillium Web'
              ),
            ),
            // Spacing
            const SizedBox(height: 35.0),
            
            // Email input field
            Container(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ), 
                    // Input field styling
                    decoration: InputDecoration(
                      hintText: 'Enter your email', 
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 122, 122, 122), 
                        fontFamily: 'Titillium Web'
                      ),
                      // Border and focus styling
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    ),
                    onChanged: (value){
                      setState(() {
                        emailController.text = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Spacing
            const SizedBox(height: 16.0),
            
            // Password input field
            Container(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextField(
                    controller: passwordController,
                    style: const TextStyle(
                      fontSize: 16, 
                      color: Colors.white, 
                      fontFamily: 'Titillium Web'
                    ), 
                    // Input field styling with password visibility toggle
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 122, 122, 122), 
                        fontFamily: 'Titillium Web'
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: Color.fromARGB(255, 27, 123, 201)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            hidePassword = !hidePassword;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Icon(
                            hidePassword ? Icons.remove_red_eye_outlined : Icons.remove_red_eye_rounded,
                            size: 25,
                            color: const Color.fromARGB(255, 154, 154, 154),
                          ),
                        ),
                      ),
                    ),
                    obscureText: hidePassword,
                    onChanged: (value) {
                      setState(() {
                        passwordController.text = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Spacing
            const SizedBox(height: 20.0),
            
            // Remember Me and Forgot Password section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                    // GestureDetector(
                    //   onTap: () {
                    //     setState(() {
                    //       rememberMe = !rememberMe;
                    //     });
                    //   },
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(6.0),
                    //     child: Icon(
                    //       rememberMe ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    //       size: 24,
                    //       color: Colors.white,
                    //     ),
                    //   ),
                    // ),
                    // const Text('Remember Me',
                    //   style: TextStyle(
                    //     fontSize: 16, 
                    //     color: Colors.white, 
                    //     fontFamily: 'Titillium Web'
                    //   )
                    // ),
                    // const SizedBox(width: 100),
                    
                    // Forgot Password link
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const ForgotPasswordPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                          ),
                        );                        
                      },
                      child: const TextButton(
                        onPressed: null,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.blue, 
                            fontFamily: 'Titillium Web'
                            ),
                        ),
                      ),
                    ),
                  ],
            ),
            // Spacing
            const SizedBox(height: 40.0),
            
            // Login Button
            GestureDetector(
              onTap: () => signUserIn(context),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: passwordController.text.isNotEmpty && emailController.text.isNotEmpty
                      ? const Color.fromARGB(255, 30, 75, 137)
                      : const Color.fromARGB(255, 85, 86, 87),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18, 
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontFamily: 'Titillium Web'
                    ),
                  ),
                ),
              ),
            ),
            // Spacing
            const SizedBox(height: 20.0),
            
            // Google Sign-In Button
            // Container(
            //   height: 55,
            //   decoration: BoxDecoration(
            //     color: Colors.transparent, 
            //     borderRadius: BorderRadius.circular(25),
            //     border: Border.all(color: const Color.fromARGB(255, 30, 75, 137), width: 4), 
            //   ),
            //   child: const Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Icon(
            //         FontAwesomeIcons.google,
            //         color: Colors.blue,
            //       ),
            //       SizedBox(width: 15),
            //       Text(
            //         'Sign in with Google',
            //         style: TextStyle(
            //           fontSize: 18, 
            //           color: Colors.blue, 
            //           fontWeight: FontWeight.bold, 
            //           fontFamily: 'Titillium Web'
            //           ),
            //       ),
            //     ],
            //   ),
            // ),
            // Spacing
            // const SizedBox(height: 30.0),
            
            // Login with Face ID
            // GestureDetector(
            //   behavior: HitTestBehavior.translucent,
            //   onTap: () {
            //   },
            //   child: const Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       TextButton(
            //         onPressed: null,
            //         child: Row(
            //           children: [
            //             Text(
            //               'Login with Face ID',
            //               style: TextStyle(
            //                 fontSize: 18, 
            //                 fontWeight: FontWeight.bold, 
            //                 color: Colors.blue, 
            //                 fontFamily: 'Titillium Web'
            //               ),
            //             ),
            //             SizedBox(width: 10),
            //             Icon(
            //               Icons.face,
            //               color: Colors.blue,
            //               size: 20,
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // Spacing
            const SizedBox(height: 40.0),
            
            // Sign-Up Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Don\'t have an account?',
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.white, 
                    fontFamily: 'Titillium Web'
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const CreateAccountPage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                      ),
                    );
                  },
                  child: const TextButton(
                    onPressed: null,
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18, 
                        color: Colors.blue, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Titillium Web'
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Spacing
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    ),
  );
}
