import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config/app_config.dart';
import 'models/user.dart';
import 'screens/home/home_screen.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/login/admin_portal_screen.dart';
import 'services/admin_portal_service.dart';
import 'services/analysis_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

import 'widgets/scamshield_error_boundary.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ScamShieldErrorView(errorDetails: details);
  };
  runApp(const ScamShieldGuardianApp());
}

class ScamShieldGuardianApp extends StatefulWidget {
  const ScamShieldGuardianApp({super.key});

  @override
  State<ScamShieldGuardianApp> createState() => _ScamShieldGuardianAppState();
}

class _ScamShieldGuardianAppState extends State<ScamShieldGuardianApp> {
  static const _themeModeKey = 'scamshield_theme_mode';

  late final AuthService _authService;
  late final AdminPortalService _adminPortalService;
  late final AnalysisService _analysisService;
  final _secureStorage = const FlutterSecureStorage();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  User? _user;
  User? _adminUser;
  bool _isDarkMode = false;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    final api = ApiService(baseUri: AppConfig.apiBaseUri);
    _authService = AuthService(api: api);
    _adminPortalService = AdminPortalService(
      api: api,
      tokenProvider: _authService.getStoredAdminToken,
    );
    _analysisService = AnalysisService(
      api: api,
      tokenProvider: _authService.getStoredToken,
    );
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      _isDarkMode = await _secureStorage.read(key: _themeModeKey) == 'dark';
    } on ApiException catch (error) {
      _bootstrapError = error.message;
    } catch (_) {
      _bootstrapError = 'Could not restore your saved appearance setting.';
    }
    try {
      _adminUser = await _authService.getCurrentAdminUser();
      _user = await _authService.getCurrentUser();
    } on ApiException catch (error) {
      _bootstrapError ??= error.message;
    } catch (_) {
      _bootstrapError ??= 'Could not restore your ScamShield session.';
    }
    if (mounted) {
      setState(() {});
    }
    WidgetsBinding.instance.allowFirstFrame();
  }

  Future<void> _setThemeMode(bool isDarkMode) async {
    setState(() => _isDarkMode = isDarkMode);
    try {
      await _secureStorage.write(
        key: _themeModeKey,
        value: isDarkMode ? 'dark' : 'light',
      );
    } catch (_) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Could not save your theme preference.')),
      );
    }
  }

  void _handleAuthenticated(User user) {
    setState(() {
      _user = user;
      _adminUser = null;
      _bootstrapError = null;
    });
  }

  void _handleAdminAuthenticated(User user) {
    setState(() {
      _adminUser = user;
      _user = null;
      _bootstrapError = null;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _user = null;
      _bootstrapError = null;
    });
  }

  Future<void> _handleAdminLogout() async {
    await _authService.logoutAdmin();
    if (!mounted) return;
    setState(() {
      _adminUser = null;
      _bootstrapError = null;
    });
  }

  Future<void> _handleAdminSessionExpired() async {
    await _authService.logoutAdmin();
    if (!mounted) return;
    setState(() {
      _adminUser = null;
      _bootstrapError =
          'Your administrator session expired. Please sign in again.';
    });
  }

  Future<void> _handleSessionExpired() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _user = null;
      _bootstrapError = 'Your session expired. Please sign in again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamShield',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: _guardianTheme(Brightness.light),
      darkTheme: _guardianTheme(Brightness.dark),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _adminUser != null
          ? AdminPortalScreen(
              user: _adminUser!,
              adminService: _adminPortalService,
              onLogout: _handleAdminLogout,
              onSessionExpired: _handleAdminSessionExpired,
              isDarkMode: _isDarkMode,
              onToggleTheme: () => unawaited(_setThemeMode(!_isDarkMode)),
            )
          : _user == null
          ? LandingScreen(
              authService: _authService,
              onAuthenticated: _handleAuthenticated,
              onAdminAuthenticated: _handleAdminAuthenticated,
              initialMessage: _bootstrapError,
              onThemeChanged: (isDarkMode) =>
                  unawaited(_setThemeMode(isDarkMode)),
            )
          : HomeScreen(
              user: _user!,
              analysisService: _analysisService,
              onLogout: _handleLogout,
              onSessionExpired: _handleSessionExpired,
              isDarkMode: _isDarkMode,
              onToggleTheme: () => unawaited(_setThemeMode(!_isDarkMode)),
            ),
    );
  }
}

ThemeData _guardianTheme(Brightness brightness) {
  const brand = Color(0xFF087E8B);
  final scheme = ColorScheme.fromSeed(
    seedColor: brand,
    brightness: brightness,
    surface: brightness == Brightness.dark
        ? const Color(0xFF151C28)
        : const Color(0xFFFFFFFF),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF0B111B)
        : const Color(0xFFF4F7FA),
    appBarTheme: AppBarTheme(
      backgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0B111B)
          : const Color(0xFFF4F7FA),
      foregroundColor: scheme.onSurface,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: brand, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
