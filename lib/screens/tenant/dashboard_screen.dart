import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../profile/notification_screen.dart';
import '../qr/qr_scanner_screen.dart';
import '../staff/customer_payments_screen.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  Timer? _timer;
  bool _loading = true;
  String? _error;
  List<CampusOrder> _orders = const [];
  bool _isKasir = false;
  String _tenantName = 'Kantin Kampus';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _isKasir = user?.role.toLowerCase() == 'kasir';
    _tenantName = user?.tenantName ?? 'Kantin Kampus';
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final orders = await DBHelper.instance.getOrdersByTenant(_tenantName);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<CampusOrder> get _activeOrders {
    final isKasir = _isKasir;
    final allowed = isKasir
        ? const {'Siap Diambil', 'Dipanggil Kasir', 'Diantar ke Meja'}
        : const {'Menunggu Persetujuan Tenant', 'Diproses', 'Dimasak'};
    return _orders.where((o) => allowed.contains(o.status)).toList();
  }

  Future<void> _advance(CampusOrder order) async {
    if (order.id == null) return;
    if (_isKasir && order.paymentMethod == 'Bayar Langsung' && order.paymentStatus != 'Lunas') {
      _message('Pesanan belum lunas. Verifikasi pembayaran terlebih dahulu.');
      return;
    }

    const flow = <String>[
      'Menunggu Persetujuan Tenant',
      'Diproses',
      'Dimasak',
      'Siap Diambil',
      'Dipanggil Kasir',
      'Diantar ke Meja',
      'Selesai',
    ];
    final i = flow.indexOf(order.status);
    if (i < 0 || i >= flow.length - 1) return;

    await DBHelper.instance.updateOrderStatus(order.id!, flow[i + 1]);
    await _refresh(silent: true);
  }

  Future<void> _reject(CampusOrder order) async {
    if (order.id == null) return;
    await DBHelper.instance.updateOrderStatus(order.id!, 'Dibatalkan');
    await _refresh(silent: true);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = (user?.role ?? 'tenant').toLowerCase();
    final isKasir = role == 'kasir';
    final active = _activeOrders;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 90;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).viewPadding.top + 12, 16, bottomPadding),
          children: [
            _header(context, user?.name ?? (isKasir ? 'Kasir' : 'Tenant'), role),
            const SizedBox(height: 10),
            _hero(isKasir),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _metric('Total Pesanan', '${_orders.length}', Icons.receipt_long, AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(child: _metric(isKasir ? 'Siap Dilayani' : 'Perlu Diproses', '${active.length}', Icons.pending_actions, AppColors.secondary)),
                const SizedBox(width: 8),
                Expanded(
                  child: _metric(
                    'Nilai Transaksi',
                    formatRupiah(_orders.fold<double>(0, (s, o) => s + o.total)),
                    Icons.payments,
                    AppColors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _quickActions(context, role, isKasir),
            const SizedBox(height: 12),
            _sectionTitle(isKasir ? 'Pesanan Siap Dilayani' : 'Pesanan Masuk Tenant'),
            const SizedBox(height: 8),
            if (_error != null)
              _errorCard()
            else if (_loading && _orders.isEmpty)
              _loadingCard()
            else if (active.isEmpty)
              _emptyOrders(isKasir)
            else
              ...active.take(10).map((o) => _orderCard(o, isKasir)),
            const SizedBox(height: 12),
            _summaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String name, String role) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryContainer.withOpacity(.22),
          child: Icon(role == 'kasir' ? Icons.point_of_sale : Icons.storefront, color: AppColors.primary, size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hai, ${name.split(' ').first} 👋', style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(role == 'kasir' ? 'Dashboard Kasir' : 'Dashboard Tenant', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              const Text('Kantin Kampus • Operasional Pesanan', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen(showBackButton: true))),
          icon: const Icon(Icons.notifications_none_rounded, size: 28),
        ),
      ],
    );
  }

  Widget _hero(bool isKasir) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isKasir ? AppColors.secondary : AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: Color(0x26FFFFFF), child: Icon(isKasir ? Icons.point_of_sale_rounded : Icons.storefront_rounded, color: Colors.white, size: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isKasir ? 'Kelola pembayaran, antrean, dan pengambilan pesanan.' : 'Terima pesanan, proses makanan, dan tandai siap untuk Kasir.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.15)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, String role, bool isKasir) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aksi Utama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _action(context, isKasir ? 'Scan QR Pengambilan' : 'Scan QR Pesanan', Icons.qr_code_scanner, AppColors.secondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())))),
                const SizedBox(width: 8),
                Expanded(child: _action(context, 'Data Pembeli', Icons.receipt_long, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerPaymentsScreen(role: role))))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _orderCard(CampusOrder order, bool isKasir) {
    final paid = order.paymentMethod != 'Bayar Langsung' || order.paymentStatus == 'Lunas';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isKasir ? Icons.receipt_long_rounded : Icons.confirmation_number_rounded,
                  size: 16, color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(order.orderCode,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                const SizedBox(width: 6),
                _status(order.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.person_outline, order.buyerName),
                const SizedBox(height: 3),
                _infoRow(Icons.confirmation_number_outlined, 'Antrean: ${order.queueNumber}'),
                const SizedBox(height: 3),
                _infoRow(
                  order.paymentMethod == 'Bayar Langsung'
                      ? Icons.money_rounded
                      : Icons.credit_card_rounded,
                  '${order.paymentMethod}  •  ${order.paymentStatus}',
                ),
                if (order.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  _infoRow(Icons.note_alt_outlined, order.note),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...order.items.map((item) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.menuName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 45),
                  child: Text(
                    formatRupiah(item.price * item.quantity),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          )),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 1, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                const Spacer(),
                Text(
                  formatRupiah(order.total),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (paid ? AppColors.primary : AppColors.error).withOpacity(.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(order.paymentStatus,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                          color: paid ? AppColors.primary : AppColors.error)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: paid ? () => _advance(order) : null,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      isKasir ? _kasirLabel(order.status) : _tenantLabel(order.status),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (!isKasir && order.status == 'Menunggu Persetujuan Tenant') ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _reject(order),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.onSurfaceMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _tenantLabel(String status) => switch (status) {
        'Menunggu Persetujuan Tenant' => 'Setujui Pesanan',
        'Diproses' => 'Mulai Masak',
        'Dimasak' => 'Tandai Siap',
        _ => 'Lanjutkan',
      };

  String _kasirLabel(String status) => switch (status) {
        'Siap Diambil' => 'Panggil Antrean',
        'Dipanggil Kasir' => 'Antar ke Meja',
        'Diantar ke Meja' => 'Selesaikan',
        _ => 'Lanjutkan',
      };

  Widget _status(String status) {
    final color = switch (status) {
      'Menunggu Persetujuan Tenant' => AppColors.secondary,
      'Diproses' || 'Dimasak' => AppColors.tertiary,
      'Siap Diambil' || 'Dipanggil Kasir' || 'Diantar ke Meja' => AppColors.blue,
      'Selesai' => AppColors.primary,
      'Dibatalkan' => AppColors.error,
      _ => AppColors.onSurfaceVariant,
    };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)));
  }

  Widget _loadingCard() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: AppColors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Memuat pesanan...', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    ),
  );

  Widget _emptyOrders(bool isKasir) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: AppColors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isKasir ? Icons.local_shipping_outlined : Icons.inbox_outlined,
              size: 52,
              color: AppColors.primary.withOpacity(.5),
            ),
            const SizedBox(height: 14),
            Text(
              isKasir ? 'Belum ada pesanan siap dilayani' : 'Belum ada pesanan masuk',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              isKasir
                  ? 'Pesanan dari Tenant akan muncul di sini setelah siap.'
                  : 'Pesanan mahasiswa akan muncul otomatis di sini.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _errorCard() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: AppColors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: AppColors.error),
            const SizedBox(height: 10),
            const Text('Dashboard gagal memuat pesanan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              _error!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _summaryCard() {
    final completed = _orders.where((o) => o.status == 'Selesai').length;
    final cancelled = _orders.where((o) => o.status == 'Dibatalkan').length;
    final paid = _orders.where((o) => o.paymentStatus == 'Lunas').length;
    final revenue = _orders.where((o) => o.status != 'Dibatalkan').fold<double>(0, (s, o) => s + o.total);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Hari Ini', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _summary('Selesai', '$completed', AppColors.primary)),
                Container(width: 1, height: 28, color: AppColors.outlineVariant),
                Expanded(child: _summary('Lunas', '$paid', AppColors.secondary)),
                Container(width: 1, height: 28, color: AppColors.outlineVariant),
                Expanded(child: _summary('Batal', '$cancelled', AppColors.error)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text('Total Pendapatan', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  const Spacer(),
                  Text(formatRupiah(revenue), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(String label, String value, Color color) => Column(
    children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
    ],
  );
}
