import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

/// M1 - Hồ sơ sinh viên, mục tiêu B1, cài đặt.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.construction),
            title: Text('M1 - Nền tảng và tài khoản'),
            subtitle: Text('Nguyễn Ngọc Thành An · Đang phát triển'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: context.read<AuthProvider>().signOut,
          ),
        ],
      ),
    );
  }
}
