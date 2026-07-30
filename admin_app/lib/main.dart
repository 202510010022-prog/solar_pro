import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';

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

class AdminTheme {
  static const background = Color(0xFF020817);
  static const surface = Color(0xCC0F172A);
  static const surfaceStrong = Color(0xFF0B1220);
  static const border = Color(0x593B82F6);
  static const blue = Color(0xFF007BFF);
  static const cyan = Color(0xFF00AAFF);
  static const green = Color(0xFF48E13B);
  static const orange = Color(0xFFFF9800);
  static const purple = Color(0xFF8A3FFC);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cyan,
        brightness: Brightness.dark,
        primary: cyan,
        secondary: green,
        surface: surfaceStrong,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x99071126),
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cyan, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class AdminRepository {
  AdminRepository(this.client);

  final SupabaseClient client;

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => client.auth.signOut();

  Future<AdminData> loadData() async {
    final results = await Future.wait([
      _invoke('list_companies'),
      _invoke('list_plans'),
      _invoke('list_payments'),
      _invoke('list_feedbacks'),
      _invoke('list_messages'),
      _invoke('list_users'),
    ]);
    return AdminData.fromMaps(
      results[0],
      results[1],
      results[2],
      results[3],
      results[4],
      results[5],
    );
  }

  Future<void> createCompany({
    required String companyName,
    required String document,
    required String planSlug,
    required String status,
    required String billingEmail,
    required int trialDays,
    required String masterName,
    required String masterEmail,
    required String matricula,
    required String password,
  }) async {
    await _invoke(
      'create_company',
      body: {
        'company': {
          'name': companyName,
          'document': document,
          'plan_slug': planSlug,
          'subscription_status': status,
          'billing_email': billingEmail,
          'trial_days': trialDays,
        },
        'master': {
          'name': masterName,
          'email': masterEmail,
          'matricula': matricula,
          'password': password,
        },
      },
    );
  }

  Future<void> updateCompany({
    required String companyId,
    required String name,
    required String document,
    required String planSlug,
    required String status,
    required String billingEmail,
    required bool active,
    String subscriptionEndsAt = '',
  }) async {
    await _invoke(
      'update_company',
      body: {
        'company': {
          'id': companyId,
          'name': name,
          'document': document,
          'plan_slug': planSlug,
          'subscription_status': status,
          'billing_email': billingEmail,
          'active': active,
          'subscription_ends_at': subscriptionEndsAt,
        },
      },
    );
  }

  Future<void> createPayment({
    required String companyId,
    required double amount,
    required DateTime dueDate,
    required String pixReference,
    required String notes,
  }) async {
    await _invoke(
      'create_payment',
      body: {
        'payment': {
          'company_id': companyId,
          'amount': amount,
          'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
          'pix_reference': pixReference,
          'notes': notes,
        },
      },
    );
  }

  Future<void> markPaymentPaid(int paymentId, {int periodMonths = 1}) async {
    await _invoke(
      'mark_payment_paid',
      body: {
        'payment': {'id': paymentId, 'period_months': periodMonths},
      },
    );
  }

  Future<void> cancelPayment(int paymentId) async {
    await _invoke(
      'cancel_payment',
      body: {
        'payment': {'id': paymentId},
      },
    );
  }

  Future<void> updateFeedback(int feedbackId, String status) async {
    await _invoke(
      'update_feedback',
      body: {
        'feedback': {'id': feedbackId, 'status': status},
      },
    );
  }

  Future<void> createMessage({
    required String companyId,
    required bool sendToAll,
    required String title,
    required String message,
    required String type,
    String expiresAt = '',
  }) async {
    await _invoke(
      'create_message',
      body: {
        'message': {
          'company_id': companyId,
          'send_to_all': sendToAll,
          'title': title,
          'message': message,
          'type': type,
          'expires_at': expiresAt,
        },
      },
    );
  }

  Future<void> createUser({
    required String companyId,
    required String name,
    required String email,
    required String matricula,
    required String role,
    required String permission,
    required String password,
  }) async {
    await _invoke(
      'create_user',
      body: {
        'user': {
          'company_id': companyId,
          'name': name,
          'email': email,
          'matricula': matricula,
          'role': role,
          'permission': permission,
          'password': password,
        },
      },
    );
  }

  Future<void> updateUser({
    required String userId,
    required String companyId,
    required String name,
    required String email,
    required String matricula,
    required String role,
    required String permission,
    required bool active,
    String password = '',
  }) async {
    await _invoke(
      'update_user',
      body: {
        'user': {
          'id': userId,
          'company_id': companyId,
          'name': name,
          'email': email,
          'matricula': matricula,
          'role': role,
          'permission': permission,
          'active': active,
          'password': password,
        },
      },
    );
  }

  Future<void> updateUserActive(String userId, bool active) async {
    await _invoke(
      'update_user_active',
      body: {
        'user': {'id': userId, 'active': active},
      },
    );
  }

  Future<Map<String, dynamic>> _invoke(
    String action, {
    Map<String, dynamic> body = const {},
  }) async {
    try {
      final response = await client.functions.invoke(
        'admin-company',
        body: {'action': action, ...body},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['error'] != null) throw StateError('${data['error']}');
        return data;
      }
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (map['error'] != null) throw StateError('${map['error']}');
        return map;
      }
      throw StateError('Resposta administrativa invalida.');
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(error.reasonPhrase ?? 'Operacao administrativa falhou.');
    }
  }
}

class AdminData {
  const AdminData({
    required this.companies,
    required this.plans,
    required this.payments,
    required this.feedbacks,
    required this.messages,
    required this.users,
  });

  final List<AdminCompany> companies;
  final List<AdminPlan> plans;
  final List<AdminPayment> payments;
  final List<AdminFeedback> feedbacks;
  final List<AdminMessage> messages;
  final List<AdminUser> users;

  factory AdminData.fromMaps(
    Map<String, dynamic> companyMap,
    Map<String, dynamic> planMap,
    Map<String, dynamic> paymentMap,
    Map<String, dynamic> feedbackMap,
    Map<String, dynamic> messageMap,
    Map<String, dynamic> userMap,
  ) {
    final companyRows = (companyMap['companies'] as List? ?? const [])
        .map((row) => AdminCompany.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final planRows = (planMap['plans'] as List? ?? const [])
        .map((row) => AdminPlan.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final paymentRows = (paymentMap['payments'] as List? ?? const [])
        .map((row) => AdminPayment.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final feedbackRows = (feedbackMap['feedbacks'] as List? ?? const [])
        .map((row) => AdminFeedback.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final messageRows = (messageMap['messages'] as List? ?? const [])
        .map((row) => AdminMessage.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final userRows = (userMap['users'] as List? ?? const [])
        .map((row) => AdminUser.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    return AdminData(
      companies: companyRows,
      plans: planRows,
      payments: paymentRows,
      feedbacks: feedbackRows,
      messages: messageRows,
      users: userRows,
    );
  }
}

class AdminCompany {
  const AdminCompany({
    required this.id,
    required this.name,
    required this.document,
    required this.planSlug,
    required this.status,
    required this.billingEmail,
    required this.active,
    required this.createdAt,
    required this.trialEndsAt,
    required this.subscriptionEndsAt,
    required this.usersCount,
    required this.projectsCount,
    required this.pendingAmount,
  });

  final String id;
  final String name;
  final String document;
  final String planSlug;
  final String status;
  final String billingEmail;
  final bool active;
  final DateTime? createdAt;
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;
  final int usersCount;
  final int projectsCount;
  final double pendingAmount;

  factory AdminCompany.fromMap(Map<String, dynamic> map) {
    return AdminCompany(
      id: '${map['id'] ?? ''}',
      name: '${map['name'] ?? ''}',
      document: '${map['document'] ?? ''}',
      planSlug: '${map['plan_slug'] ?? 'starter'}',
      status: '${map['subscription_status'] ?? 'trial'}',
      billingEmail: '${map['billing_email'] ?? ''}',
      active: map['active'] != false,
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
      trialEndsAt: DateTime.tryParse('${map['trial_ends_at'] ?? ''}'),
      subscriptionEndsAt: DateTime.tryParse(
        '${map['subscription_ends_at'] ?? ''}',
      ),
      usersCount: _int(map['users_count']),
      projectsCount: _int(map['projects_count']),
      pendingAmount: _double(map['pending_amount']),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  DateTime? get planDueAt => subscriptionEndsAt ?? trialEndsAt;

  int? get daysUntilDue {
    final dueAt = planDueAt;
    if (dueAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
    return due.difference(today).inDays;
  }
}

class AdminPlan {
  const AdminPlan({
    required this.slug,
    required this.name,
    required this.monthlyPrice,
  });

  final String slug;
  final String name;
  final double monthlyPrice;

  factory AdminPlan.fromMap(Map<String, dynamic> map) {
    final value = map['monthly_price'];
    return AdminPlan(
      slug: '${map['slug'] ?? ''}',
      name: '${map['name'] ?? ''}',
      monthlyPrice: value is num
          ? value.toDouble()
          : double.tryParse('$value') ?? 0,
    );
  }
}

class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.amount,
    required this.status,
    required this.pixReference,
    required this.notes,
    required this.dueDate,
    required this.paidAt,
    required this.createdAt,
  });

  final int id;
  final String companyId;
  final String companyName;
  final double amount;
  final String status;
  final String pixReference;
  final String notes;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime? createdAt;

  bool get canBePaid => status == 'pending' || status == 'overdue';
  bool get canBeCanceled => status == 'pending' || status == 'overdue';

  factory AdminPayment.fromMap(Map<String, dynamic> map) {
    final company = map['companies'];
    final companyMap = company is Map ? Map<String, dynamic>.from(company) : {};
    return AdminPayment(
      id: _int(map['id']),
      companyId: '${map['company_id'] ?? ''}',
      companyName: '${companyMap['name'] ?? 'Empresa'}',
      amount: _double(map['amount']),
      status: '${map['status'] ?? 'pending'}',
      pixReference: '${map['pix_reference'] ?? ''}',
      notes: '${map['notes'] ?? ''}',
      dueDate: DateTime.tryParse('${map['due_date'] ?? ''}'),
      paidAt: DateTime.tryParse('${map['paid_at'] ?? ''}'),
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class AdminFeedback {
  const AdminFeedback({
    required this.id,
    required this.companyName,
    required this.profileName,
    required this.profileEmail,
    required this.rating,
    required this.area,
    required this.message,
    required this.status,
    required this.appVersion,
    required this.deviceInfo,
    required this.createdAt,
  });

  final int id;
  final String companyName;
  final String profileName;
  final String profileEmail;
  final int rating;
  final String area;
  final String message;
  final String status;
  final String appVersion;
  final String deviceInfo;
  final DateTime? createdAt;

  String get areaLabel {
    return switch (area) {
      'geral' => 'Geral',
      'login' => 'Login',
      'crm' => 'CRM',
      'projetos' => 'Projetos',
      'dimensionamento' => 'Dimensionamento',
      'financeiro' => 'Financeiro',
      'sincronizacao' => 'Sincronização',
      'visual' => 'Visual',
      _ => area,
    };
  }

  String get statusLabel {
    return switch (status) {
      'open' => 'Aberto',
      'reviewing' => 'Em análise',
      'resolved' => 'Resolvido',
      'archived' => 'Arquivado',
      _ => status,
    };
  }

  factory AdminFeedback.fromMap(Map<String, dynamic> map) {
    final company = map['companies'];
    final profile = map['profiles'];
    final companyMap = company is Map ? Map<String, dynamic>.from(company) : {};
    final profileMap = profile is Map ? Map<String, dynamic>.from(profile) : {};
    return AdminFeedback(
      id: _int(map['id']),
      companyName: '${companyMap['name'] ?? 'Empresa'}',
      profileName: '${profileMap['name'] ?? 'Usuário'}',
      profileEmail: '${profileMap['email'] ?? ''}',
      rating: _int(map['rating']),
      area: '${map['area'] ?? 'geral'}',
      message: '${map['message'] ?? ''}',
      status: '${map['status'] ?? 'open'}',
      appVersion: '${map['app_version'] ?? ''}',
      deviceInfo: '${map['device_info'] ?? ''}',
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class AdminMessage {
  const AdminMessage({
    required this.id,
    required this.companyName,
    required this.title,
    required this.message,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.readAt,
    required this.expiresAt,
  });

  final int id;
  final String companyName;
  final String title;
  final String message;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  String get typeLabel {
    return switch (type) {
      'billing' => 'Cobrança',
      'warning' => 'Atenção',
      'success' => 'Confirmação',
      _ => 'Informação',
    };
  }

  String get statusLabel {
    return switch (status) {
      'unread' => 'Não lida',
      'read' => 'Lida',
      'archived' => 'Arquivada',
      _ => status,
    };
  }

  factory AdminMessage.fromMap(Map<String, dynamic> map) {
    final company = map['companies'];
    final companyMap = company is Map ? Map<String, dynamic>.from(company) : {};
    return AdminMessage(
      id: _int(map['id']),
      companyName: '${companyMap['name'] ?? 'Empresa'}',
      title: '${map['title'] ?? ''}',
      message: '${map['message'] ?? ''}',
      type: '${map['type'] ?? 'info'}',
      status: '${map['status'] ?? 'unread'}',
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
      readAt: DateTime.tryParse('${map['read_at'] ?? ''}'),
      expiresAt: DateTime.tryParse('${map['expires_at'] ?? ''}'),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class AdminUser {
  const AdminUser({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.name,
    required this.email,
    required this.matricula,
    required this.role,
    required this.permission,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String name;
  final String email;
  final String matricula;
  final String role;
  final String permission;
  final bool active;
  final DateTime? createdAt;

  String get permissionLabel {
    return switch (permission) {
      'owner' => 'Master',
      'platform_admin' => 'Admin Plataforma',
      'diretor' => 'Diretor',
      'assessor_daf' => 'Assessor DAF',
      'assessor_projetos' => 'Assessor Projetos',
      _ => permission,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    final company = map['companies'];
    final companyMap = company is Map ? Map<String, dynamic>.from(company) : {};
    return AdminUser(
      id: '${map['id'] ?? ''}',
      companyId: '${map['company_id'] ?? ''}',
      companyName: '${companyMap['name'] ?? 'Empresa'}',
      name: '${map['name'] ?? ''}',
      email: '${map['email'] ?? ''}',
      matricula: '${map['matricula'] ?? ''}',
      role: '${map['role'] ?? ''}',
      permission: '${map['permission'] ?? ''}',
      active: map['active'] != false,
      createdAt: DateTime.tryParse('${map['created_at'] ?? ''}'),
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

enum AdminSection { overview, companies, users, payments, feedbacks, messages }

extension AdminSectionInfo on AdminSection {
  String get title {
    return switch (this) {
      AdminSection.overview => 'Visão geral',
      AdminSection.companies => 'Empresas',
      AdminSection.users => 'Empresas e usuários',
      AdminSection.payments => 'Cobranças Pix',
      AdminSection.feedbacks => 'Feedbacks e chamados',
      AdminSection.messages => 'Mensagens',
    };
  }

  String get subtitle {
    return switch (this) {
      AdminSection.overview => 'Relatórios, receita, conversão e uso.',
      AdminSection.companies => 'Cadastro, planos e status das empresas.',
      AdminSection.users => 'Dados da empresa, dependentes e acessos.',
      AdminSection.payments => 'Cobranças, pagamentos e inadimplência.',
      AdminSection.feedbacks => 'Chamados enviados pelo app cliente.',
      AdminSection.messages => 'Comunicados enviados ao aplicativo.',
    };
  }
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
                    return _AdminError(
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
        _SummaryGrid(companies: companies),
        const SizedBox(height: 18),
        _OperationalSummary(
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

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.section,
    required this.onSelect,
  });

  final AdminSection section;
  final ValueChanged<AdminSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xAA020817),
        border: Border(right: BorderSide(color: AdminTheme.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AdminTheme.blue,
                  child: Icon(Icons.solar_power_rounded),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOLAR PRO',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'ADMIN',
                      style: TextStyle(
                        color: AdminTheme.cyan,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 34),
            _SideItem(
              icon: Icons.business_rounded,
              title: 'Visão geral',
              active: section == AdminSection.overview,
              onTap: () => onSelect(AdminSection.overview),
            ),
            _SideItem(
              icon: Icons.apartment_rounded,
              title: 'Empresas',
              active: section == AdminSection.companies,
              onTap: () => onSelect(AdminSection.companies),
            ),
            _SideItem(
              icon: Icons.payments_outlined,
              title: 'Cobranças',
              active: section == AdminSection.payments,
              onTap: () => onSelect(AdminSection.payments),
            ),
            _SideItem(
              icon: Icons.groups_rounded,
              title: 'Empresas e usuários',
              active: section == AdminSection.users,
              onTap: () => onSelect(AdminSection.users),
            ),
            _SideItem(
              icon: Icons.feedback_outlined,
              title: 'Feedbacks',
              active: section == AdminSection.feedbacks,
              onTap: () => onSelect(AdminSection.feedbacks),
            ),
            _SideItem(
              icon: Icons.campaign_outlined,
              title: 'Mensagens',
              active: section == AdminSection.messages,
              onTap: () => onSelect(AdminSection.messages),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminTheme.green.withValues(alpha: 0.08),
                border: Border.all(
                  color: AdminTheme.green.withValues(alpha: 0.35),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Painel separado do app cliente.\nOperação comercial com mais controle.',
                style: TextStyle(color: AdminTheme.muted, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: active
                ? AdminTheme.blue.withValues(alpha: 0.22)
                : Colors.transparent,
            border: Border.all(
              color: active ? AdminTheme.cyan : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? AdminTheme.cyan : AdminTheme.muted),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: active ? AdminTheme.text : AdminTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminHeader extends StatelessWidget {
  const AdminHeader({
    super.key,
    required this.section,
    required this.onLogout,
    required this.onRefresh,
    required this.onCreate,
    required this.onCreatePayment,
    required this.onCreateMessage,
    required this.onCreateUser,
  });

  final AdminSection section;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final VoidCallback onCreatePayment;
  final VoidCallback onCreateMessage;
  final VoidCallback onCreateUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.subtitle,
                style: const TextStyle(color: AdminTheme.muted),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Atualizar',
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('Nova empresa'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onCreatePayment,
          icon: const Icon(Icons.pix_rounded),
          label: const Text('Cobrança Pix'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onCreateMessage,
          icon: const Icon(Icons.campaign_rounded),
          label: const Text('Comunicado'),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onCreateUser,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Usuário'),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Sair',
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.companies});

  final List<AdminCompany> companies;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final active = companies.where((item) => item.active).length;
    final users = companies.fold<int>(0, (sum, item) => sum + item.usersCount);
    final projects = companies.fold<int>(
      0,
      (sum, item) => sum + item.projectsCount,
    );
    final pending = companies.fold<double>(
      0,
      (sum, item) => sum + item.pendingAmount,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1050 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 2.6,
          children: [
            StatCard(
              icon: Icons.business_rounded,
              label: 'Empresas ativas',
              value: '$active',
              color: AdminTheme.blue,
            ),
            StatCard(
              icon: Icons.groups_rounded,
              label: 'Usuários ativos',
              value: '$users',
              color: AdminTheme.green,
            ),
            StatCard(
              icon: Icons.folder_copy_rounded,
              label: 'Projetos',
              value: '$projects',
              color: AdminTheme.purple,
            ),
            StatCard(
              icon: Icons.pix_rounded,
              label: 'Pendente',
              value: money.format(pending),
              color: AdminTheme.orange,
            ),
          ],
        );
      },
    );
  }
}

class _OperationalSummary extends StatelessWidget {
  const _OperationalSummary({
    required this.payments,
    required this.feedbacks,
    required this.messages,
  });

  final List<AdminPayment> payments;
  final List<AdminFeedback> feedbacks;
  final List<AdminMessage> messages;

  @override
  Widget build(BuildContext context) {
    final openPayments = payments
        .where(
          (payment) =>
              payment.status == 'pending' || payment.status == 'overdue',
        )
        .length;
    final openFeedbacks = feedbacks
        .where(
          (feedback) =>
              feedback.status == 'open' || feedback.status == 'reviewing',
        )
        .length;
    final resolvedFeedbacks = feedbacks
        .where((feedback) => feedback.status == 'resolved')
        .length;
    final unreadMessages = messages
        .where((message) => message.status == 'unread')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: constraints.maxWidth > 900 ? 3.2 : 5,
          children: [
            StatCard(
              icon: Icons.pix_rounded,
              label: 'Cobranças abertas',
              value: '$openPayments',
              color: AdminTheme.orange,
            ),
            StatCard(
              icon: Icons.support_agent_rounded,
              label: 'Chamados em aberto',
              value: '$openFeedbacks',
              color: AdminTheme.cyan,
            ),
            StatCard(
              icon: Icons.task_alt_rounded,
              label: 'Chamados resolvidos',
              value: '$resolvedFeedbacks',
              color: AdminTheme.green,
            ),
            StatCard(
              icon: Icons.campaign_rounded,
              label: 'Mensagens não lidas',
              value: '$unreadMessages',
              color: AdminTheme.purple,
            ),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AdminTheme.muted)),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommercialReports extends StatelessWidget {
  const CommercialReports({
    super.key,
    required this.companies,
    required this.payments,
    required this.users,
  });

  final List<AdminCompany> companies;
  final List<AdminPayment> payments;
  final List<AdminUser> users;

  @override
  Widget build(BuildContext context) {
    final report = CommercialReportData.from(
      companies: companies,
      payments: payments,
      users: users,
    );
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0x3300AAFF),
                child: Icon(Icons.analytics_rounded, color: AdminTheme.cyan),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatórios comerciais',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Receita, conversão, planos e uso da plataforma.',
                      style: TextStyle(color: AdminTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1100 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 2.8,
                children: [
                  StatCard(
                    icon: Icons.payments_rounded,
                    label: 'Receita recebida no mês',
                    value: money.format(report.monthlyReceived),
                    color: AdminTheme.green,
                  ),
                  StatCard(
                    icon: Icons.pending_actions_rounded,
                    label: 'Receita pendente',
                    value: money.format(report.pendingRevenue),
                    color: AdminTheme.orange,
                  ),
                  StatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Receita atrasada',
                    value: money.format(report.overdueRevenue),
                    color: Colors.redAccent,
                  ),
                  StatCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Conversão teste → ativo',
                    value: '${report.conversionRate.toStringAsFixed(1)}%',
                    color: AdminTheme.cyan,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 980;
              final children = [
                ReportBreakdownCard(
                  title: 'Status das empresas',
                  icon: Icons.business_center_rounded,
                  items: report.statusItems,
                ),
                ReportBreakdownCard(
                  title: 'Usuários por plano',
                  icon: Icons.group_rounded,
                  items: report.usersByPlanItems,
                ),
                TopCompaniesCard(companies: report.topCompanies),
              ];
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children
                      .map(
                        (child) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: child,
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return Column(
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: child,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CommercialReportData {
  const CommercialReportData({
    required this.monthlyReceived,
    required this.pendingRevenue,
    required this.overdueRevenue,
    required this.conversionRate,
    required this.statusItems,
    required this.usersByPlanItems,
    required this.topCompanies,
  });

  final double monthlyReceived;
  final double pendingRevenue;
  final double overdueRevenue;
  final double conversionRate;
  final List<ReportBreakdownItem> statusItems;
  final List<ReportBreakdownItem> usersByPlanItems;
  final List<AdminCompany> topCompanies;

  factory CommercialReportData.from({
    required List<AdminCompany> companies,
    required List<AdminPayment> payments,
    required List<AdminUser> users,
  }) {
    final now = DateTime.now();
    final monthlyReceived = payments
        .where(
          (payment) =>
              payment.status == 'paid' &&
              payment.paidAt != null &&
              payment.paidAt!.year == now.year &&
              payment.paidAt!.month == now.month,
        )
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final pendingRevenue = payments
        .where((payment) => payment.status == 'pending')
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final overdueRevenue = payments
        .where((payment) => payment.status == 'overdue')
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    final trialCount = companies.where((item) => item.status == 'trial').length;
    final activeCount = companies
        .where((item) => item.status == 'active')
        .length;
    final conversionBase = trialCount + activeCount;
    final conversionRate = conversionBase == 0
        ? 0.0
        : (activeCount / conversionBase) * 100;

    final byStatus = <String, int>{};
    for (final company in companies) {
      final label = _statusLabel(company.status, company.active);
      byStatus[label] = (byStatus[label] ?? 0) + 1;
    }

    final usersByPlan = <String, int>{};
    final planByCompany = {
      for (final company in companies) company.id: company.planSlug,
    };
    for (final user in users.where((user) => user.active)) {
      final plan = planByCompany[user.companyId] ?? 'sem plano';
      usersByPlan[plan] = (usersByPlan[plan] ?? 0) + 1;
    }

    final topCompanies = [...companies]
      ..sort((a, b) {
        final aScore = (a.projectsCount * 3) + a.usersCount;
        final bScore = (b.projectsCount * 3) + b.usersCount;
        return bScore.compareTo(aScore);
      });

    return CommercialReportData(
      monthlyReceived: monthlyReceived,
      pendingRevenue: pendingRevenue,
      overdueRevenue: overdueRevenue,
      conversionRate: conversionRate,
      statusItems: byStatus.entries
          .map((entry) => ReportBreakdownItem(entry.key, entry.value))
          .toList(),
      usersByPlanItems: usersByPlan.entries
          .map((entry) => ReportBreakdownItem(entry.key, entry.value))
          .toList(),
      topCompanies: topCompanies.take(5).toList(),
    );
  }

  static String _statusLabel(String status, bool active) {
    if (!active) return 'Inativa';
    return switch (status) {
      'active' => 'Ativa',
      'trial' => 'Teste',
      'past_due' => 'Atrasada',
      'blocked' => 'Bloqueada',
      'canceled' => 'Cancelada',
      _ => status,
    };
  }
}

class ReportBreakdownItem {
  const ReportBreakdownItem(this.label, this.value);

  final String label;
  final int value;
}

class ReportBreakdownCard extends StatelessWidget {
  const ReportBreakdownCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<ReportBreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x66071126),
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AdminTheme.cyan),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Sem dados suficientes.',
              style: TextStyle(color: AdminTheme.muted),
            )
          else
            ...items.map((item) {
              final percent = total == 0 ? 0.0 : item.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(color: AdminTheme.muted),
                          ),
                        ),
                        Text(
                          '${item.value}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: percent.clamp(0, 1),
                        backgroundColor: AdminTheme.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AdminTheme.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class TopCompaniesCard extends StatelessWidget {
  const TopCompaniesCard({super.key, required this.companies});

  final List<AdminCompany> companies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x66071126),
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: AdminTheme.cyan),
              SizedBox(width: 8),
              Text(
                'Ranking de uso',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (companies.isEmpty)
            const Text(
              'Sem empresas cadastradas.',
              style: TextStyle(color: AdminTheme.muted),
            )
          else
            ...companies.asMap().entries.map((entry) {
              final company = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AdminTheme.blue.withValues(alpha: 0.18),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${company.projectsCount} projetos • ${company.usersCount} usuários',
                            style: const TextStyle(
                              color: AdminTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class CompanyTable extends StatelessWidget {
  const CompanyTable({
    super.key,
    required this.companies,
    required this.plans,
    required this.onEdit,
  });

  final List<AdminCompany> companies;
  final List<AdminPlan> plans;
  final void Function(AdminCompany company, List<AdminPlan> plans) onEdit;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    if (companies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhuma empresa encontrada.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AdminTheme.text,
        ),
        dataTextStyle: const TextStyle(color: AdminTheme.text),
        columns: const [
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Plano')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Vencimento')),
          DataColumn(label: Text('Usuários')),
          DataColumn(label: Text('Projetos')),
          DataColumn(label: Text('Pendente')),
          DataColumn(label: Text('Ações')),
        ],
        rows: companies.map((company) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 260,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        company.billingEmail.isEmpty
                            ? company.document
                            : company.billingEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AdminTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(Text(company.planSlug)),
              DataCell(
                StatusPill(status: company.status, active: company.active),
              ),
              DataCell(PlanDueCell(company: company)),
              DataCell(Text('${company.usersCount}')),
              DataCell(Text('${company.projectsCount}')),
              DataCell(Text(money.format(company.pendingAmount))),
              DataCell(
                IconButton(
                  onPressed: () => onEdit(company, plans),
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Editar empresa',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class PlanDueCell extends StatelessWidget {
  const PlanDueCell({super.key, required this.company});

  final AdminCompany company;

  @override
  Widget build(BuildContext context) {
    final dueAt = company.planDueAt;
    final days = company.daysUntilDue;
    final date = DateFormat('dd/MM/yyyy');

    final Color color;
    final String label;
    if (dueAt == null || days == null) {
      color = AdminTheme.muted;
      label = 'Sem vencimento';
    } else if (days < 0) {
      color = Colors.redAccent;
      label = 'Vencido há ${days.abs()}d';
    } else if (days == 0) {
      color = AdminTheme.orange;
      label = 'Vence hoje';
    } else if (days <= 7) {
      color = AdminTheme.orange;
      label = 'Vence em ${days}d';
    } else if (days <= 15) {
      color = AdminTheme.cyan;
      label = 'Vence em ${days}d';
    } else {
      color = AdminTheme.green;
      label = 'Em dia';
    }

    return SizedBox(
      width: 150,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dueAt == null ? '-' : date.format(dueAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.40)),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
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

class PaymentTable extends StatelessWidget {
  const PaymentTable({
    super.key,
    required this.payments,
    required this.onPaid,
    required this.onCancel,
  });

  final List<AdminPayment> payments;
  final void Function(AdminPayment payment) onPaid;
  final void Function(AdminPayment payment) onCancel;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat('dd/MM/yyyy');
    if (payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhuma cobrança encontrada.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AdminTheme.text,
        ),
        dataTextStyle: const TextStyle(color: AdminTheme.text),
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Vencimento')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Referência Pix')),
          DataColumn(label: Text('Ações')),
        ],
        rows: payments.map((payment) {
          return DataRow(
            cells: [
              DataCell(Text('#${payment.id}')),
              DataCell(
                SizedBox(
                  width: 230,
                  child: Text(
                    payment.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              DataCell(Text(money.format(payment.amount))),
              DataCell(
                Text(
                  payment.dueDate == null ? '-' : date.format(payment.dueDate!),
                ),
              ),
              DataCell(PaymentStatusPill(status: payment.status)),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    payment.pixReference.isEmpty ? '-' : payment.pixReference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AdminTheme.muted),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: payment.canBePaid
                          ? () => onPaid(payment)
                          : null,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      tooltip: 'Marcar como paga',
                    ),
                    IconButton(
                      onPressed: payment.canBeCanceled
                          ? () => onCancel(payment)
                          : null,
                      icon: const Icon(Icons.cancel_outlined),
                      tooltip: 'Cancelar cobrança',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class UserTable extends StatelessWidget {
  const UserTable({
    super.key,
    required this.users,
    required this.onEdit,
    required this.onToggleActive,
  });

  final List<AdminUser> users;
  final ValueChanged<AdminUser> onEdit;
  final void Function(AdminUser user, bool active) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhum usuário encontrado.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AdminTheme.text,
        ),
        dataTextStyle: const TextStyle(color: AdminTheme.text),
        columns: const [
          DataColumn(label: Text('Usuário')),
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Matrícula')),
          DataColumn(label: Text('Permissão')),
          DataColumn(label: Text('Cargo')),
          DataColumn(label: Text('Criado em')),
          DataColumn(label: Text('Ativo')),
          DataColumn(label: Text('Ações')),
        ],
        rows: users.map((user) {
          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 240,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AdminTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    user.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(user.matricula)),
              DataCell(Text(user.permissionLabel)),
              DataCell(Text(user.role)),
              DataCell(
                Text(
                  user.createdAt == null ? '-' : date.format(user.createdAt!),
                ),
              ),
              DataCell(
                Switch(
                  value: user.active,
                  onChanged: (value) => onToggleActive(user, value),
                ),
              ),
              DataCell(
                IconButton(
                  onPressed: () => onEdit(user),
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Editar usuário',
                ),
              ),
            ],
          );
        }).toList(),
      ),
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

class FeedbackTable extends StatelessWidget {
  const FeedbackTable({
    super.key,
    required this.feedbacks,
    required this.onStatusChanged,
  });

  final List<AdminFeedback> feedbacks;
  final void Function(AdminFeedback feedback, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm');
    if (feedbacks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhum chamado encontrado.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AdminTheme.text,
        ),
        dataTextStyle: const TextStyle(color: AdminTheme.text),
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Usuário')),
          DataColumn(label: Text('Área')),
          DataColumn(label: Text('Nota')),
          DataColumn(label: Text('Mensagem')),
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Status')),
        ],
        rows: feedbacks.map((feedback) {
          return DataRow(
            cells: [
              DataCell(Text('#${feedback.id}')),
              DataCell(
                SizedBox(
                  width: 180,
                  child: Text(
                    feedback.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 180,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feedback.profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (feedback.profileEmail.isNotEmpty)
                        Text(
                          feedback.profileEmail,
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
              ),
              DataCell(Text(feedback.areaLabel)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < feedback.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AdminTheme.orange,
                      size: 18,
                    ),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 320,
                  child: Text(
                    feedback.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  feedback.createdAt == null
                      ? '-'
                      : date.format(feedback.createdAt!),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: feedback.status,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Aberto')),
                      DropdownMenuItem(
                        value: 'reviewing',
                        child: Text('Em análise'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Resolvido'),
                      ),
                      DropdownMenuItem(
                        value: 'archived',
                        child: Text('Arquivado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null && value != feedback.status) {
                        onStatusChanged(feedback, value);
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class MessageTable extends StatelessWidget {
  const MessageTable({super.key, required this.messages});

  final List<AdminMessage> messages;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm');
    if (messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Nenhuma mensagem enviada.',
            style: TextStyle(color: AdminTheme.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AdminTheme.text,
        ),
        dataTextStyle: const TextStyle(color: AdminTheme.text),
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Empresa')),
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Título')),
          DataColumn(label: Text('Mensagem')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Enviada em')),
          DataColumn(label: Text('Expira em')),
        ],
        rows: messages.map((message) {
          return DataRow(
            cells: [
              DataCell(Text('#${message.id}')),
              DataCell(
                SizedBox(
                  width: 190,
                  child: Text(
                    message.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              DataCell(MessageTypePill(type: message.type)),
              DataCell(
                SizedBox(
                  width: 210,
                  child: Text(
                    message.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 320,
                  child: Text(
                    message.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(message.statusLabel)),
              DataCell(
                Text(
                  message.createdAt == null
                      ? '-'
                      : date.format(message.createdAt!),
                ),
              ),
              DataCell(
                Text(
                  message.expiresAt == null
                      ? '-'
                      : DateFormat('dd/MM/yyyy').format(message.expiresAt!),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, required this.active});

  final String status;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = !active
        ? AdminTheme.muted
        : switch (status) {
            'active' => AdminTheme.green,
            'trial' => AdminTheme.blue,
            'past_due' => AdminTheme.orange,
            'blocked' => Colors.redAccent,
            _ => AdminTheme.purple,
          };
    final label = !active
        ? 'inativa'
        : switch (status) {
            'active' => 'ativa',
            'trial' => 'teste',
            'past_due' => 'atrasada',
            'canceled' => 'cancelada',
            'blocked' => 'bloqueada',
            _ => status,
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class PaymentStatusPill extends StatelessWidget {
  const PaymentStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => AdminTheme.green,
      'overdue' => Colors.redAccent,
      'canceled' => AdminTheme.muted,
      _ => AdminTheme.orange,
    };
    final label = switch (status) {
      'paid' => 'paga',
      'overdue' => 'atrasada',
      'canceled' => 'cancelada',
      _ => 'pendente',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class MessageTypePill extends StatelessWidget {
  const MessageTypePill({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'billing' => AdminTheme.orange,
      'warning' => Colors.redAccent,
      'success' => AdminTheme.green,
      _ => AdminTheme.cyan,
    };
    final label = switch (type) {
      'billing' => 'Cobrança',
      'warning' => 'Atenção',
      'success' => 'Confirmação',
      _ => 'Informação',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
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

class Field extends StatelessWidget {
  const Field({
    super.key,
    required this.width,
    required this.controller,
    required this.label,
  });

  final double width;
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44007BFF),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AdminError extends StatelessWidget {
  const _AdminError({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AdminCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0x33FF9800),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: AdminTheme.orange,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Acesso administrativo indisponível',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AdminTheme.muted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Trocar login'),
                  ),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
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
