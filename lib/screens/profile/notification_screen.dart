import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/db_helper.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/api_feedback.dart';
import '../../utils/formatters.dart';

class NotificationScreen extends StatefulWidget {
  final bool showBackButton;

  const NotificationScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = context.read<AuthProvider>().currentUser?.id;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final data = await DBHelper.instance.getNotifications(id);
      await DBHelper.instance.markNotificationsRead(id);
      if (!mounted) return;
      setState(() => _items = data);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Item dihapus dari layar lebih dulu (wajib untuk Dismissible), lalu
  /// dikembalikan bila server gagal menghapusnya.
  Future<void> _delete(int id) async {
    final previous = List<Map<String, dynamic>>.of(_items);
    setState(() => _items = _items.where((e) => e['id'] != id).toList());
    try {
      await DBHelper.instance.deleteNotification(id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _items = previous);
      showApiError(context, e);
    }
  }

  Future<void> _deleteAll() async {
    final id = context.read<AuthProvider>().currentUser?.id;
    if (id == null) return;

    try {
      await DBHelper.instance.deleteAllNotifications(id);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
      return;
    }
    if (!mounted) return;
    setState(() => _items = []);
  }

  IconData _icon(String? type) {
    switch (type) {
      case 'topup':
        return Icons.account_balance_wallet;
      case 'order':
        return Icons.receipt_long;
      case 'promo':
      case 'discount':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                tooltip: 'Kembali ke Dashboard',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              onPressed: _deleteAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Hapus semua',
            ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: AppColors.outline,
                        ),
                        SizedBox(height: 12),
                        Center(child: Text('Belum ada notifikasi')),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final n = _items[index];
                        final id = n['id'] as int;

                        return Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _delete(id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.outlineVariant,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primaryContainer
                                      .withOpacity(.15),
                                  child: Icon(
                                    _icon(n['type']?.toString()),
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n['title']?.toString() ??
                                                  'Notifikasi',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.error,
                                            ),
                                            onPressed: () => _delete(id),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        n['message']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        formatDateTime(n['createdAt']?.toString()),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
