import 'package:flutter/material.dart';

import '../models/app_profile.dart';
import '../models/app_subscription.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import 'clients_page.dart';
import 'dashboard_page.dart';
import 'financial_page.dart';
import 'more_page.dart';
import 'projects_page.dart';
import 'sizing_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository, required this.onLogout});

  final SolarProRepository repository;
  final VoidCallback onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  AppProfile? profile;
  AppSubscription? subscription;

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadSubscription();
  }

  Future<void> loadProfile() async {
    try {
      final value = await widget.repository.loadProfile();
      if (mounted) setState(() => profile = value);
    } catch (_) {
      if (mounted) setState(() => profile = null);
    }
  }

  Future<void> loadSubscription() async {
    try {
      final value = await widget.repository.loadSubscription();
      if (mounted) setState(() => subscription = value);
    } catch (_) {
      if (mounted) setState(() => subscription = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compactNav = MediaQuery.sizeOf(context).width < 390;
    final pages = [
      DashboardPage(
        repository: widget.repository,
        profile: profile,
        onOpenTab: (tabIndex) => setState(() => index = tabIndex),
      ),
      ClientsPage(repository: widget.repository, profile: profile),
      ProjectsPage(repository: widget.repository, profile: profile),
      SizingPage(repository: widget.repository, subscription: subscription),
      FinancialPage(repository: widget.repository, profile: profile),
      MorePage(
        repository: widget.repository,
        profile: profile,
        subscription: subscription,
        onLogout: () async {
          await widget.repository.signOut();
          widget.onLogout();
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        centerTitle: true,
        title: Text(
          _titleFor(index),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
      drawer: _SolarProDrawer(
        profile: profile,
        subscription: subscription,
        onOpenMore: () {
          Navigator.pop(context);
          setState(() => index = 5);
        },
        onLogout: () async {
          Navigator.pop(context);
          await widget.repository.signOut();
          widget.onLogout();
        },
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        labelBehavior: compactNav
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'CRM',
          ),
          const NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Projetos',
          ),
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: const Icon(Icons.bolt_rounded),
            label: compactNav ? 'Dimens.' : 'Dimensionar',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: compactNav ? 'Financ.' : 'Financeiro',
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'Mais',
          ),
        ],
      ),
    );
  }

  String _titleFor(int value) {
    return switch (value) {
      0 => 'Dashboard',
      1 => 'Clientes',
      2 => 'Projetos',
      3 => 'Dimensionamento',
      4 => 'Financeiro',
      _ => 'Mais',
    };
  }
}

class _SolarProDrawer extends StatelessWidget {
  const _SolarProDrawer({
    required this.profile,
    required this.subscription,
    required this.onOpenMore,
    required this.onLogout,
  });

  final AppProfile? profile;
  final AppSubscription? subscription;
  final VoidCallback onOpenMore;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final currentProfile = profile;
    final currentSubscription = subscription;
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.green,
                        child: Text(
                          _initials(currentProfile?.name ?? 'Solar Pro'),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Solar Pro',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w900)),
                            Text(
                              currentProfile?.name.isNotEmpty == true
                                  ? currentProfile!.name
                                  : 'Usuário conectado',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DrawerInfo(
                      label: 'Matrícula',
                      value: currentProfile?.matricula ?? '-'),
                  _DrawerInfo(
                      label: 'Cargo', value: currentProfile?.role ?? '-'),
                  _DrawerInfo(
                      label: 'Permissão',
                      value: currentProfile?.permission ?? '-'),
                  _DrawerInfo(
                      label: 'Plano',
                      value: currentSubscription?.planName ?? '-'),
                  _DrawerInfo(
                      label: 'Status',
                      value: currentSubscription?.statusLabel ?? '-'),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            _DrawerTile(
              icon: Icons.cloud_done_outlined,
              title: 'Sincronização',
              subtitle: 'Conectado ao Supabase',
              onTap: onOpenMore,
            ),
            _DrawerTile(
              icon: Icons.settings_outlined,
              title: 'Configurações',
              subtitle: 'Reservado para a próxima etapa',
              onTap: onOpenMore,
            ),
            _DrawerTile(
              icon: Icons.info_outline_rounded,
              title: 'Sobre o app',
              subtitle: 'Solar Pro Mobile 0.1.0',
              onTap: onOpenMore,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sair da conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'SP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _DrawerInfo extends StatelessWidget {
  const _DrawerInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(label,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppTheme.green.withValues(alpha: 0.12),
        child: Icon(icon, color: AppTheme.green),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
