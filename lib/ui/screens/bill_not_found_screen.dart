import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BillNotFoundScreen extends StatelessWidget {
  const BillNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tagihan tidak ditemukan. Mungkin sudah dihapus.'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ke daftar tagihan'),
            ),
          ],
        ),
      ),
    );
  }
}
