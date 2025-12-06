import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/carousel_provider.dart';
import '../screens/floating/floating_player_screen.dart';
import '../services/window_service.dart';

final windowService = WindowService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowService.init(size: const Size(520, 360));
  runApp(const FloatingPlayerApp());
}

class FloatingPlayerApp extends StatelessWidget {
  const FloatingPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CarouselProvider()..loadConfigFromPrefs()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Floating Player',
        theme: ThemeData.dark(useMaterial3: true),
        home: Builder(
          builder: (ctx) {
            final p = ctx.read<CarouselProvider>();
            if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
              windowService.registerHotkeys(
                onTogglePlay: () => p.isPlaying ? p.pause() : p.start(),
                onPrev: () => p.prev(),
                onNext: () => p.next(),
                onHide: () => windowService.hideFloatingWindow(),
              );
            }
            return const FloatingPlayerScreen();
          },
        ),
      ),
    );
  }
}