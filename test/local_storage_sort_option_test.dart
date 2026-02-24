import 'dart:io';

import 'package:despesas_praia/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box box;
  late LocalStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('despesas_praia_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox('local_storage_sort_option_test');
    storage = LocalStorage(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('local_storage_sort_option_test');
    await tempDir.delete(recursive: true);
  });

  test('retorna dateRecentFirst quando não há valor salvo', () {
    final option = storage.loadExpenseSortOption();

    expect(option, ExpenseSortOption.dateRecentFirst);
  });

  test('retorna opção correta para valor válido salvo', () async {
    await storage.saveExpenseSortOption(ExpenseSortOption.valueHighToLow.name);

    final option = storage.loadExpenseSortOption();

    expect(option, ExpenseSortOption.valueHighToLow);
  });

  test('retorna dateRecentFirst para valor inválido salvo', () async {
    await box.put('expenses_sort_option', 'valor_invalido');

    final option = storage.loadExpenseSortOption();

    expect(option, ExpenseSortOption.dateRecentFirst);
  });
}
