// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/svg.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:intl/intl.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

/// Represents the dashboard page of the application.
class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // database service instance
  late DatabaseService _databaseService;

  Future<void> _initData() async {
    // Allow for user data changes to sync and update
    // This will display circular progess indicator
    await Future.delayed(const Duration(seconds: 1));

    User? user = FirebaseAuth.instance.currentUser;
    // If we do not have a user and the context is valid
    if (user == null && mounted) {
      log('dashboard.dart: User is not logged in');
      await Navigator.pushReplacementNamed(context, '/login');
    }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);

    // If there is no matching CID, redirect to login page
    if (service == null && mounted) {
      await Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Otherwise set the database service instance
      _databaseService = service!;
      log('dashboard.dart: Database Service has been initialized with CID: ${_databaseService.cid}');
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
              if (!userSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              // Once we have the user snapshot, we can build the dashboard
              return StreamBuilder<List<UserWithAssets>>(
                  stream: _databaseService.getConnectedUsersWithAssets,
                  builder: (context, connectedUsersSnapshot) {
                    if (!connectedUsersSnapshot.hasData || connectedUsersSnapshot.data!.isEmpty) {
                      // If there is no connected users, we build the dashboard for a single user
                      return _dashboardSingleUser(userSnapshot);
                    }
                    // Otherwise, we build the dashboard with connected users
                    return dashboardWithConnectedUsers(
                        context, userSnapshot, connectedUsersSnapshot);
                  });
            });
      });

  Scaffold _dashboardSingleUser(AsyncSnapshot<UserWithAssets> userSnapshot) {
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
    double totalUserAssets = 0.00, totalUserAGQ = 0.00, totalUserAK1 = 0.00;
    double latestIncome = 0.00;

    // We don't know the order of the funds, and perhaps the
    // length could change in the future, so we'll loop through
    for (var asset in user.assets) {
      switch (asset['fund']) {
        case 'AGQ':
          totalUserAGQ += asset['total'];
          break;
        case 'AK1':
          totalUserAK1 += asset['total'];
          break;
        default:
            latestIncome = double.parse(asset['ytd'].toString());
          totalUserAssets += asset['total'];
      }
    }
    double percentageAGQ =
        totalUserAGQ / totalUserAssets * 100; // Percentage of AGQ
    double percentageAK1 =
        totalUserAK1 / totalUserAssets * 100; // Percentage of AK1

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              _buildAppBar(userName, cid),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      // Total assets section
                      _buildTotalAssetsSection(totalUserAssets, latestIncome),
                      const SizedBox(height: 32),
                      // User breakdown section
                      _buildUserBreakdownSection(
                          userName, totalUserAssets, latestIncome, user.assets),
                      const SizedBox(height: 32),
                      // Assets structure section
                      _buildAssetsStructureSection(
                          totalUserAssets, percentageAGQ, percentageAK1),
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

  Scaffold dashboardWithConnectedUsers(
      BuildContext context,
      AsyncSnapshot<UserWithAssets> userSnapshot,
      AsyncSnapshot<List<UserWithAssets>> connectedUsers) {
    int numConnectedUsers = connectedUsers.data!.length;
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
          latestIncome = double.parse(asset['ytd'].toString());
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
    log('dashboard.dart: Total AGQ: $totalAGQ, Total AK1: $totalAK1, Total Assets: $totalAssets, Total User Assets: $totalUserAssets, AGQ: $percentageAGQ, Percentage AK1: $percentageAK1');

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              _buildAppBar(userName, cid),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildTotalAssetsSection(totalAssets, latestIncome),
                      const SizedBox(height: 32),
                      _buildUserBreakdownSection(
                          userName, totalUserAssets, latestIncome, user.assets),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Text(
                            'Connected Users',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                          Spacer(),
                          Text(
                            '($numConnectedUsers)',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildConnectedUsersSection(connectedUsers.data!),
                      const SizedBox(height: 30),
                      _buildAssetsStructureSection(
                          totalAssets, percentageAGQ, percentageAK1),
                      const SizedBox(height: 130),
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

  SliverAppBar _buildAppBar(Map<String, String> userName, String? cid) =>
      SliverAppBar(
        backgroundColor: const Color.fromARGB(255, 30, 41, 59),
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        expandedHeight: 0,
        snap: false,
        floating: true,
        pinned: true,
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back, ${userName['first']} ${userName['last']}!',
                      style: TextStyle(
                        fontSize: 23,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Client ID: $cid',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
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
            padding: const EdgeInsets.only(right: 5.0),
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
                padding: const EdgeInsets.all(20.0),
                child: SvgPicture.asset(
                  'assets/icons/bell.svg',
                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  height: 30,
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildTotalAssetsSection(double totalAssets, double latestIncome) =>
      Container(
        width: 400,
        height: 160,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: AssetImage('assets/icons/total_assets_gradient.png'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            colorFilter: ColorFilter.mode(
                Colors.blue.withOpacity(0.9), BlendMode.dstATop),
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(
                  'Total Assets',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'Titillium Web',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _currencyFormat(totalAssets),
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Titillium Web',
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/YTD.svg',
                      height: 13,
                    ),
                    SizedBox(width: 5),
                    Text(
                      _currencyFormat(latestIncome),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      );

  // String fund
  ListTile _buildAssetTile(String fieldName, double amount, String fund,
      {String? companyName}) {
    String sectionName = '';
    switch (fieldName) {
      case 'nuviewTrad':
        sectionName = 'Nuview Cash IRA';
        break;
      case 'nuviewRoth':
        sectionName = 'Nuview Cash Roth IRA';
        break;
      case 'nuviewSepIRA':
        sectionName = 'Nuview Cash SEP IRA';
        break;
      case 'roth':
        sectionName = 'Roth IRA';
        break;
      case 'trad':
        sectionName = 'Traditional IRA';
        break;
      case 'sep':
        sectionName = 'SEP IRA';
        break;
      case 'personal':
        sectionName = 'Personal';
        break;
      case 'company':
        try {
          sectionName = companyName!;
        } catch (e) {
          log('dashboard.dart: Error building asset tile for company: $e');
          sectionName = '';
        }
        break;
      default:
        sectionName = fieldName;
    }

    Widget leadingIcon;
    if (fund == 'agq') {
      leadingIcon = SvgPicture.asset('assets/icons/agq_logo.svg');
    } else if (fund == 'ak1') {
      leadingIcon = SvgPicture.asset('assets/icons/ak1_logo.svg');
    } else {
      leadingIcon = Icon(Icons.account_balance, color: Colors.white);
    }

    return ListTile(
      leading: leadingIcon,
      title: Text(
        sectionName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Titillium Web',
        ),
      ),
      trailing: Text(
        _currencyFormat(amount),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Titillium Web',
        ),
      ),
    );
  }

  Widget _buildUserBreakdownSection(
      Map<String, String> userName,
      double totalUserAssets,
      double latestIncome,
      List<Map<String, dynamic>> assets) {
    // Initialize empty lists for the tiles
    List<ListTile> assetTilesAGQ = [];
    List<ListTile> assetTilesAK1 = [];

    // For each document in assets subcollection
    for (var asset in assets) {
      switch (asset['fund']) {
        case 'AGQ':
          try {
            asset.entries.where((entry) {
              if (entry.key == 'company') {
                return true;
              }
              return false;
            }).forEach((entry) {
              if (entry.value != 0) {
                assetTilesAGQ.add(_buildAssetTile(
                    entry.key, (entry.value).toDouble(), 'agq',
                    companyName: userName['company']));
              }
            });
            // for each entry in the document that is not total, latestIncome, or fund
            // create a ListTile and add it to the list
            for (var entry in asset.entries) {
              if (entry.value is num && 
                  entry.value != 0 &&
                  entry.key != 'total' &&
                  entry.key != 'company') {
                assetTilesAGQ.add(
                    _buildAssetTile(entry.key, entry.value.toDouble(), 'agq'));
              }
            }
          } on TypeError catch (e) {
            log('dashboard.dart: Error building asset tile for AGQ Fund for user ${userName['first']} + ${userName['last']}: $e');
          }
          break;
        case 'AK1':
          try {
            asset.entries.where((entry) {
              if (entry.key == 'company') {
                return true;
              }
              return false;
            }).forEach((entry) {
              if (entry.value != 0) {
                assetTilesAK1.add(_buildAssetTile(
                    entry.key, (entry.value).toDouble(), 'ak1',
                    companyName: userName['company']));
              }
            });
            // for each entry in the document that is not total, latestIncome, or fund
            // create a ListTile and add it to the list
            for (var entry in asset.entries) {
              if (entry.value is num &&
                  entry.value != 0 &&
                  entry.key != 'total' &&
                  entry.key != 'company') {
                assetTilesAK1.add(
                    _buildAssetTile(entry.key, entry.value.toDouble(), 'ak1'));
              }
            }
          } on TypeError catch (e) {
            log('dashboard.dart: Error building asset tile for AGQ Fund for user ${userName['first']} + ${userName['last']}: $e');
          }
          break;
      }
    }

    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent, // removes splash effect
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              '${userName['first']} ${userName['last']}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            SizedBox(width: 10),
            SvgPicture.asset(
              'assets/icons/YTD.svg',
              height: 13,
            ),
            SizedBox(width: 5),
            Text(
              _currencyFormat(latestIncome),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            ),
          ],
        ),
        subtitle: Text(
          _currencyFormat(totalUserAssets),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            fontFamily: 'Titillium Web',
          ),
        ),
        maintainState: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        collapsedBackgroundColor: const Color.fromARGB(255, 30, 41, 59),
        backgroundColor: const Color.fromARGB(255, 30, 41, 59),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
                left: 25.0, right: 25.0, bottom: 10.0, top: 10.0),
            child: Divider(color: Colors.grey[300]),
          ),
          Column(
            children: assetTilesAK1,
          ),
          Column(
            children: assetTilesAGQ,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedUsersSection(List<UserWithAssets> connectedUsers) =>
      Stack(
        children: [
          ExpandableCarousel(
            options: CarouselOptions(
              viewportFraction: 1.0,
              autoPlay: false,
              controller: CarouselController(),
              floatingIndicator: false,
              restorationId: 'expandable_carousel',
            ),
            items: connectedUsers.map((user) {
              String firstName = user.info['name']['first'] as String;
              String lastName = user.info['name']['last'] as String;
              String companyName = user.info['name']['company'] as String;
              Map<String, String> userName = {
                'first': firstName,
                'last': lastName,
                'company': companyName
              };
              double totalUserAssets = 0.00, latestIncome = 0.00;
              for (var asset in user.assets) {
                switch (asset['fund']) {
                  case 'AGQ':
                    break;
                  case 'AK1':
                    break;
                  default:
                    latestIncome = asset['ytd'];
                    totalUserAssets += asset['total'];
                }
              }
              return Builder(
                builder: (BuildContext context) => Column(
                  children: [
                    _buildConnectedUserBreakdownSection(
                      userName,
                      totalUserAssets,
                      latestIncome,
                      user.assets,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      );

  Widget _buildConnectedUserBreakdownSection(
      Map<String, String> userName,
      double totalUserAssets,
      double latestIncome,
      List<Map<String, dynamic>> assets) {
    // Initialize empty lists for the tiles
    List<ListTile> assetTilesAGQ = [];
    List<ListTile> assetTilesAK1 = [];

    for (var asset in assets) {
      switch (asset['fund']) {
        case 'AGQ':
          try {
            asset.entries.where((entry) {
              if (entry.key == 'company') {
                return true;
              }
              return false;
            }).forEach((entry) {
              if (entry.value != 0) {
                assetTilesAGQ.add(_buildAssetTile(
                    entry.key, (entry.value).toDouble(), 'agq',
                    companyName: userName['company']));
              }
            });
            // for each entry in the document that is not total, latestIncome, or fund
            // create a ListTile and add it to the list
            for (var entry in asset.entries) {
              if (entry.value is num &&
                  entry.value != 0 &&
                  entry.key != 'total' &&
                  entry.key != 'company') {
                assetTilesAGQ.add(
                    _buildAssetTile(entry.key, entry.value.toDouble(), 'agq'));
              }
            }
          } on TypeError catch (e) {
            log('dashboard.dart: Error building asset tile for AGQ Fund for user ${userName['first']} + ${userName['last']}: $e');
          }
          break;
        case 'AK1':
          try {
            asset.entries.where((entry) {
              if (entry.key == 'company') {
                return true;
              }
              return false;
            }).forEach((entry) {
              if (entry.key == 'total') {
                assetTilesAK1.add(_buildAssetTile(
                  entry.key, (entry.value).toDouble(), 'ak1',
                  companyName: userName['company']));
              }
            });
            // for each entry in the document that is not total, latestIncome, or fund
            // create a ListTile and add it to the list
            for (var entry in asset.entries) {
              if (entry.value is num &&
                  entry.value != 0 &&
                  entry.key != 'total' &&
                  entry.key != 'company') {
                assetTilesAK1.add(
                    _buildAssetTile(entry.key, entry.value.toDouble(), 'ak1'));
              }
            }
          } on TypeError catch (e) {
            log('dashboard.dart: Error building asset tile for AGQ Fund for user ${userName['first']} + ${userName['last']}: $e');
          }
          break;
      }
    }

    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent, // removes splash effect
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              '${userName['first']} ${userName['last']}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Titillium Web',
              ),
            ),
            SizedBox(width: 10),
            SvgPicture.asset(
              'assets/icons/YTD.svg',
              height: 13,
            ),
            SizedBox(width: 5),
            Text(
              _currencyFormat(latestIncome),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Titillium Web',
              ),
            ),
          ],
        ),
        subtitle: Text(
          _currencyFormat(totalUserAssets),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            fontFamily: 'Titillium Web',
          ),
        ),
        maintainState: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.white), // Add this line
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.white), // And this line
        ),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
                left: 25.0, right: 25.0, bottom: 10.0, top: 10.0),
            child: Divider(color: Colors.grey[300]),
          ), // Add a light divider bar
          Column(
            children: assetTilesAK1,
          ),
          Column(
            children: assetTilesAGQ,
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsStructureSection(
          double totalUserAssets, double percentageAGQ, double percentageAK1) =>
      Container(
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
                          color: const Color.fromARGB(255, 12, 94, 175),
                          radius: 25,
                          value: percentageAGQ,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          color: const Color.fromARGB(255, 49, 153, 221),
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
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        Text(
                          _currencyFormat(totalUserAssets),
                          style: TextStyle(
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
                    Icon(
                      Icons.circle,
                      size: 20,
                      color: Color.fromARGB(255, 12, 94, 175),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'AGQ Fixed Income',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    Spacer(), // This will push the following widgets to the right
                    Text(
                      '${percentageAGQ.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 20,
                      color: Color.fromARGB(255, 49, 153, 221),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'AK1 Fund',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    Spacer(), // This will push the following widgets to the right
                    Text(
                      '${percentageAK1.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
              ],
            )
          ],
        ),
      );

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
              'assets/icons/dashboard_filled.svg',
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
              'assets/icons/analytics_hollowed.svg',
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
