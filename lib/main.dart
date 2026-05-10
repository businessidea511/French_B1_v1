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

void main() async {
  // Capture all Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("🔥 Flutter Error: ${details.exception}");
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e) {
    debugPrint("Binding error: $e");
  }

  // Run app immediately
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => LessonsProvider()),
      ],
      child: const FrenchB1App(),
    ),
  );

  // Background initialization with delay to ensure UI is ready
  Future.delayed(const Duration(milliseconds: 500), () {
    _initializeServices().catchError((e) {
      debugPrint("Init service error: $e");
    });
  });
}

Future<void> _initializeServices() async {
  // 1. Try loading environment
  final possiblePaths = [".env", "assets/.env", "assets/env/.env"];
  for (String path in possiblePaths) {
    try {
      await dotenv.load(fileName: path);
      debugPrint("Success: Loaded environment from $path");
      break;
    } catch (_) {}
  }

  // 2. Initialize Supabase
  try {
    final supabaseUrl = String.fromEnvironment('SUPABASE_URL').isNotEmpty 
        ? String.fromEnvironment('SUPABASE_URL') 
        : (dotenv.env['SUPABASE_URL'] ?? '');
    final supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty 
        ? String.fromEnvironment('SUPABASE_ANON_KEY') 
        : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('✅ Supabase Initialized');
    }
  } catch (e) {
    debugPrint('❌ Supabase Init Error: $e');
  }
}

class FrenchB1App extends StatelessWidget {
  const FrenchB1App({super.key});

  void _handleScroll(BuildContext context, double offset,
      {bool isPage = false}) {
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
              title: 'French B1 Learning',
              theme: AppTheme.darkTheme,
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
                  child: CallbackShortcuts(
                    bindings: <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                          _handleScroll(context, -100),
                      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                          _handleScroll(context, 100),
                      const SingleActivator(LogicalKeyboardKey.pageUp): () =>
                          _handleScroll(context,
                              -MediaQuery.of(context).size.height * 0.8,
                              isPage: true),
                      const SingleActivator(LogicalKeyboardKey.pageDown): () =>
                          _handleScroll(
                              context, MediaQuery.of(context).size.height * 0.8,
                              isPage: true),
                      const SingleActivator(LogicalKeyboardKey.home): () {
                        final controller = PrimaryScrollController.maybeOf(context);
                        if (controller != null && controller.hasClients) {
                          controller.animateTo(0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut);
                        }
                      },
                      const SingleActivator(LogicalKeyboardKey.end): () {
                        final controller = PrimaryScrollController.maybeOf(context);
                        if (controller != null && controller.hasClients) {
                          controller.animateTo(
                              controller.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut);
                        }
                      },
                    },
                    child: child!,
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
