import 'dart:convert';

import 'project_address.dart';

class ExtraMaterial {
  const ExtraMaterial({required this.name, required this.value});

  final String name;
  final double value;

  factory ExtraMaterial.fromMap(Map<String, dynamic> map) {
    return ExtraMaterial(
      name: '${map['name'] ?? ''}',
      value: Project._double(map['value']),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'value': value};
}

class Project {
  const Project({
    this.id,
    required this.clientId,
    required this.clientName,
    required this.address,
    required this.projectDate,
    required this.status,
    required this.averageConsumption,
    required this.averageHsp,
    required this.annualConsumption,
    required this.systemPower,
    required this.moduleCount,
    required this.monthlyGeneration,
    required this.monthlySavings,
    required this.annualGeneration,
    required this.projectValue,
    required this.laborCost,
    required this.moduleUnitCost,
    required this.inverterCost,
    required this.supportCost,
    required this.extraMaterials,
    required this.energyTariff,
    required this.modulePower,
    required this.paybackYears,
    required this.monthlyConsumptions,
    required this.monthlyHsp,
    required this.monthlyGenerations,
    required this.monthlyBalances,
    required this.downPayment,
    required this.paymentType,
    required this.discount,
    required this.installmentsCount,
    required this.installmentValue,
    required this.firstDueDate,
    required this.financialNotes,
    required this.updatedAt,
  });

  final int? id;
  final int clientId;
  final String clientName;
  final ProjectAddress address;
  final String projectDate;
  final String status;
  final double averageConsumption;
  final double averageHsp;
  final double annualConsumption;
  final double systemPower;
  final int moduleCount;
  final double monthlyGeneration;
  final double monthlySavings;
  final double annualGeneration;
  final double projectValue;
  final double laborCost;
  final double moduleUnitCost;
  final double inverterCost;
  final double supportCost;
  final List<ExtraMaterial> extraMaterials;
  final double energyTariff;
  final double modulePower;
  final double paybackYears;
  final List<double> monthlyConsumptions;
  final List<double> monthlyHsp;
  final List<double> monthlyGenerations;
  final List<double> monthlyBalances;
  final double downPayment;
  final String paymentType;
  final double discount;
  final int installmentsCount;
  final double installmentValue;
  final DateTime? firstDueDate;
  final String financialNotes;
  final DateTime? updatedAt;

  factory Project.fromMap(Map<String, dynamic> map) {
    final client = map['clients'];
    return Project(
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
      clientId: _int(map['client_id']),
      clientName: client is Map ? '${client['name'] ?? ''}' : '',
      address: ProjectAddress.fromMap(map),
      projectDate: '${map['project_date'] ?? ''}',
      status: '${map['status'] ?? 'Em negociação'}',
      averageConsumption: _double(map['average_consumption']),
      averageHsp: _double(map['average_hsp']),
      annualConsumption: _double(map['annual_consumption']),
      systemPower: _double(map['system_power']),
      moduleCount: _int(map['module_count']),
      monthlyGeneration: _double(map['monthly_generation']),
      monthlySavings: _double(map['monthly_savings']),
      annualGeneration: _double(map['annual_generation']),
      projectValue: _double(map['project_value']),
      laborCost: _double(map['labor_cost']),
      moduleUnitCost: _double(map['module_unit_cost']),
      inverterCost: _double(map['inverter_cost']),
      supportCost: _double(map['support_cost']),
      extraMaterials: _materials(map['extra_materials']),
      energyTariff: _double(map['energy_tariff']),
      modulePower: _double(map['module_power']),
      paybackYears: _double(map['payback_years']),
      monthlyConsumptions: _doubleList(map['monthly_consumptions']),
      monthlyHsp: _doubleList(map['monthly_hsp']),
      monthlyGenerations: _doubleList(map['monthly_generations']),
      monthlyBalances: _doubleList(map['monthly_balances']),
      downPayment: _double(map['down_payment']),
      paymentType: '${map['payment_type'] ?? ''}',
      discount: _double(map['discount']),
      installmentsCount: _int(map['installments_count']),
      installmentValue: _double(map['installment_value']),
      firstDueDate: DateTime.tryParse('${map['first_due_date'] ?? ''}'),
      financialNotes: '${map['financial_notes'] ?? ''}',
      updatedAt: DateTime.tryParse('${map['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toStatusMap() {
    return {'status': status};
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static List<double> _doubleList(dynamic value) {
    if (value is List) {
      return value.map(_double).toList();
    }
    final raw = '$value'.trim();
    if (raw.isEmpty || raw == 'null') return [];
    final cleaned = raw.replaceAll('[', '').replaceAll(']', '');
    return cleaned
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(_double)
        .toList();
  }

  static List<ExtraMaterial> _materials(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => ExtraMaterial.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }
    final raw = '$value'.trim();
    if (raw.isEmpty || raw == 'null') return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => ExtraMaterial.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
