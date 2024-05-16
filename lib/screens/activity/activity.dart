import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:team_shaikh_app/resources.dart';
import 'package:team_shaikh_app/screens/notification.dart';
import 'package:team_shaikh_app/utilities.dart';
import 'package:team_shaikh_app/screens/dashboard/dashboard.dart';
import 'package:team_shaikh_app/screens/analytics/analytics.dart';
import 'package:team_shaikh_app/database.dart';
import 'package:team_shaikh_app/screens/profile/profile.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({Key? key}) : super(key: key);
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<Map<String, dynamic>> activities = [];
  String _sorting = 'new-to-old';
  // ignore: prefer_final_fields
  List<String> _typeFilter = ['income', 'deposit', 'withdrawal', 'pending'];
  // ignore: prefer_final_fields
  List<String> _fundsFilter = ['AK1 Holdings LP', 'AGQ Consulting LLC'];

  DateTimeRange selectedDates = DateTimeRange(
    start: DateTime(1900),
    end: DateTime.now(),
  );



  late DatabaseService _databaseService;

  Future<void> _initData() async {
    // If the user is signed in (which should always be the case on this screen)
    User? user = FirebaseAuth.instance.currentUser;
    // If not, we return to login page
    if (user == null) {
      await Navigator.pushReplacementNamed(context, '/login');
    }
    // Fetch CID using async constructor
    DatabaseService? service = await DatabaseService.fetchCID(user!.uid, 1);
    // If there is no matching CID, redirect to login page and alert the user
    if (service == null) {
      if (!mounted){ return; }
      await CustomAlertDialog.showAlertDialog(context, 'User does not exist error!', 
        'The current user is not associated with any account... We will redirect you to the login page to sign in with a valid user.');
      
      await FirebaseAuth.instance.signOut(); // Sign that user out
      if (!mounted){ return; }
      await Navigator.pushReplacementNamed(context, '/login');
      
    } else {
      // Otherwise set the database service instance
      _databaseService = service;
    }
  }

  bool agqIsChecked = true;
  bool ak1IsChecked = true;

  bool isIncomeChecked = true;
  bool isWithdrawalChecked = true;
  bool isPendingWithdrawalChecked = true;
  bool isDepositChecked = true;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _initData(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _databaseService.getActivities,
        builder: (context, activitiesSnapshot) {
          if (!activitiesSnapshot.hasData || activitiesSnapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return StreamBuilder<UserWithAssets>(
            stream: _databaseService.getUserWithAssets, // Assuming this is the stream for the user
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return StreamBuilder<List<UserWithAssets>>(
                stream: _databaseService.getConnectedUsersWithAssets, // Assuming this is the stream for connected users
                builder: (context, connectedUsers) {
                  if (!connectedUsers.hasData || connectedUsers.data == null) {
                    return _buildActivitySingleUser(userSnapshot, activitiesSnapshot);
                  }
                  return _buildActivityWithConnectedUsers(userSnapshot, connectedUsers, activitiesSnapshot);

                },
              );
            },
          );
        },
      );
    },
  );

  bool _isSameDay(DateTime date1, DateTime date2) => 
    date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
    
  dynamic _getActivityType(Map<String, dynamic> activity) {
      switch(activity['type']){
        case 'income':
          if (activity['fund'] == 'AGQ Consulting LLC') {
            return 'Fixed Income';
          }
          return 'Dividend Payment';
        case 'deposit':
          return 'Deposit';
        case 'withdrawal':
          return 'Withdrawal';
        case 'pending':
          return 'Pending Withdrawal';
        default:
          return 'Error';
      }

    }
  // Implement sorting on activities based on the user's selection (defaulted to _sorting = 'new-to-old')
  void sort(List<Map<String, dynamic>> activities) {
    try {
      switch (_sorting) {
        case 'new-to-old':
          activities.sort((a, b) => b['time'].compareTo(a['time']));
          break;
        case 'old-to-new':
          activities.sort((a, b) => (a['time']).compareTo(b['time']));
          break;
        case 'low-to-high':
          activities.sort((a, b) => (a['amount']).compareTo((b['amount']).toDouble()));
          break;
        case 'high-to-low':
          activities.sort((a, b) => (b['amount']).compareTo((a['amount'])));
          break;
      }
    } catch (e) {
      if (e is TypeError) {
        // Handle TypeError here (usually casting error)
        log('activity.dart: Caught TypeError: $e');
      } else {
        // Handle other exceptions here
        log('activity.dart: Caught Exception: $e');
      }
    }
  }

  void filter(List<Map<String, dynamic>> activities) {
    activities.removeWhere((element) => !_typeFilter.contains(element['type']));
    activities.removeWhere((element) => !_fundsFilter.contains(element['fund']));
    activities.removeWhere((element) => element['time'].toDate().isBefore(selectedDates.start) || element['time'].toDate().isAfter(selectedDates.end));

    if (_typeFilter.isEmpty) {
      _typeFilter = ['income', 'deposit', 'withdrawal', 'pending'];
    }

    if (_fundsFilter.isEmpty) {
      _fundsFilter = ['AK1 Holdings LP', 'AGQ Consulting LLC'];
    }
  }

  Scaffold _buildActivitySingleUser(AsyncSnapshot<UserWithAssets> userSnapshot, AsyncSnapshot<List<Map<String, dynamic>>> activitiesSnapshot){
    activities = activitiesSnapshot.data!;
    filter(activities);
    sort(activities);
    return Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: <Widget>[
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return _buildFilterAndSort();
                          // } else if (index == 1) {
                          // return _buildHorizontalButtonList(connectedUsersNames); // Add your button list here
                        } else {
                          // activities.sort((a, b) => b['time'].compareTo(a['time'])); // Sort the list by time in reverse order
                          final activity = activities[index - 1]; // Subtract 2 because the first index is used by the search bar and the second by the button list
                          return _buildActivityWithDayHeader(activity, index - 1, activities);
                        }
                      },
                      
                      childCount: activities.length + 1, 
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 150.0), // Add some space at the bottom
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

  Scaffold _buildActivityWithConnectedUsers(AsyncSnapshot<UserWithAssets> userSnapshot, AsyncSnapshot<List<UserWithAssets>> connectedUsers, AsyncSnapshot<List<Map<String, dynamic>>> activitiesSnapshot) {
    activities = activitiesSnapshot.data!;
    filter(activities);
    sort(activities);
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: <Widget>[
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.only(top: 20.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return _buildFilterAndSort();
                      // } else if (index == 1) {
                      //   return _buildHorizontalButtonList(userSnapshot.data!, connectedUsers.data!); // Add your button list here
                      } else {
                        
                        // activities.sort((a, b) => b['time'].compareTo(a['time'])); // Sort the list by time in reverse order
                        final activity = activities[index - 1]; // Subtract 2 because the first index is used by the search bar and the second by the button list
                        return _buildActivityWithDayHeader(activity, index - 1, activities);
                      }
                    },
                    
                    childCount: activities.length + 1, // Add 2 to include the search bar and the button list
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 150.0), // Add some space at the bottom
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

  // This is the search bar area 
  Widget _buildFilterAndSort() => Padding(
    padding: const EdgeInsets.fromLTRB(20.0,10,20,10),
    child: Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: SvgPicture.asset(
              'assets/icons/filter.svg',
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              height: 24,
              width: 24,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: AppColors.defaultGray200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0,
            ),
            label: const Text(
              'Filter',
              style: TextStyle(
                color: AppColors.defaultGray200,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Titillium Web',
              ),
            ),
            onPressed: () {
              _buildFilterOptions(context);
            },
          ),
        ),
        const SizedBox(width: 10), // Add some space between the buttons
        Expanded(
          child: ElevatedButton.icon(
            icon: SvgPicture.asset(
              'assets/icons/sort.svg',
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              height: 24,
              width: 24,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: AppColors.defaultGray200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 0,
            ),
            label: const Text(
              'Sort',
              style: TextStyle(
                color: AppColors.defaultGray200,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Titillium Web',
              ),
            ),
            
            onPressed: () {
              _buildSortOptions(context);
            },
          ),
        ),
      ],
    ),
  );

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
                    'Activity',
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
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
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
            child: SvgPicture.asset(
              'assets/icons/bell.svg',
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              height: 30,
            ),
          ),
        ),
      ],
    );  

  // If the activity is on a new day, we create a header stating the day.
  Widget _buildActivityWithDayHeader(Map<String, dynamic> activity, int index, List<Map<String, dynamic>> activities) {
    final activityDate = (activity['time'] as Timestamp).toDate();
    final previousActivityDate = index > 0 ? (activities[index - 1]['time'] as Timestamp).toDate() : null;
    final nextActivityDate = index < activities.length - 1 ? (activities[index + 1]['time'] as Timestamp).toDate() : null;
    final firstActivityDate = (activities[0]['time'] as Timestamp).toDate();

    bool isLastActivityForTheDay = nextActivityDate == null || !_isSameDay(activityDate, nextActivityDate);
    bool isLatestDate = _isSameDay(activityDate, firstActivityDate);

    if (previousActivityDate == null || !_isSameDay(activityDate, previousActivityDate)) {
      return Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(20.0, isLatestDate ? 20.0 : 40.0, 20.0, 25.0), // Add padding to the top only if it's not the latest date
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('MMMM d, yyyy').format(activityDate),
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                ),
              ),
            ),
          ), // Day header
          _buildActivity(activity, !isLastActivityForTheDay), // Activity
        ],
      );
    } else {
      return _buildActivity(activity, !isLastActivityForTheDay);
    }
  }
  
  Widget _buildActivity(Map<String, dynamic> activity, bool showDivider, ) { 

        // Assuming activity['time'] is a Timestamp object
        Timestamp timestamp = activity['time'];

        // Convert the Timestamp to a DateTime
        DateTime dateTime = timestamp.toDate();

        // Create a new DateFormat for the desired time format
        DateFormat timeFormat = DateFormat('h:mm a'); 

        // Use the timeFormat to format the dateTime
        String time = timeFormat.format(dateTime);

        // Create a new DateFormat for the desired date format
        DateFormat dateFormat = DateFormat('EEEE, MMM. d, yyyy');

        // Use the dateFormat to format the dateTime
        String date = dateFormat.format(dateTime);

        Color getColorBasedOnActivityType(String activityType) {
          switch (activityType) {
            case 'deposit':
              return AppColors.defaultGreen400;
            case 'withdrawal':
              return AppColors.defaultRed400;
            case 'pending':
              return AppColors.defaultYellow400;
            case 'income':
              return AppColors.defaultBlue300;
            default:
              return AppColors.defaultWhite;
          }
        }

        Color getUnderlayColorBasedOnActivityType(String activityType) {
          switch (activityType) {
            case 'deposit':
              return Color.fromARGB(255, 21, 52, 57);
            case 'withdrawal':
              return Color.fromARGB(255, 41, 25, 28);
            case 'pending':
              return Color.fromARGB(255, 24, 46, 68);
            case 'income':
              return Color.fromARGB(255, 24, 46, 68);
            default:
              return AppColors.defaultWhite;
          }
        }

        Widget getIconBasedOnActivityType(String activityType) {
          switch (activityType) {
            case 'deposit':
              return SvgPicture.asset(
                'assets/icons/deposit.svg',
                color: getColorBasedOnActivityType(activityType),
                height: 30,
                width: 30,
              );
            case 'withdrawal':
              return SvgPicture.asset(
                'assets/icons/withdrawal.svg',
                color: getColorBasedOnActivityType(activityType),
                height: 30,
                width: 30,
              );
            case 'pending':
              return SvgPicture.asset(
                'assets/icons/pending_withdrawal.svg',
                color: getColorBasedOnActivityType(activityType),
                height: 30,
                width: 30,
              );
            case 'income':
              return SvgPicture.asset(
                'assets/icons/income.svg',
                color: getColorBasedOnActivityType(activityType),
                height: 30,
                width: 30,
              );
            default:
              return Icon(
                Icons.circle,
                color: AppColors.defaultWhite,
                size: 30,
              );
          }
        }

        
      return Column(
        children: [
          
          GestureDetector(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 5.0, 15.0, 5.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.circle,
                            color: getUnderlayColorBasedOnActivityType(activity['type']),
                            size: 70,
                          ),
                          getIconBasedOnActivityType(activity['type']),
                        ]
                      ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['fund'],
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getActivityType(activity),
                        style: TextStyle(
                          fontSize: 15,
                          color: getColorBasedOnActivityType(activity['type']),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Titillium Web',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${activity['type'] == 'withdrawal' ? '-' : ''}${currencyFormat(activity['amount'].toDouble())}',
                          style: TextStyle(
                            fontSize: 18,
                            color: getColorBasedOnActivityType(activity['type']),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Titillium Web',
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                          const SizedBox(width: 7), // Add width
                          Container(
                            height: 15, // You can adjust the height as needed
                            child: const VerticalDivider(
                              color: Colors.white,
                              width: 1,
                              thickness: 1,
                            ),
                          ),
                          const SizedBox(width: 7), // Add width
                          Text(
                            activity['recipient'] ,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent, // Make the background transparent
                builder: (BuildContext context) => ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    child: FractionallySizedBox(
                      heightFactor: 0.67, 
                      child: Container(
                      color: AppColors.defaultBlueGray800,
                      child: SingleChildScrollView(child: Column(
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                            child: Text(
                              'Activity Details', // Your title here
                              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Titillium Web'),
                            ),
                          ),

                          Text(
                            '${activity['type'] == 'withdrawal' ? '-' : ''}${currencyFormat(activity['amount'].toDouble())}',
                            style: TextStyle(
                              fontSize: 30,
                              color: getColorBasedOnActivityType(activity['type']),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Titillium Web',
                            ),
                          ),

                          const SizedBox(height: 15),

                          Center(
                            child: Text(
                              '${() {
                                switch (activity['type']) {
                                  case 'deposit':
                                    return 'Deposit to your investment at';
                                  case 'withdrawal':
                                    return 'Withdrawal from your investment at';
                                  case 'pending':
                                    return 'Pending withdrawal from your investment at';
                                  case 'income':
                                    return 'Fixed income to your investment at';
                                  default:
                                    return '';
                                }
                              }()} ${activity['fund']}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Titillium Web',
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: getColorBasedOnActivityType(activity['type']),
                                  size: 25,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _getActivityType(activity),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: getColorBasedOnActivityType(activity['type']),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Titillium Web',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 25),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.blue,
                                  size: 50,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Description',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        children: [
                                          Text(
                                            '${() {
                                              switch (activity['type']) {
                                                case 'deposit':
                                                  return 'Deposit to your investment at';
                                                case 'withdrawal':
                                                  return 'Withdrawal from your investment at';
                                                case 'pending':
                                                  return 'Pending withdrawal from your investment at';
                                                case 'income':
                                                  return 'Fixed income to your investment at';
                                                default:
                                                  return '';
                                              }
                                            }()} ${activity['fund']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: Divider(
                              color: Colors.white,
                              thickness: 0.2,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.blue,
                                  size: 50,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        children: [
                                          Text(
                                            date,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: Divider(
                              color: Colors.white,
                              thickness: 0.2,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.blue,
                                  size: 50,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recipient',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Titillium Web',
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        children: [
                                          Text(
                                            activity['recipient'],
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontFamily: 'Titillium Web',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),


                        ],
                      ),
                    ),
                    ),
                  ),
              ));
            },
          ),
          
          if (showDivider)
            const Padding(
              padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
              child: Divider(
                color: Color.fromARGB(255, 132, 132, 132),
                thickness: 0.2,
              ),
            )
        ],
      );
    
    }


  Widget _buildHorizontalButtonList(UserWithAssets user, List<UserWithAssets> connectedUsers) => SizedBox(
    height: 35.0,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10.0, left: 20.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.defaultBlue500,
              side: const BorderSide(color: AppColors.defaultBlue500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            onPressed: () {
              // Implement your button functionality here
            },
            child: const Text(
              'All',
              style: TextStyle(
                fontFamily: 'Titillium Web',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Make the text white
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
           // Add trailing padding
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: AppColors.defaultBlueGray100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            onPressed: () {
              // Implement your button functionality here
            },
            child: Text(
              '${user.info['name']['first']} ${user.info['name']['last']}',
              style: const TextStyle(
                fontFamily: 'Titillium Web',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Make the text white
              ),
            ),
          ),
        ),
        for (var connectedUser in connectedUsers)
          Padding(
            padding: const EdgeInsets.only(right: 10.0), // Add trailing padding
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppColors.defaultBlueGray100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onPressed: () {
                // Implement your button functionality here
              },
              child: Text(
                '${connectedUser.info['name']['first']} ${connectedUser.info['name']['last']}',
                style: const TextStyle(
                  fontFamily: 'Titillium Web',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Make the text white
                ),
              ),
            ),
          ),
        const SizedBox(width: 10.0), // Add some space after the last button
      ],
    ),
  );

// This is the bottom navigation bar 
  Widget _buildBottomNavigationBar(BuildContext context) => Container(
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
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: SvgPicture.asset(
              'assets/icons/dashboard_hollowed.svg',
              height: 22,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const AnalyticsPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: SvgPicture.asset(
              'assets/icons/analytics_hollowed.svg',
              height: 22,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ActivityPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );},
            child: SvgPicture.asset(
              'assets/icons/activity_filled.svg',
              height: 20,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                ),
              );
            },
            child: SvgPicture.asset(
              'assets/icons/profile_hollowed.svg',
              height: 22,
            ),
          ),
        ],
      ),
    );

  
  
  void _buildFilterOptions(BuildContext context) {

    /// Edits the filter based on the value of `value`
    /// 
    /// If `value` is true, it adds `key` to filter, if false it removes
    /// `code` specifies which filter to edit; 1 for fund, 2 for type
    void editFilter(int code, bool value, String key){
      switch (code) {
        case 1:
          if (value) {
            if (!_fundsFilter.contains(key)) {
              _fundsFilter.add(key);
            }
          } else {
            _fundsFilter.remove(key);
          }
          break;
        case 2:
          if (value) {
            if (!_typeFilter.contains(key)) {
              _typeFilter.add(key);
            }
          } else {
            _typeFilter.remove(key);
          }
          break;
      }
    }


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make the background transparent
      builder: (BuildContext context) => ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            color: AppColors.defaultBlueGray800,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                 Padding(
                  padding: EdgeInsets.all(25.0),
                  child: Text(
                    'Filter Activity', // Your title here
                    style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Titillium Web'),
                  ),
                ),

                SingleChildScrollView(
                  child: ListView(
                    physics: NeverScrollableScrollPhysics(), // to disable ListView's scrolling
                    shrinkWrap: true,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: ListTile(
                          title: Row(
                            children: [
                              const Text('By Time Period', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                              const SizedBox(width: 10), // Add some spacing between the title and the date
                              // Container(
                              //   decoration: BoxDecoration(
                              //     color: AppColors.defaultBlueGray500,
                              //     borderRadius: BorderRadius.circular(10), // Add a rounded border
                              //   ),
                              //   padding: EdgeInsets.all(8.0), // Add some padding to give the text some room
                              //   child: Text(
                              //     selectedDates.start == selectedDates.end
                              //       ? '${DateFormat.yMd().format(selectedDates.start)}'
                              //       : '${DateFormat.yMd().format(selectedDates.start)} - ${DateFormat.yMd().format(selectedDates.end)}',
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //       fontFamily: 'Titillium Web',
                              //       fontWeight: FontWeight.bold, // Bolden the font
                              //     ),
                              //   ),
                              // )
                            ],
                          ),
                          onTap: () async {
                            // Implement your filter option 1 functionality here
                            final DateTimeRange? dateTimeRange = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(3000),
                              builder: (BuildContext context, Widget? child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    scaffoldBackgroundColor: AppColors.defaultGray500,
                                    textTheme: TextTheme(
                                      headlineMedium: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Titillium Web',
                                        fontSize: 20,
                                      ),
                                      bodyMedium: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Titillium Web',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                ),
                            );
                            if (dateTimeRange != null) {
                              setState(() {
                                selectedDates = dateTimeRange;
                              });
                            }
                          },
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              const Text('By Fund', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                              const SizedBox(width: 10), // Add some spacing between the title and the date
                              // Container(
                              //   decoration: BoxDecoration(
                              //     color: AppColors.defaultBlueGray500,
                              //     borderRadius: BorderRadius.circular(10), // Add a rounded border
                              //   ),
                              //   padding: EdgeInsets.all(8.0), // Add some padding to give the text some room
                              //   child: Text(
                              //     '$selectedFunds',
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //       fontFamily: 'Titillium Web',
                              //       fontWeight: FontWeight.bold, // Bolden the font
                              //     ),
                              //   ),
                              // )
                            ],
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          children: [
                            StatefulBuilder(
                              builder: (BuildContext context, StateSetter setState) => Column(
                                  children: <Widget>[
                                    CheckboxListTile(
                                      title: const Text(
                                        'AGQ Consulting LLC',
                                        style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                      ),
                                      value: agqIsChecked,
                                      onChanged: (bool? value) {
                                        editFilter(1, value!, 'AGQ Consulting LLC');
                                        setState(() {
                                          agqIsChecked = value;
                                        });
                                      },
                                    ),
                                    CheckboxListTile(
                                      title: const Text(
                                        'AK1 Holdings LP',
                                        style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                      ),
                                      value: ak1IsChecked,
                                      onChanged: (bool? value) {
                                        editFilter(1, value!, 'AK1 Holdings LP');
                                        setState(() {
                                          ak1IsChecked = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              const Text('By Type of Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Titillium Web')),
                              const SizedBox(width: 10), // Add some spacing between the title and the date
                              // Container(
                              //   decoration: BoxDecoration(
                              //     color: AppColors.defaultBlueGray500,
                              //     borderRadius: BorderRadius.circular(10), // Add a rounded border
                              //   ),
                              //   padding: EdgeInsets.all(8.0), // Add some padding to give the text some room
                              //   child: Flexible(
                              //     child: Text(
                              //       selectedActivityTypes,
                              //       style: TextStyle(
                              //         color: Colors.white,
                              //         fontFamily: 'Titillium Web',
                              //         fontWeight: FontWeight.bold, // Bolden the font
                              //       ),
                              //     ),
                              //   ),
                              // )
                            ],
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          children: [
                            StatefulBuilder(
                              builder: (BuildContext context, StateSetter setState) => Column(
                                  children: <Widget>[
                                    CheckboxListTile(
                                      title: Text(
                                        'Income',
                                        style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                      ),
                                      value: isIncomeChecked,
                                      onChanged: (bool? value) {
                                        editFilter(2, value!, 'income');
                                        setState(() {
                                          isIncomeChecked = value;
                                        });
                                      },
                                    ),
                                    CheckboxListTile(
                                      title: Text(
                                        'Withdrawal',
                                        style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                      ),
                                      value: isWithdrawalChecked,
                                      onChanged: (bool? value) {
                                        editFilter(2, value!, 'withdrawal');
                                        setState(() {
                                          isWithdrawalChecked = value;
                                        });
                                      },
                                    ),
                                    CheckboxListTile(
                                      title: Text(
                                        
                                        'Pending Withdrawal',
                                        style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                      ),
                                      value: isPendingWithdrawalChecked,
                                      onChanged: (bool? value) {
                                        editFilter(2, value!, 'pending');
                                        setState(() {
                                          isPendingWithdrawalChecked = value;
                                        });
                                      },
                                    ),
                                    CheckboxListTile(
                                      title: Text(
                                        'Deposit',
                                        style: TextStyle(fontSize: 16.0, color: Colors.white, fontFamily: 'Titillium Web'),
                                      ),
                                      value: isDepositChecked,
                                      onChanged: (bool? value) {
                                        editFilter(2, value!, 'deposit');
                                        setState(() {
                                          isDepositChecked = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Container(
                        color: AppColors.defaultBlueGray800,
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // This is the background color
                          ),
                          child: const Text('Apply', style: TextStyle(color: Color(0xFF8991A1), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web')),
                          onPressed: () {
                            Navigator.pop(context);
                            // Implement your apply functionality here
                            setState(() {
                            log('$_fundsFilter');
                            log('$_typeFilter');
                              filter(activities);
                            });
                          } // Close the bottom sheet,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      child: TextButton(
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.close, color: Colors.white),
                            Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Titillium Web')),
                          ],
                        ),
                        onPressed: () {
                          // Implement your cancel functionality here
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _buildSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make the background transparent
      builder: (BuildContext context) => SingleChildScrollView(
        child: Container(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: Container(
              color: AppColors.defaultBlueGray800,
              child: Wrap(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20.0), // Add some space at the top
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Sort By',
                              style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Titillium Web'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0), // Add some space between the title and the options
                        _buildOption(context, 'Date: New to Old (Default)', 'new-to-old'),
                        _buildOption(context, 'Date: Old to New', 'old-to-new'),
                        _buildOption(context, 'Amount: Low to High', 'low-to-high'),
                        _buildOption(context, 'Amount: High to Low', 'high-to-low'),
                        const SizedBox(height: 20.0), // Add some space at the bottom
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, String value) => Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
            color: _sorting == value ? AppColors.defaultBlue500 : Colors.transparent, // Change the color based on whether the option is selected
        borderRadius: BorderRadius.circular(20.0),
        ),
        child: TextButton(
          child: Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Titillium Web')),
          onPressed: () {
            setState(() {
              _sorting = value;
            });
            Navigator.pop(context); // Close the bottom sheet
          },
        ),
      ),
    );
}

