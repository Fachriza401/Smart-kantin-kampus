import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';

/// Layar admin untuk melihat daftar tenant terdaftar.
/// Saat ini data tenant masih statis dari DummyData (read-only).
class TenantManageScreen extends StatelessWidget {
  const TenantManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Tenant')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: DummyData.tenants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final tenant = DummyData.tenants[i];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: tenant.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            tenant.imageUrl,
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            errorBuilder: (_, __, ___) => Icon(
                              DummyData.iconFor(tenant.icon),
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Icon(
                          DummyData.iconFor(tenant.icon),
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tenant.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${tenant.rating} (${tenant.reviewCount} ulasan)',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                ),
                const Icon(Icons.storefront,
                    color: AppColors.primaryContainer, size: 28),
              ],
            ),
          );
        },
      ),
    );
  }
}
