import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

Widget buildGoogleSignInButton({required VoidCallback onPressed, required bool loading}) {
  return Builder(
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.login),
          label: Text(l10n.signInWithGoogle),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      );
    }
  );
}
