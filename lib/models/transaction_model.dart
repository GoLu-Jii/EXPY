class TransactionModel {
  final int? id;
  final int classId;
  final double amount;
  final String? note;
  final String timestamp;

  TransactionModel({
    this.id,
    required this.classId,
    required this.amount,
    this.note,
    required this.timestamp,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      classId: map['class_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      timestamp: map['timestamp'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'class_id': classId,
      'amount': amount,
      'note': note,
      'timestamp': timestamp,
    };
  }
}
