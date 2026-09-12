import 'package:flutter/foundation.dart';

import '../db/db_helper.dart';
import '../models/menu_item.dart';
import '../models/promo.dart';

/// Provider untuk fitur admin: mengelola menu & promo.
class AdminProvider extends ChangeNotifier {
  final _db = DBHelper.instance;

  List<MenuItem> _menus = [];
  List<Promo> _promos = [];

  List<MenuItem> get menus => List.unmodifiable(_menus);
  List<Promo> get promos => List.unmodifiable(_promos);

  bool _loading = false;
  bool get loading => _loading;

  /// Muat semua menu & promo dari database.
  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _menus = await _db.getAllMenus();
    _promos = await _db.getAllPromos();
    _loading = false;
    notifyListeners();
  }

  // ---------------- MENU ----------------

  Future<void> refreshMenus() async {
    _menus = await _db.getAllMenus();
    notifyListeners();
  }

  Future<void> addMenu(MenuItem menu) async {
    await _db.insertMenu(menu);
    await refreshMenus();
  }

  Future<void> updateMenu(MenuItem menu) async {
    await _db.updateMenu(menu);
    await refreshMenus();
  }

  Future<void> deleteMenu(int id) async {
    await _db.deleteMenu(id);
    await refreshMenus();
  }

  /// Ubah status ketersediaan (stok) menu dengan cepat.
  Future<void> setMenuAvailability(int id, bool tersedia) async {
    await _db.setMenuAvailability(id, tersedia);
    await refreshMenus();
  }

  // ---------------- PROMO ----------------

  Future<void> refreshPromos() async {
    _promos = await _db.getAllPromos();
    notifyListeners();
  }

  Future<void> addPromo(Promo promo) async {
    await _db.insertPromo(promo);
    await refreshPromos();
  }

  Future<void> updatePromo(Promo promo) async {
    await _db.updatePromo(promo);
    await refreshPromos();
  }

  Future<void> deletePromo(int id) async {
    await _db.deletePromo(id);
    await refreshPromos();
  }
}
