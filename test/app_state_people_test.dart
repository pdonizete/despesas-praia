import 'dart:io';

import 'package:despesas_praia/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late LocalStorage storage;
  late AppState state;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('despesas_praia_people_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('app_state_people_test');
    storage = LocalStorage(box);
    state = AppState(storage)..load();
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('app_state_people_test');
    await tempDir.delete(recursive: true);
  });

  test('LocalStorage aceita lista dinâmica de pessoas', () async {
    await storage.savePeople(['Ana', 'Bia', 'Caio', 'Duda', 'Enzo']);

    expect(storage.people, ['Ana', 'Bia', 'Caio', 'Duda', 'Enzo']);
  });

  test('remove pessoa com reatribuição e reindexa paidBy', () async {
    await state.updatePeople(['A', 'B', 'C']);

    await state.addExpense(
      value: 30,
      category: Category.outros,
      paidBy: 1,
      date: DateTime(2026, 2, 1),
    );
    await state.addExpense(
      value: 20,
      category: Category.outros,
      paidBy: 2,
      date: DateTime(2026, 2, 2),
    );

    await state.removePerson(1, reassignExpensesTo: 0);

    expect(state.people, ['A', 'C']);
    expect(state.expenses[0].paidBy, 0);
    expect(state.expenses[1].paidBy, 1);
  });

  test('remove pessoa com despesas sem reatribuição lança erro', () async {
    await state.updatePeople(['A', 'B']);
    await state.addExpense(
      value: 10,
      category: Category.outros,
      paidBy: 1,
      date: DateTime(2026, 2, 1),
    );

    expect(() => state.removePerson(1), throwsA(isA<StateError>()));
  });
}
