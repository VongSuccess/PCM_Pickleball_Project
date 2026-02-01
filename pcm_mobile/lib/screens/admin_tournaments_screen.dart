import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';
import 'admin_tournament_detail_screen.dart'; // Will create next

class AdminTournamentsScreen extends StatefulWidget {
  const AdminTournamentsScreen({super.key});

  @override
  State<AdminTournamentsScreen> createState() => _AdminTournamentsScreenState();
}

class _AdminTournamentsScreenState extends State<AdminTournamentsScreen> {
  List<dynamic> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() => _isLoading = true);
    try {
      // Assuming getTournaments returns all or we can filter
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final response = await api.getTournaments();
      setState(() {
        _tournaments = response.data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final feeController = TextEditingController();
    final prizeController = TextEditingController();
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 2));
    String format = 'Knockout';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Tạo giải đấu'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên giải đấu')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: format,
                    items: ['Knockout', 'RoundRobin', 'Hybrid'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (val) => setStateDialog(() => format = val!),
                    decoration: const InputDecoration(labelText: 'Thể thức'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: feeController, decoration: const InputDecoration(labelText: 'Phí tham gia'), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(controller: prizeController, decoration: const InputDecoration(labelText: 'Tổng thưởng'), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Bắt đầu: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setStateDialog(() => startDate = picked);
                    },
                  ),
                  ListTile(
                    title: Text('Kết thúc: ${DateFormat('dd/MM/yyyy').format(endDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: endDate.isBefore(startDate) ? startDate : endDate, firstDate: startDate, lastDate: DateTime(2030));
                      if (picked != null) setStateDialog(() => endDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                   if (nameController.text.isEmpty) return;
                   try {
                     final api = Provider.of<AuthProvider>(context, listen: false).apiService;
                     await api.createTournament({
                       'name': nameController.text,
                       'format': format,
                       'startDate': startDate.toIso8601String(),
                       'endDate': endDate.toIso8601String(),
                       'entryFee': double.tryParse(feeController.text) ?? 0,
                       'prizePool': double.tryParse(prizeController.text) ?? 0
                     });
                     if (mounted) {
                       Navigator.pop(context);
                       _loadTournaments();
                     }
                   } catch(e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                   }
                },
                child: const Text('Tạo'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Giải đấu'), automaticallyImplyLeading: false),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          final t = _tournaments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${t['status']} - ${t['participantCount']} người tham gia'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTournamentDetailScreen(tournamentId: t['id']))),
            ),
          );
        },
      ),
    );
  }
}
