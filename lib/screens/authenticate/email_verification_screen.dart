import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:agq_app/components/alert_dialog.dart';
import 'package:agq_app/components/progress_indicator.dart';
import 'package:agq_app/database/auth_helper.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _isCheckingVerification = false;
  Timer? _verificationCheckTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _checkEmailVerification(),
    );
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        
        if (updatedUser != null && updatedUser.emailVerified) {
          _verificationCheckTimer?.cancel();
          
          if (!mounted) return;
          
          // Update authentication state
          final authState = Provider.of<AuthState>(context, listen: false);
          authState.setInitiallyAuthenticated(true);
          
          // Update Firebase messaging token
          if (mounted) {
            await updateFirebaseMessagingToken(updatedUser, context);
          }
          
          // Show success message
          await CustomAlertDialog.showAlertDialog(
            context,
            'Email Verified!',
            'Your email has been successfully verified.',
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
          );
          
          if (!mounted) return;
          
          // Navigate to dashboard
          await Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }
      }
    } catch (e) {
      log('Error checking email verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        
        if (!mounted) return;
        
        // Start cooldown
        setState(() {
          _resendCooldown = 5; // 5 seconds cooldown
        });
        
        _cooldownTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (_resendCooldown > 0) {
              setState(() {
                _resendCooldown--;
              });
            } else {
              timer.cancel();
            }
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent to ${user.email}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      log('Error resending verification email: $e');
      if (mounted) {
        String errorMessage = 'Failed to send verification email. Please try again later.';
        
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
        
        await CustomAlertDialog.showAlertDialog(
          context,
          'Error',
          errorMessage,
        );
      }
    } catch (e) {
      log('Unexpected error resending verification email: $e');
      if (mounted) {
        await CustomAlertDialog.showAlertDialog(
          context,
          'Error',
          'An unexpected error occurred. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      await Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      log('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 24, 39),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email verification icon
              SvgPicture.asset(
                'assets/icons/verify_email_iconart.svg',
                height: 200,
                width: 200,
              ),
              
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Titillium Web',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'We sent a verification email to:\n${user?.email ?? 'your email'}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Titillium Web',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Please check your email and click the verification link to continue.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Titillium Web',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Checking verification status indicator
              if (_isCheckingVerification)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Checking verification status...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 32),
              
              // Resend verification email button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _resendCooldown > 0 || _isLoading ? null : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 30, 75, 137),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CustomProgressIndicator()
                      : Text(
                          _resendCooldown > 0
                              ? 'Resend in ${_resendCooldown}s'
                              : 'Resend Verification Email',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sign out button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _signOut,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Titillium Web',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
