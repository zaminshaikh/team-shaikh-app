import 'package:flutter/material.dart';

class AuthState extends ChangeNotifier {
  bool _hasNavigatedToFaceIDPage = false;
  bool _justAuthenticated = false;
  bool _initiallyAuthenticated = false;
  bool _isAppLockEnabled = false;
  bool _forceDashboard = false;

  bool get hasNavigatedToFaceIDPage => _hasNavigatedToFaceIDPage;
  bool get justAuthenticated => _justAuthenticated;
  bool get initiallyAuthenticated => _initiallyAuthenticated;
  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get forceDashboard => _forceDashboard;

  void setHasNavigatedToFaceIDPage(bool value) {
    _hasNavigatedToFaceIDPage = value;
    notifyListeners();
  }

  void setJustAuthenticated(bool value) {
    _justAuthenticated = value;
    notifyListeners();
  }

  void setInitiallyAuthenticated(bool value) {
    _initiallyAuthenticated = value;
    notifyListeners();
  }

  void setAppLockEnabled(bool value) {
    _isAppLockEnabled = value;
    notifyListeners();
  }

  void setForceDashboard(bool value) {
    _forceDashboard = value;
    notifyListeners();
  }
}
