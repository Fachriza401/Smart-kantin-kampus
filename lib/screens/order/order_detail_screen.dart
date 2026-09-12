import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/order_barcode.dart';
import '../../widgets/pickup_location_card.dart';
import '../cart/cart_screen.dart';
import 'rating_screen.dart';

/// Status urutan untuk progress tracking.
const _orderFlow = [
  'Menunggu Pembayaran',
  'Menunggu Persetujuan Tenant',
  'Diproses',
  'Siap Diambil',
  'Selesai',
];

class OrderDetailScreen extends StatelessWidget {
  final CampusOrder order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderDone = order.status == 'Selesai';
    final progress = _currentStep(order.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Tracking progress ──
          _buildTracking(context, progress, orderDone),

          // ── Ringkasan status ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ID Pesanan',
                          style: TextStyle(color: AppColors.onSurfaceMuted)),
                      Text(order.orderCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(status: order.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Detail menu ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Detail Menu',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(height: 20),
                ...order.items.map(
                  (it) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(it.menuName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text('${it.quantity}x',
                            style: const TextStyle(
                                color: AppColors.onSurfaceMuted)),
                        const SizedBox(width: 12),
                        Text(formatRupiah(it.subtotal)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Bukti pesanan ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bukti Pesanan',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                OrderBarcode(value: order.orderCode),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Lokasi penjemputan ──
          PickupLocationCard(pickupTime: order.pickupTime),
          const SizedBox(height: 16),

          // ── Info pembayaran ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Metode Pembayaran'),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        order.paymentMethod,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Waktu Ambil'),
                    Text(order.pickupTime,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (order.queueNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nomor Antrean'),
                      Text(order.queueNumber,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bayar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(formatRupiah(order.total),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),

          if (orderDone) ...[
            const SizedBox(height: 20),
            // ── Quick re-order & rating ──
            ElevatedButton.icon(
              onPressed: () => _reorder(context),
              icon: const Icon(Icons.replay),
              label: const Text('Pesan Lagi (Quick Re-order)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RatingScreen(order: order)),
              ),
              icon: const Icon(Icons.star_outline),
              label: const Text('Beri Rating & Ulasan'),
            ),
          ],
        ],
      ),
    );
  }

  int _currentStep(String status) {
    final idx = _orderFlow.indexOf(status);
    if (idx >= 0) return idx;
    if (status == 'Dibatalkan') return -1;
    if (status == 'Siap Diambil') return 3;
    return 0;
  }

  Widget _buildTracking(
      BuildContext context, int progress, bool orderDone) {
    if (order.status == 'Dibatalkan') {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pesanan ini telah dibatalkan.',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    final steps = orderDone
        ? const ['Diproses', 'Dimasak', 'Siap Diambil', 'Selesai']
        : const ['Dibuat', 'Diproses', 'Siap Diambil'];
    final current = orderDone
        ? steps.length
        : progress <= 1
            ? 0
            : progress >= 3
                ? steps.length
                : 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                orderDone ? Icons.check_circle : Icons.timeline,
                color: orderDone ? AppColors.primary : AppColors.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                orderDone ? 'Pesanan Selesai' : 'Status Pesanan',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < current
                              ? AppColors.primary
                              : AppColors.surfaceContainerHigh,
                        ),
                        child: Icon(
                          i < current
                              ? Icons.check
                              : Icons.circle_outlined,
                          size: 16,
                          color: i < current
                              ? Colors.white
                              : AppColors.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: i < current
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: i < current
                              ? AppColors.primaryDark
                              : AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    height: 2,
                    width: 14,
                    color: i < current - 1
                        ? AppColors.primary
                        : AppColors.surfaceContainerHigh,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reorder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    // Ambil data menu terbaru untuk memastikan ketersediaan.
    final menus = await DBHelper.instance.getAllMenus();
    final byName = {for (final m in menus) m.name: m};
    var added = 0;
    var skipped = 0;
    for (final item in order.items) {
      final menu = byName[item.menuName];
      if (menu == null || !menu.tersedia) {
        skipped++;
        continue;
      }
      cart.addItem(menu, quantity: item.quantity);
      added++;
    }
    if (!context.mounted) return;
    if (added == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Tidak ada menu yang bisa diulang (mungkin sudah habis).')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$added menu ditambahkan ke keranjang${skipped > 0 ? ' • $skipped menu habis' : ''}.'),
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final done = status == 'Selesai';
    final cancel = status == 'Dibatalkan';
    final bg = cancel
        ? AppColors.errorContainer
        : done
            ? AppColors.primaryContainer
            : AppColors.tertiaryContainer;
    final color = cancel
        ? AppColors.onErrorContainer
        : done
            ? AppColors.onPrimaryContainer
            : AppColors.onTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}