import 'package:flutter/material.dart';
import '../themes/app_colors.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(title: const Text('Cài đặt hệ thống'), backgroundColor: AppColors.darkSportBackground, foregroundColor: Colors.white, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildItem('Cấu hình chung', Icons.settings_applications),
          _buildItem('Quản lý phân quyền', Icons.security),
          _buildItem('Backup dữ liệu', Icons.backup),
          _buildItem('Phiên bản ứng dụng (v1.0.0)', Icons.info_outline),
        ],
      ),
    );
  }

  Widget _buildItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }
}

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(title: const Text('Hỗ trợ'), backgroundColor: AppColors.darkSportBackground, foregroundColor: Colors.white, elevation: 0),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_mic, size: 64, color: AppColors.darkSportAccent),
            SizedBox(height: 16),
            Text('Liên hệ kỹ thuật', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('hotline: 1900 1234', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
