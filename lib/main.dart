import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  runApp(
    const SmartKantinKampusApp(),
  );
}

class SmartKantinKampusApp extends StatelessWidget {
  const SmartKantinKampusApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..load(),
        ),

        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        // ======================================================
        // SATU-SATUNYA CART PROVIDER
        // ======================================================

        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(),
        ),

        ChangeNotifierProvider(
          create: (_) => AdminProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Smart Kantin Kampus',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
