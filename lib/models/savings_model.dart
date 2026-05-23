class SavingsModel {
  final int? id;
  final int monthId;
  final double amount;
  final String? note;
  final String type; // "deposit" or "withdraw"
  final String timestamp;

  SavingsModel({
    this.id,
    required this.monthId,
    required this.amount,
    this.note,
    required this.type,
    required this.timestamp,
  });

  factory SavingsModel.fromMap(Map<String, dynamic> map) {
    return SavingsModel(
      id: map['id'] as int?,
      monthId: map['month_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      type: map['type'] as String,
      timestamp: map['timestamp'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'month_id': monthId,
      'amount': amount,
      'note': note,
      'type': type,
      'timestamp': timestamp,
    };
  }
}
