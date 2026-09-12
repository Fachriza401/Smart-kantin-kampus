import 'package:flutter/material.dart';

import '../../db/db_helper.dart';
import '../../models/promo.dart';
import '../../theme/app_theme.dart';
import '../tenant/promo_menu_screen.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  late Future<List<Promo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Promo>> _load() async {
    final promos = await DBHelper.instance.getAllPromos();
    return promos.where((promo) => promo.active).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher & Promo')),
      body: FutureBuilder<List<Promo>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final promos = snapshot.data ?? const <Promo>[];
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientSoftGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_offer_outlined,
                      size: 52,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Belum ada voucher aktif',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cek kembali nanti ya!',
                    style: TextStyle(color: AppColors.onSurfaceMuted),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final promo = promos[index];
              return _VoucherCard(promo: promo);
            },
          );
        },
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Promo promo;
  const _VoucherCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PromoMenuScreen(promo: promo),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Discount side
              Container(
                width: 92,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPromo,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'DISKON',
                      style: TextStyle(
                        color: AppColors.onTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${promo.discount.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.onTertiary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promo.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.onSurfaceMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Lihat Menu',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'AKTIF',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
