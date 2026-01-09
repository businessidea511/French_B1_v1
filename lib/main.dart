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

  @override
  Widget build(BuildContext context) {
    // Root FocusNode to keep everything organized
    final FocusNode rootFocusNode = FocusNode(debugLabel: 'RootFocusNode');

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          PrimaryScrollController.of(
                  FocusManager.instance.primaryFocus!.context!)
              ?.animateTo(
            (PrimaryScrollController.of(
                            FocusManager.instance.primaryFocus!.context!)
                        ?.offset ??
                    0) -
                100,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          PrimaryScrollController.of(
                  FocusManager.instance.primaryFocus!.context!)
              ?.animateTo(
            (PrimaryScrollController.of(
                            FocusManager.instance.primaryFocus!.context!)
                        ?.offset ??
                    0) +
                100,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        },
      },
      child: Listener(
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
            home: const HomePage(),
          ),
        ),
      ),
    );
  }
}
