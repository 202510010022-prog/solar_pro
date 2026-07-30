class ManualPayment {
  const ManualPayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.paidAt,
    required this.status,
    required this.pixReference,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final double amount;
  final String currency;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String status;
  final String pixReference;
  final String notes;
  final DateTime? createdAt;

  bool get isPaid => status == 'paid';
  bool get canBePaid => status == 'pending' || status == 'overdue';
  bool get canBeCanceled => status == 'pending' || status == 'overdue';

  String get statusLabel {
    return switch (status) {
      'pending' => 'Pendente',
      'paid' => 'Pago',
      'overdue' => 'Atrasado',
      'canceled' => 'Cancelado',
      _ => status,
    };
  }

  factory ManualPayment.fromMap(Map<String, dynamic> map) {
    return ManualPayment(
      id: _int(map['id']),
      amount: _double(map['amount']),
      currency: '${map['currency'] ?? 'BRL'}',
      dueDate: DateTime.tryParse('${map['due_date'] ?? ''}'),
      paidAt: DateTime.tryParse('${map['paid_at'] ?? ''}'),
      status: '${map['status'] ?? 'pending'}',
      pixReference: '${map['pix_reference'] ?? ''}',
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
