class AppMessage {
  const AppMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.paymentId,
    required this.createdAt,
    required this.readAt,
    required this.expiresAt,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final String status;
  final int? paymentId;
  final DateTime? createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  bool get isUnread => status == 'unread';

  String get typeLabel {
    return switch (type) {
      'billing' => 'Cobrança',
      'warning' => 'Atenção',
      'success' => 'Confirmação',
      _ => 'Informação',
    };
  }

  factory AppMessage.fromMap(Map<String, dynamic> map) {
    return AppMessage(
      id: _int(map['id']),
      title: '${map['title'] ?? ''}',
      message: '${map['message'] ?? ''}',
      type: '${map['type'] ?? 'info'}',
      status: '${map['status'] ?? 'unread'}',
      paymentId: map['payment_id'] == null ? null : _int(map['payment_id']),
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
      readAt: DateTime.tryParse('${map['read_at'] ?? ''}'),
      expiresAt: DateTime.tryParse('${map['expires_at'] ?? ''}'),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
