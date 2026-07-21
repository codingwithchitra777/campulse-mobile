import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildGoogleSignInButton({required VoidCallback onPressed, required bool loading}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: web.renderButton(),
  );
}
