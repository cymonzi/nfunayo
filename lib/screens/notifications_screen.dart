import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, String>> _notifications = [];
  Map<String, String>?
  _lastDeletedNotification; // Store the last deleted notification
  int? _lastDeletedIndex; // Store the index of the last deleted notification
  // ignore: unused_field
  int _unreadCount = 0; // Track the number of unread notifications

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _resetUnreadCount(); // Reset unread count when the screen is opened
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotifications = prefs.getStringList('notifications') ?? [];
    setState(() {
      _notifications =
          savedNotifications.map((notification) {
            final parts = notification.split('|');
            return {'title': parts[0], 'body': parts[1], 'time': parts[2]};
          }).toList();
      _unreadCount =
          _notifications.length; // Set unread count to total notifications
    });
  }

  Future<void> _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    setState(() {
      _notifications = [];
    });
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'notifications',
      _notifications
          .map((n) => '${n['title']}|${n['body']}|${n['time']}')
          .toList(),
    );
  }

  String _formatTime(String time) {
    final now = DateTime.now();
    final notificationTime = DateTime.parse(time);
    final difference = now.difference(notificationTime);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    return '${notificationTime.day}/${notificationTime.month}/${notificationTime.year}';
  }

  IconData _getNotificationIcon(String title) {
    if (title.contains('Success')) return Icons.check_circle;
    if (title.contains('Warning')) return Icons.warning;
    return Icons.notifications;
  }

  void _resetUnreadCount() {
    setState(() {
      _unreadCount = 0;
    });
  }

  void _showClearAllConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.green),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearNotifications();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteNotification(int index) {
    setState(() {
      _lastDeletedNotification = _notifications[index];
      _lastDeletedIndex = index;
      _notifications.removeAt(index);
    });

    // Save the updated notifications list
    _saveNotifications();

    // Show SnackBar with Undo option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Restore the deleted notification
            if (_lastDeletedNotification != null && _lastDeletedIndex != null) {
              setState(() {
                _notifications.insert(
                  _lastDeletedIndex!,
                  _lastDeletedNotification!,
                );
              });
              _saveNotifications(); // Save the restored notifications
            }
          },
        ),
        duration: const Duration(seconds: 3), // SnackBar duration
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear All Notifications',
            onPressed: _showClearAllConfirmationDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child:
            _notifications.isNotEmpty
                ? ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Dismissible(
                      key: Key(notification['time']!),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        _deleteNotification(index); // Delete the notification
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: Icon(
                            _getNotificationIcon(notification['title']!),
                            color: Colors.blue,
                          ),
                          title: Text(notification['title']!),
                          subtitle: Text(notification['body']!),
                          trailing: Text(
                            _formatTime(notification['time']!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
                : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No notifications yet!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
