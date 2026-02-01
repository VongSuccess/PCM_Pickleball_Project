import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/booking_provider.dart';
import '../themes/app_colors.dart';
import 'wallet_screen.dart';
import 'booking_screen.dart';
import 'tournaments_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'members_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _screens => [
    const DashboardTab(),
    const WalletScreen(),
    const BookingScreen(),
    const TournamentsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setupSignalR();
    });
  }

  void _setupSignalR() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    
    auth.signalRService.notificationStream.listen((data) {
      if (mounted) {
        final message = data['message'] ?? '';
        final type = data['type'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: type == 'Error' ? Colors.red : AppColors.darkSportAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (type == 'Success' || type == 'WalletUpdate') {
          wallet.loadWalletInfo();
        }
      }
    });
  }

  void _loadData() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    walletProvider.loadWalletInfo();
    bookingProvider.loadCourts();
    bookingProvider.loadMyBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.darkSportBackground, // Dark Theme Background
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.darkSportAccent,
        unselectedItemColor: AppColors.darkSportTextSecondary,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Ví'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_tennis_rounded), label: 'Thi đấu'), 
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Giải đấu'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Cá nhân'),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _unreadCount = 0;
  
  // Mock Stats
  final Map<String, dynamic> _stats = {
    'activeCourts': 12,
    'openEvents': 3,
    'members': 450,
  };
  
  // Mock Upcoming
  final List<Map<String, String>> _upcoming = [
    {
      'title': 'Đặt sân: Sân 4',
      'time': '10:00 Sáng • Đánh đơn',
      'date': '12',
      'month': 'T10',
    },
    {
      'title': 'Tứ kết giải mở rộng',
      'time': '02:00 Chiều • Giải đấu',
      'date': '15',
      'month': 'T10',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnreadCount();
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final response = await auth.apiService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = response.data['count'] ?? 0;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$'); // Using $ to match image, or ₫ for VN
    // But user context is recursive, let's stick to user locale ₫ but style like image.

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildWalletCard(),
            const SizedBox(height: 24),
            _buildQuickAccess(),
            const SizedBox(height: 24),
            _buildClubStats(),
            const SizedBox(height: 24),
            _buildRankSection(),
            const SizedBox(height: 24),
            _buildUpcomingActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.darkSportAccent, width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/avatar_placeholder.png'), // Fallback
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.darkSportAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('PRO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Hội Viên',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      user?.tier ?? 'Hội viên tiêu chuẩn',
                      style: const TextStyle(
                        color: AppColors.darkSportAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: ${user?.id.substring(0, 5) ?? "88291"}',
                      style: TextStyle(
                        color: AppColors.darkSportTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.white),
              if (_unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard() {
    final wallet = Provider.of<WalletProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SỐ DƯ VÍ HIỆN TẠI',
            style: TextStyle(
              color: AppColors.darkSportTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(wallet.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                   final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                   homeState?.setState(() => homeState._currentIndex = 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkSportAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Nạp tiền', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Last transaction (optional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giao dịch gần nhất: -50.000đ (Sân 4)',
                  style: TextStyle(color: AppColors.darkSportTextSecondary, fontSize: 11),
                ),
                Icon(Icons.chevron_right, color: AppColors.darkSportTextSecondary, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Truy cập nhanh',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAccessPill(
              'Đặt sân', Icons.calendar_today_rounded, 
              () {
                  final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                  homeState?.setState(() => homeState._currentIndex = 2);
              }
            ),
            _buildQuickAccessPill(
              'Giải đấu', Icons.emoji_events_rounded,
              () {
                  final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                  homeState?.setState(() => homeState._currentIndex = 3);
              }
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAccessPill(
              'Hội viên', Icons.people_outline_rounded,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersScreen()))
            ),
            _buildQuickAccessPill(
              'Lịch trình', Icons.schedule_rounded,
              () {} // Todo: Schedule
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessPill(String label, IconData icon, VoidCallback onTap) {
    return  Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.darkSportSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 6),
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.darkSportBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.darkSportAccent, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thống kê CLB',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Cập nhật',
              style: TextStyle(color: AppColors.darkSportAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCircle('12', 'SÂN HOẠT ĐỘNG'),
            _buildStatCircle('3', 'SỰ KIỆN MỞ'),
            _buildStatCircle('450', 'THÀNH VIÊN'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCircle(String value, String label) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(color: AppColors.darkSportAccent, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppColors.darkSportTextSecondary, fontSize: 9, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRankSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XẾP HẠNG DUPR',
                style: TextStyle(
                  color: AppColors.darkSportTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                 padding: const EdgeInsets.all(4),
                 decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                 child: const Icon(Icons.trending_up, color: AppColors.darkSportAccent, size: 16),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '3.5',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/ 8.0',
                  style: TextStyle(color: AppColors.darkSportTextSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 3.5 / 8.0,
              backgroundColor: Colors.black,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.darkSportAccent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NGƯỜI MỚI', style: TextStyle(color: AppColors.darkSportTextSecondary, fontSize: 10)),
              Text('MỤC TIÊU: 4.0', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động sắp tới',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._upcoming.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSportSurface,
            borderRadius: BorderRadius.circular(30), // Pill shape for item
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.darkSportAccent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['month']!,
                      style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item['date']!,
                      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['time']!,
                      style: TextStyle(color: AppColors.darkSportTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.darkSportTextSecondary),
            ],
          ),
        )).toList(),
      ],
    );
  }
}
