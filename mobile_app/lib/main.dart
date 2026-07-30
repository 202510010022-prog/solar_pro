import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'services/cache_service.dart';
import 'services/solarpro_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  try {
    SupabaseConfig.validate();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    runApp(const SolarProMobileApp());
  } catch (error) {
    runApp(SolarProStartupErrorApp(error: error));
  }
}

class SolarProMobileApp extends StatefulWidget {
  const SolarProMobileApp({super.key});

  @override
  State<SolarProMobileApp> createState() => _SolarProMobileAppState();
}

class _SolarProMobileAppState extends State<SolarProMobileApp> {
  late final repository = SolarProRepository(
    Supabase.instance.client,
    CacheService(),
  );

  @override
  Widget build(BuildContext context) {
    final loggedIn = repository.currentUser != null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Solar Pro',
      theme: AppTheme.dark(),
      home: loggedIn
          ? HomePage(
              repository: repository,
              onLogout: () => setState(() {}),
            )
          : LoginPage(
              repository: repository,
              onLoggedIn: () => setState(() {}),
            ),
    );
  }
}

class SolarProStartupErrorApp extends StatelessWidget {
  const SolarProStartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Solar Pro',
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x5535B96F)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: AppTheme.green,
                        size: 42,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Não foi possível iniciar o Solar Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Confira sua conexão com o Supabase. Se estiver usando '
                        'a versão web, limpe os dados do site e tente novamente.',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        '$error',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: main,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
