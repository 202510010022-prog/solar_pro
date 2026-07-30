class ProjectPayment {
  const ProjectPayment({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.paymentType,
    required this.paidAt,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final int projectId;
  final double amount;
  final String paymentType;
  final DateTime? paidAt;
  final String status;
  final String notes;
  final DateTime? createdAt;

  bool get isPaid => status == 'paid';

  factory ProjectPayment.fromMap(Map<String, dynamic> map) {
    return ProjectPayment(
      id: _int(map['id']),
      projectId: _int(map['project_id']),
      amount: _double(map['amount']),
      paymentType: '${map['payment_type'] ?? ''}',
      paidAt: DateTime.tryParse('${map['paid_at'] ?? ''}'),
      status: '${map['status'] ?? 'paid'}',
      notes: '${map['notes'] ?? ''}',
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
    );
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
