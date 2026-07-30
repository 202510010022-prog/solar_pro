class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.amount,
    required this.status,
    required this.pixReference,
    required this.notes,
    required this.dueDate,
    required this.paidAt,
    required this.createdAt,
  });

  final int id;
  final String companyId;
  final String companyName;
  final double amount;
  final String status;
  final String pixReference;
  final String notes;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime? createdAt;

  bool get canBePaid => status == 'pending' || status == 'overdue';
  bool get canBeCanceled => status == 'pending' || status == 'overdue';

  factory AdminPayment.fromMap(Map<String, dynamic> map) {
    final company = map['companies'];
    final companyMap = company is Map ? Map<String, dynamic>.from(company) : {};
    return AdminPayment(
      id: _int(map['id']),
      companyId: '${map['company_id'] ?? ''}',
      companyName: '${companyMap['name'] ?? 'Empresa'}',
      amount: _double(map['amount']),
      status: '${map['status'] ?? 'pending'}',
      pixReference: '${map['pix_reference'] ?? ''}',
      notes: '${map['notes'] ?? ''}',
      dueDate: DateTime.tryParse('${map['due_date'] ?? ''}'),
      paidAt: DateTime.tryParse('${map['paid_at'] ?? ''}'),
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
