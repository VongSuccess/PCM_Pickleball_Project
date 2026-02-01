import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSignalR();
    });
  }

  void _setupSignalR() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _subscription = auth.signalRService.notificationStream.listen((data) {
      if (mounted) {
        // Option 1: Reload all
         _loadNotifications();
         
        // Option 2: Add manually (faster UI)
        /*
        setState(() {
          _notifications.insert(0, {
            'id': 0, // Placeholder
            'message': data['message'],
            'type': data['type'],
            'createdDate': DateTime.now().toIso8601String(),
            'isRead': false
          });
        });
        */
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await auth.apiService.getNotifications();
      setState(() {
        _notifications = response.data is List ? response.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.apiService.markNotificationRead(id);
      setState(() {
        _notifications[index]['isRead'] = true;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _markAllAsRead() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.apiService.markAllNotificationsRead();
      setState(() {
        for (var n in _notifications) {
          n['isRead'] = true;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'Success':
        return Icons.check_circle;
      case 'Warning':
        return Icons.warning;
      case 'Info':
      default:
        return Icons.info;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'Success':
        return Colors.green;
      case 'Warning':
        return Colors.orange;
      case 'Info':
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đánh dấu tất cả',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Không có thông báo', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          color: n['isRead'] == true ? null : Colors.blue.withAlpha(25),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColor(n['type'] ?? 'Info').withAlpha(50),
                              child: Icon(_getIcon(n['type'] ?? 'Info'), color: _getColor(n['type'] ?? 'Info')),
                            ),
                            title: Text(
                              n['message'] ?? '',
                              style: TextStyle(
                                fontWeight: n['isRead'] == true ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(_formatDate(n['createdDate'] ?? '')),
                            trailing: n['isRead'] == true
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _markAsRead(n['id'], index),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
