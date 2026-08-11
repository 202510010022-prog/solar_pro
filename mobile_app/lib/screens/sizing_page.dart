import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_subscription.dart';
import '../models/client.dart';
import '../models/project_address.dart';
import '../services/pvgis_validation_service.dart';
import '../services/sizing_service.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../widgets/monthly_energy_bars.dart';
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
  static const _sizingPerformanceRatio = 0.80;

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
  final addressZipCode = TextEditingController();
  final addressStreet = TextEditingController();
  final addressNumber = TextEditingController();
  final addressNeighborhood = TextEditingController();
  final addressCity = TextEditingController();
  final addressState = TextEditingController();
  final addressComplement = TextEditingController();
  final extraMaterials = <_MaterialItem>[];

  SizingResult? result;
  PvgisValidationResult? pvgisValidation;
  PvgisValidationResult? hspPvgisLookup;
  double projectCost = 0;
  List<Client> clients = [];
  Client? selectedClient;
  bool loadingClients = true;
  bool saving = false;
  bool validatingPvgis = false;
  bool loadingHsp = false;
  bool pvgisGenerationApplied = false;

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
    for (final controller in _addressControllers) {
      controller.addListener(_refreshAddressPreview);
    }
    loadClients();
    calculate();
  }

  @override
  void dispose() {
    for (final controller in _addressControllers) {
      controller.removeListener(_refreshAddressPreview);
    }
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
      ..._addressControllers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _addressControllers => [
        addressZipCode,
        addressStreet,
        addressNumber,
        addressNeighborhood,
        addressCity,
        addressState,
        addressComplement,
      ];

  ProjectAddress get currentAddress => ProjectAddress(
        zipCode: _digitsOnly(addressZipCode.text),
        street: addressStreet.text.trim(),
        addressNumber: addressNumber.text.trim(),
        neighborhood: addressNeighborhood.text.trim(),
        city: addressCity.text.trim(),
        state: addressState.text.trim().toUpperCase(),
        addressComplement: addressComplement.text.trim(),
      );

  void _refreshAddressPreview() {
    if (mounted) setState(() {});
  }

  void _fillAddress(ProjectAddress address) {
    addressZipCode.text = address.zipCode;
    addressStreet.text = address.street;
    addressNumber.text = address.addressNumber;
    addressNeighborhood.text = address.neighborhood;
    addressCity.text = address.city;
    addressState.text = address.state;
    addressComplement.text = address.addressComplement;
  }

  void _fillAddressFromClient(Client? client) {
    if (client == null) {
      _fillAddress(const ProjectAddress.empty());
      return;
    }
    _fillAddress(ProjectAddress.fromClient(client));
  }

  void calculate({bool keepPvgisValidation = false}) {
    final baseResult = service.calculate(
      monthlyConsumption: consumption.map(_number).toList(),
      monthlyHsp: hsp.map(_number).toList(),
      generationExtraPercent: _number(extra),
      performanceRatio: _sizingPerformanceRatio,
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
        performanceRatio: _sizingPerformanceRatio,
        modulePower: _number(modulePower),
        tariff: _number(tariff),
        projectValue: cost,
      );
      projectCost = cost;
      if (!keepPvgisValidation) {
        pvgisValidation = null;
        pvgisGenerationApplied = false;
      }
    });
  }

  Future<void> loadClients() async {
    try {
      final loaded = await widget.repository.loadClients();
      if (!mounted) return;
      final initialClient = loaded.isEmpty ? null : loaded.first;
      setState(() {
        clients = loaded;
        selectedClient = initialClient;
        loadingClients = false;
      });
      _fillAddressFromClient(initialClient);
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
        address: currentAddress,
        monthlyConsumption: consumption.map(_number).toList(),
        monthlyHsp: hsp.map(_number).toList(),
        generationExtraPercent: _number(extra),
        performanceRatio: _sizingPerformanceRatio,
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
    } catch (error) {
      if (!mounted) return;
      _message(
        friendlyNetworkError(
          error,
          fallback: 'Não foi possível salvar. Verifique sua conexão e login.',
        ),
      );
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
                      onChanged: (client) {
                        setState(() => selectedClient = client);
                        _fillAddressFromClient(client);
                      },
                      decoration: const InputDecoration(
                          labelText: 'Selecione o cliente'),
                    ),
              const SizedBox(height: 16),
              const Text(
                'Endereço deste orçamento',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pré-preenchido pelo cliente, mas editável apenas para este orçamento.',
                style: TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _ProjectAddressFields(
                zipCode: addressZipCode,
                street: addressStreet,
                addressNumber: addressNumber,
                neighborhood: addressNeighborhood,
                city: addressCity,
                state: addressState,
                addressComplement: addressComplement,
                onLookupCep: lookupProjectCep,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        NeonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepTitle('2', 'Consumo e HSP médio diário por mês'),
              const SizedBox(height: 6),
              const Text(
                'Informe o consumo em kWh. O HSP médio diário de cada mês pode ser preenchido pelo PVGIS.',
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
                      'Use o endereço do projeto para preencher o HSP médio diário de cada mês, calculado no plano otimizado dos módulos.',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: loadingHsp ? null : fillHspFromProjectAddress,
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
                    if (hspPvgisLookup != null) ...[
                      const SizedBox(height: 10),
                      _HspPvgisSourceCard(lookup: hspPvgisLookup!),
                    ],
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
                          Expanded(
                            child: _field(
                              'HSP (h/dia)',
                              hsp[index],
                              onChanged: (_) => _clearHspLookupMetadata(),
                            ),
                          ),
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
                address: currentAddress,
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
                  sizingPerformanceRatio: _sizingPerformanceRatio,
                  pvgisGenerationApplied: pvgisGenerationApplied,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final itemWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(12, (index) {
                        return SizedBox(
                          width: itemWidth,
                          child: _MonthlyBalanceBar(
                            month: months[index],
                            consumption: consumption[index].text,
                            generation: data.monthlyGenerations[index],
                            balance: data.monthlyBalances[index],
                          ),
                        );
                      }),
                    );
                  },
                ),
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

  Widget _field(
    String label,
    TextEditingController controller, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> lookupProjectCep() async {
    final cep = _digitsOnly(addressZipCode.text);
    if (cep.length != 8) {
      _message('Informe um CEP válido com 8 números.');
      return;
    }

    try {
      final lookup = await widget.repository.lookupCep(cep);
      _fillAddress(
        ProjectAddress(
          zipCode: lookup.zipCode,
          street: lookup.street,
          addressNumber: addressNumber.text.trim(),
          neighborhood: lookup.neighborhood,
          city: lookup.city,
          state: lookup.state,
          addressComplement: addressComplement.text.trim(),
        ),
      );
      _message('Endereço deste orçamento preenchido pelo CEP.');
    } catch (error) {
      if (!mounted) return;
      _message(
        friendlyNetworkError(
          error,
          fallback: 'Não foi possível consultar o CEP agora.',
        ),
      );
    }
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

  Future<void> fillHspFromProjectAddress() async {
    final address = currentAddress;
    if (address.zipCode.isEmpty && address.cityState.isEmpty) {
      _message('Informe o endereço deste orçamento antes de buscar HSP.');
      return;
    }

    setState(() => loadingHsp = true);
    try {
      final lookup = await widget.repository.lookupMonthlyHspWithPvgis(
        address: address,
      );
      if (lookup.monthlyHsp.length < 12) {
        _message('PVGIS não retornou HSP médio diário completo.');
        return;
      }

      for (var i = 0; i < 12; i++) {
        hsp[i].text = lookup.monthlyHsp[i].toStringAsFixed(2);
      }
      calculate();
      if (!mounted) return;
      setState(() => hspPvgisLookup = lookup);
      _message('HSP médio diário preenchido pelo PVGIS.');
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
    final address = currentAddress;
    final hasCoordinates = latitude != null && longitude != null;
    if (data == null || data.systemPower <= 0) {
      _message('Calcule o dimensionamento antes de validar.');
      return;
    }
    if (!hasCoordinates &&
        address.zipCode.isEmpty &&
        address.cityState.isEmpty) {
      _message('Informe o endereço deste orçamento antes de validar.');
      return;
    }

    setState(() => validatingPvgis = true);
    try {
      final validation = await widget.repository.validateWithPvgis(
        address: address,
        latitude: latitude,
        longitude: longitude,
        installedPowerKwp: data.systemPower,
        estimatedAnnualGeneration: data.annualGeneration,
      );
      if (!mounted) return;
      setState(() {
        pvgisValidation = validation;
        pvgisGenerationApplied = false;
      });
      final threshold = _formatPercent(
        PvgisValidationResult.reviewThresholdPercent,
      );
      _message(validation.needsReview
          ? 'Diferença entre os métodos acima de $threshold. Revise as premissas.'
          : 'Comparação PVGIS dentro da faixa de $threshold.');
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
      pvgisGenerationApplied = true;
    });
    _message('Geração ajustada com base no PVGIS.');
  }

  void acceptPvgisValidation() {
    if (pvgisValidation == null) return;
    _message('Estimativa Solar Pro mantida.');
  }

  void _clearHspLookupMetadata() {
    if (hspPvgisLookup == null) return;
    setState(() => hspPvgisLookup = null);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _friendlyPvgisError(Object error) {
    final text = friendlyNetworkError(
      error,
      fallback:
          'Não foi possível validar no PVGIS. Confira o endereço e a conexão.',
    );
    if (text.isEmpty) {
      return 'Não foi possível validar no PVGIS. Confira o endereço e a conexão.';
    }
    if (text.length > 220) return '${text.substring(0, 220)}...';
    return text;
  }

  String _formatPercent(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.001) return '${rounded.toInt()}%';
    return '${value.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');
}

class _MaterialItem {
  const _MaterialItem({required this.name, required this.value});

  final String name;
  final double value;

  Map<String, dynamic> toMap() => {'name': name, 'value': value};
}

class _ProjectAddressFields extends StatelessWidget {
  const _ProjectAddressFields({
    required this.zipCode,
    required this.street,
    required this.addressNumber,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.addressComplement,
    required this.onLookupCep,
  });

  final TextEditingController zipCode;
  final TextEditingController street;
  final TextEditingController addressNumber;
  final TextEditingController neighborhood;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController addressComplement;
  final VoidCallback onLookupCep;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 680;
        if (!twoColumns) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _addressField('CEP', zipCode)),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onLookupCep,
                    icon: const Icon(Icons.search_rounded, size: 17),
                    label: const Text('Buscar'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _addressField('Rua', street),
              const SizedBox(height: 10),
              _addressField('Número', addressNumber),
              const SizedBox(height: 10),
              _addressField('Bairro', neighborhood),
              const SizedBox(height: 10),
              _addressField('Cidade', city),
              const SizedBox(height: 10),
              _addressField('Estado', state),
              const SizedBox(height: 10),
              _addressField('Complemento', addressComplement),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _addressField('CEP', zipCode)),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onLookupCep,
                  icon: const Icon(Icons.search_rounded, size: 17),
                  label: const Text('Buscar CEP'),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _addressField('Rua', street)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _addressField('Número', addressNumber)),
                const SizedBox(width: 10),
                Expanded(child: _addressField('Bairro', neighborhood)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _addressField('Cidade', city)),
                const SizedBox(width: 10),
                Expanded(child: _addressField('Estado', state)),
              ],
            ),
            const SizedBox(height: 10),
            _addressField('Complemento', addressComplement),
          ],
        );
      },
    );
  }

  Widget _addressField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({
    required this.address,
    required this.onUseCurrentLocation,
  });

  final ProjectAddress address;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final addressLine = address.addressLine.trim();
    final hasAddress = addressLine.isNotEmpty;

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
                          ? addressLine
                          : 'Complete o endereço deste orçamento para validar pelo PVGIS.',
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

class _HspPvgisSourceCard extends StatelessWidget {
  const _HspPvgisSourceCard({required this.lookup});

  final PvgisValidationResult lookup;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _PvgisDetailRow(
        label: 'HSP médio anual',
        value:
            '${_formatNumber(_weightedAnnualHsp(lookup.monthlyHsp), 2)} h/dia',
      ),
      if (lookup.pvgisRadiationDatabase != null)
        _PvgisDetailRow(
          label: 'Base solar',
          value: lookup.pvgisRadiationDatabase!,
        ),
      _PvgisDetailRow(
        label: 'Plano dos módulos',
        value: _planeLabel(lookup),
      ),
      if (lookup.pvSlope != null)
        _PvgisDetailRow(
          label: 'Inclinação',
          value: '${_formatDegrees(lookup.pvSlope!)}°',
        ),
      if (lookup.pvAzimuth != null)
        _PvgisDetailRow(
          label: 'Azimute',
          value:
              '${_formatDegrees(lookup.pvAzimuth!)}° (${_cardinalDirection(lookup.pvAzimuth!)})',
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.green.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preenchido pelo PVGIS',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ...rows,
          if (lookup.geocodingProvider == 'nominatim') ...[
            const SizedBox(height: 4),
            const Text(
              '© OpenStreetMap contributors - openstreetmap.org/copyright',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PvgisValidationCard extends StatelessWidget {
  const _PvgisValidationCard({
    required this.validation,
    required this.validating,
    required this.sizingPerformanceRatio,
    required this.pvgisGenerationApplied,
    required this.onValidate,
    required this.onAdjust,
    required this.onAccept,
  });

  final PvgisValidationResult? validation;
  final bool validating;
  final double sizingPerformanceRatio;
  final bool pvgisGenerationApplied;
  final VoidCallback onValidate;
  final VoidCallback onAdjust;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final data = validation;
    final needsReview = data?.needsReview == true && !pvgisGenerationApplied;
    final color = data == null
        ? AppTheme.primaryBlue
        : pvgisGenerationApplied
            ? AppTheme.green
            : needsReview
                ? AppTheme.orange
                : AppTheme.green;
    final label = data == null
        ? 'Não comparado'
        : pvgisGenerationApplied
            ? 'PVGIS aplicado'
            : data.badgeLabel;
    final solarProPrLabel =
        'Solar Pro (PR ${(sizingPerformanceRatio * 100).toStringAsFixed(0)}%)';
    final pvgisLoss = data?.pvgisSystemLossPercent;
    final pvgisLabel = pvgisLoss == null
        ? 'PVGIS'
        : 'PVGIS (perdas sistema ${pvgisLoss.toStringAsFixed(0)}%)';
    final comparisonText = data == null
        ? 'Compare a estimativa simplificada do Solar Pro com a simulação do PVGIS.'
        : pvgisGenerationApplied
            ? 'A geração mensal do resultado foi ajustada para os valores do PVGIS.'
            : _pvgisComparisonText(data);

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
                        needsReview && !pvgisGenerationApplied
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
                      'Comparação PVGIS',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comparisonText,
                      style:
                          const TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 420;
                final tiles = [
                  _PvgisMetricTile(
                    label: solarProPrLabel,
                    value:
                        '${_formatKwhYear(data.estimatedAnnualGeneration)} kWh/ano',
                  ),
                  _PvgisMetricTile(
                    label: pvgisLabel,
                    value:
                        '${_formatKwhYear(data.pvgisAnnualGeneration)} kWh/ano',
                  ),
                ];
                if (!wide) {
                  return Column(
                    children: [
                      tiles.first,
                      const SizedBox(height: 8),
                      tiles.last,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: tiles.first),
                    const SizedBox(width: 8),
                    Expanded(child: tiles.last),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            _PvgisSimulationDetails(
              data: data,
              sizingPerformanceRatio: sizingPerformanceRatio,
            ),
            if (data.geocodingProvider == 'nominatim') ...[
              const SizedBox(height: 8),
              const Text(
                '© OpenStreetMap contributors - openstreetmap.org/copyright',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                  validating ? 'Comparando...' : 'Comparar com PVGIS',
                ),
              ),
              if (data != null && data.needsReview && !pvgisGenerationApplied)
                ElevatedButton.icon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('Usar geração PVGIS'),
                ),
              if (data != null && data.needsReview && !pvgisGenerationApplied)
                TextButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Manter Solar Pro'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _pvgisComparisonText(PvgisValidationResult data) {
    if (data.isEquivalentForDisplay) {
      return 'Os dois métodos apresentam geração anual equivalente.';
    }

    final percent =
        data.absoluteDifferencePercent.toStringAsFixed(1).replaceAll('.', ',');
    if (data.isPvgisHigher) {
      return 'PVGIS estima $percent% mais geração que o Solar Pro.';
    }
    if (data.isPvgisLower) {
      return 'PVGIS estima $percent% menos geração que o Solar Pro.';
    }
    return 'Os dois métodos apresentam geração anual equivalente.';
  }
}

class _PvgisSimulationDetails extends StatelessWidget {
  const _PvgisSimulationDetails({
    required this.data,
    required this.sizingPerformanceRatio,
  });

  final PvgisValidationResult data;
  final double sizingPerformanceRatio;

  @override
  Widget build(BuildContext context) {
    final threshold = _formatPercent(
      PvgisValidationResult.reviewThresholdPercent,
    );
    final rows = <Widget>[
      if (data.pvgisRadiationDatabase != null)
        _PvgisDetailRow(
            label: 'Base solar', value: data.pvgisRadiationDatabase!),
      _PvgisDetailRow(label: 'Plano dos módulos', value: _planeLabel(data)),
      if (data.pvSlope != null)
        _PvgisDetailRow(
          label: 'Inclinação',
          value: '${_formatDegrees(data.pvSlope!)}°',
        ),
      if (data.pvAzimuth != null)
        _PvgisDetailRow(
          label: 'Azimute',
          value:
              '${_formatDegrees(data.pvAzimuth!)}° (${_cardinalDirection(data.pvAzimuth!)})',
        ),
      if (data.pvgisAnnualPlaneIrradiationKwhM2 != null)
        _PvgisDetailRow(
          label: 'Irradiação anual no plano',
          value:
              '${_formatNumber(data.pvgisAnnualPlaneIrradiationKwhM2!, 0)} kWh/m²/ano',
        ),
      if (data.pvgisAnnualGenerationSdKwh != null)
        _PvgisDetailRow(
          label: 'Variabilidade anual (desvio padrão)',
          value: '${_formatNumber(data.pvgisAnnualGenerationSdKwh!, 0)} kWh',
        ),
      _PvgisDetailRow(label: 'Localização', value: _locationLabel(data)),
      if (data.geocodingProvider == 'nominatim')
        _PvgisDetailRow(
          label: 'Nível da localização',
          value: _geocodingLevelLabel(data.geocodingLevel),
        ),
    ];

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: false,
        title: const Text(
          'Detalhes da simulação',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        children: [
          ...rows,
          if (data.locationLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text(
              'Referência localizada',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.locationLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Faixa de revisão Solar Pro: ±$threshold.',
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'O PR do Solar Pro (${(sizingPerformanceRatio * 100).toStringAsFixed(0)}%) e as perdas informadas ao PVGIS são premissas de modelos diferentes e não são diretamente equivalentes.',
            style: const TextStyle(color: AppTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatPercent(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.001) return '${rounded.toInt()}%';
    return '${value.toStringAsFixed(1).replaceAll('.', ',')}%';
  }
}

class _PvgisMetricTile extends StatelessWidget {
  const _PvgisMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _PvgisDetailRow extends StatelessWidget {
  const _PvgisDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

double _weightedAnnualHsp(List<double> monthlyHsp) {
  if (monthlyHsp.length < 12) return 0;
  var weighted = 0.0;
  for (var i = 0; i < 12; i++) {
    weighted += monthlyHsp[i] * SizingService.daysInMonth[i];
  }
  return weighted / 365;
}

String _planeLabel(PvgisValidationResult data) {
  if (data.orientationMode == 'automatic') {
    return 'otimizado pelo PVGIS';
  }
  return 'definido para a simulação';
}

String _locationLabel(PvgisValidationResult data) {
  if (data.locationSource == 'current_location') {
    return 'GPS do dispositivo';
  }

  switch (data.geocodingLevel) {
    case 'street_number':
      return 'Localização pelo endereço';
    case 'street':
      return 'Localização pelo logradouro';
    case 'neighborhood':
      return 'Localização pelo bairro';
    case 'postal_code':
      return 'Localização aproximada pelo CEP';
    case 'city':
      return 'Localização aproximada pela cidade';
  }
  return 'Endereço do projeto';
}

String _geocodingLevelLabel(String? level) {
  switch (level) {
    case 'street_number':
      return 'Endereço com número';
    case 'street':
      return 'Logradouro';
    case 'neighborhood':
      return 'Bairro';
    case 'postal_code':
      return 'CEP';
    case 'city':
      return 'Cidade';
  }
  return 'Endereço';
}

String _formatKwhYear(double value) {
  return value.round().toString();
}

String _formatNumber(double value, int fractionDigits) {
  return value
      .toStringAsFixed(fractionDigits)
      .replaceAll('.', ',')
      .replaceAll(RegExp(r',0$'), '');
}

String _formatDegrees(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) return rounded.toInt().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _cardinalDirection(double degrees) {
  final normalized = ((degrees % 360) + 360) % 360;
  const labels = ['N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO'];
  final index = ((normalized + 22.5) ~/ 45) % 8;
  return labels[index];
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
    return MonthlyEnergyBars(
      month: month,
      consumption: consumed,
      generation: generation,
      balance: balance,
    );
  }

  double _number(String text) {
    final normalized = text.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
}
