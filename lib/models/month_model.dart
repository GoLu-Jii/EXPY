class MonthModel {
  final int? id;
  final String monthYear;
  final double initialBalance;

  MonthModel({
    this.id,
    required this.monthYear,
    required this.initialBalance,
  });

  factory MonthModel.fromMap(Map<String, dynamic> map) {
    return MonthModel(
      id: map['id'] as int?,
      monthYear: map['month_year'] as String,
      initialBalance: (map['initial_balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'month_year': monthYear,
      'initial_balance': initialBalance,
    };
  }
}
