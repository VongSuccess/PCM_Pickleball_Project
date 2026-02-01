import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure fl_chart is added to pubspec.yaml
import '../providers/wallet_provider.dart';
import 'payment_webview_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../themes/app_colors.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _selectedFilter = 'all'; // all, success, pending
  String _selectedTime = 'week';   // today, week, month, quarter

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).loadWalletInfo();
    });
  }

  void _showDepositDialog() {
       final amountController = TextEditingController();
    final descController = TextEditingController();
    String? selectedImagePath;
    
    // Save reference to wallet provider BEFORE opening dialog
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Dialog state
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.darkSportSurface,
          title: const Text('Nạp tiền', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Số tiền (VNĐ)',
                    labelStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.attach_money, color: AppColors.darkSportAccent),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.darkSportAccent)
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                   style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Ghi chú',
                    labelStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.note, color: AppColors.darkSportAccent),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.darkSportAccent)
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Image Picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() {
                        selectedImagePath = picked.path;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: selectedImagePath != null
                        ? Image.file(
                            File(selectedImagePath!),
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text('Tải lên bằng chứng CK', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                            ],
                          ),
                  ),
                ),
                 const SizedBox(height: 16),
                 // Transfer Info
                 Container(
                   padding: const EdgeInsets.all(12),
                   width: double.infinity,
                   decoration: BoxDecoration(
                     color: AppColors.darkSportAccent.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: AppColors.darkSportAccent.withOpacity(0.2)),
                   ),
                   child: Column(
                     children: [
                       const Text('Chuyển khoản đến:', style: TextStyle(color: AppColors.darkSportAccent, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 4),
                       const Text('VCB: 1234567890', style: TextStyle(color: Colors.white)),
                       const Text('Vợt Thủ Phố Núi', style: TextStyle(color: Colors.white70, fontSize: 12)),
                     ],
                   ),
                 )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                 if (amount != null && amount > 0) {
                  // Manual Deposit with Image
                  final success = await wallet.requestDeposit(amount, descController.text, selectedImagePath);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    scaffoldMessenger.showSnackBar(SnackBar(
                      content: Text(success ? 'Yêu cầu gửi thành công!' : 'Lỗi gửi yêu cầu'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ));
                    if (success) wallet.loadWalletInfo();
                  }
                }
              },
               style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
              child: const Text('Gửi thủ công', style: TextStyle(color: Colors.white)),
            ),
             ElevatedButton(
            onPressed: () async {
               final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                // VNPay Deposit
                Navigator.pop(dialogContext); // Close dialog first
                
                final url = await wallet.initiateVnPayDeposit(amount, descController.text);
                if (url != null && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentWebViewScreen(
                        paymentUrl: url,
                        onPaymentResult: (success) {
                          if (success) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Thanh toán thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            wallet.loadWalletInfo();
                          } else {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Thanh toán thất bại hoặc đã hủy'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Lỗi tạo URL thanh toán'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkSportAccent),
            child: const Text('VNPay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
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
        title: const Text('Ví tiền', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
        ],
        leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
               backgroundColor: Colors.white24,
               child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(wallet),
                const SizedBox(height: 24),
                _buildWeeklyActivityChart(),
                const SizedBox(height: 24),
                _buildSearchAndFilters(),
                const SizedBox(height: 16),
                _buildTransactionsList(wallet),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(WalletProvider wallet) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676), // Bright Green like design
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
           BoxShadow(
             color: const Color(0xFF00E676).withOpacity(0.3),
             blurRadius: 20,
             offset: const Offset(0, 10),
           )
        ]
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng số dư',
                style: TextStyle(
                  color: Color(0xFF004D40), // Dark Teal text
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(wallet.balance),
                style: const TextStyle(
                  color: Colors.black, // Black for high contrast
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.1),
                   shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user, color: Color(0xFF004D40), size: 20),
              )
            ],
          ),
          
          // VIP Badge
          Positioned(
             bottom: 0,
             left: 0,
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.black.withOpacity(0.1)),
               ),
               child: const Text('VIP', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 10)),
             ),
          ),

          // Top Up Button
          Positioned(
            bottom: 0,
            right: 0,
            child: ElevatedButton.icon(
              onPressed: _showDepositDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nạp tiền'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF052011), // Dark button background
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
            ),
          ),

          // Card Icon top right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.1),
                 shape: BoxShape.circle
               ),
               child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF004D40)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSportSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hoạt động tuần',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                   Text('+12% ', style: TextStyle(color: AppColors.darkSportAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                   Text('vs tuần trước', style: TextStyle(color: AppColors.darkSportTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold);
                        String text;
                        switch (value.toInt()) {
                          case 0: text = 'T2'; break;
                          case 1: text = 'T3'; break;
                          case 2: text = 'T4'; break;
                          case 3: text = 'T5'; break;
                          case 4: text = 'T6'; break;
                          case 5: text = 'T7'; break;
                          case 6: text = 'CN'; break;
                          default: text = '';
                        }
                        return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                   _makeBarGroup(0, 5),
                   _makeBarGroup(1, 8),
                   _makeBarGroup(2, 12), // Higher wednesday
                   _makeBarGroup(3, 7),
                   _makeBarGroup(4, 15), // High friday
                   _makeBarGroup(5, 10),
                   _makeBarGroup(6, 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.darkSportTextSecondary.withOpacity(0.3), // Inactive color
          width: 8,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
             show: true,
             toY: 20,
             color: Colors.transparent, 
          )
        ),
      ],
      showingTooltipIndicators: [],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.darkSportSurface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: const TextField(
             style: TextStyle(color: Colors.white),
             decoration: InputDecoration(
               hintText: 'Tìm kiếm giao dịch',
               hintStyle: TextStyle(color: Colors.white38),
               icon: Icon(Icons.search, color: Colors.white38),
               border: InputBorder.none,
             ),
          ),
        ),
        const SizedBox(height: 16),
        // Time Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTimeFilterChip('today', 'Hôm nay'),
              const SizedBox(width: 8),
              _buildTimeFilterChip('week', 'Tuần này'),
              const SizedBox(width: 8),
              _buildTimeFilterChip('month', 'Tháng này'),
               const SizedBox(width: 8),
              _buildTimeFilterChip('quarter', 'Theo quý'),
            ],
          ),
        ),
         const SizedBox(height: 12),
        // Status Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
             children: [
                _buildStatusFilterChip('all', 'Tất cả'),
                const SizedBox(width: 8),
                _buildStatusFilterChip('success', 'Thành công'),
                const SizedBox(width: 8),
                _buildStatusFilterChip('pending', 'Đang xử lý'),
             ],
          ),
        )
      ],
    );
  }
  
   Widget _buildTimeFilterChip(String value, String label) {
    final isSelected = _selectedTime == value;
    return GestureDetector(
       onTap: () => setState(() => _selectedTime = value),
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
         decoration: BoxDecoration(
           color: isSelected ? AppColors.darkSportAccent : AppColors.darkSportSurface,
           borderRadius: BorderRadius.circular(20),
         ),
         child: Text(
           label,
           style: TextStyle(
             color: isSelected ? Colors.black : Colors.white70,
             fontWeight: FontWeight.bold,
             fontSize: 12,
           ),
         ),
       ),
    );
  }

  Widget _buildStatusFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
       onTap: () => setState(() => _selectedFilter = value),
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
         decoration: BoxDecoration(
           color: isSelected ? Colors.green.withOpacity(0.2) : Colors.transparent,
           borderRadius: BorderRadius.circular(20),
           border: Border.all(color: isSelected ? Colors.green : Colors.white10),
         ),
         child: Text(
           label,
           style: TextStyle(
             color: isSelected ? Colors.green : Colors.white54,
             fontWeight: FontWeight.w600,
             fontSize: 12,
           ),
         ),
       ),
    );
  }

  Widget _buildTransactionsList(WalletProvider wallet) {
     return Column(
       children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text(
               'Giao dịch',
               style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
             ),
             Text(
               'Xem tất cả',
               style: TextStyle(color: AppColors.darkSportAccent, fontSize: 12, fontWeight: FontWeight.bold),
             ),
           ],
         ),
         const SizedBox(height: 16),
         
         if (wallet.walletInfo?.recentTransactions.isEmpty ?? true)
            Center(child: Text("Chưa có giao dịch", style: TextStyle(color: Colors.white38))),

         ...(wallet.walletInfo?.recentTransactions ?? []).map((tx) => _buildTransactionItem(tx)).toList(),
       ],
     );
  }

  Widget _buildTransactionItem(dynamic tx) {
     final bool isIncome = tx.amount > 0;
     final color = isIncome ? AppColors.darkSportAccent : Colors.redAccent;
     final icon = isIncome ? Icons.account_balance_wallet : Icons.sports_tennis;

     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: AppColors.darkSportSurface,
         borderRadius: BorderRadius.circular(24),
         border: Border.all(color: Colors.white.withOpacity(0.05)),
       ),
       child: Row(
         children: [
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: isIncome ? AppColors.darkSportAccent.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
               shape: BoxShape.circle,
             ),
             child: Icon(icon, color: isIncome ? AppColors.darkSportAccent : Colors.blue, size: 20),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   tx.description ?? 'Giao dịch',
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   // Fix Timezone: Updated to use tx.createdDate directly (handled in Model)
                   DateFormat('dd/MM HH:mm').format(tx.createdDate),
                   style: TextStyle(color: AppColors.darkSportTextSecondary, fontSize: 12),
                 ),
               ],
             ),
           ),
           Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text(
                 '${isIncome ? '+' : ''}${currencyFormat.format(tx.amount)}',
                 style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
               ),
               Text(
                 'SUCCESSFUL', // Mock status for now
                 style: TextStyle(color: AppColors.darkSportAccent, fontSize: 10, fontWeight: FontWeight.bold),
               ),
             ],
           )
         ],
       ),
     );
  }
}
