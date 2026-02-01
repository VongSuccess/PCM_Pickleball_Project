import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/tournament_models.dart';
import '../widgets/tournament_bracket.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.user?.tier == 'Admin' || auth.user?.username == 'admin';
    final tournament = _data?['tournament'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournamentName),
        actions: [
          if (isAdmin)
            IconButton(
              icon: _isGenerating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Icon(Icons.shuffle),
              tooltip: 'Tạo lịch thi đấu ngẫu nhiên',
              onPressed: _isGenerating ? null : _generateSchedule,
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Color(0xFF00BFA5),
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Thông tin & VĐV'),
                    Tab(text: 'Cây thi đấu'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildInfoTab(tournament, _data?['participants'] ?? []),
                      _buildBracketTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoTab(dynamic tournament, List<dynamic> participants) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament != null) ...[
             Card(
               child: ListTile(
                 title: const Text('Trạng thái giải'),
                 trailing: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: Colors.blue,
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Text(tournament['status'] ?? '', style: const TextStyle(color: Colors.white)),
                 ),
               ),
             ),
             const SizedBox(height: 16),
          ],
          Text('Danh sách VĐV (${participants.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...participants.map((p) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(p['memberName'][0])),
              title: Text(p['memberName']),
              subtitle: Text(p['teamName'] != null && p['teamName'].isNotEmpty ? 'Team: ${p['teamName']}' : 'Cá nhân'),
              trailing: const Icon(Icons.more_vert),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: const Text('Xem hồ sơ'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tính năng đang phát triển')),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.sports_kabaddi, color: Colors.red),
                        title: const Text('Gửi lời thách đấu'),
                        onTap: () async {
                          Navigator.pop(context);
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          
                          // Quick confirm
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Thách đấu'),
                              content: Text('Bạn có muốn thách đấu với ${p['memberName']} không?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đồng ý')),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              final res = await auth.apiService.createDuel(p['memberId']);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res.data['message']), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          )),
        ],
      ),
    );
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

