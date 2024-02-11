// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:team_shaikh_app/screens/activity/activity.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;
  List<String> data = [
    'assets/icons/dashboard_hollowed.png',
    'assets/icons/analytics_hollowed.png',
    'assets/icons/activity_hollowed.png',
    'assets/icons/profile_hollowed.png',
  ];

  // database service instance
  late DatabaseService _databaseService;

  Future<void> _initData() async {
    // Get the current user
    User user = FirebaseAuth.instance.currentUser!;
    String uid = user.uid;

    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(uid, 1);
    if (_databaseService == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      _databaseService = service!;
      log('Database Service has been initialized with CID: ${_databaseService.cid}');
    }
  }

  String _currencyFormat(double amount) => NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
      locale: 'en_US',
    ).format(amount);

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _initData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return StreamBuilder<UserWithAssets>(
          stream: _databaseService.getUserWithAssets,
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return StreamBuilder<List<UserWithAssets>>(
              stream: _databaseService.getConnectedUsersWithAssets,
              builder: (context, connectedUsersSnapshot) {
                if (!connectedUsersSnapshot.hasData) {
                  log('Connected users snapshot has no data');
                  return _dashboardSingleUser(userSnapshot);
                }
                return dashboardWithConnectedUsers(context, userSnapshot, connectedUsersSnapshot);
              }
            );
          }
        );      
      }
    );

  Scaffold _dashboardSingleUser(AsyncSnapshot<UserWithAssets> userSnapshot) {
    
    UserWithAssets user = userSnapshot.data!;
    String userName = user.info['name']['first'] + ' ' + user.info['name']['last'];
    String? cid = _databaseService.cid;
    double totalUserAGQ = 0.00, totalUserAK1 = 0.00;
    double latestIncome = 0.00;
    // Create a date object with the earliest possible date in 1970
    DateTime latestIncomeDate = DateTime(0);

    // We don't know the order of the funds, and perhaps the
    // length could change in the future, so we'll loop through
    for (var asset in user.assets) {
      switch (asset['fund']) {
        case 'AGQ Consulting LLC':
          totalUserAGQ += asset['total'];
          Map<String, dynamic> agq = asset;
          // Remove any zero values from the map
          agq.removeWhere((key, value) => value is num && value == 0.0);
          // Check if the latest income date is after the current latest income date
          DateTime latestIncomeDateAGQ = (agq['latestIncome']['time']).toDate();
          // Set the time to 00:00:00 to compare the dates
          latestIncomeDateAGQ = DateTime(latestIncomeDateAGQ.year, latestIncomeDateAGQ.month, latestIncomeDateAGQ.day, 0, 0, 0, 0, 0);
          if (latestIncomeDateAGQ.isAfter(latestIncomeDate)) {
            latestIncomeDate = latestIncomeDateAGQ;
            latestIncome = agq['latestIncome']['amount'];
          } else if (latestIncomeDateAGQ.isAtSameMomentAs(latestIncomeDate)) {
            latestIncome += agq['latestIncome']['amount'];
          }

          break;
        case 'AK1 Holdings LP':
          totalUserAK1 += asset['total'];
          Map<String, dynamic> ak1 = asset;
          // Remove any zero values from the map
          ak1.removeWhere((key, value) => value is num && value == 0.0);

          // Check if the latest income date is after the current latest income date
          DateTime latestIncomeDateAK1 = (ak1['latestIncome']['time']).toDate();
          // Set the time to 00:00:00 to compare the dates
          latestIncomeDateAK1 = DateTime(latestIncomeDateAK1.year, latestIncomeDateAK1.month, latestIncomeDateAK1.day, 0, 0, 0, 0, 0);
          if (latestIncomeDateAK1.isAfter(latestIncomeDate)) {
            latestIncomeDate = latestIncomeDateAK1;
            latestIncome = ak1['latestIncome']['amount'];
          } else if (latestIncomeDateAK1.isAtSameMomentAs(latestIncomeDate)) {
            latestIncome += ak1['latestIncome']['amount'];
          }

          break;
      }
    }
    double totalUserAssets = totalUserAGQ + totalUserAK1; // Total assets of one user
    double percentageAGQ = totalUserAGQ / totalUserAssets * 100; // Percentage of AGQ
    double percentageAK1 = totalUserAK1 / totalUserAssets * 100; // Percentage of AK1

    

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
                        _buildUserBreakdownSection(userName, totalUserAssets, latestIncome),
                        const SizedBox(height: 32),
                        // Assets structure section
                        _buildAssetsStructureSection(totalUserAssets, percentageAGQ, percentageAK1),
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
              child: _buildBottomNavigationBar(),
            ),
          ],
        ),
      );
  }

  Scaffold dashboardWithConnectedUsers(BuildContext context, AsyncSnapshot<UserWithAssets> user, AsyncSnapshot<List<UserWithAssets>> connectedUsers) { 
    int numConnectedUsers = connectedUsers.data!.length;
    String userName = 'test';
    String? cid = _databaseService.cid;
    double totalUserAssets = 0.00;
    double totalAssets = 0.00;
    double latestIncome = 0.00;
    double percentageAGQ = 0.00;
    double percentageAK1 = 0.00;


    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          _buildAppBar(userName, cid),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildTotalAssetsSection(totalAssets, latestIncome),
                  const SizedBox(height: 32),
                  _buildUserBreakdownSection(userName, totalUserAssets, latestIncome),
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
                      SizedBox(width: 220),
                      Text(
                        '$numConnectedUsers',
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
                  _buildConnectedUsersSection(),
                  const SizedBox(height: 80),
                  _buildAssetsStructureSection(totalAssets, percentageAGQ, percentageAK1),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );  
  }
    
  SliverAppBar _buildAppBar(String userName, String? cid) => SliverAppBar(
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
                  'Welcome Back, $userName!',
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
        padding: const EdgeInsets.only(right: 10.0),
        child: Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    ],
  );
    
  Widget _buildTotalAssetsSection(double totalAssets, double latestIncome) => Container(
    width: 400,
    height: 160,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(15),
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
                Image.asset(
                  'assets/icons/green_arrow_up.png',
                  height: 20,
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
  
  Widget _buildUserBreakdownSection(String userName, double totalUserAssets, double latestIncome) => Theme(
    data: ThemeData(
      splashColor: Colors.transparent, // removes splash effect
    ),
    child: ExpansionTile(
      title: Row(
        children: [
          Text(
            userName,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Titillium Web',
            ),
          ),
          SizedBox(width: 10),
          Image.asset(
                  'assets/icons/green_arrow_up.png',
                  height: 20,
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
        Divider(color: Colors.grey[300]), // Add a light divider bar
        ListTile(
          leading: Icon(Icons.account_balance, color: Colors.white), // Add an icon
          title: Text(
            'Asset 1',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          trailing: Text(
            _currencyFormat(12000),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
        ),
        Divider(
          color: Colors.grey[300], // Light grey color
          thickness: 0.5, // Thinner line
          indent: 16, // Indent from the left
          endIndent: 16, // Indent from the right
        ), // Add a light divider bar
        ListTile(
          leading: Icon(Icons.account_balance, color: Colors.white), // Add an icon
          title: Text(
            'Asset 2',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
          trailing: Text(
            _currencyFormat(46000),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontFamily: 'Titillium Web',
            ),
          ),
        ),
        // Add more ListTiles for more assets
      ],
    ),
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
                color: Color.fromARGB(255,12,94,175),
              ),
              SizedBox(width: 10),
              Text('AGQ Fixed Income',
                style: TextStyle(
                  fontSize: 15, 
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontFamily: 'Titillium Web', 
                ),
              ),
              Spacer(), // This will push the following widgets to the right
              Text('${percentageAGQ.toStringAsFixed(1)}%',
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
                color: Color.fromARGB(255,49,153,221),
              ),
              SizedBox(width: 10),
              Text('AK1 Holdings LP',
                style: TextStyle(
                  fontSize: 15, 
                  color: Colors.white, 
                  fontWeight: FontWeight.w600, 
                  fontFamily: 'Titillium Web', 
                ),
              ),
              Spacer(), // This will push the following widgets to the right
              Text('${percentageAK1.toStringAsFixed(1)}%',
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

  Widget _buildBottomNavigationBar() => Container(
    margin: const EdgeInsets.only(bottom: 50, right: 20, left: 20),
    height: 80,
    padding: const EdgeInsets.only(right: 30, left: 30),
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
      children: List.generate(
        data.length,
        (i) => GestureDetector(
          onTap: () {
            setState(() {
              selectedIndex = i;
            });

            if (data[i] == 'assets/icons/analytics_hollowed.png') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const AnalyticsPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }

            if (data[i] == 'assets/icons/dashboard_hollowed.png') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }

            if (data[i] == 'assets/icons/activity_hollowed.png') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ActivityPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }

            if (data[i] == 'assets/icons/profile_hollowed.png') {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            }

          },

          child: Image.asset(
            i == selectedIndex && data[i] == 'assets/icons/dashboard_hollowed.png'
              ? 'assets/icons/dashboard_filled.png'
              : data[i],
            height: 50,
          ),       
        ),
      ),
    ),    
  );

  Widget _buildConnectedUsersSection() => CarouselSlider(
    options: CarouselOptions(
      height: 90.0,
      aspectRatio: 16 / 9,
      viewportFraction: 1,
      initialPage: 0,
      enableInfiniteScroll: false,
      reverse: true,
      autoPlay: false,
      enlargeCenterPage: true,
      enlargeFactor: 0.2,
      onPageChanged: (index, reason) {
        // Your callback function for page changes
      },
      scrollDirection: Axis.horizontal,
    ),
    items: ['Jane Doe', 'Kristin Watson', 'Floyd Miles'].map((i) => Builder(
        builder: (BuildContext context) => Container(
            padding: const EdgeInsets.all(15),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: Colors.white,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          i,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.abc),
                        const SizedBox(width: 5),
                        const Text(
                          '\$1,816',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '\$500,000.00',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Titillium Web',
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ],
            ),
          ),
      )).toList(),
  );

}
