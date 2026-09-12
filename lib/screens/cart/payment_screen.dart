import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../order/order_status_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String pickupTime;
  final String note;
  final String queueNumber;

  const PaymentScreen({
    super.key,
    required this.pickupTime,
    required this.note,
    required this.queueNumber,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentMode = 'online';
  bool _loading = false;
  bool _preferenceLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentPreference();
  }

  Future<void> _loadPaymentPreference() async {
    final mode = await context.read<AuthProvider>().getPreferredPaymentMode();
    if (!mounted) return;
    setState(() {
      _paymentMode = mode;
      _preferenceLoaded = true;
    });
  }

  Future<void> _confirmOrder() async {
    if (_loading) return;
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final isGuest = auth.isGuest;

    if (!isGuest && user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi pengguna tidak ditemukan.')));
      return;
    }
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong.')));
      return;
    }
    final guestName = auth.guestName;
    final guestEmail = auth.guestEmail;
    if (isGuest && (guestName == null || guestEmail == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identitas pemesan belum lengkap.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final paymentLabel = _paymentMode == 'cash' ? 'Bayar Langsung' : 'Pembayaran Virtual';
      final orderCode = generateOrderCode();
      final paymentPayload = 'SMARTKANTIN|$orderCode|AMOUNT=${cart.total.toStringAsFixed(0)}|BUYER=${guestEmail ?? user?.email ?? ''}';
      final order = CampusOrder(
        userId: user?.id ?? 0,
        orderCode: orderCode,
        tenantName: cart.tenantName ?? 'Kantin Kampus',
        total: cart.total,
        paymentMethod: paymentLabel,
        paymentRecipient: 'Admin Smart Kantin',
        paymentStatus: paymentLabel == 'Pembayaran Virtual' ? 'Lunas' : 'Menunggu Pembayaran',
        status: 'Menunggu Persetujuan Tenant',
        pickupTime: widget.pickupTime,
        note: widget.note,
        createdAt: DateTime.now().toIso8601String(),
        guestName: guestName,
        guestEmail: guestEmail,
        queueNumber: widget.queueNumber,
        paymentLink: 'https://pay.smartkantin.local/$orderCode',
        paymentQrPayload: paymentPayload,
        items: cart.items.map((cartItem) => OrderItem(
          orderId: 0,
          menuName: cartItem.menuItem.name,
          price: cartItem.menuItem.price,
          quantity: cartItem.quantity,
        )).toList(),
      );

      final orderId = await DBHelper.instance.createOrder(order);
      if (orderId <= 0) throw Exception('Pesanan gagal dibuat.');
      cart.clear();
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: orderId)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan gagal dibuat: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final modeLabel = _paymentMode == 'cash' ? 'Bayar Langsung' : 'Pembayaran Virtual';

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(.35))),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.payment, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Metode pembayaran dari Profile', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 3),
                  Text(modeLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ])),
                const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.secondary.withOpacity(.35)),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: AppColors.secondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pembayaran diterima dan dipantau oleh Admin Smart Kantin.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineVariant)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                'Ringkasan Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(height: 20),
              ...cart.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.menuItem.name} x${item.quantity}'),
                      ),
                      Text(formatRupiah(item.subtotal)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(formatRupiah(cart.subtotal)),
                ],
              ),
              if (cart.discount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cart.promoTitle?.isNotEmpty == true
                            ? cart.promoTitle!
                            : 'Promo/Voucher',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '-${formatRupiah(cart.discount)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatRupiah(cart.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ]),
          ),
          if (_paymentMode == 'online') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.outlineVariant)),
              child: const Column(children: [
                Text('QR pembayaran akan dibuat setelah pesanan disimpan.', style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                SizedBox(height: 6),
                Text('Untuk melanjutkan pembayaran setelah meninggalkan halaman ini, buka menu Order.', style: TextStyle(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Setelah checkout, menu Order menyimpan barcode pembayaran untuk pesanan yang belum lunas.', style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.4)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: (!_preferenceLoaded || _loading) ? null : _confirmOrder,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
            label: Text(_loading ? 'Memproses...' : 'Checkout Pesanan'),
          ),
        ),
      ),
    );
  }
}
