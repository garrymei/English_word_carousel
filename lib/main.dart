import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/word_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/carousel_provider.dart';
import 'screens/home_screen.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'English Word Carousel',
        theme: AppTheme.light(),
        home: const HomeScreen(),
      ),
    );
  }
}
