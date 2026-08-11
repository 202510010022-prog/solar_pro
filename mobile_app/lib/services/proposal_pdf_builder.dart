import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/app_subscription.dart';
import '../models/client.dart';
import '../models/project.dart';

class ProjectProposalPdfBuilder {
  ProjectProposalPdfBuilder();

  static const _primary = PdfColor(0.137, 0, 0.682);
  static const _navy = PdfColor(0, 0.122, 0.2);
  static const _yellow = PdfColor(0.992, 0.824, 0.165);
  static const _softPurple = PdfColor(0.953, 0.945, 1);
  static const _border = PdfColor(0.863, 0.89, 0.918);
  static const _muted = PdfColor(0.424, 0.467, 0.525);

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
  final _date = DateFormat('dd/MM/yyyy');

  Future<Uint8List> build({
    required Project project,
    required Client? client,
    required AppSubscription? subscription,
    DateTime? generatedAt,
  }) async {
    final now = generatedAt ?? DateTime.now();
    final validUntil = now.add(const Duration(days: 15));
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => _footer(context, project),
        build: (_) => [
          _header(
            companyName: subscription?.companyName,
            generatedAt: now,
            validUntil: validUntil,
            project: project,
          ),
          pw.SizedBox(height: 18),
          _section(
            title: 'Cliente e instalação',
            children: [
              _twoColumns(
                left: _infoBox(
                  title: 'Dados do cliente',
                  rows: [
                    _row('Nome', client?.name ?? project.clientName),
                    _row('Documento', client?.document ?? ''),
                    _row('Telefone', client?.phone ?? ''),
                    _row('E-mail', client?.email ?? ''),
                  ],
                ),
                right: _infoBox(
                  title: 'Endereço da instalação',
                  rows: [
                    _row('Endereço', _installationAddress(project)),
                    _row('Complemento', project.address.addressComplement),
                  ],
                ),
              ),
            ],
          ),
          _section(
            title: 'Resumo técnico',
            children: [
              pw.Row(
                children: [
                  _metric('Potência', '${_decimal(project.systemPower)} kWp'),
                  pw.SizedBox(width: 8),
                  _metric('Módulos', '${project.moduleCount} un.'),
                  pw.SizedBox(width: 8),
                  _metric(
                    'Geração anual',
                    '${_kwh.format(project.annualGeneration)} kWh',
                  ),
                  pw.SizedBox(width: 8),
                  _metric(
                    'Geração média',
                    '${_kwh.format(project.monthlyGeneration)} kWh/mês',
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              _infoBox(
                title: 'Equipamentos inclusos',
                rows: [
                  _row('Potência do módulo',
                      '${_decimal(project.modulePower)} W'),
                  _row('Módulos', '${project.moduleCount} unidades'),
                  _row('Inversor', 'Incluso'),
                  _row('Estrutura de fixação', 'Inclusa'),
                  ...project.extraMaterials.map(
                    (item) => _row(item.name, 'Incluso'),
                  ),
                ],
              ),
            ],
          ),
          _section(
            title: 'Geração mensal estimada',
            children: [
              pw.TableHelper.fromTextArray(
                headers: const ['Mês', 'Consumo', 'Geração', 'Saldo'],
                data: List.generate(12, (index) {
                  final consumption = _at(project.monthlyConsumptions, index);
                  final generation = _at(project.monthlyGenerations, index);
                  final balance = _at(project.monthlyBalances, index);
                  return [
                    _months[index],
                    '${_kwh.format(consumption)} kWh',
                    '${_kwh.format(generation)} kWh',
                    '${_kwh.format(balance)} kWh',
                  ];
                }),
                headerDecoration: const pw.BoxDecoration(color: _navy),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                border: pw.TableBorder.all(color: _border, width: 0.5),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
              ),
            ],
          ),
          _section(
            title: 'Resumo financeiro',
            children: [
              _twoColumns(
                left: _infoBox(
                  title: 'Investimento',
                  rows: [
                    _row('Valor do projeto',
                        _money.format(project.projectValue)),
                    if (project.discount > 0)
                      _row('Desconto', _money.format(project.discount)),
                    if (project.downPayment > 0)
                      _row('Entrada', _money.format(project.downPayment)),
                    _row('Condição', _paymentTerms(project)),
                  ],
                ),
                right: _infoBox(
                  title: 'Retorno estimado',
                  rows: [
                    _row(
                      'Economia mensal',
                      _money.format(project.monthlySavings),
                    ),
                    _row('Payback', '${_decimal(project.paybackYears)} anos'),
                    _row(
                      'Tarifa considerada',
                      '${_money.format(project.energyTariff)}/kWh',
                    ),
                  ],
                ),
              ),
              if (project.financialNotes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 8),
                _noteBox('Observações', project.financialNotes),
              ],
            ],
          ),
          _noteBox(
            'Aviso',
            'Valores estimados com base nos dados informados e irradiação disponível.',
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header({
    required String? companyName,
    required DateTime generatedAt,
    required DateTime validUntil,
    required Project project,
  }) {
    final displayCompany = companyName?.trim().isNotEmpty == true
        ? companyName!.trim()
        : 'Solar Pro';
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 6, height: 78, color: _yellow),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  displayCompany,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Proposta Comercial',
                  style: pw.TextStyle(
                    color: _yellow,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Projeto ${project.id == null ? '' : '#${project.id}'}',
                  style:
                      const pw.TextStyle(color: PdfColors.white, fontSize: 10),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _headerDate('Gerada em', _date.format(generatedAt)),
              pw.SizedBox(height: 6),
              _headerDate('Validade', _date.format(validUntil)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _headerDate(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey300)),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _section({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _primary,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          ...children,
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

  pw.Widget _infoBox({
    required String title,
    required List<_ProposalRow> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _navy,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          ...rows.where((row) => row.value.trim().isNotEmpty).map(_infoRow),
        ],
      ),
    );
  }

  pw.Widget _infoRow(_ProposalRow row) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 84,
            child: pw.Text(
              row.label,
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              _orDash(row.value),
              style: pw.TextStyle(
                color: _navy,
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metric(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _softPurple,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: _border),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(color: _muted, fontSize: 8)),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _noteBox(String title, String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _navy,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(text, style: const pw.TextStyle(color: _muted, fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context, Project project) {
    final seller = project.sellerName?.trim();
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            seller == null || seller.isEmpty
                ? 'Vendedor não atribuído'
                : 'Vendedor responsável: $seller',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  _ProposalRow _row(String label, String value) {
    return _ProposalRow(label, value);
  }

  double _at(List<double> values, int index) {
    return index < values.length ? values[index] : 0;
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
    final dueDate = project.firstDueDate;
    if (dueDate != null) parts.add('1º vencimento: ${_date.format(dueDate)}');
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

  String _decimal(double value) {
    return NumberFormat.decimalPatternDigits(
      locale: 'pt_BR',
      decimalDigits: value.abs() >= 10 ? 0 : 2,
    ).format(value);
  }

  String _orDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }
}

class _ProposalRow {
  const _ProposalRow(this.label, this.value);

  final String label;
  final String value;
}
