import 'package:despesas_praia/domain/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula saldos com cota total/4', () {
    final balances = calculateBalances([100, 0, 0, 0], peopleCount: 4);

    expect(balances[0], 75);
    expect(balances[1], -25);
    expect(balances[2], -25);
    expect(balances[3], -25);
  });

  test('calcula saldos com N dinâmico', () {
    final balances = calculateBalances([90, 0, 0], peopleCount: 3);

    expect(balances[0], 60);
    expect(balances[1], -30);
    expect(balances[2], -30);
  });

  test('gera transacoes minimas entre devedores e credores', () {
    final balances = [75.0, -25.0, -25.0, -25.0];
    final transfers = calculateSettlements(balances);

    expect(transfers.length, 3);
    expect(transfers[0].from, 1);
    expect(transfers[0].to, 0);
    expect(transfers[0].amount, 25);
    expect(transfers[1].from, 2);
    expect(transfers[1].to, 0);
    expect(transfers[1].amount, 25);
    expect(transfers[2].from, 3);
    expect(transfers[2].to, 0);
    expect(transfers[2].amount, 25);
  });
}
