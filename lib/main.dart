import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/notification_model.dart';
import 'services/gonotify_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotifyApp());
}

class NotifyApp extends StatelessWidget {
  const NotifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      home: const NotificationHomeScreen(),
    );
  }
}

class NotificationHomeScreen extends StatefulWidget {
  const NotificationHomeScreen({super.key});

  @override
  State<NotificationHomeScreen> createState() => _NotificationHomeScreenState();
}

class _NotificationHomeScreenState extends State<NotificationHomeScreen> {
  final List<NotificationModel> _notifications = [];
  GonotifyClient? _client;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _serverUrl = 'wss://your-gonotify-app.onrender.com/ws';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSavedSettingsAndConnect();
  }

  Future<void> _loadSavedSettingsAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverUrl = prefs.getString('server_url') ?? _serverUrl;
    });

    _client = GonotifyClient(
      serverUrl: _serverUrl,
      topics: ['orders', 'alerts'],
      onStatusChanged: (status) {
        if (mounted) setState(() => _status = status);
      },
      onMessageReceived: (notification) {
        if (!mounted) return;
        setState(() {
          _notifications.insert(0, notification);
        });
        _showInAppSnackbar(notification);
      },
    );

    _client?.connect();
  }

  void _showInAppSnackbar(NotificationModel n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFF10B981)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(n.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openSettingsDialog() {
    final controller = TextEditingController(text: _serverUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure WebSocket Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your Gonotify WebSocket URL (e.g. Render URL or local Wi-Fi IP):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ws://192.168.0.x:8080/ws',
                prefixIcon: Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('server_url', newUrl);
                setState(() => _serverUrl = newUrl);
                _client?.updateServerUrl(newUrl);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showDetailsBottomSheet(NotificationModel n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final formattedDate = DateFormat('yMMMd – hh:mm:ss a').format(
          DateTime.fromMillisecondsSinceEpoch(n.timestamp * 1000),
        );
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(n.event, style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
                  ),
                  Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Text(n.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(n.body, style: const TextStyle(fontSize: 16)),
              if (n.data != null) ...[
                const SizedBox(height: 16),
                const Text('Data Payload:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(n.data),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _client?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _notifications.where((n) {
      if (_selectedFilter == 'orders') return n.topic == 'orders' || n.event.contains('ORDER');
      if (_selectedFilter == 'alerts') return n.topic == 'alerts';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('Notify', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          _buildConnectionChip(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredNotifications.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (ctx, i) {
                      final item = filteredNotifications[i];
                      return _buildNotificationCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionChip() {
    Color color;
    String label;
    switch (_status) {
      case ConnectionStatus.connected:
        color = const Color(0xFF10B981);
        label = 'Connected';
        break;
      case ConnectionStatus.connecting:
        color = const Color(0xFFF59E0B);
        label = 'Connecting';
        break;
      case ConnectionStatus.disconnected:
        color = const Color(0xFFEF4444);
        label = 'Offline';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('all', 'All'),
          const SizedBox(width: 8),
          _buildFilterChip('orders', 'Orders'),
          const SizedBox(width: 8),
          _buildFilterChip('alerts', 'Alerts'),
          const Spacer(),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              tooltip: 'Clear All',
              onPressed: () => setState(() => _notifications.clear()),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildNotificationCard(NotificationModel item) {
    final formattedTime = DateFormat('hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(item.timestamp * 1000),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: item.event.contains('ORDER')
              ? const Color(0xFF10B981).withOpacity(0.15)
              : const Color(0xFF6366F1).withOpacity(0.15),
          child: Icon(
            item.event.contains('ORDER') ? Icons.shopping_bag_outlined : Icons.notifications_none,
            color: item.event.contains('ORDER') ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Text(formattedTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(item.body, style: TextStyle(color: Colors.grey.shade700)),
        ),
        onTap: () => _showDetailsBottomSheet(item),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Live events from Bornomala will appear here instantly.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
