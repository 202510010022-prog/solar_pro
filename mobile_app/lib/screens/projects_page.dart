import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/app_profile.dart';
import '../models/project_payment.dart';
import '../models/project_status.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../widgets/neon_card.dart';
import '../widgets/payment_status_badge.dart';
import '../widgets/rejection_reason_dialog.dart';
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
  late Future<_ProjectsData> future;
  final search = TextEditingController();
  String statusFilter = 'Todos';
  late bool showOnlyMine;

  @override
  void initState() {
    super.initState();
    showOnlyMine = !_canManageAll;
    future = _loadProjects();
    search.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant ProjectsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile?.id != widget.profile?.id) {
      showOnlyMine = !_canManageAll;
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProjectsData>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _ProjectsData();
        final projects = data.projects;
        final filtered = projects.where((project) {
          final query = search.text.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              project.clientName.toLowerCase().contains(query) ||
              '${project.id}'.contains(query);
          final selectedStatus = ProjectStatus.fromDbValue(statusFilter);
          final matchesStatus = statusFilter == 'Todos' ||
              (selectedStatus?.matches(project.status) ?? false);
          final sellerId = widget.profile?.id;
          final matchesSeller = !showOnlyMine ||
              (sellerId != null && project.sellerId == sellerId);
          return matchesSearch && matchesStatus && matchesSeller;
        }).toList();
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              future = _loadProjects(cacheFirst: false);
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
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.person_rounded, size: 18),
                          label: Text('Meus projetos'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.groups_rounded, size: 18),
                          label: Text('Todos'),
                        ),
                      ],
                      selected: {showOnlyMine},
                      onSelectionChanged: (selection) {
                        setState(() => showOnlyMine = selection.first);
                      },
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
                            widget.profile?.canManageAll == true ? 318 : 244,
                      ),
                      itemBuilder: (context, index) => _ProjectTile(
                        project: filtered[index],
                        payments: data.paymentsByProject[filtered[index].id] ??
                            const [],
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
      future = _loadProjects(cacheFirst: false);
    });
  }

  Future<_ProjectsData> _loadProjects({bool cacheFirst = true}) async {
    final canUseFinancial = widget.profile?.canUseFinancial == true;
    final results = await Future.wait([
      widget.repository.loadProjects(cacheFirst: cacheFirst),
      if (canUseFinancial)
        widget.repository.loadProjectPayments(cacheFirst: cacheFirst),
    ]);
    final projects = results[0] as List<Project>;
    final payments = canUseFinancial
        ? results[1] as List<ProjectPayment>
        : const <ProjectPayment>[];
    return _ProjectsData(
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

  bool get _canManageAll => widget.profile?.canManageAll == true;
}

class _ProjectTile extends StatefulWidget {
  const _ProjectTile({
    required this.project,
    required this.payments,
    required this.repository,
    required this.profile,
    required this.onChanged,
  });

  final Project project;
  final List<ProjectPayment> payments;
  final SolarProRepository repository;
  final AppProfile? profile;
  final VoidCallback onChanged;

  @override
  State<_ProjectTile> createState() => _ProjectTileState();
}

class _ProjectTileState extends State<_ProjectTile> {
  late String status = ProjectStatus.fallbackDbValue(widget.project.status);
  late String rejectionReason = widget.project.rejectionReason;

  @override
  void didUpdateWidget(covariant _ProjectTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id ||
        oldWidget.project.status != widget.project.status ||
        oldWidget.project.rejectionReason != widget.project.rejectionReason) {
      status = ProjectStatus.fallbackDbValue(widget.project.status);
      rejectionReason = widget.project.rejectionReason;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManageAll = widget.profile?.canManageAll == true;
    final statusOptions = ProjectStatus.selectableFor(
      currentValue: widget.project.status,
      canManageAll: canManageAll,
    );
    final isManualCorrection = canManageAll &&
        ProjectStatus.isManualCorrection(
          currentValue: widget.project.status,
          targetValue: status,
        );

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
                      builder: (_) => ProjectDetailsPage(
                        project: widget.project,
                        payments: widget.payments,
                        canUseFinancial:
                            widget.profile?.canUseFinancial == true,
                      ),
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
                        const SizedBox(height: 3),
                        Text(
                          'Vendedor: ${widget.project.sellerName?.trim().isNotEmpty == true ? widget.project.sellerName : 'não atribuído'}',
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
                        builder: (_) => ProjectDetailsPage(
                          project: widget.project,
                          payments: widget.payments,
                          canUseFinancial:
                              widget.profile?.canUseFinancial == true,
                        ),
                      ),
                    );
                  }
                  if (value == 'edit') {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectEditPage(
                          project: widget.project,
                          repository: widget.repository,
                          profile: widget.profile,
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
          if (widget.profile?.canUseFinancial == true) ...[
            PaymentStatusBadge(
              project: widget.project,
              payments: widget.payments,
              compact: true,
            ),
            const SizedBox(height: 12),
          ],
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
            key: ValueKey('project-status-${widget.project.id}-$status'),
            initialValue: ProjectStatus.fallbackDbValue(status),
            items: statusOptions
                .map(
                  (item) => DropdownMenuItem(
                    value: item.dbValue,
                    child: Text(item.label),
                  ),
                )
                .toList(),
            onChanged: _changeStatus,
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          if (ProjectStatus.rejected.matches(status) &&
              rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _RejectionReasonPreview(reason: rejectionReason),
          ],
          if (isManualCorrection) ...[
            const SizedBox(height: 8),
            const _ManualStatusCorrectionHint(),
          ],
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

  Future<void> _changeStatus(String? value) async {
    if (value == null || widget.project.id == null) return;

    final previousStatus = status;
    final previousReason = rejectionReason;
    var nextReason = '';

    if (ProjectStatus.rejected.matches(value)) {
      final reason = await showRejectionReasonDialog(
        context,
        initialReason: rejectionReason,
      );
      if (!mounted || reason == null) {
        setState(() {
          status = previousStatus;
          rejectionReason = previousReason;
        });
        return;
      }
      nextReason = reason;
    }

    setState(() {
      status = value;
      rejectionReason = nextReason;
    });

    try {
      await widget.repository.updateProjectStatus(
        widget.project.id!,
        value,
        rejectionReason: nextReason,
      );
      widget.onChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status atualizado com sucesso.')),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          status = previousStatus;
          rejectionReason = previousReason;
        });
      }
      if (!mounted) return;
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

  double _progressFor(String status) {
    if (ProjectStatus.completed.matches(status)) return 1.0;
    if (ProjectStatus.installing.matches(status)) return 0.85;
    if (ProjectStatus.approved.matches(status)) return 0.65;
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

class _ProjectsData {
  const _ProjectsData({
    this.projects = const [],
    this.paymentsByProject = const {},
  });

  final List<Project> projects;
  final Map<int?, List<ProjectPayment>> paymentsByProject;
}

class _ManualStatusCorrectionHint extends StatelessWidget {
  const _ManualStatusCorrectionHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Alteração manual de status',
              style: TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectionReasonPreview extends StatelessWidget {
  const _RejectionReasonPreview({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppTheme.purple.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.purple, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Motivo: $reason',
              style: const TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
