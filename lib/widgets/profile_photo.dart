import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Batas aman data URL foto profil: kolom `users.photoPath` bertipe
/// TEXT MySQL (64 KB).
const maxProfilePhotoDataLength = 60000;

/// Hasil decode base64 di-cache agar avatar tidak berkedip saat layar
/// di-rebuild (mis. oleh polling notifikasi).
final _decoded = <String, Uint8List>{};
const _maxCacheEntries = 8;

Uint8List? _bytesOf(String dataUrl) {
  final cached = _decoded[dataUrl];
  if (cached != null) return cached;
  try {
    final bytes = UriData.parse(dataUrl).contentAsBytes();
    if (_decoded.length >= _maxCacheEntries) _decoded.clear();
    _decoded[dataUrl] = bytes;
    return bytes;
  } on FormatException {
    return null;
  }
}

/// Foto profil dapat berupa:
/// - `data:image/...;base64,...` -> tersimpan di server, tampil di semua HP
/// - `http(s)://...`             -> foto dari internet (mis. akun demo)
/// - path file                    -> data lama, hanya ada di HP pengunggah
ImageProvider? profilePhotoProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('data:image')) {
    final bytes = _bytesOf(path);
    return bytes == null ? null : MemoryImage(bytes);
  }
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return FileImage(File(path));
}

/// Gambar foto profil dengan [fallback] bila kosong atau gagal dimuat.
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.path,
    required this.size,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String? path;
  final double size;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final provider = profilePhotoProvider(path);
    if (provider == null) return fallback;
    return Image(
      image: provider,
      width: size,
      height: size,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
