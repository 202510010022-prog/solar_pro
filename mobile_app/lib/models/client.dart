class Client {
  const Client({
    this.id,
    required this.name,
    required this.document,
    required this.phone,
    required this.email,
    required this.zipCode,
    required this.street,
    required this.addressNumber,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.addressComplement,
  });

  final int? id;
  final String name;
  final String document;
  final String phone;
  final String email;
  final String zipCode;
  final String street;
  final String addressNumber;
  final String neighborhood;
  final String city;
  final String state;
  final String addressComplement;

  String get cityState {
    final cityText = city.trim();
    final stateText = state.trim();
    if (cityText.isEmpty && stateText.isEmpty) return '';
    if (stateText.isEmpty) return cityText;
    if (cityText.isEmpty) return stateText;
    return '$cityText/$stateText';
  }

  String get addressLine {
    final parts = <String>[
      if (street.trim().isNotEmpty)
        addressNumber.trim().isEmpty
            ? street.trim()
            : '${street.trim()}, ${addressNumber.trim()}',
      if (neighborhood.trim().isNotEmpty) neighborhood.trim(),
      if (cityState.isNotEmpty) cityState,
      if (zipCode.trim().isNotEmpty) 'CEP ${zipCode.trim()}',
    ];
    return parts.join(' • ');
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      name: '${map['name'] ?? ''}',
      document: '${map['document'] ?? ''}',
      phone: '${map['phone'] ?? ''}',
      email: '${map['email'] ?? ''}',
      zipCode: '${map['zip_code'] ?? ''}',
      street: '${map['street'] ?? ''}',
      addressNumber: '${map['address_number'] ?? ''}',
      neighborhood: '${map['neighborhood'] ?? ''}',
      city: '${map['city'] ?? ''}',
      state: '${map['state'] ?? ''}',
      addressComplement: '${map['address_complement'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap({String? companyId}) {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      'name': name,
      'document': document,
      'phone': phone,
      'email': email,
      'zip_code': zipCode,
      'street': street,
      'address_number': addressNumber,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'address_complement': addressComplement,
    };
  }
}
