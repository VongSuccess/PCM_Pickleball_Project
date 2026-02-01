import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';

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
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await auth.apiService.getMembers(search: search, tier: tier);
      final data = response.data;
      setState(() {
        _members = data is Map ? (data['data'] ?? []) : (data is List ? data : []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getRankColor(double? rank) {
    if (rank == null) return Colors.grey;
    if (rank >= 5.0) return Colors.red;
    if (rank >= 4.0) return Colors.orange;
    if (rank >= 3.5) return Colors.amber;
    return AppColors.primary;
  }

  Color _getTierColor(String? tier) {
    switch (tier) {
      case 'Diamond':
        return Colors.purple;
      case 'Gold':
        return Colors.amber;
      case 'Silver':
        return Colors.grey;
      default:
        return Colors.brown;
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

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMembers(
          search: _searchController.text,
          tier: _selectedTier,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and search
              Row(
                children: [
                  Icon(Icons.sports_tennis, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thành viên CLB',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Quản lý danh sách hội viên PickleBall',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isWideScreen) SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm hội viên...',
                        prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (value) {
                        _loadMembers(search: value, tier: _selectedTier);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Stat Cards Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                        title: 'Tổng hội viên',
                        value: '$_totalMembers',
                        icon: Icons.people_rounded,
                        color: AppColors.info,
                        width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                      ),
                      _buildStatCard(
                        title: 'Đang hoạt động',
                        value: '$_activeMembers',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.primary,
                        width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                      ),
                      _buildStatCard(
                        title: 'Rank TB',
                        value: _avgRank.toStringAsFixed(2),
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.accent,
                        width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                      ),
                      _buildStatCard(
                        title: 'Tổng trận',
                        value: '$_totalMatches',
                        icon: Icons.sports_score_rounded,
                        color: Colors.red,
                        width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Members Table Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Danh sách Hội viên',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_totalMembers người',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Mobile Search (if not wide screen)
                    if (!isWideScreen) Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm hội viên...',
                          prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                          filled: true,
                          fillColor: AppColors.cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (value) {
                          _loadMembers(search: value, tier: _selectedTier);
                        },
                      ),
                    ),
                    
                    // Table Column Headers
                    if (isWideScreen) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.cream, width: 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text('Hội viên', style: _headerStyle)),
                          Expanded(flex: 1, child: Center(child: Text('Rank', style: _headerStyle))),
                          Expanded(flex: 1, child: Center(child: Text('Trận', style: _headerStyle))),
                          Expanded(flex: 1, child: Center(child: Text('Thắng', style: _headerStyle))),
                          Expanded(flex: 2, child: Text('Tỷ lệ thắng', style: _headerStyle)),
                          Expanded(flex: 1, child: Center(child: Text('Trạng thái', style: _headerStyle))),
                          Expanded(flex: 1, child: Center(child: Text('Thao tác', style: _headerStyle))),
                        ],
                      ),
                    ),
                    
                    // Members List
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_members.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('Không tìm thấy hội viên')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _members.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.cream),
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return _buildMemberRow(member, isWideScreen);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(dynamic member, bool isWideScreen) {
    final fullName = member['fullName'] as String? ?? '';
    final email = member['email'] as String? ?? '';
    final tier = member['tier'] as String?;
    final rank = (member['duprRank'] as num?)?.toDouble();
    final totalMatches = (member['totalMatches'] as int?) ?? 0;
    final wins = (member['wins'] as int?) ?? 0;
    final winRate = totalMatches > 0 ? (wins / totalMatches * 100) : 0.0;
    final isActive = member['isActive'] != false;

    if (isWideScreen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Hội viên
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getTierColor(tier),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Rank
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRankColor(rank),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rank?.toStringAsFixed(2) ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            
            // Trận
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '$totalMatches',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            
            // Thắng
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '$wins',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            
            // Tỷ lệ thắng (Progress bar)
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: winRate / 100,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          winRate > 50 ? AppColors.success : AppColors.warning,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${winRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Trạng thái
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Hoạt động' : 'Ngừng',
                    style: TextStyle(
                      color: isActive ? AppColors.success : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            
            // Thao tác
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.visibility_outlined, color: AppColors.info, size: 20),
                    onPressed: () {
                      // View member
                    },
                    tooltip: 'Xem',
                  ),
                  // ADMIN ACTION
                  if (Provider.of<AuthProvider>(context).user?.role == 'Admin')
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: () => _showEditMemberDialog(member),
                    tooltip: 'Sửa',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: _getTierColor(tier),
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              fullName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              rank?.toStringAsFixed(2) ?? 'N/A',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.sports_score, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text('$totalMatches trận', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.emoji_events, size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Text('$wins thắng', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Hoạt động' : 'Ngừng',
                  style: TextStyle(
                    color: isActive ? AppColors.success : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to member profile
      },
    );
  }

  Future<void> _showEditMemberDialog(dynamic member) async {
    final nameController = TextEditingController(text: member['fullName']);
    final rankController = TextEditingController(text: (member['duprRank'] ?? 0).toString());
    String selectedTier = member['tier'] ?? 'Standard';
    bool isActive = member['isActive'] != false;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Sửa thành viên: ${member['username']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['Standard', 'Silver', 'Gold', 'Diamond', 'Admin'].contains(selectedTier) ? selectedTier : 'Standard',
                    decoration: const InputDecoration(labelText: 'Hạng thành viên'),
                    items: ['Standard', 'Silver', 'Gold', 'Diamond', 'Admin']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setStateDialog(() => selectedTier = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rankController,
                    decoration: const InputDecoration(labelText: 'Điểm trình độ (DUPR)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Trạng thái hoạt động'),
                    subtitle: Text(isActive ? 'Đang hoạt động' : 'Đã bị khóa', style: TextStyle(color: isActive ? Colors.green : Colors.red)),
                    value: isActive,
                    activeColor: AppColors.success,
                    onChanged: (val) => setStateDialog(() => isActive = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final api = Provider.of<AuthProvider>(context, listen: false).apiService;
                    await api.updateMember(member['id'], {
                      'fullName': nameController.text,
                      'tier': selectedTier,
                      'duprRank': double.tryParse(rankController.text),
                      'isActive': isActive
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
                      _loadMembers();
                    }
                  } catch (e) {
                    if (mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
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
}
