import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/excuse.dart';
import '../../../core/providers/excuse_provider.dart';
import '../../../core/theme/app_theme.dart';

class ExcuseDetailScreen extends ConsumerWidget {
  final String excuseId;

  const ExcuseDetailScreen({super.key, required this.excuseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final excuseAsync = ref.watch(excuseDetailProvider(excuseId));
    final dateFormat = DateFormat('dd.MM.yyyy');
    final dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Entschuldigung')),
      body: excuseAsync.when(
        data: (excuse) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status badge
              Center(
                child: Chip(
                  avatar: Icon(
                    _statusIcon(excuse.status),
                    color: _statusColor(excuse.status),
                    size: 18,
                  ),
                  label: Text(
                    _statusLabel(excuse.status),
                    style: TextStyle(
                      color: _statusColor(excuse.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: _statusColor(excuse.status).withAlpha(25),
                  side: BorderSide(color: _statusColor(excuse.status).withAlpha(80)),
                ),
              ),
              const SizedBox(height: 24),

              // Student
              if (excuse.studentName != null)
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Schüler/in',
                  value: excuse.studentName!,
                ),

              // Date range
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Zeitraum',
                value: '${dateFormat.format(excuse.dateFrom)} – ${dateFormat.format(excuse.dateTo)}',
              ),

              // Submission type
              _DetailRow(
                icon: excuse.submissionType == ExcuseSubmission.digital
                    ? Icons.send
                    : Icons.print,
                label: 'Einreichung',
                value: excuse.submissionType == ExcuseSubmission.digital
                    ? 'Digital'
                    : 'Papier',
              ),

              // Reason
              if (excuse.reason != null)
                _DetailRow(
                  icon: Icons.note_outlined,
                  label: 'Grund',
                  value: excuse.reason!,
                ),

              // Attestation
              _DetailRow(
                icon: Icons.medical_information_outlined,
                label: 'Attest',
                value: excuse.attestationProvided ? 'Ja' : 'Nein',
              ),

              // Linked absences
              if (excuse.linkedAbsences != null && excuse.linkedAbsences! > 0)
                _DetailRow(
                  icon: Icons.link,
                  label: 'Verknüpfte Fehlstunden',
                  value: '${excuse.linkedAbsences}',
                ),

              // Submitted at
              _DetailRow(
                icon: Icons.access_time,
                label: 'Eingereicht',
                value: dateTimeFormat.format(excuse.submittedAt),
              ),

              // Approved info
              if (excuse.approvedAt != null)
                _DetailRow(
                  icon: Icons.check_circle_outline,
                  label: excuse.status == ExcuseStatus.approved
                      ? 'Genehmigt am'
                      : 'Bearbeitet am',
                  value: dateTimeFormat.format(excuse.approvedAt!),
                ),

              const SizedBox(height: 32),

              // Teacher/admin actions
              if ((auth.isTeacher || auth.isAdmin) &&
                  excuse.status == ExcuseStatus.pending) ...[
                FilledButton.icon(
                  onPressed: () => _approve(context, ref),
                  icon: const Icon(Icons.check),
                  label: const Text('Genehmigen'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.approved,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, ref),
                  icon: const Icon(Icons.close),
                  label: const Text('Ablehnen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rejected,
                  ),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fehler: $err'),
              TextButton(
                onPressed: () => ref.invalidate(excuseDetailProvider(excuseId)),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(excuseActionsProvider).approve(excuseId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entschuldigung genehmigt')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entschuldigung ablehnen'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Begründung',
            hintText: 'Grund für die Ablehnung...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rejected),
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await ref.read(excuseActionsProvider).reject(excuseId, result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entschuldigung abgelehnt')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }

  IconData _statusIcon(ExcuseStatus s) => switch (s) {
        ExcuseStatus.pending => Icons.pending_outlined,
        ExcuseStatus.approved => Icons.check_circle_outline,
        ExcuseStatus.rejected => Icons.cancel_outlined,
      };

  Color _statusColor(ExcuseStatus s) => switch (s) {
        ExcuseStatus.pending => AppColors.pending,
        ExcuseStatus.approved => AppColors.approved,
        ExcuseStatus.rejected => AppColors.rejected,
      };

  String _statusLabel(ExcuseStatus s) => switch (s) {
        ExcuseStatus.pending => 'Ausstehend',
        ExcuseStatus.approved => 'Genehmigt',
        ExcuseStatus.rejected => 'Abgelehnt',
      };
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                )),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
