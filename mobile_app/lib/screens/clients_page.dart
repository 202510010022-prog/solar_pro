import 'package:flutter/material.dart';

import '../models/app_profile.dart';
import '../models/client.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_card.dart';
import 'client_details_page.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage(
      {super.key, required this.repository, required this.profile});

  final SolarProRepository repository;
  final AppProfile? profile;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late Future<List<Client>> future;
  final search = TextEditingController();
  Set<int> clientIdsWithProjects = {};
  String projectFilter = 'Todos';
  String stateFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    future = widget.repository.loadClients();
    _loadProjectLinks();
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Client>>(
      future: future,
      builder: (context, snapshot) {
        final clients = snapshot.data ?? [];
        final states = [
          'Todos',
          ...clients
              .map((client) => client.state)
              .where((state) => state.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
        ];
        final filtered = clients.where((client) {
          final query = search.text.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              client.name.toLowerCase().contains(query) ||
              client.city.toLowerCase().contains(query) ||
              client.street.toLowerCase().contains(query) ||
              client.neighborhood.toLowerCase().contains(query) ||
              client.zipCode.toLowerCase().contains(query) ||
              client.document.toLowerCase().contains(query) ||
              client.email.toLowerCase().contains(query) ||
              client.phone.toLowerCase().contains(query);
          final hasProject =
              client.id != null && clientIdsWithProjects.contains(client.id);
          final matchesProject = projectFilter == 'Todos' ||
              (projectFilter == 'Com projeto' && hasProject) ||
              (projectFilter == 'Sem projeto' && !hasProject);
          final matchesState =
              stateFilter == 'Todos' || client.state == stateFilter;
          return matchesSearch && matchesProject && matchesState;
        }).toList();
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed:
                widget.profile == null ? null : () => _openClientForm(context),
            label: const Text('Cliente'),
            icon: const Icon(Icons.add_rounded),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() =>
                  future = widget.repository.loadClients(cacheFirst: false));
              await Future.wait([future, _loadProjectLinks(cacheFirst: false)]);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Clientes',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('${filtered.length} de ${clients.length} cliente(s)',
                    style: const TextStyle(color: AppTheme.muted)),
                const SizedBox(height: 16),
                NeonCard(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: search,
                          decoration: const InputDecoration(
                            hintText: 'Buscar cliente',
                            prefixIcon: Icon(Icons.search_rounded),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openFilters(context, states),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TabLabel(
                      text: 'Todos',
                      active: projectFilter == 'Todos',
                      onTap: () => setState(() => projectFilter = 'Todos'),
                    ),
                    _TabLabel(
                      text: 'Com projeto',
                      active: projectFilter == 'Com projeto',
                      onTap: () =>
                          setState(() => projectFilter = 'Com projeto'),
                    ),
                    _TabLabel(
                      text: 'Sem projeto',
                      active: projectFilter == 'Sem projeto',
                      onTap: () =>
                          setState(() => projectFilter = 'Sem projeto'),
                    ),
                  ],
                ),
                if (projectFilter != 'Todos' || stateFilter != 'Todos') ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (projectFilter != 'Todos')
                        Chip(
                            label: Text(projectFilter),
                            onDeleted: () =>
                                setState(() => projectFilter = 'Todos')),
                      if (stateFilter != 'Todos')
                        Chip(
                            label: Text('Estado: $stateFilter'),
                            onDeleted: () =>
                                setState(() => stateFilter = 'Todos')),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const NeonCard(
                    child: Text('Nenhum cliente encontrado.',
                        style: TextStyle(color: AppTheme.muted)),
                  )
                else
                  ...filtered.map(
                    (client) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: const BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: AppTheme.border)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailsPage(
                              client: client,
                              repository: widget.repository,
                            ),
                          ),
                        ),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: _avatarColor(client.name),
                          child: Text(
                            _initials(client.name),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                        title: Text(client.name),
                        subtitle: Text(
                          '${client.addressLine.isEmpty ? client.cityState : client.addressLine}\n${client.phone} • ${client.email}',
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openClientForm(context, client: client);
                            }
                            if (value == 'delete') {
                              _deleteClient(context, client);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Editar')),
                            if (widget.profile?.canManageAll == true)
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadProjectLinks({bool cacheFirst = true}) async {
    try {
      final ids = await widget.repository
          .loadClientIdsWithProjects(cacheFirst: cacheFirst);
      if (mounted) setState(() => clientIdsWithProjects = ids);
    } catch (_) {
      if (mounted) setState(() => clientIdsWithProjects = {});
    }
  }

  Future<void> _openFilters(BuildContext context, List<String> states) async {
    var selectedProject = projectFilter;
    var selectedState = states.contains(stateFilter) ? stateFilter : 'Todos';
    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtros de clientes',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProject,
                    items: const ['Todos', 'Com projeto', 'Sem projeto']
                        .map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) =>
                        setModalState(() => selectedProject = value ?? 'Todos'),
                    decoration: const InputDecoration(labelText: 'Projetos'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedState,
                    items: states
                        .map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) =>
                        setModalState(() => selectedState = value ?? 'Todos'),
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            selectedProject = 'Todos';
                            selectedState = 'Todos';
                            Navigator.pop(context, true);
                          },
                          child: const Text('Limpar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (applied == true && mounted) {
      setState(() {
        projectFilter = selectedProject;
        stateFilter = selectedState;
      });
    }
  }

  Future<void> _openClientForm(BuildContext context, {Client? client}) async {
    final name = TextEditingController(text: client?.name ?? '');
    final phone = TextEditingController(text: client?.phone ?? '');
    final email = TextEditingController(text: client?.email ?? '');
    final zipCode = TextEditingController(text: client?.zipCode ?? '');
    final street = TextEditingController(text: client?.street ?? '');
    final addressNumber =
        TextEditingController(text: client?.addressNumber ?? '');
    final neighborhood =
        TextEditingController(text: client?.neighborhood ?? '');
    final city = TextEditingController(text: client?.city ?? '');
    final state = TextEditingController(
        text: client?.state.isNotEmpty == true ? client!.state : 'BA');
    final addressComplement =
        TextEditingController(text: client?.addressComplement ?? '');
    final document = TextEditingController(text: client?.document ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  client == null ? 'Novo cliente' : 'Editar cliente',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome')),
                const SizedBox(height: 10),
                TextField(
                    controller: document,
                    decoration: const InputDecoration(labelText: 'CPF/CNPJ')),
                const SizedBox(height: 10),
                TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Telefone')),
                const SizedBox(height: 10),
                TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: zipCode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'CEP'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _lookupCepIntoFields(
                        zipCode: zipCode,
                        street: street,
                        neighborhood: neighborhood,
                        city: city,
                        state: state,
                      ),
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'Buscar CEP',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: street,
                    decoration: const InputDecoration(labelText: 'Rua')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: addressNumber,
                        decoration: const InputDecoration(labelText: 'Número'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: neighborhood,
                        decoration: const InputDecoration(labelText: 'Bairro'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: city,
                    decoration: const InputDecoration(labelText: 'Cidade')),
                const SizedBox(height: 10),
                TextField(
                    controller: state,
                    decoration: const InputDecoration(labelText: 'Estado')),
                const SizedBox(height: 10),
                TextField(
                    controller: addressComplement,
                    decoration:
                        const InputDecoration(labelText: 'Complemento')),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    final profile = widget.profile;
                    if (profile == null) return;
                    final cepOk = await _lookupCepIntoFields(
                      zipCode: zipCode,
                      street: street,
                      neighborhood: neighborhood,
                      city: city,
                      state: state,
                      silentSuccess: true,
                    );
                    if (!cepOk) return;
                    final payload = Client(
                      id: client?.id,
                      name: name.text.trim(),
                      document: document.text.trim(),
                      phone: phone.text.trim(),
                      email: email.text.trim(),
                      zipCode: _onlyDigits(zipCode.text),
                      street: street.text.trim(),
                      addressNumber: addressNumber.text.trim(),
                      neighborhood: neighborhood.text.trim(),
                      city: city.text.trim(),
                      state: state.text.trim().toUpperCase(),
                      addressComplement: addressComplement.text.trim(),
                    );
                    if (client == null) {
                      await widget.repository
                          .createClient(payload, profile.companyId);
                    } else {
                      await widget.repository.updateClient(payload);
                    }
                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: Text(
                      client == null ? 'Salvar cliente' : 'Salvar alterações'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true && mounted) {
      setState(() => future = widget.repository.loadClients(cacheFirst: false));
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
            content: Text(client == null
                ? 'Cliente salvo com sucesso.'
                : 'Cliente atualizado com sucesso.')),
      );
    }
  }

  Future<void> _deleteClient(BuildContext context, Client client) async {
    if (client.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content:
            Text('Todos os projetos de ${client.name} também serão removidos.'),
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
    if (confirmed != true) return;
    try {
      await widget.repository.deleteClient(client.id!);
      if (!mounted) return;
      setState(() => future = widget.repository.loadClients(cacheFirst: false));
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Cliente excluído com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o cliente.')),
      );
    }
  }

  Future<bool> _lookupCepIntoFields({
    required TextEditingController zipCode,
    required TextEditingController street,
    required TextEditingController neighborhood,
    required TextEditingController city,
    required TextEditingController state,
    bool silentSuccess = false,
  }) async {
    final cep = _onlyDigits(zipCode.text);
    if (cep.length != 8) {
      _showMessage('Informe um CEP válido com 8 números.');
      return false;
    }

    try {
      final address = await widget.repository.lookupCep(cep);
      zipCode.text = address.zipCode;
      street.text = address.street;
      neighborhood.text = address.neighborhood;
      city.text = address.city;
      state.text = address.state;
      if (!silentSuccess) {
        _showMessage('Endereço preenchido pelo CEP.');
      }
      return true;
    } catch (error) {
      _showMessage(_friendlyCepError(error));
      return false;
    }
  }

  String _friendlyCepError(Object error) {
    final text = error.toString().replaceFirst('Bad state: ', '');
    if (text.contains('CEP') || text.contains('cep')) return text;
    return 'Não foi possível consultar o CEP agora.';
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel(
      {required this.text, this.active = false, required this.onTap});

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                color: active ? AppTheme.text : AppTheme.muted,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 76,
              height: 2,
              color: active ? AppTheme.green : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _avatarColor(String seed) {
  const colors = [
    Color(0xFF8B5CF6),
    Color(0xFF38B86A),
    Color(0xFFF59E0B),
    Color(0xFF0EA5A8),
    Color(0xFF2F80ED),
  ];
  return colors[seed.hashCode.abs() % colors.length];
}

String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');
