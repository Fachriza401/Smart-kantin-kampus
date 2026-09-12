# TODO - Update Fitur

## 1. Metode Pembayaran
- [ ] Tambah logika pengurangan saldo saat bayar "Saldo Kampus"
- [ ] Tambah metode "Transfer Bank" (BCA, BRI, Mandiri)
- [ ] Perbaiki UI metode pembayaran lebih informatif

## 2. Edit Profil
- [ ] Buat `edit_profile_screen.dart` (nama, email, password)
- [ ] Hubungkan tombol "Edit Profil" di profile_screen
- [ ] Gunakan `updateProfile()` dari AuthProvider

## 3. Kebijakan Privasi
- [ ] Buat `privacy_policy_screen.dart`
- [ ] Hubungkan tombol "Kebijakan Privasi"

## 4. Saldo Akun Baru = 0 & Top-Up
- [ ] Ubah default saldo baru menjadi 0 (user.dart, auth_provider.dart, db_helper.dart)
- [ ] Buat fitur `topUpSaldo` di AuthProvider
- [ ] Buat screen "Isi Saldo"/top-up
- [ ] Tambah menu top-up di profile_screen

