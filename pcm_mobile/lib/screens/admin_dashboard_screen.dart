import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';
import 'members_screen.dart';
import 'admin_courts_screen.dart';
import 'admin_finance_screen.dart';  // New Finance Screen
import 'admin_more_screen.dart';     // New More Screen

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminOverviewTab(), 
    const MembersScreen(),    
    const AdminCourtsScreen(),
    const AdminFinanceScreen(),
    const AdminMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.darkSportBackground,
          selectedItemColor: AppColors.darkSportAccent,
          unselectedItemColor: Colors.white54,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Tổng quan'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Hội viên'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_tennis_outlined), activeIcon: Icon(Icons.sports_tennis), label: 'Sân bãi'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money), activeIcon: Icon(Icons.monetization_on), label: 'Tài chính'),
            BottomNavigationBarItem(icon: Icon(Icons.menu), activeIcon: Icon(Icons.menu_open), label: 'Thêm'),
          ],
        ),
      ),
    );
  }
}

// ============== COMPONENT: OVERVIEW TAB (Read-Only) ==============
class AdminOverviewTab extends StatefulWidget {
  const AdminOverviewTab({super.key});

  @override
  State<AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<AdminOverviewTab> {
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _pendingDeposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final dashboardResponse = await auth.apiService.getAdminDashboard();
      final pendingResponse = await auth.apiService.getPendingDeposits();
      if (mounted) {
        setState(() {
          _dashboardData = dashboardResponse.data;
          _pendingDeposits = pendingResponse.data is List ? pendingResponse.data : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmtMoney(dynamic val) {
     if (val == null) return '0đ';
     final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
     return formatter.format(val);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent));

    final user = Provider.of<AuthProvider>(context).user;
    final totalMembers = _dashboardData?['totalMembers'] ?? 0;
    final monthlyBookings = _dashboardData?['monthlyBookings'] ?? 0;
    final totalDeposit = _dashboardData?['monthlyDeposits'] ?? 0; 
    final revenue = _dashboardData?['revenue'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.darkSportAccent,
          backgroundColor: AppColors.darkSportSurface,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === 1. HEADER ===
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                      child: user?.avatarUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Quản trị viên',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Text('Vợt Thủ Phố Núi HQ', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
                  ],
                ),

                const SizedBox(height: 24),

                // === 2. CLUB STATS ===
                const Text('THỐNG KÊ CÂU LẠC BỘ', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Thành viên', '$totalMembers', Icons.groups, '+12%', true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Booking', '$monthlyBookings', Icons.calendar_today, '+5%', true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Giải đấu', '3', Icons.emoji_events, '-2%', false)),
                  ],
                ),

                const SizedBox(height: 24),

                // === 3. FINANCIAL OVERVIEW ===
                const Text('TỔNG QUAN TÀI CHÍNH', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFinancialCard(
                        'Tổng nạp', 
                        _fmtMoney(totalDeposit), 
                        Icons.account_balance_wallet, 
                        const Color(0xFF00C853),
                        'TUẦN'
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                       child: _buildFinancialCard(
                        'Tổng chi', 
                        _fmtMoney(totalDeposit * 0.3), 
                        Icons.payments, 
                        const Color(0xFFFF5252),
                        'TUẦN'
                      )
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // === 4. URGENT ALERTS (Read Only) ===
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CẢNH BÁO KHẨN CẤP', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                      child: Text('${_pendingDeposits.length + 1} ACTION ITEMS', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                
                // Alert 1: Maintenance
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bảo trì sân bãi', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                            Text('Sân 3 cần kiểm tra bề mặt.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        )
                      ),
                    ],
                  ),
                ),

                // Alert 2: Pending Top-ups Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSportSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                       Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                        child: const Icon(Icons.sync_alt, color: Colors.white70, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Duyệt nạp tiền', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('${_pendingDeposits.length} yêu cầu chờ xử lý', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Just a summary button, no action except maybe navigation implies awareness
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.darkSportAccent, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, String growth, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.darkSportAccent, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            growth, 
            style: TextStyle(
              color: isPositive ? AppColors.darkSportAccent : Colors.redAccent, 
              fontSize: 10, 
              fontWeight: FontWeight.bold
            )
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(String label, String value, IconData icon, Color color, String badge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                )
             ],
           ),
           const SizedBox(height: 24),
           Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
           const SizedBox(height: 4),
           Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
