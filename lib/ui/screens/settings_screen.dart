import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagihan_air/state/app_info_provider.dart';
import 'package:tagihan_air/state/database_providers.dart';
import 'package:tagihan_air/ui/widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const SectionHeader('Tentang'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versi'),
            subtitle: Text(
              info == null ? '' : '${info.version} (${info.buildNumber})',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Database'),
            subtitle: Text('${ref.watch(databaseConfigProvider)}'),
          ),
        ],
      ),
    );
  }
}
