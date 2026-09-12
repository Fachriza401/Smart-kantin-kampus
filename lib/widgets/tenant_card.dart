import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../models/tenant.dart';
import '../theme/app_theme.dart';

class TenantCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback onTap;
  final double width;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.onTap,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 145,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: tenant.imageUrl.isNotEmpty
                ? Image.network(
                    tenant.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Icon(
                      DummyData.iconFor(tenant.icon),
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    DummyData.iconFor(tenant.icon),
                    size: 40,
                    color: Colors.white,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tenant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppColors.tertiary),
                      const SizedBox(width: 2),
                      Text('${tenant.rating}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      const Text('•',
                          style: TextStyle(color: AppColors.outlineVariant)),
                      const SizedBox(width: 6),
                      Text(
                        tenant.etaText,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
