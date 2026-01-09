import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

import 'package:flutter/services.dart';

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
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp):
            const ScrollIntent(direction: AxisDirection.up),
        LogicalKeySet(LogicalKeyboardKey.arrowDown):
            const ScrollIntent(direction: AxisDirection.down),
        LogicalKeySet(LogicalKeyboardKey.pageUp): const ScrollIntent(
            direction: AxisDirection.up, type: ScrollIncrementType.page),
        LogicalKeySet(LogicalKeyboardKey.pageDown): const ScrollIntent(
            direction: AxisDirection.down, type: ScrollIncrementType.page),
      },
      child: MaterialApp(
        title: 'French B1 Learning',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: true,
        ),
        builder: (context, child) {
          return Focus(
            autofocus: true,
            descendantsAreFocusable: true,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const HomePage(),
      ),
    );
  }
}
