import 'package:despesas_praia/main.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _expense({
  required String id,
  required Category category,
  required double value,
  DateTime? date,
}) {
  return Expense(
    id: id,
    value: value,
    category: category,
    paidBy: 0,
    date: date ?? DateTime(2026, 2, 1),
    description: '',
  );
}

void main() {
  test('categoriesInExpenses retorna categorias usadas na ordem do enum', () {
    final expenses = [
      _expense(id: '1', category: Category.outros, value: 10),
      _expense(id: '2', category: Category.alimentacao, value: 20),
      _expense(id: '3', category: Category.outros, value: 30),
      _expense(id: '4', category: Category.transporte, value: 40),
    ];

    final categories = categoriesInExpenses(expenses);

    expect(categories, [
      Category.alimentacao,
      Category.transporte,
      Category.outros,
    ]);
  });

  test(
    'applyExpenseCategoryFilter filtra por categoria quando selecionada',
    () {
      final expenses = [
        _expense(id: '1', category: Category.alimentacao, value: 10),
        _expense(id: '2', category: Category.transporte, value: 20),
        _expense(id: '3', category: Category.alimentacao, value: 30),
      ];

      final filtered = applyExpenseCategoryFilter(
        expenses,
        Category.alimentacao,
      );

      expect(filtered.map((e) => e.id), ['1', '3']);
    },
  );

  test('applyExpenseCategoryFilter mantém lista quando categoria é nula', () {
    final expenses = [
      _expense(id: '1', category: Category.alimentacao, value: 10),
      _expense(id: '2', category: Category.transporte, value: 20),
    ];

    final filtered = applyExpenseCategoryFilter(expenses, null);

    expect(filtered, expenses);
  });

  test('sortExpenses ordena por data recente primeiro por padrão', () {
    final expenses = [
      _expense(
        id: 'old',
        category: Category.alimentacao,
        value: 50,
        date: DateTime(2026, 1, 1),
      ),
      _expense(
        id: 'new',
        category: Category.alimentacao,
        value: 10,
        date: DateTime(2026, 3, 1),
      ),
    ];

    final sorted = sortExpenses(expenses);

    expect(sorted.map((e) => e.id), ['new', 'old']);
  });

  test('sortExpenses ordena por valor maior→menor com desempate por data', () {
    final expenses = [
      _expense(
        id: 'same-older',
        category: Category.alimentacao,
        value: 100,
        date: DateTime(2026, 1, 1),
      ),
      _expense(
        id: 'same-newer',
        category: Category.alimentacao,
        value: 100,
        date: DateTime(2026, 2, 1),
      ),
      _expense(
        id: 'highest',
        category: Category.alimentacao,
        value: 200,
        date: DateTime(2026, 1, 15),
      ),
    ];

    final sorted = sortExpenses(
      expenses,
      option: ExpenseSortOption.valueHighToLow,
    );

    expect(sorted.map((e) => e.id), ['highest', 'same-newer', 'same-older']);
  });

  test('sortExpenses ordena por valor menor→maior com desempate por data', () {
    final expenses = [
      _expense(
        id: 'same-older',
        category: Category.alimentacao,
        value: 10,
        date: DateTime(2026, 1, 1),
      ),
      _expense(
        id: 'same-newer',
        category: Category.alimentacao,
        value: 10,
        date: DateTime(2026, 2, 1),
      ),
      _expense(
        id: 'highest',
        category: Category.alimentacao,
        value: 50,
        date: DateTime(2026, 1, 15),
      ),
    ];

    final sorted = sortExpenses(
      expenses,
      option: ExpenseSortOption.valueLowToHigh,
    );

    expect(sorted.map((e) => e.id), ['same-newer', 'same-older', 'highest']);
  });
}
