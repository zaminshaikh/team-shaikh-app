import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/database/database.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:provider/provider.dart';

import 'package:agq_app/database/auth_helper.dart';

class AppleAuthService {
  /// Sign in with Apple (without CID - for login)
  Future<bool> signInWithApple(BuildContext context) async {
    try {
      // Check if Apple Sign In is available on this platform
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          await CustomAlertDialog.showAlertDialog(
            context,
            'Not Available',
            'Sign in with Apple is not available on this device.',
            icon: const Icon(Icons.error_outline, color: Colors.red),
          );
        }
        return false;
      }

      log('Starting Apple sign in process (login flow)');
      
      // Generate secure nonce - MUST follow Firebase requirements
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      
      log('Generated nonce for Apple Sign In');

      // Request credential from Apple
      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );
        
        log('Got Apple credential with identity token length: ${appleCredential.identityToken?.length ?? 0}');
        
        if (appleCredential.identityToken == null) {
          log('Error: Identity token is null');
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Apple Sign In failed: Identity token is null',
          );
        }

        // Create OAuthCredential
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken!,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        );
        
        log('Created OAuth credential for Firebase');

        // Sign in with Firebase
        final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        final user = userCredential.user;
        
        if (user == null) {
          log('Error: Firebase user is null after sign in');
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Failed to get user after Apple sign in',
          );
        }
        
        log('Successfully signed in with Firebase using Apple ID: ${user.uid}');

        // Update display name if needed
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          String fullName = '${appleCredential.givenName} ${appleCredential.familyName}';
          if (user.displayName == null || user.displayName!.isEmpty) {
            await user.updateDisplayName(fullName);
          }
        }
        
        // Check if this user has a linked CID
        final db = DatabaseService(user.uid);
        final isLinked = await db.isUIDLinked(user.uid);
        
        if (!isLinked) {
          log('User is not linked to any CID');
          if (context.mounted) {
            await CustomAlertDialog.showAlertDialog(
              context,
              'Account Not Found',
              'This Apple ID is not linked to any account. Please create an account first.',
              icon: const Icon(Icons.error_outline, color: Colors.red),
            );
          }
          await FirebaseAuth.instance.signOut();
          return false;
        }
        if (!context.mounted) return false;
        // Update Firebase messaging token
        await updateFirebaseMessagingToken(user, context);
                
        return true;
      } catch (signInError) {
        log('Error during Apple Sign In process: $signInError');
        rethrow;
      }
    } catch (e) {
      log('Error in Apple sign in: $e', stackTrace: StackTrace.current);
      if (context.mounted) {
        String message = 'Failed to sign in with Apple';
        if (e.toString().contains('canceled')) {
          message = 'Sign in was canceled';
        } else if (e.toString().contains('invalid-credential')) {
          message = 'Authentication failed. Please try again or use another method.';
        }
        await _showError(context, message);
      }
      return false;
    }
  }

  /// Sign up with Apple account (with CID)
  Future<void> signUpWithApple(BuildContext context, String cid) async {
    try {
      // Check if Apple Sign In is available on this platform
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          await CustomAlertDialog.showAlertDialog(
            context,
            'Not Available',
            'Sign in with Apple is not available on this device.',
            icon: const Icon(Icons.error_outline, color: Colors.red),
          );
        }
        return;
      }

      log('Starting Apple sign in process');
      
      // Generate secure nonce - MUST follow Firebase requirements
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      
      log('Generated nonce for Apple Sign In');

      // Request credential from Apple
      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );
        
        log('Got Apple credential with identity token length: ${appleCredential.identityToken?.length ?? 0}');
        
        if (appleCredential.identityToken == null) {
          log('Error: Identity token is null');
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Apple Sign In failed: Identity token is null',
          );
        }

        // Create OAuthCredential
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken!,
          rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,
        );
        
        log('Created OAuth credential for Firebase');

        // Sign in with Firebase
        final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        final user = userCredential.user;
        
        if (user == null) {
          log('Error: Firebase user is null after sign in');
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Failed to get user after Apple sign in',
          );
        }
        
        log('Successfully signed in with Firebase using Apple ID: ${user.uid}');

        // Process the user data
        String displayName = 'Apple User';
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
          // Update display name if needed
          if (user.displayName == null || user.displayName!.isEmpty) {
            await user.updateDisplayName(displayName);
          }
        }
        if (!context.mounted) return;
        // Process sign-up with database
        await _processSignUp(context, userCredential, cid);
      } catch (signInError) {
        log('Error during Apple Sign In process: $signInError');
        rethrow;
      }
    } catch (e) {
      log('Error in Apple sign up: $e', stackTrace: StackTrace.current);
      if (context.mounted) {
        String message = 'Failed to sign up with Apple';
        if (e.toString().contains('canceled')) {
          message = 'Sign in was canceled';
        } else if (e.toString().contains('invalid-credential')) {
          message = 'Authentication failed. Please try again or use another method.';
        }
        await _showError(context, message);
      }
    }
  }

  /// Generates a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the SHA-256 hash of [input] in hex notation
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Process the sign up after authentication
  Future<void> _processSignUp(
      BuildContext context, UserCredential userCredential, String cid) async {
    User user = userCredential.user!;
    log('Processing Apple sign up for user: ${user.uid}');

    // Check if this is a new user
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    log('Is new user: $isNewUser');

    try {
      // Initialize database with CID
      final db = DatabaseService.withCID(user.uid, cid);

      // Check if CID exists
      if (!(await db.checkDocumentExists(cid)) && context.mounted) {
        log('No record found for Client ID: $cid');
        await _showError(context,
            'No record found for Client ID $cid. Please contact support.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // Check if CID is already linked
      if (await db.checkDocumentLinked(cid)) {
        if (!isNewUser && context.mounted) {
          // User is logging in with existing account
          log('Existing user logging in with Apple ID');
          await updateFirebaseMessagingToken(user, context);
          if (context.mounted) {
            Provider.of<AuthState>(context, listen: false)
                .setInitiallyAuthenticated(true);
            await Navigator.of(context)
                .pushNamedAndRemoveUntil('/dashboard', (route) => false);
          }
        } else if (context.mounted) {
          // Someone else has already linked with this CID
          log('CID already linked to another account: $cid');
          await _showError(context,
              'This Client ID is already linked to another account. Please use a different Client ID or contact support.');
          await FirebaseAuth.instance.signOut();
        }
        return;
      }

      // Link new user
      log('Linking new user with Apple ID');
      // Use displayName if available, otherwise email or a default
      final userIdentifier = user.displayName ?? user.email ?? 'Apple User';
      await db.linkNewUser(userIdentifier);
      if (!context.mounted) return;
      await updateFirebaseMessagingToken(user, context);

      // Notify user of success
      if (context.mounted) {
        await CustomAlertDialog.showAlertDialog(
          context,
          'Success',
          'Your account has been created and linked successfully.',
          icon: const Icon(Icons.check_circle_outline_rounded,
              color: Colors.green),
        );
        if (!context.mounted) return;
        // Update app state and navigate to dashboard
        Provider.of<AuthState>(context, listen: false)
            .setInitiallyAuthenticated(true);
        await Navigator.of(context)
            .pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      log('Error in _processSignUp: $e', stackTrace: StackTrace.current);
      if (context.mounted) {
        await _showError(context, 'Failed to process sign-up: ${e.toString()}');
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  /// Show error dialog
  Future<void> _showError(BuildContext context, String message) async {
    if (context.mounted) {
      await CustomAlertDialog.showAlertDialog(
        context,
        'Error',
        message,
        icon: const Icon(Icons.error_outline, color: Colors.red),
      );
    }
  }
}
