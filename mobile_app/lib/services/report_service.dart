import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/client.dart';
import '../models/project.dart';
import '../models/project_status.dart';
import 'report_file_saver.dart';
import 'solarpro_repository.dart';

enum ReportType {
  monthlySales('Mensal de Vendas'),
  projects('Projetos');

  const ReportType(this.label);
  final String label;
}

enum ReportFormat {
  csv('CSV'),
  pdf('PDF');

  const ReportFormat(this.label);
  final String label;
}

class ReportFile {
  const ReportFile({
    required this.reportType,
    required this.format,
    required this.savedReport,
  });

  final ReportType reportType;
  final ReportFormat format;
  final SavedReport savedReport;

  String get fileName => savedReport.fileName;
  String? get path => savedReport.path;
}

class ReportService {
  ReportService(this.repository);

  final SolarProRepository repository;

  static const _headers = [
    'Projeto',
    'Cliente',
    'Status',
    'Valor do projeto',
    'Data de criação',
    'Potência instalada',
    'Geração anual estimada',
    'Payback',
    'Economia mensal estimada',
  ];

  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _number = NumberFormat.decimalPattern('pt_BR');
  final _date = DateFormat('dd/MM/yyyy');
  final _stamp = DateFormat('yyyyMMdd_HHmm');

  Future<ReportFile> generateProjectsReport({
    required ReportType type,
    required ReportFormat format,
  }) async {
    final projects = await repository.loadProjects(cacheFirst: true);
    final clients = await repository.loadClients(cacheFirst: true);
    final rows = _projectRows(_filterProjects(projects, type), clients);

    return switch (format) {
      ReportFormat.csv => _generateCsv(type: type, rows: rows),
      ReportFormat.pdf => _generatePdf(type: type, rows: rows),
    };
  }

  Future<void> shareReport(ReportFile report) async {
    await SharePlus.instance.share(
      ShareParams(
        text: report.reportType == ReportType.monthlySales
            ? 'Relatório mensal de vendas Solar Pro'
            : 'Relatório de projetos Solar Pro',
        files: [report.savedReport.xFile],
      ),
    );
  }

  Future<void> downloadReport(ReportFile report) async {
    await downloadSavedReport(report.savedReport);
  }

  Future<void> printPdfReport(ReportFile report) async {
    if (report.format != ReportFormat.pdf) return;
    final bytes = await report.savedReport.xFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<ReportFile> _generateCsv({
    required ReportType type,
    required List<_ProjectReportRow> rows,
  }) async {
    final content = const CsvEncoder(
      fieldDelimiter: ';',
      quoteCharacter: '"',
      lineDelimiter: '\n',
    ).convert([
      _headers,
      ...rows.map((row) => row.csvValues),
      [],
      ['Totais'],
      ['Quantidade de projetos', rows.length],
      [
        'Soma de valores',
        rows.fold<double>(0, (sum, row) => sum + row.project.projectValue),
      ],
      [
        'Soma de geração',
        rows.fold<double>(0, (sum, row) => sum + row.project.annualGeneration),
      ],
    ]);

    final saved = await saveReportBytes(
      fileName: _fileName(type, 'csv'),
      mimeType: 'text/csv',
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
    return ReportFile(
      reportType: type,
      format: ReportFormat.csv,
      savedReport: saved,
    );
  }

  Future<ReportFile> _generatePdf({
    required ReportType type,
    required List<_ProjectReportRow> rows,
  }) async {
    final document = pw.Document();
    final totalValue =
        rows.fold<double>(0, (sum, row) => sum + row.project.projectValue);
    final totalGeneration =
        rows.fold<double>(0, (sum, row) => sum + row.project.annualGeneration);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório de Projetos',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${type.label} • Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Solar Pro • Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: _headers,
            data: rows.map((row) => row.pdfValues).toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green600),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _totalBox('Projetos', '${rows.length}'),
                _totalBox('Soma de valores', _money.format(totalValue)),
                _totalBox(
                  'Soma de geração',
                  '${_number.format(totalGeneration)} kWh',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final saved = await saveReportBytes(
      fileName: _fileName(type, 'pdf'),
      mimeType: 'application/pdf',
      bytes: await document.save(),
    );
    return ReportFile(
      reportType: type,
      format: ReportFormat.pdf,
      savedReport: saved,
    );
  }

  pw.Widget _totalBox(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  List<Project> _filterProjects(List<Project> projects, ReportType type) {
    if (type == ReportType.projects) return projects;
    final now = DateTime.now();
    return projects.where((project) {
      final date = DateTime.tryParse(project.projectDate);
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();
  }

  List<_ProjectReportRow> _projectRows(
    List<Project> projects,
    List<Client> clients,
  ) {
    final clientsById = {for (final client in clients) client.id: client};
    return projects.map((project) {
      return _ProjectReportRow(
        project: project,
        client: clientsById[project.clientId],
        money: _money,
        number: _number,
        date: _date,
      );
    }).toList();
  }

  String _fileName(ReportType type, String extension) {
    final typeSlug =
        type == ReportType.monthlySales ? 'mensal_vendas' : 'projetos';
    return 'solarpro_${typeSlug}_${_stamp.format(DateTime.now())}.$extension';
  }
}

class _ProjectReportRow {
  const _ProjectReportRow({
    required this.project,
    required this.client,
    required this.money,
    required this.number,
    required this.date,
  });

  final Project project;
  final Client? client;
  final NumberFormat money;
  final NumberFormat number;
  final DateFormat date;

  String get projectLabel => project.id == null ? '-' : '#${project.id}';

  String get clientLabel {
    final name = client?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    final projectName = project.clientName.trim();
    return projectName.isEmpty ? 'Cliente sem nome' : projectName;
  }

  String get createdAt {
    final parsed = DateTime.tryParse(project.projectDate);
    return parsed == null ? project.projectDate : date.format(parsed);
  }

  List<Object> get csvValues => [
        projectLabel,
        clientLabel,
        ProjectStatus.labelFor(project.status),
        project.projectValue,
        createdAt,
        project.systemPower,
        project.annualGeneration,
        project.paybackYears,
        project.monthlySavings,
      ];

  List<String> get pdfValues => [
        projectLabel,
        clientLabel,
        ProjectStatus.labelFor(project.status),
        money.format(project.projectValue),
        createdAt,
        '${number.format(project.systemPower)} kWp',
        '${number.format(project.annualGeneration)} kWh',
        '${number.format(project.paybackYears)} anos',
        money.format(project.monthlySavings),
      ];
}
