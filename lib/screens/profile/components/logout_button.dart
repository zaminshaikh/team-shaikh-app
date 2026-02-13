// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agq_app/database/auth_helper.dart';
import 'package:agq_app/database/models/client_model.dart';
import 'package:agq_app/screens/utils/resources.dart';

class LogoutButton extends StatefulWidget {
  final Client client;

  const LogoutButton({super.key, required this.client});

  @override
  LogoutButtonState createState() => LogoutButtonState();
}

class LogoutButtonState extends State<LogoutButton> {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showLogoutDialog(context),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Changed from Color.fromARGB(255, 149, 28, 28)
                  border: Border.all(color: Colors.red), // Added red border
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/logout.svg',
                        color: Colors.red, // Changed from Colors.white
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red, // Changed from Colors.white
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) => AlertDialog(
          backgroundColor: AppColors.defaultBlueGray800,
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Confirm Logout',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/icons/logout.svg',
                        width: 24,
                        height: 24,
                        color: Colors.white, 
                      ),
                    ],
                  ),
                ),
                const Text('Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); 
                _logout(); 
              },
              child: Container(
                width: double.infinity, 
                padding: const EdgeInsets.symmetric(vertical: 10), 
                decoration: BoxDecoration(
                  color: Colors.transparent, // Changed from Color.fromARGB(255, 149, 28, 28)
                  border: Border.all(color: Colors.red, width: 1.5), // Added red border
                  borderRadius: BorderRadius.circular(10), 
                ),
                child: const Text(
                  'Logout',
                  textAlign: TextAlign.center, 
                  style: TextStyle(
                    color: Colors.red, // Changed from default color
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10), 
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); 
              },
              child: Container(
                width: double.infinity, 
                padding: const EdgeInsets.symmetric(vertical: 10), 
                decoration: BoxDecoration(
                  color: Colors.transparent, 
                  border: Border.all(
                    color: Colors.white, 
                    width: 1, 
                  ),
                  borderRadius: BorderRadius.circular(10), 
                ),
                child: const Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, 
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  void _logout() async {
    log('settings.dart: Signing out...');

    Future<void> handleLogout() async {
      // Continue sign out asynchronously.
      await deleteFirebaseMessagingToken(FirebaseAuth.instance.currentUser, context);
      await FirebaseAuth.instance.signOut();
      assert(FirebaseAuth.instance.currentUser == null);
      log('settings.dart: Successfully signed out');
      return;
    }
    unawaited(handleLogout());
    // Immediately navigate away to avoid security rules issues when signed out.
    await Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);

    // Continue sign out asynchronously.
    return;
  }
}


