import 'package:flutter/material.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/order_barcode.dart';

class GuestPaymentResumeScreen extends StatefulWidget {
  final CampusOrder order;

  const GuestPaymentResumeScreen({super.key, required this.order});

  @override
  State<GuestPaymentResumeScreen> createState() =>
      _GuestPaymentResumeScreenState();
}

class _GuestPaymentResumeScreenState extends State<GuestPaymentResumeScreen> {
  bool _loading = false;
  CampusOrder? _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _markPaid() async {
    final order = _order;
    if (_loading || order?.id == null) return;

    setState(() => _loading = true);
    await DBHelper.instance.markVirtualPaymentPaid(order!.id!);
    final refreshed = await DBHelper.instance.getOrderById(order.id!);

    if (!mounted) return;
    setState(() {
      _order = refreshed;
      _loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pembayaran berhasil diverifikasi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPaid = order.paymentStatus == 'Lunas';

    return Scaffold(
      appBar: AppBar(title: const Text('Lanjutkan Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Column(
              children: [
                const Text(
                  'QR Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ${order.orderCode}',
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OrderBarcode(
                    value: order.paymentQrPayload ?? order.orderCode,
                    size: 210,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Total ${formatRupiah(order.total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.paymentStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isPaid ? AppColors.primary : AppColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                const Row(
                  children: [
                    Icon(Icons.receipt_long, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Ringkasan Pesanan',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.menuName, style: const TextStyle(fontSize: 14)),
                        ),
                        Text(
                          formatRupiah(item.price * item.quantity),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      formatRupiah(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isPaid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _markPaid,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_rounded),
                label: Text(
                  _loading ? 'Memverifikasi...' : 'Saya Sudah Bayar',
                ),
              ),
            ),
          if (isPaid)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: const Text(
                'Pembayaran sudah lunas. Pesanan akan mengikuti proses Tenant/Kasir.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
