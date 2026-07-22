import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class GoogleProfile {
  final String userId;
  final String name;
  final String? email;

  /// Google account avatar URL (from the signed-in account), shown in the
  /// top-left app-bar avatar + the drawer header. Null → initials fallback.
  final String? photoUrl;

  /// Backend-issued JWT. Sent as `Authorization: Bearer <token>` on every
  /// authed request; persisted so the session survives an app restart.
  final String? token;

  const GoogleProfile(
      {required this.userId, required this.name, this.email, this.photoUrl, this.token});

  Map<String, dynamic> toJson() =>
      {'userId': userId, 'name': name, 'email': email, 'photoUrl': photoUrl, 'token': token};

  factory GoogleProfile.fromJson(Map<String, dynamic> json) => GoogleProfile(
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        token: json['token'] as String?,
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

    GoogleSignIn.instance.authenticationEvents.listen((event) async {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final account = event.user;
        try {
          final auth = account.authentication;
          final idToken = auth.idToken;
          if (idToken != null) {
            final res = await ApiService.instance.googleLogin(idToken);
            if (res['success'] == true) {
              final p = GoogleProfile(
                userId: res['userId'] as String,
                name: (res['userName'] as String?) ?? 'Google User',
                email: res['email'] as String?,
                // The backend response has no avatar; take it from the Google
                // account directly.
                photoUrl: account.photoUrl,
                token: res['token'] as String?,
              );
              _applyProfile(p);
              await _persist(p);
            }
          }
        } catch (e) {
          debugPrint('Google Sign-In backend login error: $e');
        }
      }
    });

    await GoogleSignIn.instance.initialize(
      serverClientId: kIsWeb ? null : _webClientId,
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
        _applyProfile(GoogleProfile.fromJson(jsonDecode(cached) as Map<String, dynamic>));
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

  /// Publishes a signed-in profile and wires its bearer token into ApiService.
  void _applyProfile(GoogleProfile p) {
    profile.value = p;
    ApiService.instance.activeUserId = p.userId;
    ApiService.instance.authToken = p.token;
  }

  /// Mirrors the web app's "Continue as Guest using Demo Account" backdoor.
  /// Hits /api/auth/demo so the session carries a real JWT (otherwise every
  /// authed call 401s).
  Future<void> loginAsDemo(String userId, String name) async {
    final res = await ApiService.instance.demoLogin(userId, name);
    final p = GoogleProfile(
      userId: (res['userId'] as String?) ?? userId,
      name: (res['userName'] as String?) ?? name,
      email: '$userId@demo.com',
      token: res['token'] as String?,
    );
    _applyProfile(p);
    await _persist(p);
  }

  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    // On web, the GIS renderButton handles the sign in popup directly.
    // On mobile, we trigger it manually. The stream listener above handles the rest.
    if (!kIsWeb) {
      await GoogleSignIn.instance.authenticate();
    }
  }

  Future<void> logout() async {
    profile.value = null;
    ApiService.instance.activeUserId = 'guest';
    ApiService.instance.authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best-effort; local session is already cleared above.
    }
  }
}