import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/booking_model.dart';
import '../themes/app_colors.dart';
import 'tournament_detail_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List<TournamentModel> _tournaments = [];
  List<TournamentModel> _filteredTournaments = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTournaments();
    });
  }

  Future<void> _loadTournaments() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await auth.apiService.getTournaments();
      final List<dynamic> data = response.data;
      setState(() {
        _tournaments = data.map((e) => TournamentModel.fromJson(e)).toList();
        _filterTournaments();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterTournaments() {
    setState(() {
      _filteredTournaments = _tournaments.where((t) {
        final matchesSearch = t.name.toLowerCase().contains(_searchController.text.toLowerCase());
        if (_selectedFilter == 'All') return matchesSearch;
        return matchesSearch && t.status == _selectedFilter;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    if (status == 'Open' || status == 'Registering') return const Color(0xFF00E676);
    if (status == 'Ongoing' || status == 'InProgress') return Colors.amber;
    if (status == 'Finished') return Colors.grey;
    return Colors.blue;
  }
  
  String _getStatusText(String status) {
    if (status == 'Open' || status == 'Registering') return 'REGISTRATION OPEN';
    if (status == 'Ongoing' || status == 'InProgress') return 'ONGOING';
    if (status == 'Finished') return 'FINISHED';
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSportBackground,
        elevation: 0,
        automaticallyImplyLeading: false, // Hide back button if in tab
        title: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF00E676), size: 28),
            const SizedBox(width: 8),
            const Text(
              'Tournaments',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _filterTournaments(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search tournaments...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00E676)),
                filled: true,
                fillColor: AppColors.darkSportSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Open', label: 'Open'),
                _buildFilterChip('InProgress', label: 'Ongoing'),
                _buildFilterChip('Finished'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
                : RefreshIndicator(
                    onRefresh: _loadTournaments,
                    color: const Color(0xFF00E676),
                    backgroundColor: AppColors.darkSportSurface,
                    child: _filteredTournaments.isEmpty 
                      ? const Center(child: Text("No tournaments found", style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredTournaments.length,
                        itemBuilder: (context, index) {
                          return _buildTournamentCard(_filteredTournaments[index]);
                        },
                      ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, {String? label}) {
    final isSelected = _selectedFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label ?? filterKey),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = filterKey;
              _filterTournaments();
            });
          }
        },
        backgroundColor: AppColors.darkSportSurface,
        selectedColor: const Color(0xFF00E676),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.white12),
        ),
      ),
    );
  }

  Widget _buildTournamentCard(TournamentModel tournament) {
    bool isJoined = tournament.isJoined;
    String statusText = _getStatusText(tournament.status);
    Color statusColor = _getStatusColor(tournament.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/court_indoor.png'), // Placeholder
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                   decoration: BoxDecoration(
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                     gradient: LinearGradient(
                       begin: Alignment.topCenter,
                       end: Alignment.bottomCenter,
                       colors: [Colors.transparent, AppColors.darkSportSurface],
                     ),
                   ),
                ),
              ),
              // Badges
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    if (isJoined)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: const [
                             Icon(Icons.check_circle, size: 12, color: Colors.black),
                             SizedBox(width: 4),
                             Text('JOINED', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF00E676)),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM d, yyyy').format(tournament.startDate)} • ${DateFormat('h:mm a').format(tournament.startDate)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Color(0xFF00E676)),
                    Text(
                      '${currencyFormat.format(tournament.entryFee)} Fee',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.emoji_events, size: 16, color: Color(0xFF00E676)),
                    Text(
                      '${currencyFormat.format(tournament.prizePool)} Prize Pool',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                       // Navigate to details and wait for result
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TournamentDetailScreen(
                              tournamentId: tournament.id,
                              tournamentName: tournament.name,
                            ),
                          ),
                        );
                        // Refresh list when returning to checking joined status
                        _loadTournaments();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined ? const Color(0xFF00E676) : Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isJoined ? 'View Dashboard' : 'View Details',
                      style: TextStyle(
                        color: isJoined ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
