import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _pendingDeposits = [];
  Map<String, dynamic>? _dashboardData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final pendingResponse = await auth.apiService.getPendingDeposits();
      final dashboardResponse = await auth.apiService.getAdminDashboard(); // For total revenue stats
      if (mounted) {
        setState(() {
          _pendingDeposits = pendingResponse.data is List ? pendingResponse.data : [];
          _dashboardData = dashboardResponse.data;
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã duyệt yêu cầu!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
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

  String _fmtMoney(dynamic val) {
     if (val == null) return '0đ';
     final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
     return formatter.format(val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(
        title: const Text('Tài chính', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkSportBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.darkSportAccent,
          labelColor: AppColors.darkSportAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
             Tab(text: "Duyệt Nạp Tiền"),
             Tab(text: "Lịch sử Giao dịch"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildPendingDepositsTab(),
              _buildTransactionHistoryTab(),
            ],
          ),
    );
  }

  Widget _buildPendingDepositsTab() {
     if (_pendingDeposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('Không có yêu cầu chờ duyệt', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingDeposits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
         final d = _pendingDeposits[index];
         return Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: AppColors.darkSportSurface,
             borderRadius: BorderRadius.circular(16),
             border: Border.all(color: Colors.white10),
           ),
           child: Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: AppColors.darkSportAccent.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.attach_money, color: AppColors.darkSportAccent),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(d['memberName'] ?? 'Thành viên', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                     const SizedBox(height: 4),
                     Text(_fmtMoney(d['amount']), style: const TextStyle(color: AppColors.darkSportAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                     const SizedBox(height: 4),
                     if (d['description'] != null && d['description'].toString().isNotEmpty) 
                        Text(d['description'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                     Text('ID: #${d['id']}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                   ],
                 ),
               ),
               Column(
                 children: [
                   IconButton(
                     onPressed: () => _approveDeposit(d['id']),
                     icon: const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                     tooltip: 'Duyệt',
                   ),
                   IconButton(
                     onPressed: () => _rejectDeposit(d['id']),
                     icon: const Icon(Icons.cancel, color: AppColors.error, size: 32),
                     tooltip: 'Từ chối',
                   ),
                 ],
               )
             ],
           ),
         );
      },
    );
  }

  Widget _buildTransactionHistoryTab() {
    // Placeholder for Transaction History - In real app, fetch from API
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Lịch sử giao dịch sẽ hiển thị ở đây', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Text('Tổng thu hiện tại: ${_fmtMoney(_dashboardData?['monthlyDeposits'])}', style: TextStyle(color: AppColors.darkSportAccent)),
        ],
      ),
    );
  }
}
