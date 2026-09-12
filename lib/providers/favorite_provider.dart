import 'package:flutter/foundation.dart';

import '../db/db_helper.dart';

/// Mengelola daftar menu favorit (wishlist) pengguna.
/// Untuk guest (userId = 0) favorit disimpan sementara di memori.
class FavoriteProvider extends ChangeNotifier {
  final Set<int> _guestFavorites = {};
  Set<int> _userFavorites = {};
  int? _userId;

  Set<int> get favoriteIds => _userId == null ? _guestFavorites : _userFavorites;

  bool isFavorite(int menuId) => favoriteIds.contains(menuId);

  /// Dipanggil saat app dimulai / sesi berubah.
  Future<void> loadForUser(int? userId) async {
    _userId = userId;
    if (userId == null) {
      notifyListeners();
      return;
    }
    final ids = await DBHelper.instance.getFavoriteMenuIds(userId);
    _userFavorites = ids.toSet();
    notifyListeners();
  }

  Future<void> toggle(int menuId) async {
    final isFav = isFavorite(menuId);
    if (_userId == null) {
      if (isFav) {
        _guestFavorites.remove(menuId);
      } else {
        _guestFavorites.add(menuId);
      }
      notifyListeners();
      return;
    }
    if (isFav) {
      _userFavorites.remove(menuId);
      await DBHelper.instance.removeFavorite(_userId!, menuId);
    } else {
      _userFavorites.add(menuId);
      await DBHelper.instance.addFavorite(_userId!, menuId);
    }
    notifyListeners();
  }
}
