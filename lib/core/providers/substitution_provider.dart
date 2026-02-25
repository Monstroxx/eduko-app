import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_service.dart';
import '../models/substitution.dart';

/// Selected date range for substitutions.
final substitutionDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Substitutions for the selected date.
final substitutionsProvider =
    FutureProvider.autoDispose<List<Substitution>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final date = ref.watch(substitutionDateProvider);

  final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final response = await api.getSubstitutions(date: dateStr);

  final list = response.data as List;
  return list.map((e) => Substitution.fromJson(e as Map<String, dynamic>)).toList();
});
