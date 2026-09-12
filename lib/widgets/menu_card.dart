import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'menu_image.dart';

class MenuListTile extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final bool? isFavorite;
  final Future<void> Function()? onToggleFavorite;

  const MenuListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onAdd,
    this.isFavorite,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final habis = !item.tersedia;
    return Opacity(
      opacity: habis ? 0.65 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: habis
                  ? AppColors.outlineVariant
                  : AppColors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  MenuImage(
                    imageUrl: item.imageUrl,
                    icon: item.icon,
                    size: 64,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  if (habis)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              'HABIS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isFavorite != null)
                          GestureDetector(
                            onTap: onToggleFavorite,
                            child: Icon(
                              isFavorite!
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
                              color: isFavorite!
                                  ? AppColors.rose
                                  : AppColors.onSurfaceMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(item.price),
                      style: TextStyle(
                        color: habis
                            ? AppColors.onSurfaceMuted
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (habis)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    'Habis',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (onAdd != null)
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  onPressed: onAdd,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
