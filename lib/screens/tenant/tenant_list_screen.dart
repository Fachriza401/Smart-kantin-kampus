import 'package:flutter/material.dart';

import '../../data/dummy_data.dart';
import '../../theme/app_theme.dart';
import 'tenant_detail_screen.dart';

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Tenant')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: DummyData.tenants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final tenant = DummyData.tenants[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TenantDetailScreen(tenant: tenant),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: tenant.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              tenant.imageUrl,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              errorBuilder: (_, __, ___) => Icon(
                                DummyData.iconFor(tenant.icon),
                                color: AppColors.primary,
                                size: 34,
                              ),
                            ),
                          )
                        : Icon(
                            DummyData.iconFor(tenant.icon),
                            color: AppColors.primary,
                            size: 34,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tenant.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: AppColors.tertiary),
                            const SizedBox(width: 2),
                            Text('${tenant.rating} (${tenant.reviewCount})',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            const Text('•'),
                            const SizedBox(width: 6),
                            Text(tenant.etaText,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tenant.isOpen
                                ? AppColors.primaryContainer.withOpacity(0.15)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tenant.isOpen ? 'Buka' : 'Tutup',
                            style: TextStyle(
                                fontSize: 11,
                                color: tenant.isOpen
                                    ? AppColors.primary
                                    : AppColors.error,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.outline),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
