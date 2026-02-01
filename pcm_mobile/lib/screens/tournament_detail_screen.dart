import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/tournament_models.dart';
import '../widgets/tournament_bracket.dart';
import '../themes/app_colors.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;

  const TournamentDetailScreen({
    super.key, 
    required this.tournamentId, 
    required this.tournamentName
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  List<dynamic> _matches = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await auth.apiService.getTournament(widget.tournamentId);
      setState(() {
        _data = response.data;
        _matches = response.data['matches'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _generateSchedule() async {
    setState(() => _isGenerating = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await auth.apiService.generateSchedule(widget.tournamentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Tạo lịch thành công')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _joinTournament() async {
    final t = _data?['tournament'];
    if (t == null) return;
    
    final double entryFee = (t['entryFee'] ?? 0).toDouble();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // 1. Check Wallet Balance
    if (auth.user?.walletBalance != null && (auth.user!.walletBalance! < entryFee)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư ví không đủ để tham gia giải.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Confirm Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSportSurface,
        title: const Text('Xác nhận tham gia', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn tham gia giải "${t['name']}"?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Phí tham gia: ', style: TextStyle(color: Colors.white70)),
                Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(entryFee), style: TextStyle(color: AppColors.darkSportAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('(Số tiền sẽ được trích trực tiếp từ ví của bạn)', style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkSportAccent, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thanh toán & Tham gia'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 3. Call API
    setState(() => _isLoading = true);
    try {
      // Assuming teamName is required, checking if single player or team tournament. 
      // For now, simpler flow: Auto-use user name or ask for Team Name if needed.
      
      final teamName = auth.user?.fullName ?? 'My Team'; 
      
      await auth.apiService.joinTournament(widget.tournamentId, teamName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tham gia thành công!'), backgroundColor: AppColors.success));
        _loadData(); // Reload to update status
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = e.toString();
        // Handle "Already joined" case gracefully
        if (msg.toLowerCase().contains('bạn đã đăng ký') || msg.toLowerCase().contains('already')) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn đã tham gia giải này rồi. Đang cập nhật...'), backgroundColor: Colors.blue));
             _loadData(); // Reload to fix state
             return;
        }

        // Handle specific error messages like "Insufficient balance"
        if (msg.contains('balance') || msg.contains('số dư')) msg = 'Số dư không đủ.';
        
        // Clean up Dio error message if possible
        if (msg.startsWith('Exception: ')) msg = msg.substring(11);
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.user?.tier == 'Admin' || auth.user?.username == 'admin';
    final tournament = _data?['tournament'];
    
    // Check if joined
    bool isJoined = false;
    if (_data != null) {
       // 1. Check explicit flag from backend
       if (_data!['isJoined'] == true) {
         isJoined = true;
       } 
       // 2. Fallback: Check participants list matches current user
       else if (_data!['participants'] != null && auth.user?.id != null) {
          final parts = _data!['participants'] as List;
          final userId = auth.user!.id; // String id
          // Check if any participant has the same memberId
          final found = parts.any((p) => p['memberId'].toString() == userId.toString());
          if (found) isJoined = true;
       }
    }

    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(
        title: Text(widget.tournamentName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkSportBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isAdmin)
             IconButton(
              icon: _isGenerating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.shuffle),
              tooltip: 'Tạo lịch thi đấu ngẫu nhiên',
              onPressed: _isGenerating ? null : _generateSchedule,
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent))
        : Column(
            children: [
               // Header Status / Dashboard Link
               if (isJoined)
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(12),
                   color: const Color(0xFF00E676).withOpacity(0.1),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: const [
                       Icon(Icons.check_circle, color: Color(0xFF00E676)),
                       SizedBox(width: 8),
                       Text('BẠN ĐÃ THAM GIA GIẢI ĐẤU NÀY', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                     ],
                   ),
                 ),

              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppColors.darkSportAccent,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.darkSportAccent,
                        tabs: const [
                          Tab(text: 'Thông tin & VĐV'),
                          Tab(text: 'Lịch thi đấu'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildInfoTab(tournament, _data?['participants'] ?? [], isJoined),
                            _buildBracketTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      bottomNavigationBar: (!isJoined && tournament != null && (tournament['status'] == 'Open' || tournament['status'] == 'Registering')) 
        ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSportSurface,
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: ElevatedButton(
              onPressed: _joinTournament,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkSportAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('THAM GIA NGAY (Entry Fee)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        : null,
    );
  }

  Widget _buildInfoTab(dynamic tournament, List<dynamic> participants, bool isJoined) {
    if (tournament == null) return const SizedBox();
    
    final status = tournament['status'] ?? 'Unknown';
    final entryFee = (tournament['entryFee'] ?? 0).toDouble();
    final prizePool = (tournament['prizePool'] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Status Card
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: AppColors.darkSportSurface,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.white10),
             ),
             child: Column(
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('Trạng thái', style: TextStyle(color: Colors.white70)),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: _getStatusColor(status).withOpacity(0.2),
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
                       ),
                       child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                     )
                   ],
                 ),
                 const Divider(height: 24, color: Colors.white12),
                 Row(
                   children: [
                     Expanded(child: _buildStatItem('Phí tham gia', NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(entryFee), Colors.orange)),
                     Expanded(child: _buildStatItem('Tổng thưởng', NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(prizePool), AppColors.darkSportAccent)),
                   ],
                 )
               ],
             ),
           ),
           
           const SizedBox(height: 24),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text('Danh sách VĐV (${participants.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
               if (isJoined)
                 Text('(Bạn đã có mặt)', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 12, fontStyle: FontStyle.italic)),
             ],
           ),
           const SizedBox(height: 12),
           
           if (participants.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Chưa có vận động viên nào', style: TextStyle(color: Colors.white30)))),

           ...participants.map((p) => Container(
             margin: const EdgeInsets.only(bottom: 8),
             decoration: BoxDecoration(
               color: AppColors.darkSportSurface,
               borderRadius: BorderRadius.circular(12),
             ),
             child: ListTile(
               leading: CircleAvatar(
                 backgroundColor: Colors.blueGrey.withOpacity(0.3),
                 child: Text((p['memberName'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
               ),
               title: Text(p['memberName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               subtitle: Text(p['teamName'] != null && p['teamName'].isNotEmpty ? 'Team: ${p['teamName']}' : 'Cá nhân', style: const TextStyle(color: Colors.white54)),
             ),
           )),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
     if (status == 'Open' || status == 'Registering') return Colors.green;
     if (status == 'Ongoing' || status == 'InProgress') return Colors.amber;
     if (status == 'Finished') return Colors.red;
     return Colors.blue;
  }

  Widget _buildBracketTab() {
    if (_matches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Chưa có lịch thi đấu\n\nAdmin cần tạo lịch thi đấu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Convert dynamic to MatchModel
    final tournament = _data?['tournament'];
    final participants = _data?['participants'] ?? [];
    
    // Build name map    
    Map<String, String> memberNames = {};
    for (var p in participants) {
      memberNames[p['memberId']] = p['memberName'];
    }

    // Convert matches to MatchModel with names
    List<MatchModel> matchModels = _matches.map((m) {
      // Get player names
      String? p1Name;
      String? p2Name;
      
      if (m['team1_Player1Id'] != null) {
        p1Name = memberNames[m['team1_Player1Id']] ?? 'TBD';
      }
      if (m['team2_Player1Id'] != null) {
        p2Name = memberNames[m['team2_Player1Id']] ?? 'TBD';
      }

      return MatchModel(
        id: m['id'] ?? 0,
        tournamentId: m['tournamentId'],
        roundName: m['roundName'],
        date: m['date'],
        startTime: m['startTime'],
        team1Player1Id: m['team1_Player1Id'],
        team1Player1Name: p1Name,
        team2Player1Id: m['team2_Player1Id'],
        team2Player1Name: p2Name,
        score1: m['score1'],
        score2: m['score2'],
        winningSide: m['winningSide'],
        status: m['status'],
      );
    }).toList();

    final tournamentModel = TournamentDetailModel(
      id: tournament?['id'] ?? 0,
      name: tournament?['name'] ?? '',
      format: tournament?['format'] ?? '',
      status: tournament?['status'] ?? '',
    );

    return TournamentBracket(
      tournament: tournamentModel,
      matches: matchModels,
    );
  }
}

