import 'package:flutter_test/flutter_test.dart';

import 'package:uas_mobile/utils/formatters.dart';

void main() {
  group('generateOrderCode', () {
    test('memuat tanggal, jam sampai detik, dan 3 digit acak', () {
      final code = generateOrderCode(DateTime(2026, 9, 30, 14, 35, 12));

      expect(code, matches(RegExp(r'^#ORD-260930-143512-[1-9]\d{2}$')));
    });

    test('pesanan pada detik yang sama tetap mendapat kode berbeda', () {
      final at = DateTime(2026, 9, 30, 14, 35, 12);
      final codes = {for (var i = 0; i < 50; i++) generateOrderCode(at)};

      expect(codes.length, greaterThan(40));
    });
  });

  group('waktu', () {
    test('nowUtcIso diakhiri Z agar server membacanya sebagai UTC', () {
      expect(nowUtcIso(), endsWith('Z'));
    });

    test('formatDateTime mengubah waktu server (UTC) ke jam lokal', () {
      const iso = '2026-09-30T07:05:00+00:00';
      final expected = DateTime.parse(iso).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');

      expect(
        formatDateTime(iso),
        '${two(expected.day)}/${two(expected.month)}/${expected.year} '
        '${two(expected.hour)}:${two(expected.minute)}',
      );
    });

    test('formatDateTime aman untuk nilai kosong atau tidak valid', () {
      expect(formatDateTime(null), '');
      expect(formatDateTime(''), '');
      expect(formatDateTime('bukan tanggal'), 'bukan tanggal');
    });
  });
}
