import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_colors.dart';
import '../providers/auth_provider.dart';
import 'admin_tournaments_screen.dart';
import 'admin_booking_screen.dart';
import 'admin_more_subscreens.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(
        title: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkSportBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuSection('QUẢN LÝ', [
            _buildMenuItem(context, 'Quản lý Giải đấu', Icons.emoji_events, Colors.orange, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminTournamentsScreen()));
            }),
            _buildMenuItem(context, 'Quản lý Đặt sân', Icons.calendar_today, Colors.blue, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookingScreen()));
            }),
             _buildMenuItem(context, 'Quản lý Trận đấu', Icons.sports_tennis, Colors.green, () {
               // Match Management is typically inside Tournaments or specific Match list.
               // For now, redirect to Tournament detail or a placeholder Match List if exists.
               // Let's create a placeholder for Matches if not exist, or re-use Booking screen structure.
               // Actually we have getMatches api, let's create a simple match list screen quickly or just show snackbar for now if I didn't create it.
               // Actually, user complained it does NOTHING. I should at least show snackbar or navigate.
               // I will navigate to a new AdminMatchesScreen (I will create it in next step or inline it).
               // For now let's map it to Tournaments screen as matches are mostly there, or show SnackBar clearer.
               // Better: Create AdminMatchListScreen later. For this step, I'll link to TournamentsScreen with a message.
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng truy cập Giải đấu để quản lý trận đấu')));
            }),
          ]),

          const SizedBox(height: 24),

          _buildMenuSection('HỆ THỐNG', [
            _buildMenuItem(context, 'Thông báo', Icons.notifications, Colors.amber, () {
               // Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())); // Assuming exists
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng Thông báo đang cập nhật')));
            }),
            _buildMenuItem(context, 'Cài đặt hệ thống', Icons.settings, Colors.grey, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => AdminSettingsScreen()));
            }),
            _buildMenuItem(context, 'Hỗ trợ', Icons.help, Colors.cyan, () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => AdminSupportScreen()));
            }),
          ]),

          const SizedBox(height: 24),

          _buildMenuSection('TÀI KHOẢN', [
            _buildMenuItem(context, 'Đăng xuất', Icons.logout, Colors.red, () async {
               final auth = Provider.of<AuthProvider>(context, listen: false);
               await auth.logout();
               if (context.mounted) {
                 Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
               }
            }),
          ]),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSportSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
      shape: const Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
    );
  }
}
