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

class _AdminTournamentDetailScreenState extends State<AdminTournamentDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final response = await api.getTournament(widget.tournamentId);
      setState(() {
        _data = response.data; // { Tournament: {}, Participants: [], Matches: [] }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSchedule() async {
    if (_data == null) return;
    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final res = await api.generateSchedule(widget.tournamentId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'])));
      _loadData();
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _finishTournament() async {
    try {
       final api = Provider.of<AuthProvider>(context, listen: false).apiService;
       final res = await api.finishTournament(widget.tournamentId);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? 'Đã xong')));
       _loadData();
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _updateMatch(dynamic match) async {
    final s1Ctrl = TextEditingController(text: match['score1'].toString());
    final s2Ctrl = TextEditingController(text: match['score2'].toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật tỉ số'),
        content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Row(
               children: [
                 Expanded(child: TextField(controller: s1Ctrl, decoration: const InputDecoration(labelText: 'Score 1'), keyboardType: TextInputType.number)),
                 const SizedBox(width: 16),
                 Expanded(child: TextField(controller: s2Ctrl, decoration: const InputDecoration(labelText: 'Score 2'), keyboardType: TextInputType.number)),
               ],
             )
           ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
                 try {
                   final api = Provider.of<AuthProvider>(context, listen: false).apiService;
                   await api.updateMatchResult(
                     match['id'], 
                     int.tryParse(s1Ctrl.text) ?? 0, 
                     int.tryParse(s2Ctrl.text) ?? 0, 
                     null
                   );
                   if (mounted) {
                     Navigator.pop(context);
                     _loadData();
                   }
                 } catch(e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                 }
            },
            child: const Text('Lưu'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_data == null) return const Scaffold(body: Center(child: Text('Lỗi')));

    final t = _data!['tournament'];
    final participants = _data!['participants'] as List;
    final matches = _data!['matches'] as List;

    return Scaffold(
      appBar: AppBar(title: Text(t['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoCard('Trạng thái', t['status'], Colors.blue),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _infoCard('Người tham gia', '${participants.length}', Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _infoCard('Số trận đấu', '${matches.length}', Colors.green)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách trận đấu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (t['status'] == 'Open' && participants.length >= 2)
                  ElevatedButton(onPressed: _generateSchedule, child: const Text('Tạo lịch đấu')),
                if (t['status'] == 'Ongoing' && matches.every((m) => m['status'] == 'Finished'))
                   ElevatedButton(onPressed: _finishTournament, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Kết thúc giải')),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final m = matches[index];
                return Card(
                  child: ListTile(
                    title: Text('${m['roundName']}'),
                    subtitle: Text('ID: ${m['id']} | ${m['date'].toString().split('T')[0]}'),
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${m['score1']} - ${m['score2']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          if (m['status'] != 'Finished')
                             IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _updateMatch(m))
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
         Text(title, style: TextStyle(color: color, fontSize: 12)),
         Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))
      ]),
    );
  }
}
