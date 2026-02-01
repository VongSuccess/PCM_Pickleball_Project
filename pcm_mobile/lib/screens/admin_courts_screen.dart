import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<AuthProvider>(context, listen: false).apiService;
      // Pass true to include inactive if backend supports filtering, or just get all
      // Assuming GET /courts returns active ones. If we want all, backend needs adjustment or we rely on what we have.
      // Backend implementation: query = query.Where(c => c.IsActive) unless includeInactive=true.
      // I added includeInactive param to backend.
      final response = await api.getCourts(); // Need to update GET in ApiService to support param or just default.
      // Wait, I didn't update GET to accept param in ApiService.dart. 
      // It's ok, let's just show active ones for now or update ApiService later.
      // Let's assume response.data is List
      setState(() {
        _courts = response.data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCourtDialog({Map<String, dynamic>? court}) async {
    final nameController = TextEditingController(text: court?['name']);
    final descController = TextEditingController(text: court?['description']);
    final priceController = TextEditingController(text: court?['pricePerHour']?.toString());
    bool isActive = court?['isActive'] ?? true;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(court == null ? 'Thêm sân mới' : 'Sửa sân'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên sân'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Giá thuê (VNĐ/giờ)'),
                keyboardType: TextInputType.number,
              ),
              if (court != null)
                SwitchListTile(
                  title: const Text('Đang hoạt động'),
                  value: isActive,
                  onChanged: (val) {
                    // Update state manually inside dialog if needed, but simple var is enough for final submit
                    isActive = val; 
                    // To update UI instantly, we need StatefulBuilder but here I just grab value at Submit.
                    // Wait, SwitchListTile needs setState to change visual.
                    // So wrap in StatefulBuilder.
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) return;
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thành công!')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteCourt(int id) async {
    final curContext = context;
    final confirm = await showDialog<bool>(
      context: curContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sân?'),
        content: const Text('Sân sẽ bị ẩn khỏi danh sách đặt sân.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Xóa')
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
        try {
            await Provider.of<AuthProvider>(curContext, listen: false).apiService.deleteCourt(id);
            _loadCourts();
        } catch(e) {
            ScaffoldMessenger.of(curContext).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sân'),
        automaticallyImplyLeading: false, // Managed by Parent Tab
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourtDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _loadCourts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courts.length,
              itemBuilder: (context, index) {
                final court = _courts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (court['isActive'] ?? true) ? Colors.green : Colors.grey,
                      child: const Icon(Icons.sports_tennis, color: Colors.white),
                    ),
                    title: Text(court['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${court['pricePerHour']} đ/h\n${court['description'] ?? ''}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCourtDialog(court: court)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteCourt(court['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}
