import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../db/db_helper.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../order/order_status_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  String? _message;

  Future<void> _handleCode(String rawValue) async {
    if (_processing || rawValue.trim().isEmpty) return;

    setState(() {
      _processing = true;
      _message = 'Memeriksa QR pesanan...';
    });

    final order = await DBHelper.instance.getOrderByCode(rawValue.trim());
    if (!mounted) return;

    if (order == null) {
      setState(() {
        _processing = false;
        _message = 'QR tidak dikenali sebagai nomor pesanan.';
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _message = null);
      return;
    }

    await _controller.stop();
    if (!mounted) return;

    final role = context.read<AuthProvider>().currentUser?.role;
    if (role == 'kasir') {
      await _verifyPickup(order);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderStatusScreen(orderId: order.id!),
        ),
      );
    }
  }

  Future<void> _verifyPickup(CampusOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verifikasi Pengambilan'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Kantin: ${order.tenantName}'),
                const SizedBox(height: 10),
                ...order.items.map(
                  (item) => Text('${item.quantity}x ${item.menuName}'),
                ),
                const Divider(height: 22),
                Text(
                  'Total: ${formatRupiah(order.total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text('Pembayaran: ${order.paymentMethod}'),
                const SizedBox(height: 10),
                Text(
                  order.status == 'Siap Diambil'
                      ? 'Pesanan sudah dikonfirmasi Tenant dan boleh diberikan kepada mahasiswa.'
                      : 'Pesanan belum siap diambil.',
                  style: TextStyle(
                    color: order.status == 'Siap Diambil'
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: order.status == 'Siap Diambil'
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('Konfirmasi Diambil'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      await DBHelper.instance.updateOrderStatus(order.id!, 'Selesai');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil diserahkan kepada mahasiswa.')),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final isKasir = role == 'kasir';

    return Scaffold(
      appBar: AppBar(
        title: Text(isKasir ? 'Scan QR Pengambilan' : 'Scan QR Kantin'),
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) return;
              final value = capture.barcodes.first.rawValue;
              if (value != null) _handleCode(value);
            },
          ),
          Center(
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 26,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.68),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: AppColors.secondaryContainer, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    isKasir
                        ? 'Arahkan kamera ke QR pesanan mahasiswa untuk memverifikasi pengambilan.'
                        : 'Arahkan kamera ke QR pesanan atau nomor antrean.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                  ],
                  if (_processing) ...[
                    const SizedBox(height: 10),
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
