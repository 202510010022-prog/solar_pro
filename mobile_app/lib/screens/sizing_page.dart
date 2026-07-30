import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_subscription.dart';
import '../models/client.dart';
import '../services/pvgis_validation_service.dart';
import '../services/sizing_service.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';

class SizingPage extends StatefulWidget {
  const SizingPage({
    super.key,
    required this.repository,
    required this.subscription,
  });

  final SolarProRepository repository;
  final AppSubscription? subscription;

  @override
  State<SizingPage> createState() => _SizingPageState();
}

class _SizingPageState extends State<SizingPage> {
  final service = SizingService();
  final consumption =
      List.generate(12, (_) => TextEditingController(text: '500'));
  final hsp = List.generate(12, (_) => TextEditingController(text: '5'));
  final extra = TextEditingController(text: '10');
  final modulePower = TextEditingController(text: '550');
  final tariff = TextEditingController(text: '0.95');
  final laborCost = TextEditingController(text: '5000');
  final moduleUnitCost = TextEditingController(text: '650');
  final inverterCost = TextEditingController(text: '4500');
  final supportCost = TextEditingController(text: '2500');
  final materialName = TextEditingController();
  final materialValue = TextEditingController();
  final extraMaterials = <_MaterialItem>[];

  SizingResult? result;
  PvgisValidationResult? pvgisValidation;
  double projectCost = 0;
  List<Client> clients = [];
  Client? selectedClient;
  bool loadingClients = true;
  bool saving = false;
  bool validatingPvgis = false;
  bool loadingHsp = false;

  static const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez'
  ];

  @override
  void initState() {
    super.initState();
    for (final controller in [
      ...consumption,
      ...hsp,
      extra,
      modulePower,
      tariff,
      laborCost,
      moduleUnitCost,
      inverterCost,
      supportCost,
    ]) {
      controller.addListener(calculate);
    }
    loadClients();
    calculate();
  }

  @override
  void dispose() {
    for (final controller in [
      ...consumption,
      ...hsp,
      extra,
      modulePower,
      tariff,
      laborCost,
      moduleUnitCost,
      inverterCost,
      supportCost,
      materialName,
      materialValue,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void calculate({bool keepPvgisValidation = false}) {
    final baseResult = service.calculate(
      monthlyConsumption: consumption.map(_number).toList(),
      monthlyHsp: hsp.map(_number).toList(),
      generationExtraPercent: _number(extra),
      performanceRatio: 0.8,
      modulePower: _number(modulePower),
      tariff: _number(tariff),
      projectValue: 0,
    );
    final cost = _projectCost(baseResult.moduleCount);
    setState(() {
      result = service.calculate(
        monthlyConsumption: consumption.map(_number).toList(),
        monthlyHsp: hsp.map(_number).toList(),
        generationExtraPercent: _number(extra),
        performanceRatio: 0.8,
        modulePower: _number(modulePower),
        tariff: _number(tariff),
        projectValue: cost,
      );
      projectCost = cost;
      if (!keepPvgisValidation) {
        pvgisValidation = null;
      }
    });
  }

  Future<void> loadClients() async {
    try {
      final loaded = await widget.repository.loadClients();
      if (!mounted) return;
      setState(() {
        clients = loaded;
        selectedClient = loaded.isEmpty ? null : loaded.first;
        loadingClients = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loadingClients = false);
    }
  }

  Future<void> saveProject() async {
    final client = selectedClient;
    final data = result;
    if (client?.id == null || data == null) {
      _message('Selecione um cliente antes de salvar.');
      return;
    }

    setState(() => saving = true);
    try {
      final validation = await widget.repository.validateProjectCreation(
        cachedSubscription: widget.subscription,
      );
      if (!validation.allowed) {
        if (!mounted) return;
        _message(validation.message!);
        return;
      }

      final profile = await widget.repository.loadProfile();
      await widget.repository.createSizingProject(
        clientId: client!.id!,
        companyId: profile.companyId,
        monthlyConsumption: consumption.map(_number).toList(),
        monthlyHsp: hsp.map(_number).toList(),
        generationExtraPercent: _number(extra),
        performanceRatio: 0.8,
        modulePower: _number(modulePower),
        tariff: _number(tariff),
        projectValue: projectCost,
        laborCost: _number(laborCost),
        moduleUnitCost: _number(moduleUnitCost),
        inverterCost: _number(inverterCost),
        supportCost: _number(supportCost),
        extraMaterials: extraMaterials.map((item) => item.toMap()).toList(),
        result: data,
      );
      if (!mounted) return;
      _message('Projeto salvo com sucesso.');
    } catch (_) {
      if (!mounted) return;
      _message('Não foi possível salvar. Verifique sua conexão e login.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = result;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Dimensionamento',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text(
            'Cálculo rápido para visita técnica. Não gera PDF no mobile.',
            style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 16),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepTitle('1', 'Cliente do projeto'),
              const SizedBox(height: 12),
              loadingClients
                  ? const LinearProgressIndicator()
                  : DropdownButtonFormField<Client>(
                      initialValue: selectedClient,
                      items: clients
                          .map(
                            (client) => DropdownMenuItem(
                              value: client,
                              child: Text(client.name.isEmpty
                                  ? 'Cliente sem nome'
                                  : client.name),
                            ),
                          )
                          .toList(),
                      onChanged: (client) =>
                          setState(() => selectedClient = client),
                      decoration: const InputDecoration(
                          labelText: 'Selecione o cliente'),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepTitle('2', 'Consumo e HSP mês a mês'),
              const SizedBox(height: 6),
              const Text(
                'Informe o consumo em kWh. O HSP pode ser preenchido automaticamente pelo endereço do cliente.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.green.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HSP automático pelo PVGIS',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Use o endereço do cliente para preencher a irradiação mensal automaticamente.',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: loadingHsp ? null : fillHspFromClientAddress,
                      icon: loadingHsp
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.wb_sunny_rounded, size: 17),
                      label: Text(
                        loadingHsp
                            ? 'Buscando HSP...'
                            : 'Preencher HSP automaticamente',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 74,
                    ),
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 42,
                            child: Text(months[index],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                          ),
                          Expanded(child: _field('kWh', consumption[index])),
                          const SizedBox(width: 8),
                          Expanded(child: _field('HSP', hsp[index])),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepTitle('3', 'Parâmetros do sistema'),
              const SizedBox(height: 6),
              const Text(
                'Configure potência dos módulos, percentual extra de geração e tarifa de energia.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('Módulo W', modulePower)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Geração extra %', extra)),
                ],
              ),
              const SizedBox(height: 10),
              _field('Tarifa R\$/kWh', tariff),
              const SizedBox(height: 10),
              _LocationPreview(
                client: selectedClient,
                onUseCurrentLocation: validateWithCurrentLocation,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepTitle('4', 'Valor dos produtos e serviços'),
              const SizedBox(height: 6),
              const Text(
                'Monte o valor final com mão de obra, módulos, inversor, suportes e materiais extras.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('Mão de obra', laborCost)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Valor por módulo', moduleUnitCost)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _field('Inversor', inverterCost)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('Suportes', supportCost)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Materiais diversos',
                  style: TextStyle(color: AppTheme.muted)),
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
                  Expanded(child: _field('Valor', materialValue)),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addMaterial,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              if (extraMaterials.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...extraMaterials.asMap().entries.map(
                      (entry) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.value.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('R\$ ${entry.value.value.toStringAsFixed(2)}'),
                            IconButton(
                              onPressed: () => _removeMaterial(entry.key),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              const Divider(color: AppTheme.border),
              _result('Módulos',
                  '${data?.moduleCount ?? 0} x R\$ ${_number(moduleUnitCost).toStringAsFixed(2)}'),
              _result('Valor total do projeto',
                  'R\$ ${projectCost.toStringAsFixed(2)}'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (data != null)
          NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resultado',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _result('Potência instalada',
                    '${data.systemPower.toStringAsFixed(2)} kWp'),
                _result('Quantidade de módulos', '${data.moduleCount}'),
                _result('Produção anual',
                    '${data.annualGeneration.toStringAsFixed(0)} kWh'),
                _result('Economia mensal',
                    'R\$ ${data.monthlySavings.toStringAsFixed(2)}'),
                _result(
                    'Payback', '${data.paybackYears.toStringAsFixed(2)} anos'),
                _result('Valor do projeto',
                    'R\$ ${projectCost.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _PvgisValidationCard(
                  validation: pvgisValidation,
                  validating: validatingPvgis,
                  onValidate: validateWithPvgis,
                  onAdjust: adjustWithPvgis,
                  onAccept: acceptPvgisValidation,
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 12),
                const Text('Geração x consumo mensal',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                ...List.generate(12, (index) {
                  return _MonthlyBalanceBar(
                    month: months[index],
                    consumption: consumption[index].text,
                    generation: data.monthlyGenerations[index],
                    balance: data.monthlyBalances[index],
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: saving ? null : saveProject,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(saving ? 'Salvando...' : 'Novo dimensionamento'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _stepTitle(String number, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.green,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ],
    );
  }

  Widget _result(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  double _number(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.contains(',')) {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ??
          0;
    }
    final dotParts = text.split('.');
    if (dotParts.length > 1 &&
        dotParts.last.length == 3 &&
        dotParts.first.length > 1) {
      return double.tryParse(text.replaceAll('.', '')) ?? 0;
    }
    return double.tryParse(text) ?? 0;
  }

  double _projectCost(int moduleCount) {
    final modules = moduleCount * _number(moduleUnitCost);
    final materials =
        extraMaterials.fold<double>(0, (sum, item) => sum + item.value);
    return _number(laborCost) +
        modules +
        _number(inverterCost) +
        _number(supportCost) +
        materials;
  }

  void _addMaterial() {
    final name = materialName.text.trim();
    final value = _number(materialValue);
    if (name.isEmpty || value <= 0) {
      _message('Informe nome e valor do material.');
      return;
    }
    setState(() {
      extraMaterials.add(_MaterialItem(name: name, value: value));
      materialName.clear();
      materialValue.clear();
    });
    calculate();
  }

  void _removeMaterial(int index) {
    setState(() => extraMaterials.removeAt(index));
    calculate();
  }

  Future<void> validateWithPvgis() async {
    await _validateWithPvgis();
  }

  Future<void> fillHspFromClientAddress() async {
    final client = selectedClient;
    if (client == null) {
      _message('Selecione um cliente antes de buscar HSP.');
      return;
    }

    setState(() => loadingHsp = true);
    try {
      final lookup = await widget.repository.lookupMonthlyHspWithPvgis(
        client: client,
      );
      if (lookup.monthlyHsp.length < 12) {
        _message('PVGIS não retornou HSP mensal completo.');
        return;
      }

      for (var i = 0; i < 12; i++) {
        hsp[i].text = lookup.monthlyHsp[i].toStringAsFixed(2);
      }
      calculate();
      if (!mounted) return;
      _message('HSP mensal preenchido pelo endereço do cliente.');
    } catch (error) {
      if (!mounted) return;
      _message(_friendlyPvgisError(error));
    } finally {
      if (mounted) setState(() => loadingHsp = false);
    }
  }

  Future<void> validateWithCurrentLocation() async {
    final position = await _currentPosition();
    if (position == null) return;
    await _validateWithPvgis(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _validateWithPvgis({double? latitude, double? longitude}) async {
    final data = result;
    final client = selectedClient;
    if (data == null || data.systemPower <= 0) {
      _message('Calcule o dimensionamento antes de validar.');
      return;
    }
    if (client == null) {
      _message('Selecione um cliente antes de validar.');
      return;
    }

    setState(() => validatingPvgis = true);
    try {
      final validation = await widget.repository.validateWithPvgis(
        client: client,
        latitude: latitude,
        longitude: longitude,
        installedPowerKwp: data.systemPower,
        estimatedAnnualGeneration: data.annualGeneration,
      );
      if (!mounted) return;
      setState(() => pvgisValidation = validation);
      _message(validation.needsReview
          ? 'PVGIS indica diferença acima de 15%.'
          : 'PVGIS validou o dimensionamento.');
    } catch (error) {
      if (!mounted) return;
      _message(_friendlyPvgisError(error));
    } finally {
      if (mounted) setState(() => validatingPvgis = false);
    }
  }

  Future<Position?> _currentPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _message('Ative a localização do dispositivo para usar GPS.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _message('Permissão de localização negada.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 18),
        ),
      );
    } catch (_) {
      _message('Não foi possível obter a localização atual.');
      return null;
    }
  }

  void adjustWithPvgis() {
    final validation = pvgisValidation;
    final data = result;
    if (validation == null || data == null) return;
    setState(() {
      result = data.withMonthlyGenerations(
        generations: validation.monthlyGenerations,
        consumption: consumption.map(_number).toList(),
        tariff: _number(tariff),
        projectValue: projectCost,
      );
    });
    _message('Geração ajustada com base no PVGIS.');
  }

  void acceptPvgisValidation() {
    if (pvgisValidation == null) return;
    _message('Validação PVGIS aceita.');
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _friendlyPvgisError(Object error) {
    final text = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
    if (text.isEmpty) {
      return 'Não foi possível validar no PVGIS. Confira o endereço e a conexão.';
    }
    if (text.length > 220) return '${text.substring(0, 220)}...';
    return text;
  }
}

class _MaterialItem {
  const _MaterialItem({required this.name, required this.value});

  final String name;
  final double value;

  Map<String, dynamic> toMap() => {'name': name, 'value': value};
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({
    required this.client,
    required this.onUseCurrentLocation,
  });

  final Client? client;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final address = client?.addressLine.trim() ?? '';
    final hasAddress = address.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.green.withValues(alpha: 0.12),
                child: const Icon(Icons.location_on_rounded,
                    color: AppTheme.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Localização do projeto',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasAddress
                          ? address
                          : 'Complete o endereço do cliente para validar pelo PVGIS.',
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onUseCurrentLocation,
            icon: const Icon(Icons.my_location_rounded, size: 17),
            label: const Text('Usar localização atual'),
          ),
        ],
      ),
    );
  }
}

class _PvgisValidationCard extends StatelessWidget {
  const _PvgisValidationCard({
    required this.validation,
    required this.validating,
    required this.onValidate,
    required this.onAdjust,
    required this.onAccept,
  });

  final PvgisValidationResult? validation;
  final bool validating;
  final VoidCallback onValidate;
  final VoidCallback onAdjust;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final data = validation;
    final needsReview = data?.needsReview == true;
    final color = data == null
        ? AppTheme.primaryBlue
        : needsReview
            ? AppTheme.orange
            : AppTheme.green;
    final label = data == null ? 'Não validado' : data.badgeLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                child: validating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        needsReview
                            ? Icons.warning_amber_rounded
                            : Icons.verified_rounded,
                        color: color,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Validação PVGIS',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data == null
                          ? 'Compare a geração estimada com dados solares por latitude e longitude.'
                          : 'Diferença ${data.differencePercent.toStringAsFixed(1)}% em relação ao cálculo atual.',
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                    if (data?.locationLabel.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        data!.locationSource == 'current_location'
                            ? 'Usando localização atual.'
                            : 'Usando endereço do cliente.',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (data != null) ...[
            const SizedBox(height: 12),
            _PvgisMetric(
              label: 'Estimado no app',
              value: '${data.estimatedAnnualGeneration.toStringAsFixed(0)} kWh',
            ),
            _PvgisMetric(
              label: 'PVGIS',
              value: '${data.pvgisAnnualGeneration.toStringAsFixed(0)} kWh',
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: validating ? null : onValidate,
                icon: const Icon(Icons.public_rounded, size: 17),
                label: Text(
                  validating ? 'Validando...' : 'Validar endereço no PVGIS',
                ),
              ),
              if (data != null && needsReview)
                ElevatedButton.icon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('Ajustar'),
                ),
              if (data != null)
                TextButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Aceitar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PvgisMetric extends StatelessWidget {
  const _PvgisMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MonthlyBalanceBar extends StatelessWidget {
  const _MonthlyBalanceBar({
    required this.month,
    required this.consumption,
    required this.generation,
    required this.balance,
  });

  final String month;
  final String consumption;
  final double generation;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final consumed = _number(consumption);
    final maxValue =
        [consumed, generation, 1.0].reduce((a, b) => a > b ? a : b);
    final positive = balance >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 38, child: Text(month)),
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: consumed / maxValue,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.orange),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: generation / maxValue,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Consumo ${consumed.toStringAsFixed(0)} kWh • Geração ${generation.toStringAsFixed(0)} kWh • Saldo ${balance.toStringAsFixed(0)} kWh',
            style: TextStyle(
              color: positive ? AppTheme.green : Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  double _number(String text) {
    final normalized = text.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
}
