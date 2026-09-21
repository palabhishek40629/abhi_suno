import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserAccount {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final bool isLoggedIn;

  UserAccount({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.isLoggedIn,
  });

  factory UserAccount.guest() => UserAccount(
        uid: '',
        name: 'अतिथि (Guest)',
        email: 'guest@abhisuno.app',
        photoUrl: '',
        isLoggedIn: false,
      );
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _loadUser();
  }

  UserAccount _currentUser = UserAccount.guest();
  UserAccount get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser.isLoggedIn;

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('user_is_logged_in') ?? false;
      if (isLoggedIn) {
        _currentUser = UserAccount(
          uid: prefs.getString('user_uid') ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: prefs.getString('user_name') ?? 'Abhishek Pal',
          email: prefs.getString('user_email') ?? 'palabhishek40629@gmail.com',
          photoUrl: prefs.getString('user_photo_url') ?? '',
          isLoggedIn: true,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> signInWithGoogle({String? customEmail, String? customName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = customEmail ?? prefs.getString('user_email') ?? 'palabhishek40629@gmail.com';
      final name = customName ?? prefs.getString('user_name') ?? 'Abhishek Pal';
      final uid = 'google_${email.hashCode.abs()}';

      _currentUser = UserAccount(
        uid: uid,
        name: name,
        email: email,
        photoUrl: '',
        isLoggedIn: true,
      );

      await prefs.setBool('user_is_logged_in', true);
      await prefs.setString('user_uid', uid);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_is_logged_in', false);
      _currentUser = UserAccount.guest();
      notifyListeners();
    } catch (_) {}
  }
}
