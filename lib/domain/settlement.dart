class SettlementTransfer {
  SettlementTransfer({
    required this.from,
    required this.to,
    required this.amount,
  });

  final int from;
  final int to;
  final double amount;
}

List<double> calculateBalances(List<double> paid, {int? peopleCount}) {
  final count = (peopleCount ?? paid.length) < 1
      ? 1
      : (peopleCount ?? paid.length);
  final total = paid.fold<double>(0, (sum, v) => sum + v);
  final quota = total / count;
  return paid.map((value) => value - quota).toList(growable: false);
}

List<SettlementTransfer> calculateSettlements(List<double> balances) {
  final result = <SettlementTransfer>[];
  final debtors = <(int, double)>[];
  final creditors = <(int, double)>[];

  for (var i = 0; i < balances.length; i++) {
    final value = balances[i];
    if (value < -0.009) debtors.add((i, -value));
    if (value > 0.009) creditors.add((i, value));
  }

  var d = 0;
  var c = 0;

  while (d < debtors.length && c < creditors.length) {
    final (debtorIdx, debtorAmount) = debtors[d];
    final (creditorIdx, creditorAmount) = creditors[c];
    final amount = debtorAmount < creditorAmount
        ? debtorAmount
        : creditorAmount;

    result.add(
      SettlementTransfer(from: debtorIdx, to: creditorIdx, amount: amount),
    );

    final newDebtor = debtorAmount - amount;
    final newCreditor = creditorAmount - amount;

    debtors[d] = (debtorIdx, newDebtor);
    creditors[c] = (creditorIdx, newCreditor);

    if (newDebtor <= 0.009) d++;
    if (newCreditor <= 0.009) c++;
  }

  return result;
}
