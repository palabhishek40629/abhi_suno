import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import 'language_service.dart';

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

  factory UserAccount.guest([bool isHindi = false]) => UserAccount(
        uid: '',
        name: isHindi ? 'अतिथि' : 'Guest',
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

  static const String kNameKey = 'user_custom_profile_name';
  static const String kEmailKey = 'user_custom_profile_email';
  static const String kImageKey = 'user_custom_profile_image';
  static const String kBioKey = 'user_custom_profile_bio';
  static const String kLoggedInKey = 'user_is_logged_in';
  static const String kGoogleUserKey = 'user_is_google_account';
  static const String kUidKey = 'user_uid';

  UserAccount _currentUser = UserAccount.guest(LanguageService().isHindi);
  UserAccount get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser.isLoggedIn;

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool(kLoggedInKey) ?? prefs.getBool('user_is_logged_in') ?? false;
      if (loggedIn) {
        final name = prefs.getString(kNameKey) ?? prefs.getString('user_name') ?? 'Abhishek Pal';
        final email = prefs.getString(kEmailKey) ?? prefs.getString('user_email') ?? 'palabhishek40629@gmail.com';
        final photo = prefs.getString(kImageKey) ?? prefs.getString('user_photo_url') ?? '';
        final uid = prefs.getString(kUidKey) ?? 'user_${email.hashCode.abs()}';

        _currentUser = UserAccount(
          uid: uid,
          name: name,
          email: email,
          photoUrl: photo,
          isLoggedIn: true,
        );
        notifyListeners();
      } else {
        _currentUser = UserAccount.guest(LanguageService().isHindi);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> signInWithGoogle({String? customEmail, String? customName, String? photoUrl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = (customEmail != null && customEmail.trim().isNotEmpty)
          ? customEmail.trim()
          : (prefs.getString(kEmailKey) ?? prefs.getString('user_email') ?? 'palabhishek40629@gmail.com');
      final name = (customName != null && customName.trim().isNotEmpty)
          ? customName.trim()
          : (prefs.getString(kNameKey) ?? prefs.getString('user_name') ?? 'Abhishek Pal');
      final photo = (photoUrl != null && photoUrl.trim().isNotEmpty)
          ? photoUrl.trim()
          : (prefs.getString(kImageKey) ?? '');
      final uid = 'google_${email.hashCode.abs()}';

      _currentUser = UserAccount(
        uid: uid,
        name: name,
        email: email,
        photoUrl: photo,
        isLoggedIn: true,
      );

      await prefs.setBool(kLoggedInKey, true);
      await prefs.setBool(kGoogleUserKey, true);
      await prefs.setString(kUidKey, uid);
      await prefs.setString(kNameKey, name);
      await prefs.setString(kEmailKey, email);
      if (photo.isNotEmpty) {
        await prefs.setString(kImageKey, photo);
      }

      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);

      // Keep UserService perfectly synchronized
      await UserService().loginWithGoogle(name: name, email: email, photoUrl: photo.isNotEmpty ? photo : null);

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kLoggedInKey, false);
      await prefs.setBool(kGoogleUserKey, false);
      await prefs.remove(kUidKey);
      _currentUser = UserAccount.guest(LanguageService().isHindi);
      await UserService().logout();
      notifyListeners();
    } catch (_) {}
  }
}
