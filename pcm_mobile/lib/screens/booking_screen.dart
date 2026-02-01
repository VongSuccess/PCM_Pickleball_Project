import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../models/booking_model.dart';
import '../themes/app_colors.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDay = DateTime.now();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  // Selection State
  CourtModel? _selectedCourt;
  TimeOfDay? _selectedStartTime;
  
  // Mock Data for UI (Real implementation would fetch availability)
  final List<TimeOfDay> _timeSlots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
     const TimeOfDay(hour: 17, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final booking = Provider.of<BookingProvider>(context, listen: false);
    // Load courts and availability (mocked for now)
    booking.loadCourts(); 
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.darkSportBackground,
      appBar: AppBar(
        title: const Text('Đặt sân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(), // Assume pushed from somewhere or just logic
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: booking.isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.darkSportAccent))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: booking.courts.length,
                    itemBuilder: (context, index) {
                      return _buildCourtCard(booking.courts[index]);
                    },
                  ),
          ),
          if (_selectedCourt != null && _selectedStartTime != null)
             _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final days = List.generate(14, (index) => DateTime.now().add(Duration(days: index)));

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = isSameDay(_selectedDay, date);
          final isToday = isSameDay(DateTime.now(), date);

          return GestureDetector(
            onTap: () => setState(() {
               _selectedDay = date;
               _selectedCourt = null; // Reset selection on date change
               _selectedStartTime = null;
            }),
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkSportAccent : AppColors.darkSportSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.darkSportAccent : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isToday)
                    Text(
                      'TODAY',
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.darkSportAccent,
                         fontSize: 8,
                         fontWeight: FontWeight.bold
                      ),
                    )
                  else
                     Text(
                      DateFormat('E').format(date).toUpperCase(),
                       style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white54,
                         fontSize: 9,
                         fontWeight: FontWeight.bold
                      ),
                     )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourtCard(CourtModel court) {
    // Real assets logic
    final String imagePath = (court.name.contains('Indoor') || court.description!.contains('Indoor')) 
        ? 'assets/images/court_indoor.png' 
        : 'assets/images/court_outdoor.jpg';
    
    return Container(
       margin: const EdgeInsets.only(bottom: 24),
       decoration: BoxDecoration(
         color: Colors.transparent, 
         borderRadius: BorderRadius.circular(16),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           // Header
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(
                 court.name, 
                 style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
               ),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: AppColors.darkSportSurface,
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: Colors.white.withOpacity(0.1)),
                 ),
                 child: Text(
                   (court.pricePerHour > 120000) ? 'TOP RATED' : 'STANDARD',
                   style: TextStyle(color: (court.pricePerHour > 120000) ? AppColors.darkSportAccent : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)
                 ),
               )
             ],
           ),
           const SizedBox(height: 12),
           
             Container(
             height: 160,
             width: double.infinity,
             decoration: BoxDecoration(
               color: Colors.grey[800], 
               borderRadius: BorderRadius.circular(16),
             ),
             child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                 children: [
                   Image.asset(
                      imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                  Icon(Icons.broken_image, color: Colors.white54),
                                  Text("Image not found: $imagePath", style: TextStyle(color: Colors.white, fontSize: 10)),
                               ]
                            )
                          ),
                        );
                      },
                   ),
                   // Overlay Gradient
                   Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                       ),
                     ),
                   ),
                 Positioned(
                   bottom: 12,
                   left: 12,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                     decoration: BoxDecoration(
                       color: Colors.black54,
                       borderRadius: BorderRadius.circular(20),
                       
                     ),
                     child: Row(
                       children: [
                         const Icon(Icons.location_on, color: Colors.white, size: 14),
                         const SizedBox(width: 4),
                         Text(
                           court.description ?? 'Khu vực chính',
                            style: const TextStyle(color: Colors.white, fontSize: 12)
                         )
                       ],
                     ),
                   ),
                 )
               ],
             ),
           ),
           ), // Added missing closing parenthesis for Container
           const SizedBox(height: 16),
           
           const Text('Khung giờ trống', style: TextStyle(color: Colors.white38, fontSize: 12)),
           const SizedBox(height: 8),
           
           // Time Slots Grid
           Wrap(
             spacing: 8,
             runSpacing: 8,
             children: _timeSlots.map((time) {
               final isSelected = (_selectedCourt?.id == court.id) && (_selectedStartTime == time);
               // Mock unavailable slots
               final isAvailable = !(time.hour == 18 || time.hour == 19); 
               
               return GestureDetector(
                 onTap: isAvailable ? () {
                   setState(() {
                     _selectedCourt = court;
                     _selectedStartTime = time;
                   });
                 } : null,
                 child: Container(
                   width: 80,
                   padding: const EdgeInsets.symmetric(vertical: 10),
                   decoration: BoxDecoration(
                     color: isSelected 
                        ? AppColors.darkSportAccent 
                        : (isAvailable ? AppColors.darkSportSurface : Colors.white.withOpacity(0.02)),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(
                       color: isSelected ? AppColors.darkSportAccent : Colors.white.withOpacity(0.05)
                     )
                   ),
                   child: Center(
                     child: Text(
                       '${time.format(context)}',
                       style: TextStyle(
                         color: isSelected 
                            ? Colors.black 
                            : (isAvailable ? AppColors.darkSportAccent : Colors.white24),
                         fontWeight: FontWeight.bold,
                         fontSize: 12,
                       ),
                     ),
                   ),
                 ),
               );
             }).toList(),
           )
         ],
       ),
    );
  }

  Widget _buildBottomBar() {
     if (_selectedCourt == null || _selectedStartTime == null) return const SizedBox.shrink();
     
     final endTime = TimeOfDay(hour: _selectedStartTime!.hour + 1, minute: _selectedStartTime!.minute);
     
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: AppColors.darkSportSurface,
         borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.4),
             blurRadius: 20,
             offset: const Offset(0, -5)
           )
         ]
       ),
       child: SafeArea(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đã chọn', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                       Text(
                        '${_selectedCourt!.name}, ${_selectedStartTime!.format(context)} - ${endTime.format(context)}',
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                       ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TỔNG CỘNG', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                       Text(
                        currencyFormat.format(_selectedCourt!.pricePerHour),
                         style: const TextStyle(color: AppColors.darkSportAccent, fontWeight: FontWeight.bold, fontSize: 20)
                       ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 12),
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Row(
                       children: [
                         Icon(Icons.account_balance_wallet, color: AppColors.darkSportAccent, size: 16),
                         SizedBox(width: 8),
                         Text('Số dư của bạn: 15.000.000đ', style: TextStyle(color: Colors.white, fontSize: 12)),
                       ],
                     ),
                     Text('NẠP TIỀN', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 10, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkSportAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Xác nhận đặt sân',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.black, size: 20)
                    ],
                  ),
                ),
              )
           ],
         ),
       ),
     );
  }

  Future<void> _handleBooking() async {
    if (_selectedCourt == null || _selectedStartTime == null) return;
    
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final startDateTime = DateTime(
      _selectedDay.year, _selectedDay.month, _selectedDay.day,
      _selectedStartTime!.hour, _selectedStartTime!.minute
    );
     final endDateTime = DateTime(
      _selectedDay.year, _selectedDay.month, _selectedDay.day,
      _selectedStartTime!.hour + 1, _selectedStartTime!.minute
    );

    // Call API
    final result = await bookingProvider.createBooking(
      _selectedCourt!.id,
      startDateTime,
      endDateTime,
    );

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        setState(() {
           _selectedCourt = null;
           _selectedStartTime = null;
        });
        // In real app, reload slots status
      }
    }
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
