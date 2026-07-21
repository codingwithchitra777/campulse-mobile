import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'history_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.account_circle, size: 80, color: Colors.blue),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Account Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 40),
        ListTile(
          leading: const Icon(Icons.history_edu, color: Colors.white),
          title: const Text('Trade Ledger (History)', style: TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          tileColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          },
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          tileColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            AuthService.instance.logout();
          },
        ),
      ],
    );
  }
}
