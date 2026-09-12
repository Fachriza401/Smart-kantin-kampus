import 'dart:async';

import 'package:flutter/material.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../qr/qr_scanner_screen.dart';

class CustomerPaymentsScreen extends StatefulWidget {
  final String role;

  const CustomerPaymentsScreen({super.key, required this.role});

  @override
  State<CustomerPaymentsScreen> createState() => _CustomerPaymentsScreenState();
}

class _CustomerPaymentsScreenState extends State<CustomerPaymentsScreen> {
  Timer? _timer;
  bool _loading = true;
  List<CampusOrder> _orders = [];
  final Map<int, AppUser?> _buyers = {};

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    final orders = await DBHelper.instance.getAllOrders();
    for (final order in orders) {
      if (!_buyers.containsKey(order.userId)) {
        _buyers[order.userId] = await DBHelper.instance.getUserById(order.userId);
      }
    }
    if (!mounted) return;
    setState(() {
      _orders = orders.where((order) => order.status != 'Dibatalkan').take(40).toList();
      _loading = false;
    });
  }

  Future<void> _confirmCash(CampusOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text('Terima pembayaran langsung untuk ${order.orderCode} sebesar ${formatRupiah(order.total)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lunas')),
        ],
      ),
    );
    if (confirmed != true) return;
    await DBHelper.instance.confirmCashPayment(order.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role == 'admin' ? 'Data Pembeli & Pembayaran Admin' : 'Data Pembeli & Pembayaran Kasir'),
        actions: [
          IconButton(
            tooltip: 'Scan QR Pengambilan',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      body: _loading && _orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summary(),
                  const SizedBox(height: 14),
                  if (_orders.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Belum ada transaksi.')))
                  else
                    ..._orders.map(_orderCard),
                ],
              ),
            ),
    );
  }

  Widget _summary() {
    final direct = _orders.where((o) => o.paymentMethod == 'Bayar Langsung').length;
    final virtual = _orders.where((o) => o.paymentMethod != 'Bayar Langsung').length;
    final pending = _orders.where((o) => o.paymentMethod == 'Bayar Langsung' && o.paymentStatus != 'Lunas').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(.95), AppColors.secondary.withOpacity(.92)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(child: _mini('Transaksi', '${_orders.length}', Icons.receipt_long_rounded)),
          Expanded(child: _mini('Virtual', '$virtual', Icons.qr_code_2_rounded)),
          Expanded(child: _mini('Langsung', '$direct', Icons.payments_rounded)),
          Expanded(child: _mini('Belum Lunas', '$pending', Icons.pending_actions_rounded)),
        ],
      ),
    );
  }

  Widget _mini(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ],
    );
  }

  Widget _orderCard(CampusOrder order) {
    final buyer = _buyers[order.userId];
    final direct = order.paymentMethod == 'Bayar Langsung';
    final paid = order.paymentStatus == 'Lunas';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(buyer?.name ?? 'Pembeli #${order.userId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: paid ? AppColors.primary.withOpacity(.10) : AppColors.secondaryContainer.withOpacity(.18), borderRadius: BorderRadius.circular(20)),
                child: Text(paid ? 'LUNAS' : (direct ? 'BELUM LUNAS' : 'VIRTUAL LUNAS'), style: TextStyle(color: paid ? AppColors.primary : AppColors.onSecondaryContainer, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(order.orderCode, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          Text(order.items.map((i) => '${i.quantity}x ${i.menuName}').join(', '), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(order.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w700)), Text(formatRupiah(order.total), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary))]),
          const SizedBox(height: 10),
          if (direct && !paid)
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _confirmCash(order), icon: const Icon(Icons.done_all_rounded), label: const Text('Lunas / Terima Pembayaran')))
          else
            Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())), icon: const Icon(Icons.qr_code_scanner_rounded), label: const Text('Validasi QR'))), const SizedBox(width: 8), Expanded(child: Text('Status: ${order.status}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)))]),
        ],
      ),
    );
  }
}
