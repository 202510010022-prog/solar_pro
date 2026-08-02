import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/app_profile.dart';
import '../models/project_status.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../widgets/neon_card.dart';
import 'project_details_page.dart';
import 'project_edit_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage(
      {super.key, required this.repository, required this.profile});

  final SolarProRepository repository;
  final AppProfile? profile;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late Future<List<Project>> future;
  final search = TextEditingController();
  String statusFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    future = widget.repository.loadProjects();
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: future,
      builder: (context, snapshot) {
        final projects = snapshot.data ?? [];
        final filtered = projects.where((project) {
          final query = search.text.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              project.clientName.toLowerCase().contains(query) ||
              '${project.id}'.contains(query);
          final matchesStatus =
              statusFilter == 'Todos' || project.status == statusFilter;
          return matchesSearch && matchesStatus;
        }).toList();
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              future = widget.repository.loadProjects(cacheFirst: false);
            });
            await future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Projetos',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('${filtered.length} de ${projects.length} projeto(s)',
                  style: const TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 16),
              NeonCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    TextField(
                      controller: search,
                      decoration: const InputDecoration(
                        hintText: 'Buscar projeto',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: statusFilter,
                      items: ['Todos', ...ProjectStatus.dbValues]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(ProjectStatus.labelFor(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => statusFilter = value ?? 'Todos'),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                const NeonCard(
                  child: Text('Nenhum projeto encontrado.',
                      style: TextStyle(color: AppTheme.muted)),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 720;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: twoColumns ? 2 : 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent:
                            widget.profile?.canManageAll == true ? 238 : 196,
                      ),
                      itemBuilder: (context, index) => _ProjectTile(
                        project: filtered[index],
                        repository: widget.repository,
                        profile: widget.profile,
                        onChanged: _reload,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _reload() {
    setState(() {
      future = widget.repository.loadProjects(cacheFirst: false);
    });
  }
}

class _ProjectTile extends StatefulWidget {
  const _ProjectTile({
    required this.project,
    required this.repository,
    required this.profile,
    required this.onChanged,
  });

  final Project project;
  final SolarProRepository repository;
  final AppProfile? profile;
  final VoidCallback onChanged;

  @override
  State<_ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<_ProjectTile> {
  late String status = widget.project.status;

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0x1F38B86A),
                child: Icon(Icons.business_rounded,
                    color: AppTheme.green, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectDetailsPage(project: widget.project),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.project.clientName.isEmpty
                              ? 'Cliente sem nome'
                              : widget.project.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.project.systemPower.toStringAsFixed(2)} kWp • ${widget.project.moduleCount} módulos • ${widget.project.projectDate}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'details') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProjectDetailsPage(project: widget.project)),
                    );
                  }
                  if (value == 'edit') {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectEditPage(
                          project: widget.project,
                          repository: widget.repository,
                        ),
                      ),
                    );
                    if (changed == true) widget.onChanged();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'details', child: Text('Detalhes')),
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: _progressFor(widget.project.status),
                    backgroundColor: AppTheme.border,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.green),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(_progressFor(widget.project.status) * 100).round()}%',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: ProjectStatus.dbValues.contains(status)
                ? status
                : ProjectStatus.negotiating.dbValue,
            items: ProjectStatus.dbValues
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(ProjectStatus.labelFor(item)),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              if (value == null || widget.project.id == null) return;
              setState(() => status = value);
              try {
                await widget.repository
                    .updateProjectStatus(widget.project.id!, value);
                widget.onChanged();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Status atualizado com sucesso.')),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        friendlyNetworkError(
                          error,
                          fallback: 'Não foi possível atualizar o status.',
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          if (widget.profile?.canManageAll == true) ...[
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed:
                    widget.project.id == null ? null : () => _delete(context),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Excluir projeto'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _progressFor(String status) {
    if (ProjectStatus.completed.matches(status)) return 1.0;
    if (ProjectStatus.closed.matches(status)) return 0.75;
    if (ProjectStatus.negotiating.matches(status)) return 0.45;
    if (ProjectStatus.rejected.matches(status)) return 0.08;
    return 0.25;
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir projeto?'),
        content: const Text('Essa ação remove o projeto do Supabase.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true || widget.project.id == null) return;
    try {
      await widget.repository.deleteProject(widget.project.id!);
      widget.onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projeto excluído com sucesso.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyNetworkError(
                error,
                fallback: 'Não foi possível excluir o projeto.',
              ),
            ),
          ),
        );
      }
    }
  }
}
