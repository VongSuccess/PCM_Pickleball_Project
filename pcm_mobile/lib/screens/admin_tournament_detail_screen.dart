import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';

class AdminTournamentDetailScreen extends StatefulWidget {
  final int tournamentId;
  const AdminTournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<AdminTournamentDetailScreen> createState() => _AdminTournamentDetailScreenState();
}

class _AdminTournamentDetailScreenState extends State<AdminTournamentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _tournament;
  List<dynamic> _matches = [];
  bool _isLoading = true;
  bool _isSeeded = true; // Toggle for Seed/Random mode mockup

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    try {
      final tResponse = await api.getTournament(widget.tournamentId);
      final mResponse = await api.getMatches(tournamentId: widget.tournamentId);
      
      if (mounted) {
        setState(() {
          _tournament = tResponse.data;
          _matches = mResponse.data is List ? mResponse.data : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSchedule() async {
    // Show confirmation dialog with Seed/Random option
    bool useSeed = true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.darkSportSurface,
          title: const Text('Tạo lịch thi đấu?', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hệ thống sẽ tự động sắp xếp các cặp đấu.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              SwitchListTile(
                 title: const Text('Ưu tiên hạt giống (Seed)', style: TextStyle(color: Colors.white)),
                 subtitle: Text(useSeed ? 'Sắp xếp theo Rank' : 'Ngẫu nhiên', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                 value: useSeed,
                 activeColor: AppColors.darkSportAccent,
                 onChanged: (val) => setStateDialog(() => useSeed = val),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), 
              child: const Text('Hủy', style: TextStyle(color: Colors.white54))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkSportAccent, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tạo Lịch'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<AuthProvider>(context, listen: false).apiService.generateSchedule(widget.tournamentId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo lịch thi đấu!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    // There is no direct updateStatus API in the provided service, only finishTournament.
    // Assuming backend might have logic or we use generic update if available.
    // For now, only 'finish' is clearly supported via api.finishTournament.
    // If 'start' is needed, maybe edit tournament start date or backend auto-starts?
    // Let's implement Finish. For Start, we might just trigger schedule generation.
    
    if (status == 'Completed') {
       try {
        await Provider.of<AuthProvider>(context, listen: false).apiService.finishTournament(widget.tournamentId);
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppColors.darkSportBackground, body: Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent)));

    if (_tournament == null) {
      return Scaffold(
        backgroundColor: AppColors.darkSportBackground,
        appBar: AppBar(backgroundColor: AppColors.darkSportBackground, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
        body: const Center(child: Text('Không tìm thấy thông tin giải đấu', style: TextStyle(color: Colors.white54))),
      );
    }

    final t = _tournament!;
    final participants = t['participants'] as List? ?? [];
    final status = t['status'] ?? 'Upcoming';
    final name = t['name'] ?? 'Chi tiết giải đấu';

    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkSportBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
           IconButton(
             icon: const Icon(Icons.edit, color: Colors.white),
             onPressed: () {
               // Navigation to Edit
             },
           )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.darkSportAccent,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.darkSportAccent,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Vận động viên'),
            Tab(text: 'Lịch đấu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(t, status),
          _buildParticipantsTab(participants),
          _buildMatchesTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> t, String status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(t, status),
          const SizedBox(height: 24),
          const Text('THAO TÁC QUẢN TRỊ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          
          if (status == 'Open' || status == 'Upcoming')
            _buildActionButton(
              'Tạo Lịch Thi Đấu (Generate Schedule)', 
              Icons.shuffle, 
              Colors.orange, 
              _generateSchedule
            ),
          
          if (status == 'Active' || status == 'InProgress') 
             _buildActionButton(
              'Kết Thúc Giải Đấu (End Tournament)', 
              Icons.emoji_events, 
              Colors.redAccent, 
              () => _updateStatus('Completed')
            ),

          if (status == 'Completed')
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
               child: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 12), Text('Giải đấu đã kết thúc', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
             )
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> t, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Chip(
                 label: Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                 backgroundColor: _getStatusColor(status).withOpacity(0.2),
                 labelStyle: TextStyle(color: _getStatusColor(status)),
               ),
               Text('${t['participants']?.length ?? 0} VĐV', style: const TextStyle(color: Colors.white70)),
             ],
           ),
           const SizedBox(height: 12),
           _buildRowInfo(Icons.calendar_today, 'Ngày bắt đầu', _fmtDate(t['startDate'])),
           _buildRowInfo(Icons.event_available, 'Ngày kết thúc', _fmtDate(t['endDate'])),
           const Divider(color: Colors.white12, height: 24),
           _buildRowInfo(Icons.monetization_on, 'Phí tham gia', NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(t['entryFee'] ?? 0)),
           _buildRowInfo(Icons.card_giftcard, 'Tổng thưởng', NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(t['prizePool'] ?? 0)),
           _buildRowInfo(Icons.category, 'Thể thức', t['format'] ?? 'Knockout'),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(List<dynamic> participants) {
    if (participants.isEmpty) return const Center(child: Text('Chưa có vận động viên đăng ký', style: TextStyle(color: Colors.white54)));
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: participants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = participants[index];
        final name = (p['user']?['fullName'] ?? p['teamName'] ?? 'Unknown').toString();
        return Container(
          decoration: BoxDecoration(
             color: AppColors.darkSportSurface,
             borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueGrey, 
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển')));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) return const Center(child: Text('Chưa có lịch thi đấu', style: TextStyle(color: Colors.white54)));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final m = _matches[index];
        final p1 = m['participant1'] != null ? (m['participant1']['teamName'] ?? 'TBD') : 'TBD';
        final p2 = m['participant2'] != null ? (m['participant2']['teamName'] ?? 'TBD') : 'TBD';
        final score = m['score']?.toString() ?? 'vs';
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkSportSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Text('Trận ${m['round'] ?? index + 1}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(p1.toString(), textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26, 
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkSportAccent.withOpacity(0.5))
                    ),
                    child: Text(score, style: const TextStyle(color: AppColors.darkSportAccent, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Text(p2.toString(), textAlign: TextAlign.left, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildRowInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch(status) {
      case 'Open': return Colors.green;
      case 'InProgress': return Colors.orange;
      case 'Completed': return Colors.red;
      case 'Upcoming': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _fmtDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr.toString()));
    } catch (_) { return dateStr.toString(); }
  }
}
