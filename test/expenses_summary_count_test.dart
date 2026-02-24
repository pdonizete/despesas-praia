import 'dart:io';

import 'package:despesas_praia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late LocalStorage storage;
  late AppState state;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('despesas_praia_summary_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('expenses_summary_count_test');
    storage = LocalStorage(box);
    state = AppState(storage)..load();

    await state.updatePeople(['Ana', 'Bia']);
    await state.addExpense(
      value: 100,
      category: Category.mercado,
      paidBy: 0,
      date: DateTime(2026, 2, 1),
      description: 'Compras',
    );
    await state.addExpense(
      value: 50,
      category: Category.mercado,
      paidBy: 1,
      date: DateTime(2026, 2, 2),
      description: 'Padaria',
    );
    await state.addExpense(
      value: 40,
      category: Category.passeio,
      paidBy: 0,
      date: DateTime(2026, 2, 3),
      description: 'Passeio',
    );
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('expenses_summary_count_test');
    await tempDir.delete(recursive: true);
  });

  testWidgets('exibe resumo de contagem total e filtrada na lista de despesas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ExpensesPage(state: state))),
    );

    expect(find.text('Mostrando 3 de 3 despesas (100%)'), findsOneWidget);

    await tester.tap(find.text('Todas').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado').last);
    await tester.pumpAndSettle();

    expect(find.text('Mostrando 2 de 3 despesas (67%)'), findsOneWidget);
  });

  testWidgets('mantém resumo sem percentual quando total de despesas é zero', (
    tester,
  ) async {
    final emptyBox = await Hive.openBox('expenses_summary_count_test_empty');
    final emptyState = AppState(LocalStorage(emptyBox))..load();
    await emptyState.updatePeople(['Ana']);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ExpensesPage(state: emptyState))),
    );

    expect(find.text('Mostrando 0 de 0 despesas'), findsOneWidget);
    expect(find.textContaining('(0%)'), findsNothing);

    await emptyBox.close();
    await Hive.deleteBoxFromDisk('expenses_summary_count_test_empty');
  });
}
