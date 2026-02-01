import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';

class AdminCourtsScreen extends StatefulWidget {
  const AdminCourtsScreen({super.key});

  @override
  State<AdminCourtsScreen> createState() => _AdminCourtsScreenState();
}

class _AdminCourtsScreenState extends State<AdminCourtsScreen> {
  List<dynamic> _courts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      final response = await api.getCourts();
      if (mounted) {
        setState(() {
          _courts = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCourtDialog({Map<String, dynamic>? court}) async {
    final nameController = TextEditingController(text: court?['name']);
    final descController = TextEditingController(text: court?['description']);
    final priceController = TextEditingController(text: court != null ? court['pricePerHour'].toString() : '');
    bool isActive = court?['isActive'] ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.darkSportSurface,
            title: Text(court == null ? 'Thêm Sân Mới' : 'Cập nhật Sân', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(nameController, 'Tên sân (VD: Sân 1)', Icons.sports_tennis),
                  const SizedBox(height: 12),
                  _buildTextField(descController, 'Mô tả / Loại sân', Icons.description),
                  const SizedBox(height: 12),
                  _buildTextField(priceController, 'Giá thuê (VNĐ/giờ)', Icons.attach_money, isNumber: true),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Đang hoạt động', style: TextStyle(color: Colors.white)),
                    subtitle: Text(isActive ? 'Sân có thể được đặt' : 'Sân đang bảo trì/khóa', style: TextStyle(color: isActive ? AppColors.success : Colors.red, fontSize: 12)),
                    value: isActive,
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setStateDialog(() => isActive = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkSportAccent, foregroundColor: Colors.black),
                onPressed: () async {
                  if (nameController.text.isEmpty || priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên và giá sân')));
                    return;
                  }
                  try {
                    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
                    final data = {
                      'name': nameController.text,
                      'description': descController.text,
                      'pricePerHour': double.tryParse(priceController.text) ?? 0,
                      if (court != null) 'isActive': isActive,
                    };

                    if (court == null) {
                      await api.createCourt(data);
                    } else {
                      await api.updateCourt(court['id'], data);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _loadCourts();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thành công!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                child: const Text('Lưu'),
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
  
  Future<void> _viewBookings(int courtId) async {
    // Show modal with loading then list of bookings
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSportBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => _CourtBookingsList(courtId: courtId, scrollController: controller),
      ),
    );
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
        title: const Text('Quản lý Sân bãi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkSportBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourtDialog(),
        backgroundColor: AppColors.darkSportAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent)) 
        : RefreshIndicator(
            onRefresh: _loadCourts,
            color: AppColors.darkSportAccent,
            backgroundColor: AppColors.darkSportSurface,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _courts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final court = _courts[index];
                final bool isActive = court['isActive'] ?? true;
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSportSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isActive ? Colors.transparent : Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 60, height: 60,
                                color: isActive ? AppColors.darkSportAccent.withOpacity(0.2) : Colors.red.withOpacity(0.1),
                                child: Icon(Icons.sports_tennis, color: isActive ? AppColors.darkSportAccent : Colors.red, size: 32),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(court['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive ? AppColors.success.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isActive ? 'Active' : 'Inactive', 
                                          style: TextStyle(color: isActive ? AppColors.success : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_fmtMoney(court['pricePerHour']) + '/giờ', style: const TextStyle(color: AppColors.darkSportAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(court['description'] ?? 'Sân tiêu chuẩn', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.white12)),
                        ),
                        child: Row(
                          children: [
                             Expanded(
                               child: TextButton.icon(
                                 onPressed: () => _viewBookings(court['id']),
                                 icon: const Icon(Icons.calendar_month, size: 18, color: Colors.blueAccent),
                                 label: const Text('Xem lịch đặt', style: TextStyle(color: Colors.blueAccent)),
                               ),
                             ),
                             Container(width: 1, height: 48, color: Colors.white12),
                             Expanded(
                               child: TextButton.icon(
                                 onPressed: () => _showCourtDialog(court: court),
                                 icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                                 label: const Text('Chỉnh sửa', style: TextStyle(color: Colors.white70)),
                               ),
                             ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }
}

class _CourtBookingsList extends StatefulWidget {
  final int courtId;
  final ScrollController scrollController;
  const _CourtBookingsList({required this.courtId, required this.scrollController});

  @override
  State<_CourtBookingsList> createState() => _CourtBookingsListState();
}

class _CourtBookingsListState extends State<_CourtBookingsList> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Get calendar for next 30 days
      final now = DateTime.now();
      final end = now.add(const Duration(days: 30));
      final response = await auth.apiService.getCalendar(now, end);
      
      if (mounted) {
        final allBookings = response.data is List ? response.data : [];
        setState(() {
          // Filter by courtId
          _bookings = allBookings.where((b) => b['courtId'] == widget.courtId).toList();
          // Sort by time
          _bookings.sort((a, b) => DateTime.parse(a['startTime']).compareTo(DateTime.parse(b['startTime'])));
          _isLoading = false;
        });
      }
    } catch(e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
             child: Container(
               width: 40, height: 4, 
               decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
             ),
          ),
          const SizedBox(height: 20),
          const Text('Lịch đặt sân sắp tới', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent))
              : _bookings.isEmpty
                  ? const Center(child: Text('Chưa có lịch đặt nào', style: TextStyle(color: Colors.white54)))
                  : ListView.separated(
                      controller: widget.scrollController,
                      itemCount: _bookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        final start = DateTime.parse(b['startTime']);
                        final end = DateTime.parse(b['endTime']);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  children: [
                                    Text(DateFormat('dd').format(start), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(DateFormat('MM').format(start), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}', style: const TextStyle(color: AppColors.darkSportAccent, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(b['description'] ?? 'Đặt sân', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                    Text('User: ${b['userId'] ?? 'Unknown'}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  ],
                                ),
                              ),
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
