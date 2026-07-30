class AdminMessage {
  const AdminMessage({
    required this.id,
    required this.companyName,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.readAt,
    required this.expiresAt,
  });

  final int id;
  final String companyName;
  final String title;
  final String message;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  String get typeLabel {
    return switch (type) {
      'billing' => 'Cobrança',
      'warning' => 'Atenção',
      'success' => 'Confirmação',
      _ => 'Informação',
    };
  }

  String get statusLabel {
    return switch (status) {
      'unread' => 'Não lida',
      'read' => 'Lida',
      'archived' => 'Arquivada',
      _ => status,
    };
  }

  factory AdminMessage.fromMap(Map<String, dynamic> map) {
    final company = map['companies'];
    final companyMap = company is Map ? Map<String, dynamic>.from(company) : {};
    return AdminMessage(
      id: _int(map['id']),
      companyName: '${companyMap['name'] ?? 'Empresa'}',
      title: '${map['title'] ?? ''}',
      message: '${map['message'] ?? ''}',
      type: '${map['type'] ?? 'info'}',
      status: '${map['status'] ?? 'unread'}',
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
