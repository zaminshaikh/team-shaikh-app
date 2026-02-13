// ignore_for_file: deprecated_member_use

import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agq_app/screens/authenticate/utils/app_state.dart';
import 'package:agq_app/screens/utils/resources.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});
  
  @override
  // ignore: library_private_types_in_public_api
  _AuthenticationPageState createState() => _AuthenticationPageState();
} 
class _AuthenticationPageState extends State<AuthenticationPage> {
  final Future<void> _initializeWidgetFuture = Future.value();

  String? cid;

  @override
  void initState() {
    super.initState();
    _loadSelectedTimeOption();
    _loadAppLockState();
  }

  // Load the selected time option from SharedPreferences
  Future<void> _loadSelectedTimeOption() async {
    final prefs = await SharedPreferences.getInstance();
    final timeOption = prefs.getString('selectedTimeOption') ?? 'Immediately'; // Changed default to 'Immediately'
    if (!mounted) return;
    context.read<AuthState>().setSelectedTimeOption(timeOption);
    log('Loaded selected time option: $timeOption');
  }

  // Save the selected time option to SharedPreferences
  Future<void> _saveSelectedTimeOption(String timeOption) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTimeOption', timeOption);
    if (!mounted) return;
    context.read<AuthState>().setSelectedTimeOption(timeOption);
    log('Saved selected time option: $timeOption');
  }

  // Load the app lock state from SharedPreferences
  Future<void> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('isAppLockEnabled') ?? false;
    if (!mounted) return;
    context.read<AuthState>().setAppLockEnabled(isEnabled);
    log('Loaded app lock state: $isEnabled');
  }

  // Save the app lock state to SharedPreferences
  Future<void> _saveAppLockState(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAppLockEnabled', isEnabled);
    if (!mounted) return;
    context.read<AuthState>().setAppLockEnabled(isEnabled);
    log('Saved app lock state: $isEnabled');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _initializeWidgetFuture, // Initialize the database service
    builder: (context, snapshot) => buildAuthenticationPage(context)
  );

  Scaffold buildAuthenticationPage(BuildContext context) {
    final appState = Provider.of<AuthState>(context, listen: false);
  
    return Scaffold(
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
                      _buildLockFeatureInfo(),
                      if (appState.isAppLockEnabled) _buildSampleCupertinoListSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
              'Authentication',
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

  Column _buildLockFeatureInfo() => Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/face_id.svg',
                color: Colors.white,
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 15),
              const Text(
                'App Lock',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Titillium Web',
                  fontSize: 22,
                ),
              ),
              const Spacer(),
              CupertinoSwitch(
                value: context.watch<AuthState>().isAppLockEnabled,
                onChanged: (bool value) {
                  context.read<AuthState>().setAppLockEnabled(value);
                  _saveAppLockState(value);
                  log('App lock enabled: $value');
                },
                activeColor: AppColors.defaultBlue300, // Set the active color
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Each time you exit the app, a passcode or biometric authentication such as Face ID will be required to re-enter. '
            'To reduce how often you are prompted, you can set a timer below. '
            'Choose how much time should pass before a passcode or biometric authentication is requested again.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.defaultBlueGray400,
              fontFamily: 'Titillium Web',
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );

  Widget _buildSampleCupertinoListSection() => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.defaultBlueGray800, // Gray background
          borderRadius: BorderRadius.circular(12.0), // Rounded borders
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildCupertinoListTile('Immediately'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: CupertinoColors.separator, thickness: 1.5),
            ),
            _buildCupertinoListTile('1 minute'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: CupertinoColors.separator, thickness: 1.5),
            ),
            _buildCupertinoListTile('2 minute'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: CupertinoColors.separator, thickness: 1.5),
            ),
            _buildCupertinoListTile('5 minute'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(color: CupertinoColors.separator, thickness: 1.5),
            ),
            _buildCupertinoListTile('10 minute'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

  Widget _buildCupertinoListTile(String timeOption) => CupertinoListTile(
      leading: SvgPicture.asset(
        'assets/icons/time.svg',
        width: 24,
        height: 24,
        color: Colors.white,
      ),
      title: Text(
        timeOption,
        style: const TextStyle(
          fontFamily: 'Titillium Web',
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        setState(() {
          context.read<AuthState>().setSelectedTimeOption(timeOption);
          _saveSelectedTimeOption(timeOption);
        });
        log('Selected time option: $timeOption');
      },
      trailing: context.watch<AuthState>().selectedTimeOption == timeOption
          ? const Icon(Icons.check_rounded, color: AppColors.defaultBlueGray400)
          : null,
    );
}