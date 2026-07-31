import 'package:flutter/material.dart';

import '../models/project.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../widgets/neon_card.dart';
import 'projects_page.dart';

class ProjectEditPage extends StatefulWidget {
  const ProjectEditPage({
    super.key,
    required this.project,
    required this.repository,
  });

  final Project project;
  final SolarProRepository repository;

  @override
  State<ProjectEditPage> createState() => _ProjectEditPageState();
}

class _ProjectEditPageState extends State<ProjectEditPage> {
  late String status = projectStatuses.contains(widget.project.status)
      ? widget.project.status
      : projectStatuses.first;
  late final laborCost =
      TextEditingController(text: widget.project.laborCost.toStringAsFixed(2));
  late final moduleUnitCost = TextEditingController(
      text: widget.project.moduleUnitCost.toStringAsFixed(2));
  late final inverterCost = TextEditingController(
      text: widget.project.inverterCost.toStringAsFixed(2));
  late final supportCost = TextEditingController(
      text: widget.project.supportCost.toStringAsFixed(2));
  late final tariff = TextEditingController(
      text: widget.project.energyTariff.toStringAsFixed(2));
  late final modulePower = TextEditingController(
      text: widget.project.modulePower.toStringAsFixed(0));
  final materialName = TextEditingController();
  final materialValue = TextEditingController();
  late final materials = widget.project.extraMaterials
      .map((item) => _MaterialItem(name: item.name, value: item.value))
      .toList();
  bool saving = false;

  @override
  void dispose() {
    laborCost.dispose();
    moduleUnitCost.dispose();
    inverterCost.dispose();
    supportCost.dispose();
    tariff.dispose();
    modulePower.dispose();
    materialName.dispose();
    materialValue.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final projectId = widget.project.id;
    if (projectId == null) return;
    setState(() => saving = true);
    try {
      await widget.repository.updateProjectSummary(
        projectId: projectId,
        status: status,
        projectValue: _totalValue(),
        laborCost: _number(laborCost.text),
        moduleUnitCost: _number(moduleUnitCost.text),
        inverterCost: _number(inverterCost.text),
        supportCost: _number(supportCost.text),
        extraMaterials: materials.map((item) => item.toMap()).toList(),
        energyTariff: _number(tariff.text),
        modulePower: _number(modulePower.text),
        paybackYears: _paybackYears(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projeto atualizado com sucesso.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyNetworkError(
              error,
              fallback: 'Não foi possível atualizar o projeto.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar projeto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.project.clientName.isEmpty
                ? 'Cliente sem nome'
                : widget.project.clientName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Edição rápida dos dados comerciais. Para recalcular geração, use a aba Dimensionar.',
            style: TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          NeonCard(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: projectStatuses
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => status = value ?? status),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _moneyField('Mão de obra', laborCost)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _moneyField('Valor por módulo', moduleUnitCost)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _moneyField('Inversor', inverterCost)),
                    const SizedBox(width: 10),
                    Expanded(child: _moneyField('Suportes', supportCost)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.border),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Materiais diversos',
                      style: TextStyle(color: AppTheme.muted)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: materialName,
                        decoration: const InputDecoration(labelText: 'Nome'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _moneyField('Valor', materialValue)),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addMaterial,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                if (materials.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...materials.asMap().entries.map(
                        (entry) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.value.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  'R\$ ${entry.value.value.toStringAsFixed(2)}'),
                              IconButton(
                                onPressed: () => setState(
                                    () => materials.removeAt(entry.key)),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
                const Divider(color: AppTheme.border),
                _summary('Módulos',
                    '${widget.project.moduleCount} x R\$ ${_number(moduleUnitCost.text).toStringAsFixed(2)}'),
                _summary('Valor total calculado',
                    'R\$ ${_totalValue().toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                TextField(
                  controller: tariff,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Tarifa R\$/kWh'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modulePower,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Potência do módulo W'),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: Text(saving ? 'Salvando...' : 'Salvar alterações'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _number(String value) {
    final text = value.trim();
    if (text.contains(',')) {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }
    return double.tryParse(text) ?? 0;
  }

  Widget _moneyField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _summary(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppTheme.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  void _addMaterial() {
    final name = materialName.text.trim();
    final value = _number(materialValue.text);
    if (name.isEmpty || value <= 0) return;
    setState(() {
      materials.add(_MaterialItem(name: name, value: value));
      materialName.clear();
      materialValue.clear();
    });
  }

  double _totalValue() {
    final moduleTotal =
        widget.project.moduleCount * _number(moduleUnitCost.text);
    final materialsTotal =
        materials.fold<double>(0, (sum, item) => sum + item.value);
    return _number(laborCost.text) +
        moduleTotal +
        _number(inverterCost.text) +
        _number(supportCost.text) +
        materialsTotal;
  }

  double _paybackYears() {
    final annualSavings = widget.project.monthlySavings * 12;
    if (annualSavings <= 0) return 0;
    return _totalValue() / annualSavings;
  }
}

class _MaterialItem {
  const _MaterialItem({required this.name, required this.value});

  final String name;
  final double value;

  Map<String, dynamic> toMap() => {'name': name, 'value': value};
}
