import 'package:despesas_praia/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildExpenseItemSemanticsLabel inclui dados essenciais da despesa', () {
    final expense = Expense(
      id: '1',
      value: 150,
      category: Category.mercado,
      paidBy: 0,
      date: DateTime(2026, 2, 20),
      parcelas: 3,
      description: 'Compras do churrasco',
    );

    final label = buildExpenseItemSemanticsLabel(
      expense: expense,
      personName: 'Ana',
    );

    expect(label, contains('R\$ 150,00'));
    expect(label, contains('categoria Mercado'));
    expect(label, contains('paga por Ana'));
    expect(label, contains('em 20/02/2026'));
    expect(label, contains('parcelada em 3 vezes'));
    expect(label, contains('descrição: Compras do churrasco'));
  });
}
