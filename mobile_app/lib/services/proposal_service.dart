import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_subscription.dart';
import '../models/client.dart';
import '../models/project.dart';
import 'proposal_pdf_builder.dart';
import 'report_file_saver.dart';
import 'solarpro_repository.dart';

class ProposalService {
  ProposalService(this.repository);

  final SolarProRepository repository;
  final _stamp = DateFormat('yyyyMMdd_HHmmss');

  Future<SavedReport> generateProjectProposal({
    required Project project,
    required AppSubscription? subscription,
    Client? client,
  }) async {
    final selectedClient = client ?? await _loadProjectClient(project.clientId);
    final bytes = await ProjectProposalPdfBuilder().build(
      project: project,
      client: selectedClient,
      subscription: subscription,
    );

    return saveReportBytes(
      fileName: _fileName(project),
      mimeType: 'application/pdf',
      bytes: bytes,
    );
  }

  Future<void> shareProposal(SavedReport proposal) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Proposta comercial Solar Pro',
        files: [proposal.xFile],
      ),
    );
  }

  Future<void> downloadProposal(SavedReport proposal) async {
    await downloadSavedReport(proposal);
  }

  Future<void> printProposal(SavedReport proposal) async {
    final bytes = await proposal.xFile.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<Client?> _loadProjectClient(int clientId) async {
    final clients = await repository.loadClients(cacheFirst: true);
    for (final client in clients) {
      if (client.id == clientId) return client;
    }
    return null;
  }

  String _fileName(Project project) {
    final suffix = project.id == null ? 'sem_id' : '${project.id}';
    return 'solarpro_proposta_${suffix}_${_stamp.format(DateTime.now())}.pdf';
  }
}
