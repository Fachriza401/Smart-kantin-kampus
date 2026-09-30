import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uas_mobile/widgets/profile_photo.dart';

void main() {
  group('profilePhotoProvider', () {
    test('mengembalikan null untuk foto kosong', () {
      expect(profilePhotoProvider(null), isNull);
      expect(profilePhotoProvider(''), isNull);
    });

    test('foto base64 dari server dibaca sebagai MemoryImage', () {
      final bytes = [1, 2, 3, 4];
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final provider = profilePhotoProvider(dataUrl);

      expect(provider, isA<MemoryImage>());
      expect((provider! as MemoryImage).bytes, bytes);
    });

    test('hasil decode base64 dipakai ulang (tidak berkedip saat rebuild)',
        () {
      final dataUrl = 'data:image/jpeg;base64,${base64Encode([9, 8, 7])}';

      final first = profilePhotoProvider(dataUrl)! as MemoryImage;
      final second = profilePhotoProvider(dataUrl)! as MemoryImage;

      expect(identical(first.bytes, second.bytes), isTrue);
    });

    test('URL internet dibaca sebagai NetworkImage', () {
      expect(
        profilePhotoProvider('https://images.unsplash.com/photo-1'),
        isA<NetworkImage>(),
      );
    });

    test('data URL rusak tidak membuat crash', () {
      expect(profilePhotoProvider('data:image/jpeg;base64'), isNull);
    });
  });
}
