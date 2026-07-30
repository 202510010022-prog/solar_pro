import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/admin_section.dart';
import 'app/admin_theme.dart';
import 'config/supabase_config.dart';
import 'models/admin_company.dart';
import 'models/admin_data.dart';
import 'models/admin_feedback.dart';
import 'models/admin_message.dart';
import 'models/admin_payment.dart';
import 'models/admin_plan.dart';
import 'models/admin_user.dart';
import 'pages/sections/overview_section.dart';
import 'services/admin_repository.dart';
import 'widgets/admin_card.dart';
import 'widgets/admin_error.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/field.dart';
import 'widgets/reports/commercial_reports.dart';
import 'widgets/tables/company_table.dart';
import 'widgets/tables/feedback_table.dart';
import 'widgets/tables/message_table.dart';
import 'widgets/tables/payment_table.dart';
import 'widgets/tables/user_table.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseConfig.validate();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
  runApp(const SolarProAdminApp());
}

class SolarProAdminApp extends StatefulWidget {
  const SolarProAdminApp({super.key});

  @override
  State<SolarProAdminApp> createState() => _SolarProAdminAppState();
}

class _SolarProAdminAppState extends State<SolarProAdminApp> {
  @override
  Widget build(BuildContext context) {
    final loggedIn = Supabase.instance.client.auth.currentUser != null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Solar Pro Admin',
      theme: AdminTheme.theme,
      home: loggedIn
          ? AdminDashboard(onLogout: () => setState(() {}))
          : LoginPage(onLoggedIn: () => setState(() {})),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoggedIn});

  final VoidCallback onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late final repository = AdminRepository(Supabase.instance.client);
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() => loading = true);
    try {
      await repository.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      widget.onLoggedIn();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login administrativo invalido.')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.4,
            colors: [Color(0x552563EB), AdminTheme.background],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: AdminCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AdminTheme.blue,
                        child: Icon(Icons.admin_panel_settings_rounded),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solar Pro Admin',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Painel interno da plataforma',
                            style: TextStyle(color: AdminTheme.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail administrativo',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    onSubmitted: (_) => signIn(),
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading ? null : signIn,
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(loading ? 'Entrando...' : 'Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late final repository = AdminRepository(Supabase.instance.client);
  late Future<AdminData> future = repository.loadData();
  AdminSection section = AdminSection.overview;
  String query = '';
  String selectedUsersCompanyId = '';

  void reload() => setState(() => future = repository.loadData());

  Future<void> logout() async {
    await repository.signOut();
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AdminTheme.background,
              Color(0xFF06101F),
              Color(0xFF071A33),
            ],
          ),
        ),
        child: Row(
          children: [
            AdminSidebar(
              section: section,
              onSelect: (value) => setState(() => section = value),
            ),
            Expanded(
              child: FutureBuilder<AdminData>(
                future: future,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AdminError(
                      message: '${snapshot.error}'.replaceFirst(
                        'Bad state: ',
                        '',
                      ),
                      onRetry: reload,
                      onLogout: logout,
                    );
                  }
                  final companies = data?.companies ?? const <AdminCompany>[];
                  final plans = data?.plans ?? const <AdminPlan>[];
                  final payments = data?.payments ?? const <AdminPayment>[];
                  final feedbacks = data?.feedbacks ?? const <AdminFeedback>[];
                  final messages = data?.messages ?? const <AdminMessage>[];
                  final users = data?.users ?? const <AdminUser>[];
                  final filtered = companies.where((company) {
                    final needle = query.trim().toLowerCase();
                    if (needle.isEmpty) return true;
                    return company.name.toLowerCase().contains(needle) ||
                        company.billingEmail.toLowerCase().contains(needle) ||
                        company.document.toLowerCase().contains(needle);
                  }).toList();

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                        sliver: SliverToBoxAdapter(
                          child: AdminHeader(
                            section: section,
                            onLogout: logout,
                            onRefresh: reload,
                            onCreate: () => _openCreateCompany(plans),
                            onCreatePayment: () =>
                                _openCreatePayment(companies),
                            onCreateMessage: () =>
                                _openCreateMessage(companies),
                            onCreateUser: () => _openCreateUser(
                              companies,
                              initialCompanyId: selectedUsersCompanyId,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(28),
                        sliver: SliverList.list(
                          children: _sectionContent(
                            companies: companies,
                            filteredCompanies: filtered,
                            plans: plans,
                            payments: payments,
                            feedbacks: feedbacks,
                            messages: messages,
                            users: users,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateCompany(List<AdminPlan> plans) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateCompanyDialog(repository: repository, plans: plans),
    );
    if (created == true) reload();
  }

  List<Widget> _sectionContent({
    required List<AdminCompany> companies,
    required List<AdminCompany> filteredCompanies,
    required List<AdminPlan> plans,
    required List<AdminPayment> payments,
    required List<AdminFeedback> feedbacks,
    required List<AdminMessage> messages,
    required List<AdminUser> users,
  }) {
    return switch (section) {
      AdminSection.overview => [
        SummaryGrid(companies: companies),
        const SizedBox(height: 18),
        OperationalSummary(
          payments: payments,
          feedbacks: feedbacks,
          messages: messages,
        ),
        const SizedBox(height: 18),
        CommercialReports(
          companies: companies,
          payments: payments,
          users: users,
        ),
      ],
      AdminSection.companies => [
        AdminCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Empresas cadastradas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: const InputDecoration(
                          hintText: 'Buscar empresa...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CompanyTable(
                companies: filteredCompanies,
                plans: plans,
                onEdit: _openEditCompany,
              ),
            ],
          ),
        ),
      ],
      AdminSection.users => [
        UsersByCompanyPanel(
          companies: companies,
          users: users,
          selectedCompanyId: selectedUsersCompanyId,
          onSelectCompany: (companyId) {
            setState(() => selectedUsersCompanyId = companyId);
          },
          onEditCompany: (company) => _openEditCompany(company, plans),
          onCreateUser: (companyId) =>
              _openCreateUser(companies, initialCompanyId: companyId),
          onEditUser: (user) => _openEditUser(user, companies),
          onToggleActive: _updateUserActive,
        ),
      ],
      AdminSection.payments => [
        AdminCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cobranças Pix',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openCreatePayment(companies),
                      icon: const Icon(Icons.pix_rounded),
                      label: const Text('Nova cobrança'),
                    ),
                  ],
                ),
              ),
              PaymentTable(
                payments: payments,
                onPaid: _markPaymentPaid,
                onCancel: _cancelPayment,
              ),
            ],
          ),
        ),
      ],
      AdminSection.feedbacks => [
        AdminCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Feedbacks e chamados',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FeedbackTable(
                feedbacks: feedbacks,
                onStatusChanged: _updateFeedbackStatus,
              ),
            ],
          ),
        ),
      ],
      AdminSection.messages => [
        AdminCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mensagens e comunicados',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openCreateMessage(companies),
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('Novo comunicado'),
                    ),
                  ],
                ),
              ),
              MessageTable(messages: messages),
            ],
          ),
        ),
      ],
    };
  }

  Future<void> _openEditCompany(
    AdminCompany company,
    List<AdminPlan> plans,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditCompanyDialog(
        repository: repository,
        company: company,
        plans: plans,
      ),
    );
    if (updated == true) reload();
  }

  Future<void> _openCreatePayment(List<AdminCompany> companies) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) =>
          CreatePaymentDialog(repository: repository, companies: companies),
    );
    if (created == true) reload();
  }

  Future<void> _openCreateMessage(List<AdminCompany> companies) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) =>
          CreateMessageDialog(repository: repository, companies: companies),
    );
    if (created == true) reload();
  }

  Future<void> _openCreateUser(
    List<AdminCompany> companies, {
    String initialCompanyId = '',
  }) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateUserDialog(
        repository: repository,
        companies: companies,
        initialCompanyId: initialCompanyId,
      ),
    );
    if (created == true) reload();
  }

  Future<void> _openEditUser(
    AdminUser user,
    List<AdminCompany> companies,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => EditUserDialog(
        repository: repository,
        user: user,
        companies: companies,
      ),
    );
    if (updated == true) reload();
  }

  Future<void> _markPaymentPaid(AdminPayment payment) async {
    final months = await showDialog<int>(
      context: context,
      builder: (_) => const PaymentPeriodDialog(),
    );
    if (months == null) return;
    try {
      await repository.markPaymentPaid(payment.id, periodMonths: months);
      reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pagamento confirmado.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    }
  }

  Future<void> _cancelPayment(AdminPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar cobrança?'),
        content: Text('A cobrança #${payment.id} será cancelada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar cobrança'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await repository.cancelPayment(payment.id);
      reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cobrança cancelada.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    }
  }

  Future<void> _updateFeedbackStatus(
    AdminFeedback feedback,
    String status,
  ) async {
    try {
      await repository.updateFeedback(feedback.id, status);
      reload();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chamado atualizado.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    }
  }

  Future<void> _updateUserActive(AdminUser user, bool active) async {
    try {
      await repository.updateUserActive(user.id, active);
      reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Usuário ativado.' : 'Usuário desativado.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    }
  }
}

class UsersByCompanyPanel extends StatelessWidget {
  const UsersByCompanyPanel({
    super.key,
    required this.companies,
    required this.users,
    required this.selectedCompanyId,
    required this.onSelectCompany,
    required this.onEditCompany,
    required this.onCreateUser,
    required this.onEditUser,
    required this.onToggleActive,
  });

  final List<AdminCompany> companies;
  final List<AdminUser> users;
  final String selectedCompanyId;
  final ValueChanged<String> onSelectCompany;
  final ValueChanged<AdminCompany> onEditCompany;
  final ValueChanged<String> onCreateUser;
  final ValueChanged<AdminUser> onEditUser;
  final void Function(AdminUser user, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    if (companies.isEmpty) {
      return const AdminCard(
        child: Center(
          child: Text(
            'Cadastre uma empresa antes de criar usuários.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    final selectedId =
        companies.any((company) => company.id == selectedCompanyId)
        ? selectedCompanyId
        : companies.first.id;
    final selectedCompany = companies.firstWhere(
      (company) => company.id == selectedId,
    );
    final selectedUsers =
        users.where((user) => user.companyId == selectedId).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final companyList = _CompanyUserSelector(
          companies: companies,
          users: users,
          selectedCompanyId: selectedId,
          onSelectCompany: onSelectCompany,
        );
        final userDetails = _CompanyUsersDetail(
          company: selectedCompany,
          users: selectedUsers,
          onEditCompany: () => onEditCompany(selectedCompany),
          onCreateUser: () => onCreateUser(selectedId),
          onEditUser: onEditUser,
          onToggleActive: onToggleActive,
        );

        if (!wide) {
          return Column(
            children: [companyList, const SizedBox(height: 18), userDetails],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 360, child: companyList),
            const SizedBox(width: 18),
            Expanded(child: userDetails),
          ],
        );
      },
    );
  }
}

class _CompanyUserSelector extends StatelessWidget {
  const _CompanyUserSelector({
    required this.companies,
    required this.users,
    required this.selectedCompanyId,
    required this.onSelectCompany,
  });

  final List<AdminCompany> companies;
  final List<AdminUser> users;
  final String selectedCompanyId;
  final ValueChanged<String> onSelectCompany;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Empresas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecione uma empresa para ver os usuários.',
            style: TextStyle(color: AdminTheme.muted),
          ),
          const SizedBox(height: 16),
          ...companies.map((company) {
            final selected = company.id == selectedCompanyId;
            final count = users
                .where((user) => user.companyId == company.id)
                .length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelectCompany(company.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AdminTheme.blue.withValues(alpha: 0.18)
                        : const Color(0x33071126),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AdminTheme.cyan : AdminTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: selected
                            ? AdminTheme.blue
                            : AdminTheme.blue.withValues(alpha: 0.18),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '$count usuário(s) • ${company.planSlug}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AdminTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CompanyUsersDetail extends StatelessWidget {
  const _CompanyUsersDetail({
    required this.company,
    required this.users,
    required this.onEditCompany,
    required this.onCreateUser,
    required this.onEditUser,
    required this.onToggleActive,
  });

  final AdminCompany company;
  final List<AdminUser> users;
  final VoidCallback onEditCompany;
  final VoidCallback onCreateUser;
  final ValueChanged<AdminUser> onEditUser;
  final void Function(AdminUser user, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return AdminCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${users.length} usuário(s) vinculados',
                        style: const TextStyle(color: AdminTheme.muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCreateUser,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Novo usuário'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onEditCompany,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar empresa'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _CompanyInfoGrid(company: company, money: money),
          ),
          UserTable(
            users: users,
            onEdit: onEditUser,
            onToggleActive: onToggleActive,
          ),
        ],
      ),
    );
  }
}

class _CompanyInfoGrid extends StatelessWidget {
  const _CompanyInfoGrid({required this.company, required this.money});

  final AdminCompany company;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final dueAt = company.planDueAt;
    final date = DateFormat('dd/MM/yyyy');
    final items = [
      ('Documento', company.document.isEmpty ? '-' : company.document),
      (
        'E-mail de cobrança',
        company.billingEmail.isEmpty ? '-' : company.billingEmail,
      ),
      ('Plano', company.planSlug),
      ('Status', company.status),
      ('Vencimento', dueAt == null ? '-' : date.format(dueAt)),
      ('Usuários', '${company.usersCount} ativo(s)'),
      ('Projetos', '${company.projectsCount} projeto(s)'),
      ('Pendente', money.format(company.pendingAmount)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 4 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            return SizedBox(
              width: width,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0x33071126),
                  border: Border.all(color: AdminTheme.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({
    super.key,
    required this.repository,
    required this.companies,
    this.initialCompanyId = '',
  });

  final AdminRepository repository;
  final List<AdminCompany> companies;
  final String initialCompanyId;

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final name = TextEditingController();
  final email = TextEditingController();
  final matricula = TextEditingController();
  final role = TextEditingController(text: 'Assessor de Projetos');
  final password = TextEditingController();
  String companyId = '';
  String permission = 'assessor_projetos';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companies.isEmpty) return;
    final hasInitial = widget.companies.any(
      (company) => company.id == widget.initialCompanyId,
    );
    companyId = hasInitial
        ? widget.initialCompanyId
        : widget.companies.first.id;
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    matricula.dispose();
    role.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await widget.repository.createUser(
        companyId: companyId,
        name: name.text.trim(),
        email: email.text.trim(),
        matricula: matricula.text.trim(),
        role: role.text.trim(),
        permission: permission,
        password: password.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário criado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: AdminCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Novo usuário',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: companyId.isEmpty ? null : companyId,
                  decoration: const InputDecoration(labelText: 'Empresa'),
                  items: widget.companies
                      .map(
                        (company) => DropdownMenuItem(
                          value: company.id,
                          child: Text(company.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => companyId = value ?? ''),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Field(width: 310, controller: name, label: 'Nome'),
                    Field(width: 310, controller: email, label: 'E-mail'),
                    Field(
                      width: 180,
                      controller: matricula,
                      label: 'Matrícula',
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: permission,
                        decoration: const InputDecoration(
                          labelText: 'Permissão',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'assessor_projetos',
                            child: Text('Assessor Projetos'),
                          ),
                          DropdownMenuItem(
                            value: 'assessor_daf',
                            child: Text('Assessor DAF'),
                          ),
                          DropdownMenuItem(
                            value: 'diretor',
                            child: Text('Diretor'),
                          ),
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('Master da empresa'),
                          ),
                          DropdownMenuItem(
                            value: 'platform_admin',
                            child: Text('Admin Plataforma'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            permission = value ?? 'assessor_projetos';
                            role.text = switch (permission) {
                              'assessor_daf' => 'Assessor DAF',
                              'diretor' => 'Diretor',
                              'owner' => 'Usuário Master',
                              'platform_admin' => 'Administrador da Plataforma',
                              _ => 'Assessor de Projetos',
                            };
                          });
                        },
                      ),
                    ),
                    Field(width: 260, controller: role, label: 'Cargo'),
                    Field(width: 220, controller: password, label: 'Senha'),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: loading ? null : submit,
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(loading ? 'Criando...' : 'Criar usuário'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    required this.repository,
    required this.user,
    required this.companies,
  });

  final AdminRepository repository;
  final AdminUser user;
  final List<AdminCompany> companies;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final name = TextEditingController(text: widget.user.name);
  late final email = TextEditingController(text: widget.user.email);
  late final matricula = TextEditingController(text: widget.user.matricula);
  late final role = TextEditingController(text: widget.user.role);
  final password = TextEditingController();
  late String companyId = widget.user.companyId;
  late String permission = widget.user.permission;
  late bool active = widget.user.active;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final hasCompany = widget.companies.any(
      (company) => company.id == companyId,
    );
    if (!hasCompany && widget.companies.isNotEmpty) {
      companyId = widget.companies.first.id;
    }
    if (![
      'assessor_projetos',
      'assessor_daf',
      'diretor',
      'owner',
      'platform_admin',
    ].contains(permission)) {
      permission = 'assessor_projetos';
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    matricula.dispose();
    role.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await widget.repository.updateUser(
        userId: widget.user.id,
        companyId: companyId,
        name: name.text.trim(),
        email: email.text.trim(),
        matricula: matricula.text.trim(),
        role: role.text.trim(),
        permission: permission,
        active: active,
        password: password.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário atualizado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: AdminCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Editar usuário',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Altere dados de acesso, permissão e senha quando necessário.',
                  style: TextStyle(color: AdminTheme.muted),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: companyId.isEmpty ? null : companyId,
                  decoration: const InputDecoration(labelText: 'Empresa'),
                  items: widget.companies
                      .map(
                        (company) => DropdownMenuItem(
                          value: company.id,
                          child: Text(company.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => companyId = value ?? ''),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Field(width: 320, controller: name, label: 'Nome'),
                    Field(width: 320, controller: email, label: 'E-mail'),
                    Field(
                      width: 180,
                      controller: matricula,
                      label: 'Matrícula',
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String>(
                        initialValue: permission,
                        decoration: const InputDecoration(
                          labelText: 'Permissão',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'assessor_projetos',
                            child: Text('Assessor Projetos'),
                          ),
                          DropdownMenuItem(
                            value: 'assessor_daf',
                            child: Text('Assessor DAF'),
                          ),
                          DropdownMenuItem(
                            value: 'diretor',
                            child: Text('Diretor'),
                          ),
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('Master da empresa'),
                          ),
                          DropdownMenuItem(
                            value: 'platform_admin',
                            child: Text('Admin Plataforma'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            permission = value ?? 'assessor_projetos';
                            role.text = switch (permission) {
                              'assessor_daf' => 'Assessor DAF',
                              'diretor' => 'Diretor',
                              'owner' => 'Usuário Master',
                              'platform_admin' => 'Administrador da Plataforma',
                              _ => 'Assessor de Projetos',
                            };
                          });
                        },
                      ),
                    ),
                    Field(width: 260, controller: role, label: 'Cargo'),
                    Field(
                      width: 260,
                      controller: password,
                      label: 'Nova senha opcional',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setState(() => active = value),
                  title: const Text('Usuário ativo'),
                  subtitle: const Text(
                    'Usuários inativos perdem acesso ao app.',
                    style: TextStyle(color: AdminTheme.muted),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: loading ? null : submit,
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(loading ? 'Salvando...' : 'Salvar usuário'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateCompanyDialog extends StatefulWidget {
  const CreateCompanyDialog({
    super.key,
    required this.repository,
    required this.plans,
  });

  final AdminRepository repository;
  final List<AdminPlan> plans;

  @override
  State<CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<CreateCompanyDialog> {
  final companyName = TextEditingController();
  final document = TextEditingController();
  final billingEmail = TextEditingController();
  final masterName = TextEditingController();
  final masterEmail = TextEditingController();
  final matricula = TextEditingController();
  final password = TextEditingController();
  String planSlug = 'starter';
  String status = 'trial';
  int trialDays = 14;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.plans.isNotEmpty) planSlug = widget.plans.first.slug;
  }

  @override
  void dispose() {
    companyName.dispose();
    document.dispose();
    billingEmail.dispose();
    masterName.dispose();
    masterEmail.dispose();
    matricula.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await widget.repository.createCompany(
        companyName: companyName.text.trim(),
        document: document.text.trim(),
        planSlug: planSlug,
        status: status,
        billingEmail: billingEmail.text.trim(),
        trialDays: trialDays,
        masterName: masterName.text.trim(),
        masterEmail: masterEmail.text.trim(),
        matricula: matricula.text.trim(),
        password: password.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa e master criados.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: AdminCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova empresa',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Field(
                      width: 360,
                      controller: companyName,
                      label: 'Empresa',
                    ),
                    Field(width: 220, controller: document, label: 'CNPJ/CPF'),
                    Field(
                      width: 320,
                      controller: billingEmail,
                      label: 'E-mail financeiro',
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: planSlug,
                        decoration: const InputDecoration(labelText: 'Plano'),
                        items: widget.plans
                            .map(
                              (plan) => DropdownMenuItem(
                                value: plan.slug,
                                child: Text(plan.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => planSlug = value ?? planSlug),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'trial',
                            child: Text('Teste'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Ativa'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => status = value ?? status),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        initialValue: '$trialDays',
                        decoration: const InputDecoration(
                          labelText: 'Dias iniciais',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            trialDays = int.tryParse(value) ?? 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AdminTheme.border),
                const SizedBox(height: 12),
                const Text(
                  'Usuário master',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Field(width: 300, controller: masterName, label: 'Nome'),
                    Field(width: 300, controller: masterEmail, label: 'E-mail'),
                    Field(
                      width: 180,
                      controller: matricula,
                      label: 'Matrícula',
                    ),
                    Field(width: 220, controller: password, label: 'Senha'),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: loading ? null : submit,
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(loading ? 'Criando...' : 'Criar empresa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditCompanyDialog extends StatefulWidget {
  const EditCompanyDialog({
    super.key,
    required this.repository,
    required this.company,
    required this.plans,
  });

  final AdminRepository repository;
  final AdminCompany company;
  final List<AdminPlan> plans;

  @override
  State<EditCompanyDialog> createState() => _EditCompanyDialogState();
}

class CreatePaymentDialog extends StatefulWidget {
  const CreatePaymentDialog({
    super.key,
    required this.repository,
    required this.companies,
  });

  final AdminRepository repository;
  final List<AdminCompany> companies;

  @override
  State<CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<CreatePaymentDialog> {
  final amount = TextEditingController();
  final dueDate = TextEditingController();
  final pixReference = TextEditingController();
  final notes = TextEditingController();
  String companyId = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companies.isNotEmpty) companyId = widget.companies.first.id;
    dueDate.text = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(const Duration(days: 7)));
  }

  @override
  void dispose() {
    amount.dispose();
    dueDate.dispose();
    pixReference.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final parsedAmount = _parseMoney(amount.text);
    final parsedDate = DateTime.tryParse(dueDate.text.trim());
    if (parsedAmount == null || parsedAmount <= 0 || parsedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe valor e vencimento válidos.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await widget.repository.createPayment(
        companyId: companyId,
        amount: parsedAmount,
        dueDate: parsedDate,
        pixReference: pixReference.text.trim(),
        notes: notes.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cobrança criada e enviada ao app.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double? _parseMoney(String value) {
    final text = value.trim();
    if (text.contains(',')) {
      return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
    }
    return double.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AdminCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nova cobrança Pix',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: companyId.isEmpty ? null : companyId,
                decoration: const InputDecoration(labelText: 'Empresa'),
                items: widget.companies
                    .map(
                      (company) => DropdownMenuItem(
                        value: company.id,
                        child: Text(company.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => companyId = value ?? ''),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Field(width: 180, controller: amount, label: 'Valor'),
                  Field(width: 180, controller: dueDate, label: 'Vencimento'),
                  Field(
                    width: 360,
                    controller: pixReference,
                    label: 'Referência Pix',
                  ),
                  Field(width: 560, controller: notes, label: 'Observações'),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: loading ? null : submit,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.pix_rounded),
                    label: Text(loading ? 'Criando...' : 'Criar cobrança'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateMessageDialog extends StatefulWidget {
  const CreateMessageDialog({
    super.key,
    required this.repository,
    required this.companies,
  });

  final AdminRepository repository;
  final List<AdminCompany> companies;

  @override
  State<CreateMessageDialog> createState() => _CreateMessageDialogState();
}

class _CreateMessageDialogState extends State<CreateMessageDialog> {
  final title = TextEditingController();
  final message = TextEditingController();
  final expiresAt = TextEditingController();
  String companyId = '';
  String type = 'info';
  bool sendToAll = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companies.isNotEmpty) companyId = widget.companies.first.id;
  }

  @override
  void dispose() {
    title.dispose();
    message.dispose();
    expiresAt.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!sendToAll && companyId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione a empresa.')));
      return;
    }

    setState(() => loading = true);
    try {
      await widget.repository.createMessage(
        companyId: companyId,
        sendToAll: sendToAll,
        title: title.text.trim(),
        message: message.text.trim(),
        type: type,
        expiresAt: expiresAt.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comunicado enviado ao app.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: AdminCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Novo comunicado',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  value: sendToAll,
                  onChanged: (value) => setState(() => sendToAll = value),
                  title: const Text('Enviar para todas as empresas ativas'),
                  subtitle: const Text(
                    'Use com cuidado para comunicados gerais da plataforma.',
                    style: TextStyle(color: AdminTheme.muted),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!sendToAll) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: companyId.isEmpty ? null : companyId,
                    decoration: const InputDecoration(labelText: 'Empresa'),
                    items: widget.companies
                        .map(
                          (company) => DropdownMenuItem(
                            value: company.id,
                            child: Text(company.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => companyId = value ?? ''),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(
                            value: 'info',
                            child: Text('Informação'),
                          ),
                          DropdownMenuItem(
                            value: 'warning',
                            child: Text('Atenção'),
                          ),
                          DropdownMenuItem(
                            value: 'success',
                            child: Text('Confirmação'),
                          ),
                          DropdownMenuItem(
                            value: 'billing',
                            child: Text('Cobrança'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => type = value ?? 'info'),
                      ),
                    ),
                    Field(
                      width: 220,
                      controller: expiresAt,
                      label: 'Expira em',
                    ),
                    Field(width: 640, controller: title, label: 'Título'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: message,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Mensagem',
                    hintText: 'Escreva o comunicado que aparecerá no app...',
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: loading ? null : submit,
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.campaign_rounded),
                      label: Text(loading ? 'Enviando...' : 'Enviar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentPeriodDialog extends StatefulWidget {
  const PaymentPeriodDialog({super.key});

  @override
  State<PaymentPeriodDialog> createState() => _PaymentPeriodDialogState();
}

class _PaymentPeriodDialogState extends State<PaymentPeriodDialog> {
  int months = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar pagamento'),
      content: DropdownButtonFormField<int>(
        initialValue: months,
        decoration: const InputDecoration(labelText: 'Período liberado'),
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 mês')),
          DropdownMenuItem(value: 3, child: Text('3 meses')),
          DropdownMenuItem(value: 6, child: Text('6 meses')),
          DropdownMenuItem(value: 12, child: Text('12 meses')),
        ],
        onChanged: (value) => setState(() => months = value ?? 1),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, months),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _EditCompanyDialogState extends State<EditCompanyDialog> {
  late final name = TextEditingController(text: widget.company.name);
  late final document = TextEditingController(text: widget.company.document);
  late final billingEmail = TextEditingController(
    text: widget.company.billingEmail,
  );
  late String planSlug = widget.company.planSlug;
  late String status = widget.company.status;
  late bool active = widget.company.active;
  final endsAt = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final date = widget.company.subscriptionEndsAt;
    endsAt.text = date == null ? '' : DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  void dispose() {
    name.dispose();
    document.dispose();
    billingEmail.dispose();
    endsAt.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      await widget.repository.updateCompany(
        companyId: widget.company.id,
        name: name.text.trim(),
        document: document.text.trim(),
        planSlug: planSlug,
        status: status,
        billingEmail: billingEmail.text.trim(),
        active: active,
        subscriptionEndsAt: endsAt.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Empresa atualizada.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'.replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: AdminCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.company.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome da empresa',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Field(width: 260, controller: document, label: 'Documento'),
                    Field(
                      width: 280,
                      controller: billingEmail,
                      label: 'E-mail de cobrança',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: planSlug,
                  decoration: const InputDecoration(labelText: 'Plano'),
                  items: widget.plans
                      .map(
                        (plan) => DropdownMenuItem(
                          value: plan.slug,
                          child: Text(plan.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => planSlug = value ?? planSlug),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'trial', child: Text('Teste')),
                    DropdownMenuItem(value: 'active', child: Text('Ativa')),
                    DropdownMenuItem(
                      value: 'past_due',
                      child: Text('Atrasada'),
                    ),
                    DropdownMenuItem(
                      value: 'blocked',
                      child: Text('Bloqueada'),
                    ),
                    DropdownMenuItem(
                      value: 'canceled',
                      child: Text('Cancelada'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => status = value ?? status),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endsAt,
                  decoration: const InputDecoration(
                    labelText: 'Fim da assinatura',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setState(() => active = value),
                  title: const Text('Empresa ativa'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: loading ? null : submit,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
