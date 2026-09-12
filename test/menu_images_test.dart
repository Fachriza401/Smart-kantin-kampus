import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:uas_mobile/data/dummy_data.dart';

void main() {
  group('DummyData menu images', () {
    test('setiap menu memiliki imageUrl non-kosong', () {
      for (final menu in DummyData.menuItems) {
        expect(menu.imageUrl.trim(), isNotEmpty,
            reason: 'Menu "${menu.name}" tidak boleh tanpa foto');
      }
    });

    test('setiap imageUrl menunjuk ke aset lokal yang benar', () {
      expect(DummyData.menuItems.length, 140,
          reason: 'Jumlah item menu harus tetap 140');
      final names = <String>{};
      for (final menu in DummyData.menuItems) {
        expect(menu.imageUrl, startsWith('assets/images/menu/'),
            reason: 'Menu "${menu.name}" harus memakai aset lokal');
        expect(File(menu.imageUrl).existsSync(), isTrue,
            reason:
                'Aset "${menu.imageUrl}" untuk menu "${menu.name}" tidak ditemukan');
        names.add(menu.name);
      }
      expect(names.length, 136,
          reason: 'Terdapat 136 nama unik (4 nama muncul di 2 kategori)');
    });

    test('photoAssetFor mengembalikan gambar untuk semua nama menu', () {
      for (final menu in DummyData.menuItems) {
        final asset = DummyData.photoAssetFor(menu.name);
        expect(asset, startsWith('assets/images/menu/'));
        expect(File(asset).existsSync(), isTrue,
            reason: 'photoAssetFor gagal untuk "${menu.name}"');
      }
    });
  });
}