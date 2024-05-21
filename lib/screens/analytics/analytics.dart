import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/utilities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // database service instance
  late DatabaseService _databaseService;

  Future<void> _initData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('User is not logged in');
      Navigator.pushReplacementNamed(context, '/login');
    }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);
    // If there is no matching CID, redirect to login page
    if (service == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
      log('Database Service has been initialized with CID: ${_databaseService.cid}');
    }
  }

  /// Formats the given amount as a currency string.
  String _currencyFormat(double amount) => NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
        locale: 'en_US',
      ).format(amount);

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _initData(), // Initialize the database service
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return StreamBuilder<UserWithAssets>(
            stream: _databaseService.getUserWithAssets,
            builder: (context, userSnapshot) {
              // Wait for the user snapshot to have data
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              // Once we have the user snapshot, we can build the activity page
              return StreamBuilder<List<UserWithAssets>>(
                stream: _databaseService.getConnectedUsersWithAssets, // Assuming this is the stream for connected users
                builder: (context, connectedUsers) {
                  if (!connectedUsers.hasData || connectedUsers.data == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _databaseService.getNotifications,
                    builder: (context, notificationsSnapshot) {
                      if (!notificationsSnapshot.hasData || notificationsSnapshot.data == null) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      unreadNotificationsCount = notificationsSnapshot.data!.where((notification) => !notification['isRead']).length;
                      // use unreadNotificationsCount as needed
                      return buildAnalyticsPage(userSnapshot, connectedUsers);
                    }
                  );
                },
              );
            });
      });

  Scaffold buildAnalyticsPage(AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    UserWithAssets user = userSnapshot.data!;
    String firstName = user.info['name']['first'] as String;
    String lastName = user.info['name']['last'] as String;
    String companyName = user.info['name']['company'] as String;
    Map<String, String> userName = {
      'first': firstName,
      'last': lastName,
      'company': companyName
    };
    String? cid = _databaseService.cid;
    // Total assets of one user
    double totalUserAssets = 0.00,
        totalAGQ = 0.00,
        totalAK1 = 0.00,
        totalAssets = 0.00;
    double latestIncome = 0.00;

    // This is a calculation of the total assets of the user only
    for (var asset in user.assets) {
      switch (asset['fund']) {
        case 'AGQ':
          totalAGQ += asset['total'];
          break;
        case 'AK1':
          totalAK1 += asset['total'];
          break;
        default:
          latestIncome = asset['ytd'];
          totalAssets += asset['total'];
          totalUserAssets += asset['total'];
      }
    }

    // This calculation is for the total assets of all connected users combined
    for (var user in connectedUsers.data!) {
      for (var asset in user.assets) {
        switch (asset['fund']) {
          case 'AGQ':
            totalAGQ += asset['total'];
            break;
          case 'AK1':
            totalAK1 += asset['total'];
            break;
          default:
            totalAssets += asset['total'];
        }
      }
    }

    double percentageAGQ = totalAGQ / totalAssets * 100; // Percentage of AGQ
    double percentageAK1 = totalAK1 / totalAssets * 100; // Percentage of AK1
    log('analytics.dart: Total AGQ: $totalAGQ, Total AK1: $totalAK1, Total Assets: $totalAssets, Total User Assets: $totalUserAssets, AGQ: $percentageAGQ, Percentage AK1: $percentageAK1');

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // Assets structure section
                      _buildAssetsStructureSection(
                          totalAssets, percentageAGQ, percentageAK1),
                      const SizedBox(height: 132),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(context),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
  backgroundColor: const Color.fromARGB(255, 30, 41, 59),
  automaticallyImplyLeading: false,
  toolbarHeight: 80,
  expandedHeight: 0,
  snap: false,
  floating: true,
  pinned: true,
  flexibleSpace: const SafeArea(
    child: Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.0, right: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: const TextStyle(
                  fontSize: 27,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ],
          ),
        ),
        
      ],
    ),
  ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5.0, bottom: 5.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 450),
                    pageBuilder: (_, __, ___) => NotificationPage(),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset(0.0, 0.0),
                        ).animate(animation),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                color: Color.fromRGBO(239, 232, 232, 0),
                padding: const EdgeInsets.all(10.0),
                child: ClipRect(
                  child: Stack(
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(top: 0), // Increase padding as needed
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.transparent, // Change this color to the one you want
                                width: 0.3, // Adjust width to your need
                              ),
                              shape: BoxShape.rectangle, // or BoxShape.rectangle if you want a rectangle
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/bell.svg',
                                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                height: 35,
                              ),
                            ),
                          ),
                      Positioned(
                        right: 0,
                        top: 3,
                        child: unreadNotificationsCount > 0
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF267DB5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '$unreadNotificationsCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Titillium Web',
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Container(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
  );
  
  Widget _buildAssetsStructureSection(double totalUserAssets, double percentageAGQ, double percentageAK1) => Container(
    width: 400,
    height: 520,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 30, 41, 59),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [

        const SizedBox(height: 10),
        
        const Row(
          children: [
            SizedBox(width: 5),
            Text(
              'Assets Structure',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            )
          ],
          
        ),
        
        const SizedBox(height: 60),

        Container(
          width: 250,
          height: 250,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: 120,
                  centerSpaceRadius: 100,
                  sectionsSpace: 10,
                  sections: [
                    PieChartSectionData(
                      color: const Color.fromARGB(255,12,94,175),
                      radius: 25,
                      value: percentageAGQ,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: const Color.fromARGB(255,49,153,221),
                      radius: 25,
                      value: percentageAK1,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [ 
                                      
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  
                    Text(
                      currencyFormat(totalUserAssets),
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
        
        const Row(
          children: [
            SizedBox(width: 30),
            Text(
              'Type',
              style: TextStyle(
                fontSize: 16, 
                color: Color.fromARGB(255, 216, 216, 216), 
                fontFamily: 'Titillium Web', 
              ),
            ),
            Spacer(), // This will push the following widgets to the right
            Text(
              '%',
              style: TextStyle(
                fontSize: 16, 
                color: Color.fromARGB(255, 216, 216, 216), 
                fontFamily: 'Titillium Web', 
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
                
        const SizedBox(height: 5),

        const Divider(
          thickness: 1.2,
          height: 1,
          color: Color.fromARGB(255, 102, 102, 102), 
          
        ),
      
        const SizedBox(height: 10),

        Column(
          
        children: [
          Row(
            children: [
              const Icon(
                Icons.circle,
                size: 20,
                color: Color.fromARGB(255,12,94,175),
              ),
              const SizedBox(width: 10),
              const Text('AGQ Fixed Income',
                style: TextStyle(
                  fontSize: 15, 
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontFamily: 'Titillium Web', 
                ),
              ),
              const Spacer(), // This will push the following widgets to the right
              Text('${percentageAGQ.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 15, 
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontFamily: 'Titillium Web', 
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.circle,
                size: 20,
                color: Color.fromARGB(255,49,153,221),
              ),
              const SizedBox(width: 10),
              const Text('AK1 Holdings LP',
                style: TextStyle(
                  fontSize: 15, 
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontFamily: 'Titillium Web', 
                ),
              ),
              const Spacer(), // This will push the following widgets to the right
              Text('${percentageAK1.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 15, 
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontFamily: 'Titillium Web', 
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],        
        )
              
      ],
    ),
  );

// This is the bottom navigation bar
  Widget _buildBottomNavigationBar(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 30, right: 20, left: 20),
    height: 80,
    padding: const EdgeInsets.only(right: 10, left: 10),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 30, 41, 59),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          spreadRadius: 8,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DashboardPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/dashboard_hollowed.svg',
              height: 22,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const AnalyticsPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/analytics_filled.svg',
              height: 22,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ActivityPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/activity_hollowed.svg',
              height: 22,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ProfilePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        child,
              ),
            );
          },
          child: Container(
            color: Color.fromRGBO(239, 232, 232, 0),
            padding: const EdgeInsets.all(20.0),
            child: SvgPicture.asset(
              'assets/icons/profile_hollowed.svg',
              height: 22,
            ),
          ),
        ),
      ],
    ),
  );
}
