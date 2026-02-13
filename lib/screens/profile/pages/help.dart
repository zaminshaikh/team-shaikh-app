// ignore_for_file: deprecated_member_use, use_build_context_synchronously, duplicate_ignore, prefer_expression_function_bodies, unused_catch_clause, empty_catches, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agq_app/screens/utils/resources.dart';
import 'package:agq_app/screens/profile/components/custom_expansion_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {

  @override
  Widget build(BuildContext context) =>  Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: <Widget>[
                _buildAppBar(context), 
                SliverPadding(
                  padding: const EdgeInsets.all(0.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _helpCenter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );   
  
// This is the app bar 
  SliverAppBar _buildAppBar(context) => SliverAppBar(
    backgroundColor: const Color.fromARGB(255, 30, 41, 59),
    automaticallyImplyLeading: false,
    toolbarHeight: 80,
    expandedHeight: 0,
    snap: false,
    floating: true,
    pinned: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
    flexibleSpace: const SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 60.0, right: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help',
              style: TextStyle(
                fontSize: 27,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
          ],
        ),
      ),
    ),
  );

// This is the Help Center section
  Container _helpCenter() => Container(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Advisors Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Point of Contact',
              style: TextStyle(
                fontSize: 25,
                color: Color.fromRGBO(255, 255, 255, 1),
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),


            const SizedBox(height: 20), 
            
            // Sonny Shaikh Info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: AppColors.defaultBlueGray600, width: 2), // Add this line
              ),
              
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name and icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 50, // Set desired width
                          height: 50, // Set desired height
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,// Circular border
                            image: DecorationImage(
                              image: AssetImage('assets/icons/sonny_headshot.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ahsan \'Sonny\' Shaikh', 
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromRGBO(255, 255, 255, 1),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),

                            Text(
                              'Partner', 
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  
                    const SizedBox(height: 20),

                  // contact info
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Info:', 
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        
                        const SizedBox(height: 15),

                        GestureDetector(
                          onTap: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'sonny@agqconsulting.com',
                              query: 'subject=${Uri.encodeComponent("Your Subject Here")}',
                            );
                            if (await canLaunch(emailLaunchUri.toString())) {
                              await launch(emailLaunchUri.toString());
                            } else {
                            }
                          },

                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/email.svg',
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Email: sonny@agqconsulting.com', 
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: () async {
                            const url = 'tel:+1 (631) 487-9818';
                            try {
                              bool launched = await launch(url);
                              if (!launched) {
                              }
                            } on PlatformException catch (e) {
                            } catch (e) {
                            }
                          },
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/phone.svg',
                                color: Colors.white,
                                height: 16,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Phone: +1 (631) 487-9818', 
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontFamily: 'Titillium Web',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20), 

            // Kash Shaikh Info
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: AppColors.defaultBlueGray600, width: 2), // Add this line
              ),
              
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name and icon
                    Row(
                      children: [
                        Container(
                          width: 50, // Set desired width
                          height: 50, // Set desired height
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,// Circular border
                            image: DecorationImage(
                              image: AssetImage('assets/icons/kash_headshot.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kashif Shaikh', 
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromRGBO(255, 255, 255, 1),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),

                            Text(
                              'Partner', 
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  
                    const SizedBox(height: 20),

                  // contact info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Info:', 
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        
                        const SizedBox(height: 15),


                        GestureDetector(
                          onTap: () async {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'kash@agqconsulting.com',
                              query: 'subject=${Uri.encodeComponent("Your Subject Here")}',
                            );
                            if (await canLaunch(emailLaunchUri.toString())) {
                              await launch(emailLaunchUri.toString());
                            } else {
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/email.svg',
                                  color: Colors.white,
                                  height: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Email: kash@agqconsulting.com', 
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: () async {
                            const url = 'tel:+1 (973) 610 4916';
                            try {
                              bool launched = await launch(url);
                              if (!launched) {
                              }
                            } on PlatformException catch (e) {
                            } catch (e) {
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/phone.svg',
                                  color: Colors.white,
                                  height: 16,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Phone: +1 (973) 610 4916',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                      ],
                    ),
                  ],
                ),
              ),
            ),

          ],
       ),

        const SizedBox(height: 40), 

        // FAQ Section
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 10),
                Text(
                  'FAQ',
                  style: TextStyle(
                    fontSize: 22,
                    color: Color.fromRGBO(255, 255, 255, 1),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Titillium Web',
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), 

            CustomExpansionTile(
              title: 'Is the app secure?',
              content: 'Absolutely. The AGQ app employs cutting-edge security measures to safeguard your data and ensure your privacy is fully protected. Your security is our top priority, and we are committed to maintaining the highest standards of data protection.',
            ),
            CustomExpansionTile(
              title: 'How do I contact customer support?',
              content: 'You can contact us via email at management@agqconsulting.com, or by phone at 973-610-4916 or 631-487-9818.',
            ),
            CustomExpansionTile(
              title: 'How do I update my personal information?',
              content: 'Log in to your account, go to profile settings, edit your information, and save the changes. For help, contact our support team at management@agqconsulting.com.',
            ),
            CustomExpansionTile(
              title: 'What should I do if my phone is lost or stolen?',
              content: 'If your phone is lost or stolen, contact us immediately. Even though the app is secured with a PIN or face ID, we will promptly disable your account to ensure your safety.',
            ),
            CustomExpansionTile(
              title: 'How can I export my financial data?',
              content: 'Go to the Documents section, click the Download button, and choose your preferred format from the options dialog.',
            ),
            
            SizedBox(height: 20),
          
          ],
        ),
      ],      
    ),
    
  );

}
