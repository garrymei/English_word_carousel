import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/error_logger.dart';
import 'providers/word_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/carousel_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/study_plan_provider.dart';
import 'providers/carousel_plan_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'services/supabase_service.dart';
import 'services/supabase_debug_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupErrorLogger();
  await SupabaseService.init();
  const supabaseDebug = bool.fromEnvironment('SUPABASE_DEBUG', defaultValue: false);
  if (supabaseDebug) {
    await SupabaseDebugService.runSmokeTest();
    await SupabaseDebugService.runWordCardDemo();
  }
  runApp(const EWCApp());
}

class EWCApp extends StatelessWidget {
  const EWCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WordProvider()),
        ChangeNotifierProvider(create: (_) => TagProvider()),
        ChangeNotifierProvider(create: (_) => CarouselProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudyPlanProvider()),
        ChangeNotifierProvider(create: (_) => CarouselPlanProvider()),
      ],
      child: MaterialApp(
        title: 'English Word Carousel',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        // Force dark theme for a more tech-savvy look by default
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
