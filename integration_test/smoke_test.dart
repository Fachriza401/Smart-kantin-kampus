// Smoke test di simulator/HP terhadap server live (hanya baca + login).
//
//   flutter test integration_test/smoke_test.dart -d <device-id>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uas_mobile/main.dart';
import 'package:uas_mobile/widgets/menu_card.dart';

const _networkTimeout = Duration(seconds: 45);

/// Pump berulang sampai [finder] muncul (menunggu respons jaringan).
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(_networkTimeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Tidak muncul dalam ${_networkTimeout.inSeconds}s: $finder');
}

/// Gulir halaman utama ke bawah sampai [finder] ter-render (list lazy).
Future<void> scrollUntilFound(WidgetTester tester, Finder finder) async {
  final vertical = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  final deadline = DateTime.now().add(_networkTimeout);
  while (DateTime.now().isBefore(deadline)) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(vertical.first, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 400));
  }
  throw TestFailure('Tidak ditemukan saat menggulir: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  testWidgets('guest: splash -> home menampilkan menu dari server',
      (tester) async {
    await tester.pumpWidget(const SmartKantinKampusApp());

    await pumpUntilFound(tester, find.text('Pengaturan'));
    await scrollUntilFound(tester, find.text('Rekomendasi Untukmu'));
    await scrollUntilFound(tester, find.byType(MenuListTile));

    expect(find.byType(MenuListTile), findsWidgets);
  });

  testWidgets('staf: login admin -> dashboard admin', (tester) async {
    await tester.pumpWidget(const SmartKantinKampusApp());
    await pumpUntilFound(tester, find.text('Pengaturan'));

    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    final portal = find.text('Portal Staf / Admin Log In');
    await tester.scrollUntilVisible(portal, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(portal);
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'admin@kantin.app');
    await tester.enterText(fields.at(1), 'admin123');
    await tester.tap(find.text('Masuk sebagai Staf'));

    await pumpUntilFound(tester, find.text('Selamat datang kembali, Admin!'));
    await pumpUntilFound(tester, find.text('Kontrol Penuh Kantin'));
  });
}
