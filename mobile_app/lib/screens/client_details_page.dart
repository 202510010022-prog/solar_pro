import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_profile.dart';
import '../models/client.dart';
import '../models/project.dart';
import '../models/project_payment.dart';
import '../models/project_status.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import '../widgets/payment_status_badge.dart';
import 'project_details_page.dart';

class ClientDetailsPage extends StatefulWidget {
  const ClientDetailsPage({
    super.key,
    required this.client,
    required this.repository,
    required this.profile,
  });

  final Client client;
  final SolarProRepository repository;
  final AppProfile? profile;

  @override
  State<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage> {
  late Future<_ClientProjectsData> projectsFuture;
  final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    projectsFuture = _loadProjects();
  }

  Future<_ClientProjectsData> _loadProjects() async {
    final canUseFinancial = widget.profile?.canUseFinancial == true;
    final results = await Future.wait([
      widget.repository.loadProjects(cacheFirst: false),
      if (canUseFinancial)
        widget.repository.loadProjectPayments(cacheFirst: false),
    ]);
    final allProjects = results[0] as List<Project>;
    final projects = allProjects
        .where((project) => project.clientId == widget.client.id)
        .toList();
    final payments = canUseFinancial
        ? results[1] as List<ProjectPayment>
        : const <ProjectPayment>[];
    return _ClientProjectsData(
      projects: projects,
      paymentsByProject: _paymentsByProject(payments),
    );
  }

  Map<int?, List<ProjectPayment>> _paymentsByProject(
    List<ProjectPayment> payments,
  ) {
    final map = <int?, List<ProjectPayment>>{};
    for (final payment in payments) {
      map.putIfAbsent(payment.projectId, () => []).add(payment);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do cliente')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            projectsFuture = _loadProjects();
          });
          await projectsFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.client.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              widget.client.cityState,
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            NeonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contato',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _info(
                      Icons.badge_rounded, 'Documento', widget.client.document),
                  _info(Icons.phone_rounded, 'Telefone', widget.client.phone),
                  _info(Icons.mail_rounded, 'Email', widget.client.email),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NeonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Endereço',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _info(Icons.markunread_mailbox_outlined, 'CEP',
                      widget.client.zipCode),
                  _info(Icons.route_rounded, 'Rua', widget.client.street),
                  _info(Icons.pin_drop_outlined, 'Número',
                      widget.client.addressNumber),
                  _info(
                      Icons.map_outlined, 'Bairro', widget.client.neighborhood),
                  _info(Icons.location_city_rounded, 'Cidade/Estado',
                      widget.client.cityState),
                  _info(Icons.notes_rounded, 'Complemento',
                      widget.client.addressComplement),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<_ClientProjectsData>(
              future: projectsFuture,
              builder: (context, snapshot) {
                final data = snapshot.data ?? const _ClientProjectsData();
                final projects = data.projects;
                final revenue = projects.fold<double>(
                    0, (sum, item) => sum + item.projectValue);
                final power = projects.fold<double>(
                    0, (sum, item) => sum + item.systemPower);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _Metric(title: 'Projetos', value: '${projects.length}'),
                        _Metric(
                            title: 'Potência total',
                            value: '${power.toStringAsFixed(2)} kWp'),
                        _Metric(
                            title: 'Valor total', value: money.format(revenue)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Projetos do cliente',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    if (projects.isEmpty)
                      const NeonCard(
                        child: Text('Nenhum projeto vinculado a este cliente.',
                            style: TextStyle(color: AppTheme.muted)),
                      )
                    else
                      ...projects.map(
                        (project) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NeonCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProjectDetailsPage(
                                        project: project,
                                        payments: data.paymentsByProject[
                                                project.id] ??
                                            const [],
                                        canUseFinancial:
                                            widget.profile?.canUseFinancial ==
                                                true,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    '#${project.id ?? '-'} • ${ProjectStatus.labelFor(project.status)}',
                                  ),
                                  subtitle: Text(
                                    '${project.systemPower.toStringAsFixed(2)} kWp • ${project.moduleCount} módulos',
                                    style:
                                        const TextStyle(color: AppTheme.muted),
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                ),
                                if (widget.profile?.canUseFinancial ==
                                    true) ...[
                                  const SizedBox(height: 8),
                                  PaymentStatusBadge(
                                    project: project,
                                    payments:
                                        data.paymentsByProject[project.id] ??
                                            const [],
                                    compact: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: AppTheme.muted, fontSize: 12)),
                Text(value.isEmpty ? '-' : value,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width > 920 ? (width - 68) / 3 : double.infinity,
      child: NeonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _ClientProjectsData {
  const _ClientProjectsData({
    this.projects = const [],
    this.paymentsByProject = const {},
  });

  final List<Project> projects;
  final Map<int?, List<ProjectPayment>> paymentsByProject;
}
