class ClassModel {
  final int? id;
  final int monthId;
  final String className;

  ClassModel({
    this.id,
    required this.monthId,
    required this.className,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] as int?,
      monthId: map['month_id'] as int,
      className: map['class_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'month_id': monthId,
      'class_name': className,
    };
  }
}
