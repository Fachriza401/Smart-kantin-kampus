import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _mode = 'online';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await context.read<AuthProvider>().getPreferredPaymentMode();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pengguna tidak ditemukan.')),
      );
      return;
    }

    await context.read<AuthProvider>().setPreferredPaymentMode(_mode);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _mode == 'online'
              ? 'Pembayaran virtual tersimpan dan akan digunakan otomatis saat checkout.'
              : 'Bayar langsung tersimpan dan akan digunakan otomatis saat checkout.',
        ),
      ),
    );

    Navigator.pop(context, _mode);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Metode Pembayaran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Mode Pembayaran',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilihan ini tersimpan khusus untuk akun mahasiswa/dosen dan otomatis dipakai pada checkout berikutnya. Checkout tidak akan meminta pilihan pembayaran lagi.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _modeTile(
                  colorScheme: colorScheme,
                  value: 'online',
                  icon: Icons.qr_code_2,
                  title: 'Pembayaran Virtual',
                  subtitle: 'QRIS, e-wallet, atau transfer virtual.',
                ),
                const SizedBox(height: 10),
                _modeTile(
                  colorScheme: colorScheme,
                  value: 'cash',
                  icon: Icons.payments_outlined,
                  title: 'Bayar Langsung',
                  subtitle: 'Bayar saat mengambil pesanan di kasir.',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Simpan Metode Pembayaran'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _modeTile({
    required ColorScheme colorScheme,
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _mode == value;
    final primary = colorScheme.primary;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _mode = value),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primary.withOpacity(0.15),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _mode,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() => _mode = newValue);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
