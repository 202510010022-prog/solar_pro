import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/admin_section.dart';
import 'app/admin_theme.dart';
import 'config/supabase_config.dart';
import 'dialogs/create_company_dialog.dart';
import 'dialogs/create_message_dialog.dart';
import 'dialogs/create_payment_dialog.dart';
import 'dialogs/create_user_dialog.dart';
import 'dialogs/edit_company_dialog.dart';
import 'dialogs/edit_user_dialog.dart';
import 'dialogs/payment_period_dialog.dart';
import 'models/admin_company.dart';
import 'models/admin_data.dart';
import 'models/admin_feedback.dart';
import 'models/admin_message.dart';
import 'models/admin_payment.dart';
import 'models/admin_plan.dart';
import 'models/admin_user.dart';
import 'pages/sections/companies_section.dart';
import 'pages/sections/feedbacks_section.dart';
import 'pages/sections/messages_section.dart';
import 'pages/sections/overview_section.dart';
import 'pages/sections/payments_section.dart';
import 'pages/sections/users_section.dart';
import 'services/admin_repository.dart';
import 'widgets/admin_card.dart';
import 'widgets/admin_error.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/reports/commercial_reports.dart';

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
        CompaniesSection(
          companies: filteredCompanies,
          plans: plans,
          onQueryChanged: (value) => setState(() => query = value),
          onEdit: _openEditCompany,
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
        PaymentsSection(
          payments: payments,
          onCreatePayment: () => _openCreatePayment(companies),
          onPaid: _markPaymentPaid,
          onCancel: _cancelPayment,
        ),
      ],
      AdminSection.feedbacks => [
        FeedbacksSection(
          feedbacks: feedbacks,
          onStatusChanged: _updateFeedbackStatus,
        ),
      ],
      AdminSection.messages => [
        MessagesSection(
          messages: messages,
          onCreateMessage: () => _openCreateMessage(companies),
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
