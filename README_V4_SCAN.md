# Cara Scan/Run Update V4

1. Extract ZIP.
2. Buka folder project di VS Code.
3. Jalankan:

flutter clean
flutter pub get
flutter analyze
flutter run

Jika database lama masih menyimpan data versi sebelumnya, migration akan menaikkan SQLite ke version 8 dan menambahkan NIRM.

Untuk test paling bersih, uninstall aplikasi dari emulator/device terlebih dahulu agar database lama ikut terhapus, lalu jalankan ulang.

Akun demo ada di DEMO_ACCOUNTS.txt.
