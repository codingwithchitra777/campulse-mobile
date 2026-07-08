import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class GoogleProfile {
  final String userId;
  final String name;
  final String? email;

  const GoogleProfile({required this.userId, required this.name, this.email});

  Map<String, dynamic> toJson() => {'userId': userId, 'name': name, 'email': email};

  factory GoogleProfile.fromJson(Map<String, dynamic> json) => GoogleProfile(
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
      );
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  // Same Web OAuth Client ID the backend's /api/auth/google endpoint checks
  // the token audience against (backend/app/api/v1/endpoints/auth.py).
  static const _webClientId = '1048965896991-dirq98278c5cj312k2o0kq3f307e2krf.apps.googleusercontent.com';
  static const _prefsKey = 'google_profile';

  final ValueNotifier<GoogleProfile?> profile = ValueNotifier<GoogleProfile?>(null);

  bool _googleInitialized = false;

  bool get isGuest => profile.value == null;
  String get activeUserId => profile.value?.userId ?? 'guest';

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _webClientId,
      clientId: kIsWeb ? _webClientId : null,
    );
    _googleInitialized = true;
  }

  /// Restores a cached session (if any) and prepares Google Sign-In.
  /// Must be awaited once at app startup before building the UI.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);
    if (cached != null) {
      try {
        profile.value = GoogleProfile.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_prefsKey);
      }
    }
    ApiService.instance.activeUserId = activeUserId;

    try {
      await _ensureGoogleInitialized();
    } catch (e) {
      debugPrint('Google Sign-In initialize failed: $e');
    }
  }

  Future<void> _persist(GoogleProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(p.toJson()));
  }

  /// Mirrors the web app's "Continue as Guest using Demo Account" backdoor.
  Future<void> loginAsDemo(String userId, String name) async {
    final p = GoogleProfile(userId: userId, name: name, email: '$userId@demo.com');
    profile.value = p;
    ApiService.instance.activeUserId = p.userId;
    await _persist(p);
  }

  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google did not return an ID token');
    }
    final res = await ApiService.instance.googleLogin(idToken);
    if (res['success'] != true) {
      throw Exception('Google sign-in failed');
    }
    final p = GoogleProfile(
      userId: res['userId'] as String,
      name: (res['userName'] as String?) ?? 'Google User',
      email: res['email'] as String?,
    );
    profile.value = p;
    ApiService.instance.activeUserId = p.userId;
    await _persist(p);
  }

  Future<void> logout() async {
    profile.value = null;
    ApiService.instance.activeUserId = 'guest';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best-effort; local session is already cleared above.
    }
  }
}