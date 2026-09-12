import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu lokasi & estimasi waktu penjemputan pesanan di kantin kampus.
class PickupLocationCard extends StatelessWidget {
  final String pickupTime;
  const PickupLocationCard({super.key, required this.pickupTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFECFDF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Lokasi Penjemputan',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: AppColors.primary, size: 22),
                    SizedBox(height: 2),
                    Text(
                      'Kantin',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kantin Kampus — Lantai 1, Gedung Serba Guna',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Area pengambilan di counter tenant. Bawa nomor antrean saat mengambil.',
                      style: TextStyle(
                          color: AppColors.onSurfaceMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 16, color: AppColors.onSurfaceMuted),
              const SizedBox(width: 6),
              Text(
                'Estimasi siap: $pickupTime',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}