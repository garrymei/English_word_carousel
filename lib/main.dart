import 'package:flutter/material.dart';

void main() {
  runApp(const EWCApp());
}

class EWCApp extends StatelessWidget {
  const EWCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Word Carousel',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('English Word Carousel')),
      body: ListView(
        children: [
          _Tile(
            title: 'Carousel Player',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CarouselPlayerScreen())),
          ),
          _Tile(
            title: 'Word Cards',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WordCardListScreen())),
          ),
          _Tile(
            title: 'Tags',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const TagManagerScreen())),
          ),
          _Tile(
            title: 'Login / Register',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AuthScreen())),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _Tile({required this.title, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// Placeholder screens
class CarouselPlayerScreen extends StatelessWidget {
  const CarouselPlayerScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Carousel Player (placeholder)')),
  );
}

class WordCardListScreen extends StatelessWidget {
  const WordCardListScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Word Cards (placeholder)')),
  );
}

class TagManagerScreen extends StatelessWidget {
  const TagManagerScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Tags (placeholder)')),
  );
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Login/Register (placeholder)')),
  );
}
