import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/booking_provider.dart';
import '../providers/auth_provider.dart';
import '../models/booking_model.dart';
import '../themes/app_colors.dart';

class CalendarBookingScreen extends StatefulWidget {
  const CalendarBookingScreen({super.key});

  @override
  State<CalendarBookingScreen> createState() => _CalendarBookingScreenState();
}

class _CalendarBookingScreenState extends State<CalendarBookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final List<int> _hours = List.generate(14, (i) => i + 8); // 8:00 - 21:00
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookingsForDay();
      _setupSignalR();
    });
  }

  void _setupSignalR() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.signalRService.calendarUpdateStream.listen((data) {
      if (mounted) {
        _loadBookingsForDay();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📅 Lịch sân đã được cập nhật!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _loadBookingsForDay() {
    final booking = Provider.of<BookingProvider>(context, listen: false);
    final startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final endOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59);
    booking.loadCalendar(startOfDay, endOfDay);
  }

  List<BookingModel> _getBookingsForDay(DateTime day) {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    return bookingProvider.calendarBookings.where((booking) {
      return isSameDay(booking.startTime, day);
    }).toList();
  }

  String _getSlotStatus(CourtModel court, int hour) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    
    final slotStart = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      hour,
      0,
    );
    final slotEnd = slotStart.add(const Duration(hours: 1));

    // Check if any booking overlaps with this slot
    for (var booking in bookingProvider.calendarBookings) {
      bool overlaps = booking.courtId == court.id &&
          booking.startTime.isBefore(slotEnd) &&
          booking.endTime.isAfter(slotStart);

      if (overlaps) {
        if (booking.memberId == auth.user?.id) {
          return 'mine'; // My booking - Green
        } else {
          return 'booked'; // Booked by others - Red
        }
      }
    }

    return 'available'; // Available - White/Cream
  }

  Color _getSlotColor(String status) {
    switch (status) {
      case 'mine':
        return AppColors.primary.withOpacity(0.3); // Green
      case 'booked':
        return AppColors.error.withOpacity(0.3); // Red
      case 'available':
        return AppColors.cream; // Cream
      default:
        return Colors.grey.shade200;
    }
  }

  void _onSlotTap(CourtModel court, int hour) {
    final status = _getSlotStatus(court, hour);
    
    if (status == 'booked') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Khung giờ này đã được đặt!')),
      );
      return;
    }

    if (status == 'mine') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đây là lịch của bạn!')),
      );
      return;
    }

    // Available - Show booking bottom sheet
    _showBookingBottomSheet(court, hour);
  }

  void _showBookingBottomSheet(CourtModel court, int startHour) {
    int duration = 1; // hours
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final hours = duration.toDouble();
          final totalPrice = hours * court.pricePerHour;
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sports_tennis,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đặt ${court.name}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDay),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Time Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Text(
                            'Giờ bắt đầu:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            '${startHour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.timelapse, color: AppColors.accent),
                          const SizedBox(width: 12),
                          const Text(
                            'Thời lượng:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          DropdownButton<int>(
                            value: duration,
                            items: [1, 2, 3, 4].map((h) {
                              return DropdownMenuItem(
                                value: h,
                                child: Text('$h giờ'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => duration = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Price
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: AppColors.textOnPrimary),
                      const SizedBox(width: 12),
                      Text(
                        'Tổng tiền:',
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currencyFormat.format(totalPrice),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.primary),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final startDateTime = DateTime(
                            _selectedDay.year,
                            _selectedDay.month,
                            _selectedDay.day,
                            startHour,
                            0,
                          );
                          final endDateTime = startDateTime.add(Duration(hours: duration));

                          final booking = Provider.of<BookingProvider>(context, listen: false);
                          final result = await booking.createBooking(
                            court.id,
                            startDateTime,
                            endDateTime,
                          );

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: result['success'] ? AppColors.success : AppColors.error,
                              ),
                            );
                            if (result['success']) _loadBookingsForDay();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'XÁC NHẬN ĐẶT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sân chi tiết'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Column(
        children: [
          // Calendar Header
          Consumer<BookingProvider>(
            builder: (context, booking, _) {
              return TableCalendar<BookingModel>(
                firstDay: DateTime.now().subtract(const Duration(days: 30)),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _loadBookingsForDay();
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: _getBookingsForDay,
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              );
            },
          ),
          
          const Divider(height: 1),
          
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend('Có thể đặt', AppColors.cream),
                _buildLegend('Của tôi', AppColors.primary.withOpacity(0.3)),
                _buildLegend('Đã đặt', AppColors.error.withOpacity(0.3)),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Slots Grid
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (context, booking, _) {
                if (booking.courts.isEmpty) {
                  return const Center(child: Text('Không có sân nào'));
                }
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.primaryLight.withOpacity(0.2)),
                      columnSpacing: 8,
                      horizontalMargin: 16,
                      columns: [
                        DataColumn(
                          label: SizedBox(
                            width: 80,
                            child: Text(
                              'Giờ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        ...booking.courts.map((court) {
                          return DataColumn(
                            label: SizedBox(
                              width: 100,
                              child: Text(
                                court.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }),
                      ],
                      rows: _hours.map((hour) {
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '${hour.toString().padLeft(2, '0')}:00',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            ...booking.courts.map((court) {
                              final status = _getSlotStatus(court, hour);
                              final color = _getSlotColor(status);
                              
                              return DataCell(
                                InkWell(
                                  onTap: () => _onSlotTap(court, hour),
                                  child: Container(
                                    width: 100,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: status == 'available' 
                                            ? AppColors.textHint 
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        status == 'mine' 
                                            ? Icons.check_circle 
                                            : status == 'booked' 
                                                ? Icons.block 
                                                : Icons.add_circle_outline,
                                        color: status == 'available' 
                                            ? AppColors.textHint 
                                            : status == 'mine' 
                                                ? AppColors.primary 
                                                : AppColors.error,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadBookingsForDay,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.refresh),
        label: const Text('Làm mới'),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.textHint),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
