import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';
import 'package:intl/intl.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String? _selectedTier;
  String? _selectedStatus; // 'active', 'inactive', null

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers({String? search, String? tier}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      // API might support status filter, but if not we can filter client-side for now
      final response = await auth.apiService.getMembers(search: search, tier: tier);
      final data = response.data;
      setState(() {
        _members = data is Map ? (data['data'] ?? []) : (data is List ? data : []);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Calculate stats
  int get _totalMembers => _members.length;
  int get _activeMembers => _members.where((m) => m['isActive'] != false).length;
  double get _avgRank {
    if (_members.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (var m in _members) {
      final rank = m['duprRank'] as num?;
      if (rank != null) {
        total += rank;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }
  int get _totalMatches {
    int total = 0;
    for (var m in _members) {
      total += (m['totalMatches'] as int?) ?? 0;
    }
    return total;
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
        title: const Text('Quản lý Hội viên', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkSportBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.darkSportAccent),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMembers(
          search: _searchController.text,
          tier: _selectedTier,
        ),
        color: AppColors.darkSportAccent,
        backgroundColor: AppColors.darkSportSurface,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tên, email, số điện thoại...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.darkSportSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onSubmitted: (val) => _loadMembers(search: val, tier: _selectedTier),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 16) / 2;
                        return Column(
                          children: [
                            Row(
                              children: [
                                _buildStatCard('Tổng hội viên', '$_totalMembers', Icons.people_outline, Colors.blue, width),
                                const SizedBox(width: 16),
                                _buildStatCard('Đang hoạt động', '$_activeMembers', Icons.verified_user_outlined, AppColors.darkSportAccent, width),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildStatCard('Rank trung bình', _avgRank.toStringAsFixed(2), Icons.emoji_events_outlined, Colors.amber, width),
                                const SizedBox(width: 16),
                                _buildStatCard('Tổng trận đấu', '$_totalMatches', Icons.sports_tennis_outlined, Colors.orangeAccent, width),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Members List Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DANH SÁCH HỘI VIÊN', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        if (_selectedTier != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.darkSportAccent, borderRadius: BorderRadius.circular(4)),
                            child: Text('Lọc: $_selectedTier', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Members List
                    _isLoading
                        ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent)))
                        : _members.isEmpty
                            ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Không tìm thấy hội viên', style: TextStyle(color: Colors.white54))))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _members.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  // Client-side status filter if needed
                                  final m = _members[index];
                                  if (_selectedStatus == 'active' && m['isActive'] == false) return const SizedBox.shrink();
                                  if (_selectedStatus == 'inactive' && m['isActive'] != false) return const SizedBox.shrink();
                                  return _buildMemberCard(m);
                                },
                              ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    final fullName = member['fullName'] ?? 'Unknown';
    final email = member['email'] ?? '';
    final isActive = member['isActive'] != false;
    final tier = member['tier'] ?? 'Standard';
    final rank = member['duprRank'] != null ? (member['duprRank'] as num).toDouble() : 0.0;
    // Mock wallet balance if not provided, assuming backend might include it or separate call needed.
    // For now we assume safety, display '---' if not present
    final walletBalance = member['walletBalance'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getTierColor(tier),
                backgroundImage: member['avatarUrl'] != null ? NetworkImage(member['avatarUrl']) : null,
                child: member['avatarUrl'] == null 
                  ? Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        if (!isActive) const Icon(Icons.block, color: Colors.redAccent, size: 16),
                      ],
                    ),
                    Text(email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _getTierColor(tier).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(tier.toUpperCase(), style: TextStyle(color: _getTierColor(tier), fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniInfo('Rank', rank.toStringAsFixed(2), Colors.amber),
              _buildMiniInfo('Ví', _fmtMoney(walletBalance), AppColors.success),
              _buildMiniInfo('Trạng thái', isActive ? 'Active' : 'Disabled', isActive ? AppColors.success : Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditMemberDialog(member),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkSportAccent,
                side: const BorderSide(color: AppColors.darkSportAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Quản lý chi tiết'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Color _getTierColor(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'diamond': return Colors.purpleAccent;
      case 'gold': return Colors.amber;
      case 'silver': return Colors.grey;
      case 'admin': return Colors.redAccent;
      default: return AppColors.darkSportAccent;
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSportBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bộ lọc Hội viên', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Hạng (Tier)', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Standard', 'Silver', 'Gold', 'Diamond'].map((t) => FilterChip(
                label: Text(t),
                selected: _selectedTier == t,
                backgroundColor: AppColors.darkSportSurface,
                selectedColor: AppColors.darkSportAccent,
                checkmarkColor: Colors.black,
                labelStyle: TextStyle(color: _selectedTier == t ? Colors.black : Colors.white),
                onSelected: (val) {
                  setState(() => _selectedTier = val ? t : null);
                  Navigator.pop(context);
                  _loadMembers(tier: _selectedTier, search: _searchController.text);
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
             const Text('Trạng thái', style: TextStyle(color: Colors.white54)),
             const SizedBox(height: 12),
             Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tất cả'), 
                  selected: _selectedStatus == null,
                  onSelected: (val) { setState(() => _selectedStatus = null); Navigator.pop(context); },
                  backgroundColor: AppColors.darkSportSurface, selectedColor: AppColors.darkSportAccent, labelStyle: TextStyle(color: _selectedStatus == null ? Colors.black : Colors.white),
                ),
                FilterChip(
                  label: const Text('Active'), 
                  selected: _selectedStatus == 'active',
                  onSelected: (val) { setState(() => _selectedStatus = 'active'); Navigator.pop(context); },
                  backgroundColor: AppColors.darkSportSurface, selectedColor: AppColors.darkSportAccent, labelStyle: TextStyle(color: _selectedStatus == 'active' ? Colors.black : Colors.white),
                ),
                FilterChip(
                  label: const Text('Disabled'), 
                  selected: _selectedStatus == 'inactive',
                  onSelected: (val) { setState(() => _selectedStatus = 'inactive'); Navigator.pop(context); },
                  backgroundColor: AppColors.darkSportSurface, selectedColor: AppColors.darkSportAccent, labelStyle: TextStyle(color: _selectedStatus == 'inactive' ? Colors.black : Colors.white),
                ),
              ],
             )
          ],
        ),
      ),
    );
  }

  Future<void> _showEditMemberDialog(dynamic member) async {
    final nameController = TextEditingController(text: member['fullName']);
    final rankController = TextEditingController(text: (member['duprRank'] ?? 0).toString());
    String selectedTier = member['tier'] ?? 'Standard';
    bool isActive = member['isActive'] != false;
    // Display only, cannot edit here (backend constraint maybe or logic separation)
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.darkSportSurface,
            title: Text('Sửa: ${member['username']}', style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin cơ bản', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        filled: true,
                        fillColor: Colors.black12,
                        labelStyle: const TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Hạng & Trình độ', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: ['Standard', 'Silver', 'Gold', 'Diamond', 'Admin'].contains(selectedTier) ? selectedTier : 'Standard',
                    dropdownColor: AppColors.darkSportSurface,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Hạng thành viên',
                      filled: true, fillColor: Colors.black12,
                      labelStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    items: ['Standard', 'Silver', 'Gold', 'Diamond', 'Admin']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setStateDialog(() => selectedTier = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rankController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Điểm DUPR',
                      filled: true, fillColor: Colors.black12,
                      labelStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Trạng thái & Tài chính', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('Cho phép hoạt động', style: TextStyle(color: Colors.white)),
                    subtitle: Text(isActive ? 'Account Active' : 'Account Disabled', style: TextStyle(color: isActive ? AppColors.success : Colors.red, fontSize: 12)),
                    value: isActive,
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setStateDialog(() => isActive = val),
                  ),
                  ListTile(
                     contentPadding: EdgeInsets.zero,
                     title: const Text('Số dư ví (Read-only)', style: TextStyle(color: Colors.white54, fontSize: 14)),
                     trailing: Text(_fmtMoney(member['walletBalance']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
                    // Ensure backend supports these fields update
                    await api.updateMember(member['id'], {
                      'fullName': nameController.text,
                      'tier': selectedTier,
                      'duprRank': double.tryParse(rankController.text),
                      'isActive': isActive
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: AppColors.success));
                      _loadMembers(search: _searchController.text);
                    }
                  } catch (e) {
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkSportAccent, foregroundColor: Colors.black),
                child: const Text('Lưu thay đổi'),
              ),
            ],
          );
        },
      ),
    );
  }
}
