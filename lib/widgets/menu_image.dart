import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../theme/app_theme.dart';

/// Foto menu yang tetap aman dipakai saat perangkat sedang offline.
///
/// Mendukung tiga sumber gambar:
/// - `assets/...` -> gambar aset lokal
/// - `data:image/...` -> gambar hasil upload (base64)
/// - `http(s)://...` -> gambar jaringan
///
/// Jika gambar benar-benar gagal dimuat maka ditampilkan fallback berupa
/// aset lokal sesuai kategori, dan hanya sebagai pilihan terakhir,
/// gradien + ikon. Tidak pernah menampilkan kotak kosong.
class MenuImage extends StatelessWidget {
  final String imageUrl;
  final String icon;
  final double size;
  final BorderRadius borderRadius;

  const MenuImage({
    super.key,
    required this.imageUrl,
    required this.icon,
    required this.size,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final iconFallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPrimary,
      ),
      alignment: Alignment.center,
      child: Icon(
        DummyData.iconFor(icon),
        color: Colors.white,
        size: size * .42,
      ),
    );

    final assetFallback = Image.asset(
      DummyData.fallbackAssetForIcon(icon),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => iconFallback,
    );

    Widget image;

    final url = imageUrl.trim();

    if (url.isEmpty) {
      image = assetFallback;
    } else if (url.startsWith('data:image')) {
      try {
        image = Image.memory(
          base64Decode(url.split(',').last),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => assetFallback,
        );
      } catch (_) {
        image = assetFallback;
      }
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      image = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => assetFallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : assetFallback,
      );
    } else {
      image = Image.asset(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => assetFallback,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: image,
    );
  }
}
