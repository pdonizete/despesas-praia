import 'package:despesas_praia/main.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _expense({
  required String id,
  required Category category,
  required double value,
  DateTime? date,
  int paidBy = 0,
}) {
  return Expense(
    id: id,
    value: value,
    category: category,
    paidBy: paidBy,
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

  test('applyExpensePeriodFilter com Tudo mantém todas as despesas', () {
    final expenses = [
      _expense(id: '1', category: Category.alimentacao, value: 10),
      _expense(id: '2', category: Category.transporte, value: 20),
    ];

    final filtered = applyExpensePeriodFilter(
      expenses,
      ExpensePeriodFilter.all,
      now: DateTime(2026, 2, 24),
    );

    expect(filtered.map((e) => e.id), ['1', '2']);
  });

  test('applyExpensePeriodFilter de 7 dias usa janela inclusiva por dia', () {
    final expenses = [
      _expense(
        id: 'inside-start',
        category: Category.alimentacao,
        value: 10,
        date: DateTime(2026, 2, 18),
      ),
      _expense(
        id: 'inside-end',
        category: Category.mercado,
        value: 20,
        date: DateTime(2026, 2, 24),
      ),
      _expense(
        id: 'outside-before',
        category: Category.outros,
        value: 30,
        date: DateTime(2026, 2, 17),
      ),
    ];

    final filtered = applyExpensePeriodFilter(
      expenses,
      ExpensePeriodFilter.last7Days,
      now: DateTime(2026, 2, 24, 23, 59),
    );

    expect(filtered.map((e) => e.id), ['inside-start', 'inside-end']);
  });

  test(
    'applyExpensePeriodFilter Hoje considera dia fechado (ignora horário)',
    () {
      final expenses = [
        _expense(
          id: 'today-early',
          category: Category.alimentacao,
          value: 10,
          date: DateTime(2026, 2, 24, 0, 1),
        ),
        _expense(
          id: 'today-late',
          category: Category.transporte,
          value: 20,
          date: DateTime(2026, 2, 24, 23, 59),
        ),
        _expense(
          id: 'yesterday',
          category: Category.outros,
          value: 30,
          date: DateTime(2026, 2, 23, 23, 59),
        ),
      ];

      final filtered = applyExpensePeriodFilter(
        expenses,
        ExpensePeriodFilter.today,
        now: DateTime(2026, 2, 24, 12, 0),
      );

      expect(filtered.map((e) => e.id), ['today-early', 'today-late']);
    },
  );

  test(
    'pipeline período -> categoria -> ordenação mantém resultado esperado',
    () {
      final expenses = [
        _expense(
          id: 'a',
          category: Category.alimentacao,
          value: 50,
          date: DateTime(2026, 2, 24),
        ),
        _expense(
          id: 'b',
          category: Category.alimentacao,
          value: 10,
          date: DateTime(2026, 2, 20),
        ),
        _expense(
          id: 'c',
          category: Category.transporte,
          value: 200,
          date: DateTime(2026, 2, 23),
        ),
        _expense(
          id: 'd',
          category: Category.alimentacao,
          value: 99,
          date: DateTime(2026, 1, 10),
        ),
      ];

      final byPeriod = applyExpensePeriodFilter(
        expenses,
        ExpensePeriodFilter.last7Days,
        now: DateTime(2026, 2, 24),
      );
      final byCategory = applyExpenseCategoryFilter(
        byPeriod,
        Category.alimentacao,
      );
      final sorted = sortExpenses(
        byCategory,
        option: ExpenseSortOption.valueLowToHigh,
      );

      expect(sorted.map((e) => e.id), ['b', 'a']);
    },
  );

  test('applyExpensePaidByFilter filtra por pagador quando selecionado', () {
    final expenses = [
      _expense(id: '1', category: Category.alimentacao, value: 10, paidBy: 0),
      _expense(id: '2', category: Category.transporte, value: 20, paidBy: 1),
      _expense(id: '3', category: Category.mercado, value: 30, paidBy: 1),
    ];

    final filtered = applyExpensePaidByFilter(expenses, 1);

    expect(filtered.map((e) => e.id), ['2', '3']);
  });

  test('applyExpensePaidByFilter mantém lista quando pagador é nulo', () {
    final expenses = [
      _expense(id: '1', category: Category.alimentacao, value: 10, paidBy: 0),
      _expense(id: '2', category: Category.transporte, value: 20, paidBy: 1),
    ];

    final filtered = applyExpensePaidByFilter(expenses, null);

    expect(filtered, expenses);
  });

  test(
    'pipeline período -> categoria -> pagador -> ordenação mantém resultado esperado',
    () {
      final expenses = [
        _expense(
          id: 'a',
          category: Category.alimentacao,
          value: 50,
          date: DateTime(2026, 2, 24),
          paidBy: 1,
        ),
        _expense(
          id: 'b',
          category: Category.alimentacao,
          value: 10,
          date: DateTime(2026, 2, 20),
          paidBy: 0,
        ),
        _expense(
          id: 'c',
          category: Category.alimentacao,
          value: 30,
          date: DateTime(2026, 2, 22),
          paidBy: 1,
        ),
        _expense(
          id: 'd',
          category: Category.transporte,
          value: 99,
          date: DateTime(2026, 2, 23),
          paidBy: 1,
        ),
      ];

      final byPeriod = applyExpensePeriodFilter(
        expenses,
        ExpensePeriodFilter.last7Days,
        now: DateTime(2026, 2, 24),
      );
      final byCategory = applyExpenseCategoryFilter(
        byPeriod,
        Category.alimentacao,
      );
      final byPaidBy = applyExpensePaidByFilter(byCategory, 1);
      final sorted = sortExpenses(
        byPaidBy,
        option: ExpenseSortOption.valueLowToHigh,
      );

      expect(sorted.map((e) => e.id), ['c', 'a']);
    },
  );

  test(
    'normalizeSelectedPaidBy reseta para Todos quando índice é inválido',
    () {
      expect(normalizeSelectedPaidBy(2, peopleCount: 2), isNull);
      expect(normalizeSelectedPaidBy(-1, peopleCount: 2), isNull);
      expect(normalizeSelectedPaidBy(null, peopleCount: 2), isNull);
      expect(normalizeSelectedPaidBy(1, peopleCount: 2), 1);
    },
  );

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
