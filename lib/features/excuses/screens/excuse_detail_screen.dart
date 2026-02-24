import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ExcuseDetailScreen extends ConsumerWidget {
  final String excuseId;

  const ExcuseDetailScreen({super.key, required this.excuseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // TODO: Fetch excuse by ID
    return Scaffold(
      appBar: AppBar(title: const Text('Entschuldigung')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status badge
            // Date range
            // Reason
            // Submission type
            // Attestation info
            // Linked absences
            const Center(child: Text('Details laden...')),

            const Spacer(),

            // Teacher actions
            if (auth.isTeacher || auth.isAdmin) ...[
              FilledButton.icon(
                onPressed: () {
                  // TODO: approve excuse
                },
                icon: const Icon(Icons.check),
                label: const Text('Genehmigen'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: reject excuse
                },
                icon: const Icon(Icons.close),
                label: const Text('Ablehnen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rejected,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  // TODO: mark as paper received
                },
                icon: const Icon(Icons.description),
                label: const Text('Papier erhalten'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
