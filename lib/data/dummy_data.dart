import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/tenant.dart';

class DummyData {
  static const List<Tenant> tenants = [
    Tenant(
      id: 1,
      name: 'Kantin Kampus',
      location: 'Area utama kampus',
      rating: 4.8,
      reviewCount: 558,
      etaText: '15-30 min',
      icon: 'storefront',
      imageUrl:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  static const List<String> categories = [
    'Makanan',
    'Minuman',
    'Nasi',
    'Mie',
    'Ayam',
    'Gorengan',
    'Snacks',
    'Dessert',
    'Kopi',
    'Teh',
    'Jus',
    'Minuman Dingin',
    'Paket Hemat',
    'Aneka',
  ];

  static final List<MenuItem> menuItems = _buildMenuItems();

  static List<MenuItem> _buildMenuItems() {
    final items = <MenuItem>[];
    var id = 1;
    for (final category in categories) {
      final names = _catalog[category]!;
      for (var i = 0; i < names.length; i++) {
        final name = names[i];
        items.add(MenuItem(
          id: id,
          tenantId: 1,
          tenantName: 'Kantin Kampus',
          name: name,
          price: (_basePrice[category]! + ((i % 5) * 1000)).toDouble(),
          category: category,
          description:
              '$name dibuat segar oleh Kantin Kampus dengan bahan pilihan.',
          rating: 4.5 + ((i % 5) * 0.1),
          reviewCount: 20 + (i * 7),
          estimasi:
              (category == 'Minuman' || category == 'Kopi' || category == 'Teh')
                  ? '5-10 menit'
                  : '15-20 menit',
          icon: _iconMap[category]!,
          imageUrl: _photoAssets[name]!,
        ));
        id++;
      }
    }
    return items;
  }

  /// Mengembalikan aset gambar lokal untuk sebuah menu berdasarkan namanya.
  ///
  /// Jika nama tidak dikenal (misal menu baru buatan Tenant), dipakai gambar
  /// default dari kategori makanan utama supaya tidak pernah kosong.
  static String photoAssetFor(String name) {
    final key = name.trim();
    final direct = _photoAssets[key];
    if (direct != null) return direct;
    for (final item in menuItems) {
      if (item.name.trim() == key) return item.imageUrl;
    }
    return 'assets/images/menu/nasi_ayam_geprek.jpg';
  }

  /// Aset gambar untuk kategori menu (fallback ketika nama tidak dikenal).
  static String fallbackAssetForCategory(String category) {
    for (final item in menuItems) {
      if (item.category == category) return item.imageUrl;
    }
    return 'assets/images/menu/nasi_ayam_geprek.jpg';
  }

  /// Aset gambar fallback berdasarkan ikon kategori untuk widget MenuImage.
  static String fallbackAssetForIcon(String icon) {
    return _iconAsset[icon] ?? 'assets/images/menu/nasi_ayam_geprek.jpg';
  }

  static IconData iconFor(String key) {
    switch (key) {
      case 'storefront':
        return Icons.storefront;
      case 'coffee':
        return Icons.coffee;
      case 'restaurant':
        return Icons.restaurant;
      case 'ramen_dining':
        return Icons.ramen_dining;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_drink':
        return Icons.local_drink;
      case 'icecream':
        return Icons.icecream;
      case 'cake':
        return Icons.cake;
      case 'tapas':
        return Icons.tapas;
      case 'rice_bowl':
        return Icons.rice_bowl;
      case 'nutrition':
        return Icons.eco;
      case 'fastfood':
        return Icons.fastfood;
      default:
        return Icons.fastfood;
    }
  }

  static List<MenuItem> menuForTenant(int tenantId) =>
      menuItems.where((m) => m.tenantId == tenantId).toList();

  static const Map<String, String> _photoAssets = {
    'Americano': 'assets/images/menu/americano.jpg',
    'Ayam Bakar Madu': 'assets/images/menu/ayam_bakar_madu.jpg',
    'Ayam Cabe Garam': 'assets/images/menu/ayam_cabe_garam.jpg',
    'Ayam Crispy': 'assets/images/menu/ayam_crispy.jpg',
    'Ayam Crispy Rice': 'assets/images/menu/ayam_crispy.jpg',
    'Ayam Geprek Keju': 'assets/images/menu/nasi_ayam_geprek.jpg',
    'Ayam Geprek Original': 'assets/images/menu/nasi_ayam_geprek.jpg',
    'Ayam Katsu': 'assets/images/menu/chicken_katsu.jpg',
    'Ayam Lada Hitam': 'assets/images/menu/ayam_lada_hitam.jpg',
    'Ayam Sambal Ijo': 'assets/images/menu/ayam_sambal_ijo.jpg',
    'Ayam Saus Mentega': 'assets/images/menu/ayam_saus_mentega.jpg',
    'Ayam Teriyaki': 'assets/images/menu/nasi_ayam_teriyaki.jpg',
    'Bakso Goreng': 'assets/images/menu/bakso_goreng.jpg',
    'Bakwan Sayur': 'assets/images/menu/bakwan_sayur.jpg',
    'Banoffee Cup': 'assets/images/menu/banoffee.jpg',
    'Batagor': 'assets/images/menu/batagor.jpg',
    'Beef Teriyaki Rice': 'assets/images/menu/beef_teriyaki.jpg',
    'Black Tea Honey': 'assets/images/menu/black_tea_honey.jpg',
    'Brownies Fudge': 'assets/images/menu/brownies.jpg',
    'Cafe Latte': 'assets/images/menu/cafe_latte.jpg',
    'Cappuccino': 'assets/images/menu/cappuccino.jpg',
    'Cappuccino Dingin': 'assets/images/menu/cappuccino.jpg',
    'Chamomile Tea': 'assets/images/menu/chamomile_tea.jpg',
    'Cheesecake Cup': 'assets/images/menu/cheesecake.jpg',
    'Chicken Katsu Rice': 'assets/images/menu/chicken_katsu.jpg',
    'Chicken Nugget': 'assets/images/menu/chicken_nugget.jpg',
    'Cireng': 'assets/images/menu/cireng.jpg',
    'Cokelat Susu': 'assets/images/menu/cokelat_susu.jpg',
    'Cold Brew': 'assets/images/menu/cold_brew.jpg',
    'Dimsum Ayam': 'assets/images/menu/dimsum.jpg',
    'Dimsum Mini': 'assets/images/menu/dimsum.jpg',
    'Es Blue Ocean': 'assets/images/menu/es_blue_ocean.jpg',
    'Es Jeruk': 'assets/images/menu/es_jeruk.jpg',
    'Es Kopi Susu Gula Aren': 'assets/images/menu/es_kopi_susu.jpg',
    'Es Krim Cokelat': 'assets/images/menu/es_krim_cokelat.jpg',
    'Es Krim Vanilla': 'assets/images/menu/es_krim_vanilla.jpg',
    'Es Lemon': 'assets/images/menu/es_lemon.jpg',
    'Es Lychee': 'assets/images/menu/lychee_drink.jpg',
    'Es Mangga': 'assets/images/menu/es_mangga.jpg',
    'Es Matcha': 'assets/images/menu/matcha_latte.jpg',
    'Es Soda Gembira': 'assets/images/menu/es_soda_gembira.jpg',
    'Es Susu Regal': 'assets/images/menu/es_susu_regal.jpg',
    'Es Taro': 'assets/images/menu/es_taro.jpg',
    'Es Teh Manis': 'assets/images/menu/es_teh_manis.jpg',
    'Es Yakult Melon': 'assets/images/menu/es_yakult_melon.jpg',
    'Espresso': 'assets/images/menu/espresso.jpg',
    'Green Tea Latte': 'assets/images/menu/green_tea_latte.jpg',
    'Ikan Sambal Matah': 'assets/images/menu/ikan_sambal.jpg',
    'Jus Alpukat': 'assets/images/menu/jus_alpukat.jpg',
    'Jus Apel': 'assets/images/menu/jus_apel.jpg',
    'Jus Buah Naga': 'assets/images/menu/jus_buah_naga.jpg',
    'Jus Jambu': 'assets/images/menu/jus_jambu.jpg',
    'Jus Jeruk': 'assets/images/menu/jus_jeruk.jpg',
    'Jus Mangga': 'assets/images/menu/jus_mangga.jpg',
    'Jus Melon': 'assets/images/menu/jus_melon.jpg',
    'Jus Nanas': 'assets/images/menu/jus_nanas.jpg',
    'Jus Semangka': 'assets/images/menu/jus_semangka.jpg',
    'Jus Strawberry': 'assets/images/menu/jus_strawberry.jpg',
    'Kacang Bawang': 'assets/images/menu/kacang_bawang.jpg',
    'Kebab Mini': 'assets/images/menu/kebab.jpg',
    'Kentang Goreng': 'assets/images/menu/kentang_goreng.jpg',
    'Keripik Kentang': 'assets/images/menu/keripik_kentang.jpg',
    'Keripik Singkong Balado': 'assets/images/menu/keripik_singkong.jpg',
    'Kerupuk Udang': 'assets/images/menu/kerupuk_udang.jpg',
    'Kopi Caramel': 'assets/images/menu/kopi_caramel.jpg',
    'Kopi Hazelnut': 'assets/images/menu/kopi_hazelnut.jpg',
    'Kopi Pandan': 'assets/images/menu/kopi_pandan.jpg',
    'Kopi Susu Gula Aren': 'assets/images/menu/es_kopi_susu.jpg',
    'Lemon Tea': 'assets/images/menu/lemon_tea.jpg',
    'Lychee Tea': 'assets/images/menu/lychee_drink.jpg',
    'Mango Sago': 'assets/images/menu/mango_sago.jpg',
    'Martabak Telur Mini': 'assets/images/menu/martabak_telur.jpg',
    'Matcha Latte': 'assets/images/menu/matcha_latte.jpg',
    'Mie Aceh': 'assets/images/menu/mie_aceh.jpg',
    'Mie Ayam': 'assets/images/menu/mie_ayam.jpg',
    'Mie Ayam Jamur': 'assets/images/menu/mie_ayam.jpg',
    'Mie Carbonara': 'assets/images/menu/mie_carbonara.jpg',
    'Mie Goreng Jawa': 'assets/images/menu/mie_goreng.jpg',
    'Mie Goreng Seafood': 'assets/images/menu/mie_goreng.jpg',
    'Mie Kuah Kari': 'assets/images/menu/mie_kuah_kari.jpg',
    'Mie Pedas Level 3': 'assets/images/menu/mie_pedas.jpg',
    'Mie Sambal Matah': 'assets/images/menu/sambal_matah.jpg',
    'Mie Tek-Tek': 'assets/images/menu/mie_goreng.jpg',
    'Milk Tea': 'assets/images/menu/thai_tea.jpg',
    'Milkshake Vanilla': 'assets/images/menu/milkshake_vanilla.jpg',
    'Mocha Latte': 'assets/images/menu/mocha_latte.jpg',
    'Nasi Ayam Geprek': 'assets/images/menu/nasi_ayam_geprek.jpg',
    'Nasi Ayam Geprek Level 1': 'assets/images/menu/nasi_ayam_geprek.jpg',
    'Nasi Ayam Geprek Level 3': 'assets/images/menu/nasi_ayam_geprek.jpg',
    'Nasi Ayam Teriyaki': 'assets/images/menu/nasi_ayam_teriyaki.jpg',
    'Nasi Bakar': 'assets/images/menu/nasi_bakar.jpg',
    'Nasi Bakar Ayam': 'assets/images/menu/nasi_bakar.jpg',
    'Nasi Campur': 'assets/images/menu/nasi_campur.jpg',
    'Nasi Campur Nusantara': 'assets/images/menu/nasi_campur.jpg',
    'Nasi Goreng Spesial': 'assets/images/menu/nasi_goreng.jpg',
    'Nasi Padang': 'assets/images/menu/nasi_padang.jpg',
    'Nasi Rendang': 'assets/images/menu/nasi_rendang.jpg',
    'Nasi Sambal Matah': 'assets/images/menu/sambal_matah.jpg',
    'Nasi Sarden': 'assets/images/menu/nasi_sarden.jpg',
    'Nasi Telur Balado': 'assets/images/menu/nasi_telur_balado.jpg',
    'Onion Rings': 'assets/images/menu/onion_rings.jpg',
    'Paket Hemat Ayam Bakar': 'assets/images/menu/ayam_bakar_madu.jpg',
    'Paket Hemat Ayam Crispy': 'assets/images/menu/ayam_crispy.jpg',
    'Paket Hemat Ayam Geprek': 'assets/images/menu/nasi_ayam_geprek.jpg',
    'Paket Hemat Beef Teriyaki': 'assets/images/menu/beef_teriyaki.jpg',
    'Paket Hemat Katsu': 'assets/images/menu/chicken_katsu.jpg',
    'Paket Hemat Komplit': 'assets/images/menu/paket_komplit.jpg',
    'Paket Hemat Mie Ayam': 'assets/images/menu/mie_ayam.jpg',
    'Paket Hemat Mie Goreng': 'assets/images/menu/mie_goreng.jpg',
    'Paket Hemat Nasi Campur': 'assets/images/menu/nasi_campur.jpg',
    'Paket Hemat Nasi Goreng': 'assets/images/menu/nasi_goreng.jpg',
    'Peach Tea': 'assets/images/menu/lemon_tea.jpg',
    'Pempek Mini': 'assets/images/menu/pempek.jpg',
    'Pisang Goreng': 'assets/images/menu/pisang_goreng.jpg',
    'Pizza Slice': 'assets/images/menu/pizza_slice.jpg',
    'Popcorn Caramel': 'assets/images/menu/popcorn_caramel.jpg',
    'Puding Cokelat': 'assets/images/menu/puding_cokelat.jpg',
    'Puding Mangga': 'assets/images/menu/puding_mangga.jpg',
    'Risoles Mayo': 'assets/images/menu/risoles.jpg',
    'Roti Bakar Cokelat': 'assets/images/menu/roti_bakar.jpg',
    'Salad Buah': 'assets/images/menu/salad_buah.jpg',
    'Sate Taichan': 'assets/images/menu/sate_taichan.jpg',
    'Singkong Keju': 'assets/images/menu/singkong_keju.jpg',
    'Siomay Bandung': 'assets/images/menu/siomay.jpg',
    'Sosis Bakar': 'assets/images/menu/sosis_bakar.jpg',
    'Susu Cokelat': 'assets/images/menu/cokelat_susu.jpg',
    'Tahu Crispy': 'assets/images/menu/tahu_crispy.jpg',
    'Tahu Isi': 'assets/images/menu/tahu_isi.jpg',
    'Takoyaki': 'assets/images/menu/takoyaki.jpg',
    'Teh Manis Dingin': 'assets/images/menu/es_teh_manis.jpg',
    'Teh Manis Panas': 'assets/images/menu/teh_manis_panas.jpg',
    'Tempe Mendoan': 'assets/images/menu/tempe_mendoan.jpg',
    'Thai Tea': 'assets/images/menu/thai_tea.jpg',
    'Tiramisu Cup': 'assets/images/menu/tiramisu.jpg',
    'Tteokbokki': 'assets/images/menu/tteokbokki.jpg',
    'Yakult Lychee': 'assets/images/menu/lychee_drink.jpg',
  };

  /// Aset fallback per ikon kategori (dipakai MenuImage saat gambar gagal).
  static const Map<String, String> _iconAsset = {
    'rice_bowl': 'assets/images/menu/nasi_goreng.jpg',
    'ramen_dining': 'assets/images/menu/mie_goreng.jpg',
    'coffee': 'assets/images/menu/es_kopi_susu.jpg',
    'local_cafe': 'assets/images/menu/es_teh_manis.jpg',
    'local_drink': 'assets/images/menu/jus_mangga.jpg',
    'icecream': 'assets/images/menu/es_soda_gembira.jpg',
    'cake': 'assets/images/menu/brownies.jpg',
    'restaurant': 'assets/images/menu/nasi_ayam_geprek.jpg',
    'tapas': 'assets/images/menu/bakwan_sayur.jpg',
    'fastfood': 'assets/images/menu/nasi_ayam_geprek.jpg',
  };

  static const Map<String, List<String>> _catalog = {
    'Makanan': [
      'Nasi Ayam Geprek',
      'Nasi Goreng Spesial',
      'Ayam Crispy Rice',
      'Beef Teriyaki Rice',
      'Chicken Katsu Rice',
      'Nasi Campur Nusantara',
      'Nasi Bakar Ayam',
      'Ikan Sambal Matah',
      'Nasi Rendang',
      'Nasi Telur Balado'
    ],
    'Minuman': [
      'Es Teh Manis',
      'Es Kopi Susu Gula Aren',
      'Cappuccino Dingin',
      'Cokelat Susu',
      'Matcha Latte',
      'Lemon Tea',
      'Yakult Lychee',
      'Susu Cokelat',
      'Thai Tea',
      'Milkshake Vanilla'
    ],
    'Nasi': [
      'Nasi Ayam Geprek Level 1',
      'Nasi Ayam Geprek Level 3',
      'Nasi Rendang',
      'Nasi Padang',
      'Nasi Bakar',
      'Nasi Campur',
      'Nasi Telur Balado',
      'Nasi Sarden',
      'Nasi Sambal Matah',
      'Nasi Ayam Teriyaki'
    ],
    'Mie': [
      'Mie Goreng Jawa',
      'Mie Ayam',
      'Mie Pedas Level 3',
      'Mie Aceh',
      'Mie Kuah Kari',
      'Mie Tek-Tek',
      'Mie Goreng Seafood',
      'Mie Sambal Matah',
      'Mie Ayam Jamur',
      'Mie Carbonara'
    ],
    'Ayam': [
      'Ayam Geprek Original',
      'Ayam Geprek Keju',
      'Ayam Crispy',
      'Ayam Sambal Ijo',
      'Ayam Bakar Madu',
      'Ayam Katsu',
      'Ayam Teriyaki',
      'Ayam Cabe Garam',
      'Ayam Lada Hitam',
      'Ayam Saus Mentega'
    ],
    'Gorengan': [
      'Bakwan Sayur',
      'Tempe Mendoan',
      'Tahu Isi',
      'Pisang Goreng',
      'Cireng',
      'Risoles Mayo',
      'Kentang Goreng',
      'Singkong Keju',
      'Bakso Goreng',
      'Tahu Crispy'
    ],
    'Snacks': [
      'Kerupuk Udang',
      'Keripik Kentang',
      'Keripik Singkong Balado',
      'Kacang Bawang',
      'Popcorn Caramel',
      'Dimsum Mini',
      'Sosis Bakar',
      'Onion Rings',
      'Chicken Nugget',
      'Roti Bakar Cokelat'
    ],
    'Dessert': [
      'Puding Cokelat',
      'Puding Mangga',
      'Brownies Fudge',
      'Cheesecake Cup',
      'Mango Sago',
      'Salad Buah',
      'Es Krim Vanilla',
      'Es Krim Cokelat',
      'Banoffee Cup',
      'Tiramisu Cup'
    ],
    'Kopi': [
      'Americano',
      'Cappuccino',
      'Cafe Latte',
      'Mocha Latte',
      'Espresso',
      'Kopi Susu Gula Aren',
      'Kopi Caramel',
      'Kopi Hazelnut',
      'Kopi Pandan',
      'Cold Brew'
    ],
    'Teh': [
      'Teh Manis Panas',
      'Teh Manis Dingin',
      'Lemon Tea',
      'Lychee Tea',
      'Peach Tea',
      'Thai Tea',
      'Milk Tea',
      'Green Tea Latte',
      'Chamomile Tea',
      'Black Tea Honey'
    ],
    'Jus': [
      'Jus Alpukat',
      'Jus Mangga',
      'Jus Jeruk',
      'Jus Jambu',
      'Jus Nanas',
      'Jus Semangka',
      'Jus Melon',
      'Jus Strawberry',
      'Jus Buah Naga',
      'Jus Apel'
    ],
    'Minuman Dingin': [
      'Es Jeruk',
      'Es Lemon',
      'Es Mangga',
      'Es Yakult Melon',
      'Es Lychee',
      'Es Soda Gembira',
      'Es Susu Regal',
      'Es Taro',
      'Es Matcha',
      'Es Blue Ocean'
    ],
    'Paket Hemat': [
      'Paket Hemat Ayam Geprek',
      'Paket Hemat Nasi Goreng',
      'Paket Hemat Mie Ayam',
      'Paket Hemat Katsu',
      'Paket Hemat Ayam Bakar',
      'Paket Hemat Beef Teriyaki',
      'Paket Hemat Ayam Crispy',
      'Paket Hemat Nasi Campur',
      'Paket Hemat Mie Goreng',
      'Paket Hemat Komplit'
    ],
    'Aneka': [
      'Dimsum Ayam',
      'Siomay Bandung',
      'Batagor',
      'Pempek Mini',
      'Sate Taichan',
      'Kebab Mini',
      'Martabak Telur Mini',
      'Pizza Slice',
      'Tteokbokki',
      'Takoyaki'
    ],
  };

  static const Map<String, int> _basePrice = {
    'Makanan': 18000,
    'Minuman': 7000,
    'Nasi': 18000,
    'Mie': 15000,
    'Ayam': 18000,
    'Gorengan': 7000,
    'Snacks': 8000,
    'Dessert': 12000,
    'Kopi': 14000,
    'Teh': 8000,
    'Jus': 10000,
    'Minuman Dingin': 10000,
    'Paket Hemat': 22000,
    'Aneka': 15000,
  };

  static const Map<String, String> _iconMap = {
    'Makanan': 'restaurant',
    'Minuman': 'local_cafe',
    'Nasi': 'rice_bowl',
    'Mie': 'ramen_dining',
    'Ayam': 'restaurant',
    'Gorengan': 'tapas',
    'Snacks': 'tapas',
    'Dessert': 'cake',
    'Kopi': 'coffee',
    'Teh': 'local_cafe',
    'Jus': 'local_drink',
    'Minuman Dingin': 'icecream',
    'Paket Hemat': 'fastfood',
    'Aneka': 'fastfood',
  };
}
