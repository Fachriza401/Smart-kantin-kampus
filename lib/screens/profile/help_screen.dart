import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _openWhatsApp() async {
    // Nomor CS dalam format internasional (0 852-7726-7052 -> 62 852-7726-7052)
    const waNumber = '6285277267052';
    const message = 'Halo Admin Smart Kantin Kampus, saya ingin bertanya...';
    final uri = Uri.parse(
        'https://wa.me/$waNumber?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle jika gagal membuka
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context, listen: false).currentUser?.role;
    final isAdmin = role == 'admin';
    final isOperator = role == 'tenant' || role == 'kasir';

    final String helpTitle;
    final Map<String, String> faqs;
    if (isOperator) {
      helpTitle = 'Bantuan Tenant & Kasir';
      faqs = const {
        'Cara memproses pesanan':
            'Periksa pesanan baru, ubah status menjadi Diproses, lalu Siap dan Selesai setelah pesanan diserahkan.',
        'Bagaimana pesanan masuk?':
            'Setiap checkout mahasiswa dengan tenant Kantin Kampus akan muncul otomatis pada dashboard Tenant/Kasir.',
        'Bagaimana mengelola menu?':
            'Pengelolaan menu dilakukan melalui Admin. Perubahan menu dan foto akan tersinkron ke tampilan mahasiswa.',
        'Kendala transaksi':
            'Catat kode pesanan dan laporkan kepada Admin untuk pemeriksaan transaksi.',
      };
    } else if (isAdmin) {
      helpTitle = 'Bantuan Admin';
      faqs = const {
        'Mengelola menu & promo':
            'Gunakan Kelola Menu dan Kelola Promo di Dashboard Admin untuk mengubah menu, harga, foto, dan promo yang tampil untuk pelanggan.',
        'Mengelola tenant & kasir':
            'Buka menu Tenant & Kasir untuk menambah atau mengelola akun Tenant dan Kasir. Permintaan reset kata sandi ditangani melalui menu Reset Password.',
        'Memantau pembayaran':
            'Admin adalah penerima pembayaran virtual pelanggan. Pantau lewat bagian Pembayaran Diterima Admin dan Data Pembeli di Dashboard.',
        'Bagaimana perubahan menu tampil?':
            'Semua perubahan menu dan foto langsung tersinkron ke tampilan pelanggan dan dashboard Tenant/Kasir.',
        'Kendala transaksi':
            'Catat kode pesanan lalu periksa lewat Data Pembeli. Jika berlarut, hubungi CS lewat WhatsApp di bawah.',
      };
    } else {
      helpTitle = 'Bantuan Pelanggan';
      faqs = const {
        'Cara memesan makanan (langkah demi langkah)':
            '1. Di halaman Home, cari menu makanan/minuman atau buka tab Cari lalu pilih kategori.\n'
            '2. Tekan tombol + pada menu untuk menambahkan ke keranjang (jumlah bisa diubah di halaman Keranjang).\n'
            '3. Buka Keranjang (tombol hijau melayang) lalu tekan Checkout.\n'
            '4. Isi data pemesan (nama & email), pilih waktu pengambilan, lalu tekan "Lanjut ke Pembayaran".\n'
            '5. Pilih Pembayaran Virtual (QR/e-wallet) atau Bayar Langsung di kasir.\n'
            '6. Setelah pesanan dibuat, pantau statusnya lewat tab Order.\n'
            '7. Saat status "Siap Diambil", tunjukkan kode/QR pesanan ke kasir lalu ambil pesananmu.',
        'Apakah perlu membuat akun untuk memesan?':
            'Tidak perlu. Mahasiswa/civitas bisa memesan langsung sebagai pelanggan tanpa login. '
            'Isi nama dan email saat checkout untuk membuat pesanan baru.',
        'Bagaimana status pesanan dipantau?':
            'Status pesanan berubah otomatis: Menunggu Persetujuan → Diproses → Dimasak → Siap Diambil. '
            'Periksa tab Order kapan saja; pesanan yang belum dibayar juga menyimpan QR pembayarannya di tab Order.',
        'Bagaimana cara membayar?':
            'Saat checkout, pilih Pembayaran Virtual (QRIS/e-wallet/transfer) lalu ikuti QR yang tersimpan di tab Order, '
            'atau pilih Bayar Langsung dan bayar di kasir saat mengambil pesanan.',
        'Bagaimana cara mengambil pesanan?':
            'Tunggu sampai status pesanan "Siap Diambil", lalu tunjukkan kode atau QR pesanan kepada kasir Tenant. '
            'Kasir akan memverifikasi dan menyerahkan pesananmu.',
        'Masalah dengan pesanan':
            'Jika pesanan bermasalah, catat kode pesanan lalu hubungi Admin lewat WhatsApp di bawah.',
      };
    }

    return Scaffold(
      appBar: AppBar(title: Text(helpTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari topik bantuan...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Pertanyaan Populer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: faqs.entries
                    .map(
                      (e) => ExpansionTile(
                        title: Text(e.key,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value,
                              style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.4)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openWhatsApp,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.forum, color: AppColors.onPrimaryContainer),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hubungi CS via WhatsApp',
                              style: TextStyle(
                                  color: AppColors.onPrimaryContainer,
                                  fontWeight: FontWeight.bold)),
                          Text('0852-7726-7052',
                              style: TextStyle(
                                  color: AppColors.onPrimaryContainer,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: AppColors.onPrimaryContainer, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
