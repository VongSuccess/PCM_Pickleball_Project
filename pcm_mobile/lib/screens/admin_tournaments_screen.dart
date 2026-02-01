import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';
import 'admin_tournament_detail_screen.dart';

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
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final response = await api.getTournaments();
      if (mounted) {
        setState(() {
          _tournaments = response.data;
          _isLoading = false;
        });
      }
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
            backgroundColor: AppColors.darkSportSurface,
            title: const Text('Tạo Giải Đấu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameController, 'Tên giải đấu', Icons.emoji_events),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: format,
                    dropdownColor: AppColors.darkSportSurface,
                    items: ['Knockout', 'RoundRobin', 'Hybrid'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (val) => setStateDialog(() => format = val!),
                    decoration: InputDecoration(
                       labelText: 'Thể thức',
                       labelStyle: const TextStyle(color: Colors.white54),
                       prefixIcon: const Icon(Icons.category, color: AppColors.darkSportAccent),
                       filled: true,
                       fillColor: Colors.white.withOpacity(0.05),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(feeController, 'Phí tham gia', Icons.monetization_on, isNumber: true),
                  const SizedBox(height: 12),
                  _buildTextField(prizeController, 'Tổng thưởng', Icons.card_giftcard, isNumber: true),
                  const SizedBox(height: 12),
                  _buildDateTile('Bắt đầu', startDate, (d) => setStateDialog(() => startDate = d)),
                  const SizedBox(height: 8),
                  _buildDateTile('Kết thúc', endDate, (d) => setStateDialog(() => endDate = d)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkSportAccent, foregroundColor: Colors.black),
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
                       'prizePool': double.tryParse(prizeController.text) ?? 0,
                       'status': 'Open',
                       'maxParticipants': 32, // Default
                     });
                     if (mounted) {
                       Navigator.pop(context);
                       _loadTournaments();
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo giải thành công!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
                     }
                   } catch(e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                   }
                },
                child: const Text('Tạo Giải'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppColors.darkSportAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
         final picked = await showDatePicker(
            context: context, 
            initialDate: date, 
            firstDate: DateTime.now().subtract(const Duration(days: 365)), 
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.darkSportAccent,
                    onPrimary: Colors.black,
                    surface: AppColors.darkSportSurface,
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: AppColors.darkSportSurface,
                ),
                child: child!,
              );
            }
         );
         if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.darkSportAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('$label: ${DateFormat('dd/MM/yyyy').format(date)}', style: const TextStyle(color: Colors.white))),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(
        title: const Text('Quản lý Giải đấu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkSportBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.darkSportAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent)) 
        : RefreshIndicator(
            onRefresh: _loadTournaments,
            color: AppColors.darkSportAccent,
            backgroundColor: AppColors.darkSportSurface,
            child: _tournaments.isEmpty 
              ? const Center(child: Text('Chưa có giải đấu nào', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tournaments.length,
              itemBuilder: (context, index) {
                final t = _tournaments[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTournamentDetailScreen(tournamentId: t['id']))).then((_) => _loadTournaments()),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.darkSportSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(t['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(t['status']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: Text(t['status'] ?? 'Unknown', style: TextStyle(color: _getStatusColor(t['status']), fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${DateFormat('dd/MM').format(DateTime.parse(t['startDate']))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(t['endDate']))}', 
                          style: const TextStyle(color: Colors.white54, fontSize: 13)
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 16, color: AppColors.darkSportAccent),
                            const SizedBox(width: 4),
                            Text('${t['participants']?.length ?? 0} người tham gia', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const Spacer(),
                            const Text('Xem chi tiết', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 14, color: AppColors.darkSportAccent),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  Color _getStatusColor(String? status) {
    switch(status) {
      case 'Open': return Colors.green;
      case 'InProgress': return Colors.orange;
      case 'Completed': return Colors.red;
      case 'Upcoming': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
