// lib/models/ledger_model.dart

class LedgerModel {
  final int? id;
  final int monthId;
  final String entityName;
  final double amount;
  final String type; // "give" or "take"
  final String? note;
  final String timestamp;

  LedgerModel({
    this.id,
    required this.monthId,
    required this.entityName,
    required this.amount,
    required this.type,
    this.note,
    required this.timestamp,
  });

  factory LedgerModel.fromMap(Map<String, dynamic> map) {
    return LedgerModel(
      id: map['id'] as int?,
      monthId: map['month_id'] as int,
      entityName: map['entity_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      note: map['note'] as String?,
      timestamp: map['timestamp'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'month_id': monthId,
      'entity_name': entityName,
      'amount': amount,
      'type': type,
      'note': note,
      'timestamp': timestamp,
    };
  }
}
