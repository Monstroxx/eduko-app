import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CreateExcuseScreen extends ConsumerStatefulWidget {
  const CreateExcuseScreen({super.key});

  @override
  ConsumerState<CreateExcuseScreen> createState() => _CreateExcuseScreenState();
}

class _CreateExcuseScreenState extends ConsumerState<CreateExcuseScreen> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _submissionType = 'digital';
  final _reasonController = TextEditingController();
  bool _loading = false;

  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entschuldigung erstellen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date range
            Text('Zeitraum', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_dateFrom != null
                        ? _dateFormat.format(_dateFrom!)
                        : 'Von'),
                    onPressed: () => _pickDate(isFrom: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_dateTo != null
                        ? _dateFormat.format(_dateTo!)
                        : 'Bis'),
                    onPressed: () => _pickDate(isFrom: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Submission type
            Text('Einreichungsart', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'digital', label: Text('Digital'), icon: Icon(Icons.send)),
                ButtonSegment(value: 'paper', label: Text('Papier'), icon: Icon(Icons.print)),
              ],
              selected: {_submissionType},
              onSelectionChanged: (s) => setState(() => _submissionType = s.first),
            ),

            const SizedBox(height: 24),

            // Reason
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Grund (optional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Actions
            if (_submissionType == 'paper') ...[
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: generate and download PDF
                },
                icon: const Icon(Icons.download),
                label: const Text('Formular als PDF herunterladen'),
              ),
              const SizedBox(height: 12),
            ],

            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_submissionType == 'digital'
                      ? 'Digital einreichen'
                      : 'Als Papier eingereicht markieren'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // respect deadline
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
          if (_dateTo != null && _dateTo!.isBefore(picked)) _dateTo = picked;
        } else {
          _dateTo = picked;
          if (_dateFrom != null && _dateFrom!.isAfter(picked)) _dateFrom = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_dateFrom == null || _dateTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Zeitraum auswählen')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // TODO: call API to create excuse
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
