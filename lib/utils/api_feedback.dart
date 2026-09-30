import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';

/// Menampilkan pesan [ApiException] sebagai SnackBar merah.
void showApiError(BuildContext context, ApiException error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(error.message), backgroundColor: AppColors.error),
    );
}
