import 'client.dart';

class ProjectAddress {
  const ProjectAddress({
    required this.zipCode,
    required this.street,
    required this.addressNumber,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.addressComplement,
  });

  const ProjectAddress.empty()
      : zipCode = '',
        street = '',
        addressNumber = '',
        neighborhood = '',
        city = '',
        state = '',
        addressComplement = '';

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

  factory ProjectAddress.fromClient(Client client) {
    return ProjectAddress(
      zipCode: client.zipCode,
      street: client.street,
      addressNumber: client.addressNumber,
      neighborhood: client.neighborhood,
      city: client.city,
      state: client.state,
      addressComplement: client.addressComplement,
    );
  }

  factory ProjectAddress.fromMap(Map<String, dynamic> map) {
    return ProjectAddress(
      zipCode: '${map['zip_code'] ?? ''}',
      street: '${map['street'] ?? ''}',
      addressNumber: '${map['address_number'] ?? ''}',
      neighborhood: '${map['neighborhood'] ?? ''}',
      city: '${map['city'] ?? ''}',
      state: '${map['state'] ?? ''}',
      addressComplement: '${map['address_complement'] ?? ''}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
