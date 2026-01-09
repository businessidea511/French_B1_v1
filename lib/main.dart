import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load local .env if it exists
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Silently continue; production uses --dart-define
  }

  runApp(const FrenchB1App());
}

class FrenchB1App extends StatelessWidget {
  const FrenchB1App({super.key});

  void _handleScroll(BuildContext context, double offset,
      {bool isPage = false}) {
    final controller = PrimaryScrollController.of(context);
    if (controller.hasClients) {
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

    return Listener(
      onPointerDown: (_) {
        // Force focus back to our app on any click to prevent browser focus-thievery
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
            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    _handleScroll(context, -100),
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _handleScroll(context, 100),
                const SingleActivator(LogicalKeyboardKey.pageUp): () =>
                    _handleScroll(
                        context, -MediaQuery.of(context).size.height * 0.8,
                        isPage: true),
                const SingleActivator(LogicalKeyboardKey.pageDown): () =>
                    _handleScroll(
                        context, MediaQuery.of(context).size.height * 0.8,
                        isPage: true),
                const SingleActivator(LogicalKeyboardKey.home): () {
                  final controller = PrimaryScrollController.of(context);
                  if (controller.hasClients) {
                    controller.animateTo(0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut);
                  }
                },
                const SingleActivator(LogicalKeyboardKey.end): () {
                  final controller = PrimaryScrollController.of(context);
                  if (controller.hasClients) {
                    controller.animateTo(controller.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut);
                  }
                },
              },
              child: child!,
            );
          },
          home: const HomePage(),
        ),
      ),
    );
  }
}
