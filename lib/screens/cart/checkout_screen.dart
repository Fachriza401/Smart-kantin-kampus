import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _queueCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final _times = const ['11:30', '12:00', '12:30', '13:00'];
  String _selectedTime = '12:00';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _queueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _generateQueue() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'A${(now % 900 + 100)}';
  }

  Future<void> _continue() async {
    final auth = context.read<AuthProvider>();

    if (auth.isGuest) {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim().toLowerCase();

      if (name.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama lengkap wajib diisi.')),
        );
        return;
      }

      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email resmi tidak valid.')),
        );
        return;
      }

      final queue = _queueCtrl.text.trim().isEmpty
          ? _generateQueue()
          : _queueCtrl.text.trim();

      await auth.setGuestSession(name: name, email: email);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            pickupTime: _selectedTime,
            note: _noteCtrl.text.trim(),
            queueNumber: queue,
          ),
        ),
      );
      return;
    }

    final queue = _queueCtrl.text.trim().isEmpty
        ? _generateQueue()
        : _queueCtrl.text.trim();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          pickupTime: _selectedTime,
          note: _noteCtrl.text.trim(),
          queueNumber: queue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isGuest = context.watch<AuthProvider>().isGuest;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isGuest) ...[
            const _SectionHeader(
              icon: Icons.person_outline,
              title: 'Data Pemesan',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email Resmi',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _queueCtrl,
              decoration: InputDecoration(
                labelText: 'Nomor Antrean / Meja',
                hintText: _generateQueue(),
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const _SectionHeader(
            icon: Icons.schedule_outlined,
            title: 'Waktu Pengambilan',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _times
                .map(
                  (time) {
                    final selected = _selectedTime == time;
                    return ChoiceChip(
                      avatar: Icon(
                        selected ? Icons.check_circle : Icons.schedule,
                        size: 16,
                        color: selected
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ),
                      label: Text(
                        time,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w700,
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
                      onSelected: (_) => setState(() => _selectedTime = time),
                    );
                  },
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Contoh: tanpa sambal, extra pedas',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
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
                          child: Text(
                            item.menuItem.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          formatRupiah(item.subtotal),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: AppColors.onSurfaceMuted)),
                    Text(
                      formatRupiah(cart.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (cart.discount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cart.promoTitle ?? 'Promo',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientSoftGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        formatRupiah(cart.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: cart.items.isEmpty ? null : _continue,
            icon: const Icon(Icons.credit_card),
            label: const Text('Lanjut ke Pembayaran'),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }
}
