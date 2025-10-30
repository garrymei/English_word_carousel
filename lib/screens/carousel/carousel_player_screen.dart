import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/carousel_provider.dart';
import '../../data/models/word_card.dart';

class CarouselPlayerScreen extends StatefulWidget {
  const CarouselPlayerScreen({super.key});
  @override
  State<CarouselPlayerScreen> createState() => _CarouselPlayerScreenState();
}

class _CarouselPlayerScreenState extends State<CarouselPlayerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CarouselProvider>().buildDeck(onlyEnabled: true));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarouselProvider>();
    final WordCard? current = provider.playingDeck.isEmpty ? null : provider.playingDeck[provider.currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('轮播播放')),
      body: current == null
          ? const Center(child: Text('没有可播放的卡片'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current.word, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(current.phonetic, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(current.chinese, style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  _Controls(provider: provider),
                ],
              ),
            ),
    );
  }
}

class _Controls extends StatelessWidget {
  final CarouselProvider provider;
  const _Controls({required this.provider});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(onPressed: provider.prev, icon: const Icon(Icons.skip_previous)),
        IconButton(
          onPressed: provider.isPlaying ? provider.pause : provider.start,
          icon: Icon(provider.isPlaying ? Icons.pause_circle : Icons.play_circle),
          iconSize: 48,
        ),
        IconButton(onPressed: provider.next, icon: const Icon(Icons.skip_next)),
      ],
    );
  }
}