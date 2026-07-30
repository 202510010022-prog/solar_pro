import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/client.dart';
import '../models/project.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import 'project_details_page.dart';

class ClientDetailsPage extends StatefulWidget {
  const ClientDetailsPage({
    super.key,
    required this.client,
    required this.repository,
  });

  final Client client;
  final SolarProRepository repository;

  @override
  State<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage> {
  late Future<List<Project>> projectsFuture;
  final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    projectsFuture = _loadProjects();
  }

  Future<List<Project>> _loadProjects() async {
    final projects = await widget.repository.loadProjects(cacheFirst: false);
    return projects
        .where((project) => project.clientId == widget.client.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do cliente')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => projectsFuture = _loadProjects());
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
            FutureBuilder<List<Project>>(
              future: projectsFuture,
              builder: (context, snapshot) {
                final projects = snapshot.data ?? [];
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
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ProjectDetailsPage(project: project)),
                              ),
                              title: Text(
                                  '#${project.id ?? '-'} • ${project.status}'),
                              subtitle: Text(
                                '${project.systemPower.toStringAsFixed(2)} kWp • ${project.moduleCount} módulos',
                                style: const TextStyle(color: AppTheme.muted),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
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
