import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'services/language_provider.dart';
import 'services/lessons_provider.dart';
import 'services/global_scroll_manager.dart';
import 'services/admin_auth.dart';
import 'services/deepseek_service.dart';
import 'services/progress_service.dart';
import 'services/translation_store.dart';
import 'widgets/motion.dart';
import 'widgets/translation_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Services (Supabase, Env) BEFORE UI
  try {
    // Try loading environment from multiple possible locations
    final possiblePaths = [".env", "assets/.env", "assets/env/.env", "env/.env"];
    for (String path in possiblePaths) {
      try {
        await dotenv.load(fileName: path);
        debugPrint("✅ Loaded environment from $path");
      } catch (_) {}
    }
    
    // Get keys with priority: 1. Build Args, 2. Env File
    final String supabaseUrl = const String.fromEnvironment('SUPABASE_URL').isNotEmpty
        ? const String.fromEnvironment('SUPABASE_URL')
        : (dotenv.env['SUPABASE_URL'] ?? '');
        
    final String supabaseKey = const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty
        ? const String.fromEnvironment('SUPABASE_ANON_KEY')
        : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      debugPrint("🚀 Supabase Initialized Successfully");
    } else {
      debugPrint("❌ Supabase keys NOT FOUND. Available env keys: ${dotenv.env.keys}");
    }
  } catch (e) {
    debugPrint("🔥 Initialization Critical Error: $e");
  }

  // Reload an admin session saved by an earlier login (expires after 12h)
  await AdminAuth.restore();
  await Future.wait([ProgressService.instance.load(), DeepSeekService.warmCache()]);
  final themeController = ThemeController();
  await themeController.load();
  AppTheme.isDark = themeController.resolveDark(
      WidgetsBinding.instance.platformDispatcher.platformBrightness);

  // 2. Set UI Orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => LessonsProvider()),
        ChangeNotifierProvider.value(value: ProgressService.instance),
        ChangeNotifierProvider.value(value: themeController),
      ],
      child: const FrenchB1App(),
    ),
  );
}


class FrenchB1App extends StatelessWidget {
  const FrenchB1App({super.key});

  void _handleScroll(BuildContext context, double offset,
      {bool isPage = false}) {
    final active = GlobalScrollManager.activeController;
    if (active != null && active.hasClients) {
      final target = active.offset + offset;
      active.animateTo(
        target.clamp(0.0, active.position.maxScrollExtent),
        duration: Duration(milliseconds: isPage ? 300 : 100),
        curve: Curves.easeOut,
      );
      return;
    }

    final controller = PrimaryScrollController.maybeOf(context);
    if (controller != null && controller.hasClients) {
      final target = controller.offset + offset;
      controller.animateTo(
        target.clamp(0.0, controller.position.maxScrollExtent),
        duration: Duration(milliseconds: isPage ? 300 : 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Root FocusNode to keep everything organized
    final FocusNode rootFocusNode = FocusNode(debugLabel: 'RootFocusNode');

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Listener(
          onPointerDown: (_) {
            if (!rootFocusNode.hasFocus) {
              rootFocusNode.requestFocus();
            }
          },
          child: Focus(
            focusNode: rootFocusNode,
            autofocus: true,
            child: MaterialApp(
              title: 'PolyLearn French',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: context.watch<ThemeController>().mode,
              debugShowCheckedModeBanner: false,
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                scrollbars: true,
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              builder: (context, child) {
                return Directionality(
                  textDirection: languageProvider.isRTL
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Builder(
                    builder: (innerContext) => CallbackShortcuts(
                      bindings: <ShortcutActivator, VoidCallback>{
                        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                            _handleScroll(innerContext, -100),
                        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                            _handleScroll(innerContext, 100),
                        const SingleActivator(LogicalKeyboardKey.pageUp): () =>
                            _handleScroll(innerContext,
                                -MediaQuery.of(innerContext).size.height * 0.8,
                                isPage: true),
                        const SingleActivator(LogicalKeyboardKey.pageDown): () =>
                            _handleScroll(
                                innerContext, MediaQuery.of(innerContext).size.height * 0.8,
                                isPage: true),
                        const SingleActivator(LogicalKeyboardKey.home): () {
                          final active = GlobalScrollManager.activeController;
                          final controller = active ?? PrimaryScrollController.maybeOf(innerContext);
                          if (controller != null && controller.hasClients) {
                            controller.animateTo(0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut);
                          }
                        },
                        const SingleActivator(LogicalKeyboardKey.end): () {
                          final active = GlobalScrollManager.activeController;
                          final controller = active ?? PrimaryScrollController.maybeOf(innerContext);
                          if (controller != null && controller.hasClients) {
                            controller.animateTo(
                                controller.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut);
                          }
                        },
                      },
                      child: ThemeSync(child: AuroraBackground(child: TranslationBanner(child: child!))),
                    ),
                  ),
                );
              },
              home: const HomePage(),
            ),
          ),
        );
      },
    );
  }
}

/// Keeps [AppTheme] colours in step with the light/dark mode, and rebuilds
/// every page when the mode changes (their colours are read while building).
class ThemeSync extends StatefulWidget {
  final Widget child;
  const ThemeSync({super.key, required this.child});

  @override
  State<ThemeSync> createState() => _ThemeSyncState();
}

class _ThemeSyncState extends State<ThemeSync> {
  AppLanguage? _language;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Interface text (tr) and colours are read without listening, so a new
    // theme or language rebuilds every screen once.
    final language = context.watch<LanguageProvider>().currentLanguage;
    final languageChanged = _language != null && _language != language;
    _language = language;
    // Shared translations of this language: one download, then instant everywhere.
    TranslationStore.loadLanguage(language.code);
    if (dark != AppTheme.isDark || languageChanged) {
      AppTheme.isDark = dark;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        void rebuild(Element e) {
          e.markNeedsBuild();
          e.visitChildren(rebuild);
        }

        (context as Element).visitChildren(rebuild);
      });
    }
    return widget.child;
  }
}
