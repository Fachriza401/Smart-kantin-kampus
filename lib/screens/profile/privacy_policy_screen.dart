import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kebijakan Privasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (Provider.of<AuthProvider>(context, listen: false).currentUser?.role == 'tenant' ||
              Provider.of<AuthProvider>(context, listen: false).currentUser?.role == 'kasir') ...[
            const _SectionTitle('Perlindungan Data Operasional'),
            const _SectionBody(
              'Data pesanan, status transaksi, dan informasi menu digunakan hanya untuk menjalankan operasional Kantin Kampus. Tenant dan Kasir tidak memerlukan saldo atau metode pembayaran pribadi di aplikasi.',
            ),
            const _SectionTitle('Akses Tenant & Kasir'),
            const _SectionBody(
              'Akun Tenant/Kasir hanya digunakan untuk memproses pesanan, memantau transaksi, dan menjalankan operasional Kantin Kampus. Hak akses tidak mencakup pengelolaan data pribadi mahasiswa di luar kebutuhan pesanan.',
            ),
          ] else ...[
          _SectionTitle('1. Pendahuluan'),
          _SectionBody(
            'Selamat datang di Smart Kantin Kampus. Kami menghargai privasi Anda '
            'dan berkomitmen untuk melindungi data pribadi yang Anda berikan saat '
            'menggunakan aplikasi ini.',
          ),
          _SectionTitle('2. Data yang Kami Kumpulkan'),
          _SectionBody(
            'Kami mengumpulkan data berikut: nama, email, dan password yang Anda '
            'daftarkan. Data ini digunakan untuk keperluan pembuatan akun dan '
            'verifikasi login.',
          ),
          _SectionTitle('3. Penggunaan Data'),
          _SectionBody(
            'Data Anda digunakan untuk: (a) memproses transaksi dan pesanan, '
            '(b) mengelola saldo kampus, (c) memberikan layanan bantuan, dan '
            '(d) meningkatkan kualitas layanan aplikasi.',
          ),
          _SectionTitle('4. Penyimpanan Data'),
          _SectionBody(
            'Data Anda disimpan secara lokal di perangkat Anda menggunakan basis '
            'data SQLite. Kami tidak mentransmisikan data pribadi Anda ke server '
            'pihak ketiga tanpa izin.',
          ),
          _SectionTitle('5. Keamanan Data'),
          _SectionBody(
            'Kami menerapkan langkah-langkah keamanan yang wajar untuk melindungi '
            'data Anda dari akses yang tidak sah. Namun, metode penyimpanan lokal '
            'memiliki keterbatasan sehingga Anda disarankan menjaga kerahasiaan '
            'kredensial akun.',
          ),
          _SectionTitle('6. Hak Anda'),
          _SectionBody(
            'Anda berhak mengakses, memperbarui, atau menghapus data pribadi Anda. '
            'Anda dapat mengubah profil melalui menu Edit Profil pada aplikasi.',
          ),
          _SectionTitle('7. Kontak'),
          _SectionBody(
            'Jika Anda memiliki pertanyaan terkait kebijakan privasi ini, silakan '
            'hubungi Admin Smart Kantin Kampus melalui fitur Bantuan pada aplikasi.',
          ),
          _SectionBody(
            'Kebijakan ini dapat diperbarui sewaktu-waktu. Perubahan akan '
            'diinformasikan melalui aplikasi.',
          ),
          ],
          const SizedBox(height: 20),
          const Center(
            child: Text(
              '© 2024 Smart Kantin Kampus',
              style: TextStyle(fontSize: 12, color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}
