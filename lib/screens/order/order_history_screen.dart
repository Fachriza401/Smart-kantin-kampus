import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'guest_payment_resume_screen.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<CampusOrder> _orders = [];
  String _filter = 'Semua';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final orders = auth.isGuest
        ? (auth.guestEmail == null
            ? <CampusOrder>[]
            : await DBHelper.instance.getOrdersByGuestEmail(auth.guestEmail!))
        : (auth.currentUser?.id == null
            ? <CampusOrder>[]
            : await DBHelper.instance.getOrdersByUser(auth.currentUser!.id!));

    if (!mounted) return;
    setState(() => _orders = orders);
  }

  List<CampusOrder> get _filtered {
    return _orders.where((order) {
      switch (_filter) {
        case 'Selesai':
          return order.status == 'Selesai';
        case 'Dibatalkan':
          return order.status == 'Dibatalkan';
        case 'Diproses':
          return order.status != 'Selesai' && order.status != 'Dibatalkan';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['Semua', 'Diproses', 'Selesai', 'Dibatalkan']
                  .map(
                    (filter) {
                      final selected = _filter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                          ),
                          onSelected: (_) =>
                              setState(() => _filter = filter),
                        ),
                      );
                    },
                  )
                  .toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: orders.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 140),
                  Icon(Icons.receipt_long_rounded,
                      size: 64, color: AppColors.onSurfaceMuted),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Belum ada pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Pesanan yang kamu buat akan muncul di sini',
                      style: TextStyle(color: AppColors.onSurfaceMuted),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final unpaid = order.paymentStatus != 'Lunas' &&
                      order.status != 'Dibatalkan';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      order.tenantName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 14,
                              color: AppColors.onSurfaceMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.orderCode,
                              style: const TextStyle(
                                color: AppColors.onSurfaceMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.items
                              .map((item) =>
                                  '${item.quantity}x ${item.menuName}')
                              .join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatRupiah(order.total),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: unpaid
                                    ? AppColors.tertiaryContainer
                                    : AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.paymentStatus,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: unpaid
                                      ? AppColors.onTertiary
                                      : AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (unpaid) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.tertiary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.tertiary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: QrImageView(
                                    data: order.paymentQrPayload ??
                                        order.orderCode,
                                    size: 48,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 15,
                                            color: AppColors.onTertiary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Belum dibayar',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.onTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'QR pembayaran tersimpan. Tekan lanjut untuk membuka kembali.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.onSurfaceMuted,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GuestPaymentResumeScreen(order: order),
                                ),
                              ),
                              icon: const Icon(Icons.qr_code_2),
                              label: const Text('Lanjutkan Pembayaran'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderDetailScreen(order: order),
                              ),
                            ),
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('Lihat Detail Pesanan'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final done = status == 'Selesai';
    final cancel = status == 'Dibatalkan';
    final bg = cancel
        ? AppColors.errorContainer
        : done
            ? AppColors.primaryContainer
            : AppColors.tertiaryContainer;
    final Color fg = cancel
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            cancel
                ? Icons.cancel_rounded
                : done
                    ? Icons.check_circle_rounded
                    : Icons.local_shipping_rounded,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
