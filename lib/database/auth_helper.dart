import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/database/database.dart';

/// Deletes any user currently in the Firebase Auth buffer.
Future<void> deleteUserInBuffer() async {
  if (FirebaseAuth.instance.currentUser != null) {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        await FirebaseAuth.instance.signOut();
      } else {
        log('Error deleting user: $e', stackTrace: StackTrace.current);
      }
    }
    log('User after delete: ${FirebaseAuth.instance.currentUser ?? 'deleted'}');
  }
}

/// Handles FirebaseAuthException and displays an error message.
Future<void> handleFirebaseAuthException(
    BuildContext context, FirebaseAuthException e, String email) async {
  String errorMessage = 'Failed to sign up. Please try again.';
  // String? temp = FirebaseAuth.instance.currentUser?.email;
  switch (e.code) {
    case 'email-already-in-use':
      if (FirebaseAuth.instance.currentUser?.email == email) {
        await deleteUserInBuffer();
      } 
      errorMessage =
          'Email $email is already in use. Please use a different email.';
      break;
    case 'invalid-email':
      errorMessage = '"$email" is not a valid email format. Please try again.';
      log('Invalid email format.');
      break;
    case 'weak-password':
      errorMessage = 'The password provided is too weak.';
      log('Weak password.');
      break;
    default:
      log('FirebaseAuthException: $e');
  }
  if (!context.mounted) {
    return;
  }
  await CustomAlertDialog.showAlertDialog(context, 'Error', errorMessage,
      icon: const Icon(Icons.error, color: Colors.red));
}

/// Updates Firebase Messaging token.
Future<void> updateFirebaseMessagingToken(User? user, BuildContext context) async {
  if (user == null) {
    return;
  }
  String? token;
  try {
    token = await FirebaseMessaging.instance.getToken();
  } catch (e) {
    log('Error fetching token: $e');
    token = await FirebaseMessaging.instance.getAPNSToken();
    log('APNS Token found: $token');
  }
  if (token != null && context.mounted) {
    // Fetch CID using async constructor
    DatabaseService? db = await DatabaseService.fetchCID(user.uid, context);

    if (db != null) {
    try {
      List<dynamic> tokens =
          (await db.getField('tokens') ?? []);

      if (!tokens.contains(token)) {
        tokens = [...tokens, token];
        await db.updateField('tokens', tokens);
      }
    } catch (e) {
      log('login.dart: Error fetching tokens: $e');
    }
  }
  }// async gap widget mounting check
}

/// Deletes the Firebase Messaging token when the user signs out.
Future<void> deleteFirebaseMessagingToken(User? user, BuildContext context) async {
  if (user == null) {
    log('auth_helper.dart: User is null.'); 
    return;
  }
  // Retrieve the current FCM token
  String? token;
  try {
    token = await FirebaseMessaging.instance.getToken();
  } catch (e) {
    log('Error fetching token: $e');
    token = await FirebaseMessaging.instance.getAPNSToken();
    log('APNS Token found: $token');
  }

  if (token != null && context.mounted) {
    // Fetch the DatabaseService instance for the user
    DatabaseService? db = await DatabaseService.fetchCID(user.uid, context);

    if (db != null) {
      try {
        // Retrieve the current list of tokens from Firestore
        List<dynamic> tokens = (await db.getField('tokens')) ?? [];

        if (tokens.contains(token)) {
          // Remove the current token from the list
          tokens.remove(token);

          // Update the tokens field in Firestore
          await db.updateField('tokens', tokens);
          log('Token removed successfully.');
        }
      } catch (e) {
        log('Error deleting token: $e');
      }
    }
  }
}

/// Resends email verification to the current user.
Future<bool> resendEmailVerification(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        await CustomAlertDialog.showAlertDialog(
          context,
          'Error',
          'No user is currently signed in.',
        );
      }
      return false;
    }

    if (user.emailVerified) {
      if (context.mounted) {
        await CustomAlertDialog.showAlertDialog(
          context,
          'Already Verified',
          'Your email is already verified.',
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
        );
      }
      return true;
    }

    await user.sendEmailVerification();
    
    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        'Verification Email Sent',
        'A verification email has been sent to ${user.email}. Please check your email and click the verification link.',
        icon: const Icon(Icons.email_outlined, color: Colors.blue),
      );
    }
    
    return true;
  } on FirebaseAuthException catch (e) {
    log('Error resending verification email: $e');
    String errorMessage = 'Failed to send verification email. Please try again.';
    
    switch (e.code) {
      case 'too-many-requests':
        errorMessage = 'Too many requests. Please wait before requesting another verification email.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is invalid.';
        break;
      case 'user-not-found':
        errorMessage = 'No user found. Please sign in again.';
        break;
    }
    
    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        'Error',
        errorMessage,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
    
    return false;
  } catch (e) {
    log('Unexpected error resending verification email: $e');
    
    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        'Error',
        'An unexpected error occurred. Please try again.',
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
    
    return false;
  }
}