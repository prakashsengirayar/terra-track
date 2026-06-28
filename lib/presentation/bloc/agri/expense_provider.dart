// lib/presentation/bloc/agri/expense_provider.dart
//
// Riverpod providers for the Expense entity: a real-time list stream
// scoped by owner, and a form-submission notifier exposing AsyncValue<void>
// for add/update/delete.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/agri_entities.dart';
import 'agri_repository_providers.dart';

final expensesStreamProvider =
    StreamProvider.family<List<ExpenseEntity>, String>((ref, ownerId) {
  return ref.watch(expenseRepositoryProvider).watchAll(ownerId);
});

class ExpenseFormNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ExpenseFormNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<bool> addExpense(ExpenseEntity expense) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(expenseRepositoryProvider).addExpense(expense);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseEntity expense) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(expenseRepositoryProvider).updateExpense(expense);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(expenseRepositoryProvider).deleteExpense(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final expenseFormProvider =
    StateNotifierProvider.autoDispose<ExpenseFormNotifier, AsyncValue<void>>(
  (ref) => ExpenseFormNotifier(ref),
);
