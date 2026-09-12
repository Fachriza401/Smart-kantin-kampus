import 'dart:async';
import 'package:flutter/material.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../home/main_shell.dart';
import '../../widgets/order_barcode.dart';
import '../../widgets/pickup_location_card.dart';
import 'rating_screen.dart';

const _statusSteps = [
  'Menunggu Persetujuan Tenant',
  'Diproses',
  'Dimasak',
  'Siap Diambil',
  'Selesai',
];

class OrderStatusScreen extends StatefulWidget {
  final int orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  CampusOrder? _order;
  Timer? _pollTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refreshStatus());
  }

  Future<void> _load() async {
    // Status dibaca dari database agar mengikuti proses tenant/kasir.
    final order = await DBHelper.instance.getOrderById(widget.orderId);
    if (!mounted) return;
    setState(() => _order = order);
  }


  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    final order = await DBHelper.instance.getOrderById(widget.orderId);
    _isRefreshing = false;
    if (!mounted || order == null) return;
    if (_order?.status != order.status ||
        _order?.paymentStatus != order.paymentStatus) {
      setState(() => _order = order);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pesanan'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
          ),
        ),
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order ID',
                              style:
                                  TextStyle(color: AppColors.onSurfaceVariant)),
                          Text(order.orderCode,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kantin',
                              style:
                                  TextStyle(color: AppColors.onSurfaceVariant)),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              order.tenantName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Waktu Ambil',
                              style:
                                  TextStyle(color: AppColors.onSurfaceVariant)),
                          Text(order.pickupTime),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bukti Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Tunjukkan barcode ini kepada kasir saat mengambil pesanan.', style: TextStyle(color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 14),
                      Center(
                        child: OrderBarcode(
                          value: order.orderCode,
                          size: ((MediaQuery.of(context).size.width - 72)
                                  .clamp(280.0, 340.0))
                              .toDouble(),
                        ),
                      ),
                      const Divider(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Pembayaran'),
                        const SizedBox(width: 10),
                        Flexible(child: Text(order.paymentMethod, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PickupLocationCard(pickupTime: order.pickupTime),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Progress Pesanan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      ..._buildSteps(order.status),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ringkasan Pesanan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(height: 20),
                      ...order.items.map(
                        (it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child:
                                      Text('${it.quantity}x ${it.menuName}')),
                              Text(formatRupiah(it.subtotal)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(formatRupiah(order.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (order.status == 'Selesai') ...[
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RatingScreen(order: order),
                      ),
                    ),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Beri Rating & Ulasan'),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  ),
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildSteps(String currentStatus) {
    final currentIndex = _statusSteps.indexOf(currentStatus);
    return List.generate(_statusSteps.length, (i) {
      final done = i <= (currentIndex == -1 ? 0 : currentIndex);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusSteps[i],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                  color: done ? AppColors.onSurface : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
