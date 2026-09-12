import 'package:flutter/material.dart';

class TopupScreen extends StatelessWidget {
  const TopupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saldo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Top Up saldo sudah tidak digunakan pada versi guest checkout.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
