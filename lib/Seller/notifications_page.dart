import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add this package for animations

class NotificationsPage extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(int)? onDelete; // Callback to delete a notification by index
  final VoidCallback? onClearAll; // Callback to clear all notifications

  const NotificationsPage({
    super.key,
    required this.notifications,
    this.onDelete,
    this.onClearAll,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late List<Map<String, dynamic>> _notifications; // Local copy of notifications

  @override
  void initState() {
    super.initState();
    _notifications = List.from(widget.notifications);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Mark a notification as read
  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['isRead'] = true;
    });
  }

  // Delete a single notification and notify SellerHomePage
  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    widget.onDelete?.call(index); // Call the callback to update SellerHomePage
  }

  // Clear all notifications and notify SellerHomePage
  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
    widget.onClearAll?.call(); // Call the callback to update SellerHomePage
    Navigator.pop(context); // Optionally close the page after clearing
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto', // Optional modern font
            ),
          ),
          actions: [
            if (_notifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: TextButton(
                  onPressed: _clearAllNotifications,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isProduct = notification['type'] == 'product';
                      final isRead = notification['isRead'] ?? false;

                      return Card(
                        color: Colors.grey[900],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isRead
                                ? Colors.teal.withOpacity(0.3)
                                : Colors.blue,
                            width: 1.5,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        child: ListTile(
                          leading: notification['imagePath'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(notification['imagePath']),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.image_not_supported,
                                  color: Colors.white, size: 60),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                notification['title'],
                                style: TextStyle(
                                  color: isRead ? Colors.white70 : Colors.white,
                                  fontSize: 18,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              Icon(
                                isRead ? Icons.check_circle : Icons.circle,
                                color: isRead ? Colors.teal : Colors.blue,
                                size: 16,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Quantity: ${notification['quantity']} ${isProduct ? 'listed successfully' : 'auction created successfully'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isRead
                                      ? Icons.mark_chat_read
                                      : Icons.mark_chat_unread,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                onPressed: () => _markAsRead(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 24),
                                onPressed: () => _deleteNotification(index),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).scale(
                          begin: Offset(0.95, 0.95),
                          end: Offset(1.0, 1.0),
                          duration: 300.ms);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
