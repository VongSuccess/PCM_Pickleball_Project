import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';
import 'members_screen.dart';
import 'admin_courts_screen.dart';
import 'admin_tournaments_screen.dart';

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
    const AdminTournamentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar for Desktop (Optional, for now use BottomNav for simplicity adaptable to mobile)
          // Navigation Rail could depend on screen width
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Hội viên'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis), label: 'Sân bãi'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Giải đấu'),
        ],
      ),
    );
  }
}

// ============== COMPONENT: OVERVIEW TAB (New Premium UI) ==============

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

  Future<void> _approveDeposit(int id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.apiService.approveDeposit(id);
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt yêu cầu nạp tiền!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectDeposit(int id) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.apiService.rejectDeposit(id, "Admin từ chối");
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.orange));
    } catch(e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Stats Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isWide = width > 600;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildGradientStatCard(
                            'Tổng thành viên', 
                            '${_dashboardData?['totalMembers'] ?? 0}', 
                            Icons.people_alt_rounded, 
                            [Colors.blue.shade400, Colors.blue.shade700],
                            isWide ? (width - 16) / 2 : width,
                          ),
                          _buildGradientStatCard(
                            'Booking Tháng', 
                            '${_dashboardData?['monthlyBookings'] ?? 0}', 
                            Icons.calendar_month_rounded, 
                            [Colors.purple.shade400, Colors.purple.shade700],
                            isWide ? (width - 16) / 2 : width,
                          ),
                          _buildGradientStatCard(
                            'Doanh thu', 
                            _fmtMoney(_dashboardData?['revenue']), 
                            Icons.monetization_on_rounded, 
                            [Colors.orange.shade400, Colors.deepOrange.shade700],
                            isWide ? (width - 16) / 2 : width,
                          ),
                          _buildGradientStatCard(
                            'Tiền nạp', 
                            _fmtMoney(_dashboardData?['monthlyDeposits']), 
                            Icons.account_balance_wallet_rounded, 
                            [AppColors.premiumGreen, AppColors.premiumGreen.withOpacity(0.7)],
                            isWide ? (width - 16) / 2 : width,
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 2. Charts Section
                  const Text('Biểu đồ tăng trưởng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Doanh thu 7 ngày qua', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            Icon(Icons.show_chart_rounded, color: AppColors.premiumGreen),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'T${(value.toInt() + 1)}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    const FlSpot(0, 3), const FlSpot(1, 1), const FlSpot(2, 4), const FlSpot(3, 2), const FlSpot(4, 5), const FlSpot(5, 3), const FlSpot(6, 6), // Should be real data
                                  ],
                                  isCurved: true,
                                  color: AppColors.premiumLime,
                                  barWidth: 4,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true, 
                                    color: AppColors.premiumLime.withOpacity(0.2)
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. Pending Deposits
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Yêu cầu Nạp tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_pendingDeposits.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: Text('${_pendingDeposits.length} mới', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDepositList(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildGradientStatCard(String title, String val, IconData icon, List<Color> colors, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.last.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDepositList() {
    if (_pendingDeposits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
             Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade300),
             const SizedBox(height: 16),
             const Text('Không có yêu cầu chờ duyệt', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingDeposits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
         final d = _pendingDeposits[index];
         return Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(16),
             boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))],
           ),
           child: Row(
             children: [
               CircleAvatar(
                 backgroundColor: AppColors.premiumGreen.withOpacity(0.1),
                 child: const Icon(Icons.attach_money, color: AppColors.premiumGreen),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(d['memberName'] ?? 'Thành viên', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                     Text(_fmtMoney(d['amount']), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                     if (d['description'] != null) Text(d['description'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                   ],
                 ),
               ),
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   IconButton(
                     icon: const Icon(Icons.check_circle, color: AppColors.success, size: 32), 
                     onPressed: () => _approveDeposit(d['id'])
                   ),
                   IconButton(
                     icon: const Icon(Icons.cancel, color: AppColors.error, size: 32), 
                     onPressed: () => _rejectDeposit(d['id'])
                   ),
                 ],
               ),
             ],
           ),
         );
      },
    );
  }

  String _fmtMoney(dynamic val) {
     if (val == null) return '0đ';
     final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
     return formatter.format(val);
  }
}
