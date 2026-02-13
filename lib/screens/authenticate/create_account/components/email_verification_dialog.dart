// email_verification_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agq_app/components/progress_indicator.dart';

/// A StatefulWidget representing the Email Verification dialog.
class EmailVerificationDialog extends StatefulWidget {
  /// Callback to execute when the user presses the Continue button.
  final Future<bool> Function() onContinue;

  const EmailVerificationDialog({
    super.key,
    required this.onContinue,
  });

  @override
  EmailVerificationDialogState createState() =>
      EmailVerificationDialogState();
}

class EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool isLoading = false;

  /// Handles the Continue button press.
  Future<void> _handleContinue() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (await widget.onContinue() == true) {
        if (mounted) {
          Navigator.of(context).pop(); // Close the dialog upon success.
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Handle any errors here (optional).
      // For example, show an error message to the user.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color.fromARGB(255, 37, 58, 86),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Adjusts the dialog size based on content.
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    'assets/icons/verify_email_iconart.svg',
                    height: 200,
                    width: 200,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Verify your Email Address',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Titillium Web',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You will receive an email with a link to verify your email. Please check your inbox.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'Titillium Web',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: isLoading ? null : _handleContinue,
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CustomProgressIndicator(),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
          ],
        ),
      );
}
