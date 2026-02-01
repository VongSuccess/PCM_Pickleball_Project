import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
    try {
      // Get bookings for selected date (start of day to end of day)
      final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final end = start.add(const Duration(days: 1));
      
      final response = await api.getCalendar(start, end);
      setState(() {
        _bookings = response.data is List ? response.data : [];
        // Sort by start time
        _bookings.sort((a, b) => DateTime.parse(a['startTime']).compareTo(DateTime.parse(b['startTime'])));
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(
        title: const Text('Quản lý Đặt sân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkSportBackground,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
                builder: (context, child) => Theme(
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
                ),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadBookings();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.today, color: AppColors.darkSportAccent),
                const SizedBox(width: 12),
                Text(
                  'Lịch ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Text('${_bookings.length} lịch', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent))
              : _bookings.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 60, color: Colors.white12),
                          SizedBox(height: 16),
                          Text('Không có lịch đặt nào trong ngày này', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        final start = DateTime.parse(b['startTime']);
                        final end = DateTime.parse(b['endTime']);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkSportSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Text(DateFormat('HH:mm').format(start), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Container(width: 2, height: 12, color: Colors.white12, margin: const EdgeInsets.symmetric(vertical: 4)),
                                  Text(DateFormat('HH:mm').format(end), style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b['court']?['name'] ?? 'Sân ?', style: const TextStyle(color: AppColors.darkSportAccent, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(b['description'] ?? 'Đặt sân', style: const TextStyle(color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 12, color: Colors.white54),
                                        const SizedBox(width: 4),
                                        Text(b['user']?['fullName'] ?? 'Khách vãng lai', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white54),
                                onPressed: () {
                                  // More actions (cancel, edit)
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
