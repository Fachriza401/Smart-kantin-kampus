import 'dart:math';

import 'package:intl/intl.dart';

String formatRupiah(num value) {
  final formatter = NumberFormat.decimalPattern('id_ID');
  return 'Rp ${formatter.format(value)}';
}

final _random = Random();

/// Contoh: `#ORD-260930-143512-507` (tanggal, jam, 3 digit acak).
///
/// Server mewajibkan kode unik; jam sampai detik + angka acak membuat
/// tabrakan praktis hanya terjadi bila dua pesanan dibuat pada detik yang
/// sama DAN mendapat angka acak yang sama (peluang 1:900).
String generateOrderCode([DateTime? at]) {
  final now = at ?? DateTime.now();
  final datePart = DateFormat('yyMMdd').format(now);
  final timePart = DateFormat('HHmmss').format(now);
  final randomPart = 100 + _random.nextInt(900);
  return '#ORD-$datePart-$timePart-$randomPart';
}

/// Waktu sekarang dalam UTC, format ISO-8601 dengan akhiran `Z`.
///
/// Server menyimpan waktu dalam UTC; tanpa `Z` jam lokal WIB akan
/// dianggap UTC sehingga tercatat 7 jam lebih lambat.
String nowUtcIso() => DateTime.now().toUtc().toIso8601String();

/// Mengubah timestamp ISO dari server menjadi jam lokal HP,
/// mis. `30/09/2026 14:05`. Mengembalikan teks asli bila tidak valid.
String formatDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
}
