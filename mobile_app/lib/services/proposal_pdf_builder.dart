import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_subscription.dart';
import '../models/client.dart';
import '../models/project.dart';

class ProjectProposalPdfBuilder {
  ProjectProposalPdfBuilder();

  static const _months = [
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
    'Dez',
  ];

  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _kwh = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 1,
  );
  final _kwp = NumberFormat.decimalPatternDigits(
    locale: 'pt_BR',
    decimalDigits: 2,
  );
  final _integer = NumberFormat.decimalPattern('pt_BR');
  final _date = DateFormat('dd/MM/yyyy');

  Future<Uint8List> build({
    required Project project,
    required Client? client,
    required AppSubscription? subscription,
    DateTime? generatedAt,
  }) async {
    final now = generatedAt ?? DateTime.now();
    final validUntil = now.add(const Duration(days: 15));
    final logo = await _loadLogo();
    final pdfTheme = await _loadPdfTheme();
    final document = pw.Document();
    final companyName = _companyName(subscription);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pdfTheme,
        margin: const pw.EdgeInsets.fromLTRB(
          ProposalPdfSpacing.page,
          ProposalPdfSpacing.page,
          ProposalPdfSpacing.page,
          36,
        ),
        footer: (context) => _footer(
          context: context,
          companyName: companyName,
          project: project,
        ),
        build: (_) => [
          _header(
            logo: logo,
            companyName: companyName,
            generatedAt: now,
            validUntil: validUntil,
            project: project,
          ),
          pw.SizedBox(height: 12),
          _clientSection(project: project, client: client),
          _technicalSummary(project),
          _financialHighlight(project),
          _generationSection(project),
          _equipmentSection(project),
          _includedScopeSection(project),
          _warrantySection(project),
          _commercialTermsSection(project: project, validUntil: validUntil),
          _technicalNotesSection(project),
          _acceptanceSection(project, client),
        ],
      ),
    );

    return document.save();
  }

  Future<pw.ThemeData> _loadPdfTheme() async {
    try {
      final regular =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final bold = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      return pw.ThemeData.withFont(
        base: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
      );
    } catch (_) {
      return pw.ThemeData.base();
    }
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final bytes = await rootBundle.load('assets/branding/solar_pro_logo.png');
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  pw.Widget _header({
    required pw.MemoryImage? logo,
    required String companyName,
    required DateTime generatedAt,
    required DateTime validUntil,
    required Project project,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: ProposalPdfColors.navy,
        borderRadius: pw.BorderRadius.circular(ProposalPdfRadii.large),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Container(
                    height: 42,
                    width: 142,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius:
                          pw.BorderRadius.circular(ProposalPdfRadii.medium),
                    ),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                pw.SizedBox(height: 10),
                pw.Text('SOLAR PRO', style: ProposalPdfText.headerBrand),
                pw.SizedBox(height: 2),
                pw.Text('Energia Solar', style: ProposalPdfText.headerSubtitle),
                pw.SizedBox(height: 10),
                pw.Text(
                  'PROPOSTA COMERCIAL',
                  style: ProposalPdfText.headerTitle,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Sistema Fotovoltaico',
                  style: ProposalPdfText.headerSubtitle,
                ),
                pw.SizedBox(height: 10),
                _smallPill('Proposta ${_projectNumber(project)}'),
              ],
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Container(
            width: 142,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: ProposalPdfColors.navyLight,
              borderRadius: pw.BorderRadius.circular(ProposalPdfRadii.medium),
              border: pw.Border.all(color: ProposalPdfColors.navyBorder),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _headerInfo('Gerada em', _date.format(generatedAt)),
                pw.SizedBox(height: 10),
                _headerInfo('Validade', _date.format(validUntil)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _clientSection({
    required Project project,
    required Client? client,
  }) {
    final clientCard = _infoCard(
      title: 'Cliente',
      rows: [
        _row('Nome completo', client?.name ?? project.clientName),
        _row('CPF/CNPJ', client?.document ?? ''),
        _row('Telefone', client?.phone ?? ''),
        _row('E-mail', client?.email ?? ''),
      ],
    );
    final addressCard = _infoCard(
      title: 'Local da instalação',
      rows: [
        _row('Endereço', _installationAddress(project)),
        _row('Complemento', project.address.addressComplement),
      ],
    );
    final hasAddress = _hasInstallationAddress(project);

    return _section(
      'CLIENTE E INSTALAÇÃO',
      [
        if (hasAddress) _twoColumns(left: clientCard, right: addressCard),
        if (!hasAddress) clientCard,
      ],
    );
  }

  pw.Widget _technicalSummary(Project project) {
    return _section(
      'RESUMO DO SISTEMA',
      [
        pw.Row(
          children: [
            _summaryCard(
              label: 'Potência instalada',
              value: '${_kwp.format(project.systemPower)} kWp',
            ),
            pw.SizedBox(width: 8),
            _summaryCard(
              label: 'Módulos',
              value: '${_integer.format(project.moduleCount)} un.',
            ),
            pw.SizedBox(width: 8),
            _summaryCard(
              label: 'Geração anual estimada',
              value: '${_kwh.format(project.annualGeneration)} kWh',
            ),
            pw.SizedBox(width: 8),
            _summaryCard(
              label: 'Geração média',
              value: '${_kwh.format(project.monthlyGeneration)} kWh/mês',
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _financialHighlight(Project project) {
    final annualSavings = project.monthlySavings * 12;
    final hasReturnData = _hasReturnData(project);
    return _section(
      'DESTAQUE FINANCEIRO',
      minFirstBlockHeight: 176,
      [
        pw.Row(
          children: [
            _financialCard(
              label: 'Investimento',
              value: _money.format(project.projectValue),
              accent: ProposalPdfColors.navy,
            ),
            pw.SizedBox(width: 8),
            _financialCard(
              label: 'Economia estimada',
              value: hasReturnData
                  ? '${_money.format(project.monthlySavings)}/mês'
                  : 'Não calculada',
              accent: ProposalPdfColors.green,
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _financialCard(
              label: 'Economia anual',
              value: hasReturnData
                  ? '${_money.format(annualSavings)}/ano'
                  : 'Não calculada',
              accent: ProposalPdfColors.green,
            ),
            pw.SizedBox(width: 8),
            _financialCard(
              label: 'Payback estimado',
              value: hasReturnData
                  ? '${_fixed(project.paybackYears, 2)} anos'
                  : 'Não disponível',
              accent: ProposalPdfColors.goldDark,
            ),
          ],
        ),
        if (!hasReturnData) ...[
          pw.SizedBox(height: 8),
          _noteCard(
            'Informe o consumo da unidade para calcular economia e retorno.',
            compact: true,
          ),
        ],
      ],
    );
  }

  pw.Widget _generationSection(Project project) {
    final hasConsumption = _hasConsumptionData(project);
    return _section(
      hasConsumption ? 'CONSUMO X GERAÇÃO ESTIMADA' : 'GERAÇÃO MENSAL ESTIMADA',
      minFirstBlockHeight: 188,
      [
        _generationChart(project, showConsumption: hasConsumption),
        if (!hasConsumption) ...[
          pw.SizedBox(height: 7),
          pw.Text(
            'Consumo mensal não informado.',
            style: ProposalPdfText.tinyMuted,
          ),
        ],
        pw.SizedBox(height: 12),
        _monthlyTable(project, showConsumption: hasConsumption),
      ],
    );
  }

  pw.Widget _equipmentSection(Project project) {
    final rows = <_ProposalRow>[
      if (project.moduleCount > 0 && project.modulePower > 0)
        _row('Módulos fotovoltaicos',
            '${_integer.format(project.moduleCount)} × ${_fixed(project.modulePower, 0)} W'),
      _row('Inversor', 'Incluso'),
      _row('Estrutura de fixação', 'Inclusa'),
      ...project.extraMaterials
          .where((item) => item.name.trim().isNotEmpty)
          .map((item) => _row(item.name, 'Incluso')),
    ];
    if (rows.isEmpty) return pw.SizedBox();

    return _section(
      'EQUIPAMENTOS INCLUSOS',
      minFirstBlockHeight: 92,
      [
        _infoCard(
          title: 'Itens principais',
          rows: rows,
        ),
      ],
    );
  }

  pw.Widget _includedScopeSection(Project project) {
    final items = <String>[
      'Projeto e dimensionamento fotovoltaico',
      if (project.moduleCount > 0) 'Módulos fotovoltaicos',
      'Inversor',
      'Estrutura de fixação',
      if (project.laborCost > 0) 'Instalação',
      ...project.extraMaterials
          .map((item) => item.name.trim())
          .where((name) => name.isNotEmpty),
    ];
    final uniqueItems = <String>{...items}.toList();
    if (uniqueItems.isEmpty) return pw.SizedBox();

    return _section(
      'O QUE ESTÁ INCLUSO',
      [
        _checkGrid(uniqueItems),
      ],
    );
  }

  pw.Widget _warrantySection(Project project) {
    final warrantyRows = <_ProposalRow>[];
    if (warrantyRows.isEmpty) return pw.SizedBox();

    return _section(
      'GARANTIAS',
      [
        _infoCard(title: 'Garantias disponíveis', rows: warrantyRows),
      ],
    );
  }

  pw.Widget _commercialTermsSection({
    required Project project,
    required DateTime validUntil,
  }) {
    return _section(
      'CONDIÇÕES COMERCIAIS',
      minFirstBlockHeight: 116,
      [
        _infoCard(
          title: 'Condições da proposta',
          rows: [
            _row('Valor do projeto', _money.format(project.projectValue)),
            if (project.discount > 0)
              _row('Desconto aplicado', _money.format(project.discount)),
            if (project.downPayment > 0)
              _row('Entrada', _money.format(project.downPayment)),
            _row('Condição de pagamento', _paymentTerms(project)),
            _row('Validade da proposta', _date.format(validUntil)),
            if (project.firstDueDate != null)
              _row('Primeiro vencimento', _date.format(project.firstDueDate!)),
            if (project.financialNotes.trim().isNotEmpty)
              _row('Observações comerciais', project.financialNotes),
          ],
        ),
      ],
    );
  }

  pw.Widget _technicalNotesSection(Project project) {
    return _section(
      'PREMISSAS E OBSERVAÇÕES',
      [
        _noteCard(
          'A geração apresentada é uma estimativa baseada nos dados '
          'informados, características do sistema e disponibilidade de '
          'irradiação solar. Os resultados reais podem variar em função de '
          'condições climáticas, orientação e inclinação dos módulos, '
          'sombreamento, temperatura, perdas do sistema e condições locais. '
          'A economia financeira também pode variar conforme tarifa de '
          'energia, perfil de consumo e regras aplicáveis de compensação de '
          'energia.',
        ),
      ],
    );
  }

  pw.Widget _acceptanceSection(Project project, Client? client) {
    return _section(
      'ACEITE DA PROPOSTA',
      minFirstBlockHeight: 140,
      [
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _signatureLine('Cliente', client?.name ?? project.clientName),
              _signatureLine('CPF/CNPJ', client?.document ?? ''),
              _signatureLine('Assinatura', ''),
              _signatureLine('Data', '____ / ____ / ______'),
              _signatureLine(
                'Consultor responsável',
                project.sellerName ?? 'Vendedor não atribuído',
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _generationChart(
    Project project, {
    required bool showConsumption,
  }) {
    final consumptions = List.generate(
      12,
      (index) => _at(project.monthlyConsumptions, index),
    );
    final generations = List.generate(
      12,
      (index) => _at(project.monthlyGenerations, index),
    );
    final maxValue = [
      ...consumptions,
      ...generations,
    ].fold<double>(0, math.max);
    final chartMax = maxValue <= 0 ? 1.0 : maxValue;

    return pw.Container(
      height: showConsumption ? 146 : 132,
      padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: _cardDecoration(color: ProposalPdfColors.greyBg),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              if (showConsumption) ...[
                _legend('Consumo', ProposalPdfColors.navy),
                pw.SizedBox(width: 12),
              ],
              _legend('Geração estimada', ProposalPdfColors.gold),
            ],
          ),
          pw.SizedBox(height: 7),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                final consumptionHeight = 92 * (consumptions[index] / chartMax);
                final generationHeight = 92 * (generations[index] / chartMax);
                return pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          if (showConsumption) ...[
                            _bar(
                              height: consumptionHeight,
                              color: ProposalPdfColors.navy,
                            ),
                            pw.SizedBox(width: 2),
                          ],
                          _bar(
                            height: generationHeight,
                            color: ProposalPdfColors.gold,
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        _months[index],
                        style: ProposalPdfText.tinyMuted,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _monthlyTable(
    Project project, {
    required bool showConsumption,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: ProposalPdfColors.border, width: 0.45),
      columnWidths: showConsumption
          ? const {
              0: pw.FlexColumnWidth(0.8),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.2),
            }
          : const {
              0: pw.FlexColumnWidth(0.8),
              1: pw.FlexColumnWidth(1.8),
            },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: ProposalPdfColors.navy),
          children: (showConsumption
                  ? ['Mês', 'Consumo', 'Geração', 'Saldo']
                  : ['Mês', 'Geração estimada'])
              .map((text) => _tableCell(
                    text,
                    header: true,
                    alignRight: text != 'Mês',
                  ))
              .toList(),
        ),
        ...List.generate(12, (index) {
          final consumption = _at(project.monthlyConsumptions, index);
          final generation = _at(project.monthlyGenerations, index);
          final balance = _at(project.monthlyBalances, index);
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.white : ProposalPdfColors.greyBg,
            ),
            children: showConsumption
                ? [
                    _tableCell(_months[index]),
                    _tableCell(
                      '${_kwh.format(consumption)} kWh',
                      alignRight: true,
                    ),
                    _tableCell(
                      '${_kwh.format(generation)} kWh',
                      alignRight: true,
                    ),
                    _tableCell(
                      '${_kwh.format(balance)} kWh',
                      alignRight: true,
                      textColor: balance < 0
                          ? ProposalPdfColors.red
                          : ProposalPdfColors.green,
                    ),
                  ]
                : [
                    _tableCell(_months[index]),
                    _tableCell(
                      '${_kwh.format(generation)} kWh',
                      alignRight: true,
                    ),
                  ],
          );
        }),
      ],
    );
  }

  pw.Widget _section(
    String title,
    List<pw.Widget> children, {
    double minFirstBlockHeight = 88,
  }) {
    final visibleChildren = children
        .where((child) => child.runtimeType.toString() != 'SizedBox')
        .toList();
    if (visibleChildren.isEmpty) return pw.SizedBox();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: ProposalPdfSpacing.section),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.NewPage(freeSpace: minFirstBlockHeight),
          pw.Container(
            padding: const pw.EdgeInsets.only(left: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                  color: ProposalPdfColors.gold,
                  width: 3,
                ),
              ),
            ),
            child: pw.Text(title, style: ProposalPdfText.sectionTitle),
          ),
          pw.SizedBox(height: 8),
          ...visibleChildren,
        ],
      ),
    );
  }

  pw.Widget _infoCard({
    required String title,
    required List<_ProposalRow> rows,
  }) {
    final visibleRows = rows
        .where((row) => row.value.trim().isNotEmpty)
        .where((row) => row.value.trim() != '-')
        .toList();
    if (visibleRows.isEmpty) return pw.SizedBox();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: ProposalPdfText.cardTitle),
          pw.SizedBox(height: 8),
          ...visibleRows.map(_infoRow),
        ],
      ),
    );
  }

  pw.Widget _summaryCard({
    required String label,
    required String value,
  }) {
    return pw.Expanded(
      child: pw.Container(
        height: 70,
        padding: const pw.EdgeInsets.all(10),
        decoration: _cardDecoration(color: ProposalPdfColors.greyBg),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label.toUpperCase(), style: ProposalPdfText.tinyMuted),
            pw.Text(value, style: ProposalPdfText.metricValue),
          ],
        ),
      ),
    );
  }

  pw.Widget _financialCard({
    required String label,
    required String value,
    required PdfColor accent,
  }) {
    return pw.Expanded(
      child: pw.Container(
        height: 74,
        padding: const pw.EdgeInsets.all(12),
        decoration: _cardDecoration(),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label.toUpperCase(), style: ProposalPdfText.tinyMuted),
            pw.Text(
              value,
              style: ProposalPdfText.financialValue.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _infoRow(_ProposalRow row) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 92,
            child: pw.Text(row.label, style: ProposalPdfText.label),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              row.value.trim(),
              style: ProposalPdfText.bodyStrong,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _noteCard(String text, {bool compact = false}) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(compact ? 9 : 12),
      decoration: _cardDecoration(color: ProposalPdfColors.greyBg),
      child: pw.Text(text, style: ProposalPdfText.bodyMuted),
    );
  }

  pw.Widget _checkGrid(List<String> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          return pw.Container(
            width: 245,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  margin: const pw.EdgeInsets.only(top: 3),
                  decoration: const pw.BoxDecoration(
                    color: ProposalPdfColors.gold,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Text(item, style: ProposalPdfText.body),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _signatureLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: 112,
            child: pw.Text(label, style: ProposalPdfText.label),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 3),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: ProposalPdfColors.border),
                ),
              ),
              child: pw.Text(
                value.trim(),
                style: ProposalPdfText.bodyStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _twoColumns({
    required pw.Widget left,
    required pw.Widget right,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: left),
        pw.SizedBox(width: 10),
        pw.Expanded(child: right),
      ],
    );
  }

  pw.Widget _smallPill(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: ProposalPdfColors.gold,
        borderRadius: pw.BorderRadius.circular(999),
      ),
      child: pw.Text(text, style: ProposalPdfText.pill),
    );
  }

  pw.Widget _headerInfo(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(), style: ProposalPdfText.headerLabel),
        pw.SizedBox(height: 3),
        pw.Text(value, style: ProposalPdfText.headerValue),
      ],
    );
  }

  pw.Widget _legend(String label, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 8, height: 8, color: color),
        pw.SizedBox(width: 4),
        pw.Text(label, style: ProposalPdfText.tinyMuted),
      ],
    );
  }

  pw.Widget _bar({
    required double height,
    required PdfColor color,
  }) {
    return pw.Container(
      width: 6,
      height: math.max(2, height),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(3),
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool header = false,
    bool alignRight = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: header
              ? ProposalPdfText.tableHeader
              : ProposalPdfText.tableBody.copyWith(
                  color: textColor ?? ProposalPdfColors.navy,
                ),
        ),
      ),
    );
  }

  pw.Widget _footer({
    required pw.Context context,
    required String companyName,
    required Project project,
  }) {
    final proposal = _projectNumber(project);
    final seller = project.sellerName?.trim();
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: ProposalPdfColors.border, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              companyName,
              style: ProposalPdfText.footer,
              maxLines: 1,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              seller == null || seller.isEmpty
                  ? 'Consultor não atribuído'
                  : 'Consultor: $seller',
              textAlign: pw.TextAlign.center,
              style: ProposalPdfText.footer,
              maxLines: 1,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              '$proposal  |  Página ${context.pageNumber} de ${context.pagesCount}',
              textAlign: pw.TextAlign.right,
              style: ProposalPdfText.footer,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  pw.BoxDecoration _cardDecoration({PdfColor color = PdfColors.white}) {
    return pw.BoxDecoration(
      color: color,
      borderRadius: pw.BorderRadius.circular(ProposalPdfRadii.medium),
      border: pw.Border.all(color: ProposalPdfColors.border, width: 0.6),
    );
  }

  _ProposalRow _row(String label, String value) {
    return _ProposalRow(label, value);
  }

  double _at(List<double> values, int index) {
    return index < values.length ? values[index] : 0;
  }

  bool _hasConsumptionData(Project project) {
    return project.annualConsumption > 0 ||
        project.monthlyConsumptions.any((value) => value > 0);
  }

  bool _hasReturnData(Project project) {
    return _hasConsumptionData(project) &&
        project.monthlySavings > 0 &&
        project.paybackYears > 0;
  }

  bool _hasInstallationAddress(Project project) {
    final address = project.address;
    return address.street.trim().isNotEmpty ||
        address.addressNumber.trim().isNotEmpty ||
        address.neighborhood.trim().isNotEmpty ||
        address.cityState.trim().isNotEmpty ||
        address.zipCode.trim().isNotEmpty ||
        address.addressComplement.trim().isNotEmpty;
  }

  String _companyName(AppSubscription? subscription) {
    final configuredName = subscription?.companyName.trim() ?? '';
    return configuredName.isEmpty ? 'Solar Pro' : configuredName;
  }

  String _projectNumber(Project project) {
    return project.id == null ? 'nº sem identificação' : 'nº ${project.id}';
  }

  String _paymentTerms(Project project) {
    final parts = <String>[];
    final type = project.paymentType.trim();
    if (type.isNotEmpty) parts.add(type);
    if (project.installmentsCount > 0 && project.installmentValue > 0) {
      parts.add(
        '${project.installmentsCount}x de ${_money.format(project.installmentValue)}',
      );
    }
    return parts.isEmpty ? 'A combinar' : parts.join(' - ');
  }

  String _installationAddress(Project project) {
    final address = project.address;
    final parts = <String>[
      if (address.street.trim().isNotEmpty)
        address.addressNumber.trim().isEmpty
            ? address.street.trim()
            : '${address.street.trim()}, ${address.addressNumber.trim()}',
      if (address.neighborhood.trim().isNotEmpty) address.neighborhood.trim(),
      if (address.cityState.trim().isNotEmpty) address.cityState.trim(),
      if (address.zipCode.trim().isNotEmpty) 'CEP ${address.zipCode.trim()}',
    ];
    return parts.join(' - ');
  }

  String _fixed(double value, int decimalDigits) {
    return NumberFormat.decimalPatternDigits(
      locale: 'pt_BR',
      decimalDigits: decimalDigits,
    ).format(value);
  }
}

class ProposalPdfColors {
  const ProposalPdfColors._();

  static const navy = PdfColor(0, 0.122, 0.2);
  static const navyLight = PdfColor(0.027, 0.184, 0.286);
  static const navyBorder = PdfColor(0.18, 0.31, 0.39);
  static const gold = PdfColor(0.992, 0.824, 0.165);
  static const goldDark = PdfColor(0.72, 0.51, 0.05);
  static const green = PdfColor(0.12, 0.56, 0.32);
  static const red = PdfColor(0.76, 0.16, 0.16);
  static const greyBg = PdfColor(0.965, 0.976, 0.988);
  static const border = PdfColor(0.863, 0.89, 0.918);
  static const muted = PdfColor(0.424, 0.467, 0.525);
}

class ProposalPdfSpacing {
  const ProposalPdfSpacing._();

  static const page = 28.0;
  static const section = 16.0;
}

class ProposalPdfRadii {
  const ProposalPdfRadii._();

  static const medium = 10.0;
  static const large = 14.0;
}

class ProposalPdfText {
  const ProposalPdfText._();

  static final headerBrand = pw.TextStyle(
    color: PdfColors.white,
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
  );
  static final headerTitle = pw.TextStyle(
    color: ProposalPdfColors.gold,
    fontSize: 22,
    fontWeight: pw.FontWeight.bold,
  );
  static const headerSubtitle = pw.TextStyle(
    color: PdfColors.white,
    fontSize: 11,
  );
  static const headerLabel = pw.TextStyle(
    color: PdfColors.grey300,
    fontSize: 7.5,
  );
  static final headerValue = pw.TextStyle(
    color: PdfColors.white,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );
  static final sectionTitle = pw.TextStyle(
    color: ProposalPdfColors.navy,
    fontSize: 12.5,
    fontWeight: pw.FontWeight.bold,
  );
  static final cardTitle = pw.TextStyle(
    color: ProposalPdfColors.navy,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );
  static const label = pw.TextStyle(
    color: ProposalPdfColors.muted,
    fontSize: 8.2,
  );
  static const body = pw.TextStyle(
    color: ProposalPdfColors.navy,
    fontSize: 8.8,
  );
  static final bodyStrong = pw.TextStyle(
    color: ProposalPdfColors.navy,
    fontSize: 8.8,
    fontWeight: pw.FontWeight.bold,
  );
  static const bodyMuted = pw.TextStyle(
    color: ProposalPdfColors.muted,
    fontSize: 8.4,
    lineSpacing: 2,
  );
  static const tinyMuted = pw.TextStyle(
    color: ProposalPdfColors.muted,
    fontSize: 7.6,
  );
  static final metricValue = pw.TextStyle(
    color: ProposalPdfColors.navy,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );
  static final financialValue = pw.TextStyle(
    color: ProposalPdfColors.navy,
    fontSize: 13.5,
    fontWeight: pw.FontWeight.bold,
  );
  static final pill = pw.TextStyle(
    color: ProposalPdfColors.navy,
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
  );
  static final tableHeader = pw.TextStyle(
    color: PdfColors.white,
    fontSize: 8.4,
    fontWeight: pw.FontWeight.bold,
  );
  static const tableBody = pw.TextStyle(
    color: ProposalPdfColors.navy,
    fontSize: 8,
  );
  static const footer = pw.TextStyle(
    color: ProposalPdfColors.muted,
    fontSize: 7.2,
  );
}

class _ProposalRow {
  const _ProposalRow(this.label, this.value);

  final String label;
  final String value;
}
