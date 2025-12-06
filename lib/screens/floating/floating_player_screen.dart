import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/window_service.dart';
import '../../providers/carousel_provider.dart';
import '../../providers/auth_provider.dart';

class FloatingPlayerScreen extends StatefulWidget {
  const FloatingPlayerScreen({super.key});

  @override
  State<FloatingPlayerScreen> createState() => _FloatingPlayerScreenState();
}

class _FloatingPlayerScreenState extends State<FloatingPlayerScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 确保进入时可响应键盘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
        // 初次构建默认从 Provider 中构建队列
        final p = context.read<CarouselProvider>();
        final uid = context.read<AuthProvider>().userId;
        p.buildDeck(onlyEnabled: true, userId: uid);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent e, CarouselProvider p) {
    if (e is! KeyDownEvent) return; // 只处理按下
    final keyLabel = e.logicalKey.keyLabel;
    switch (keyLabel) {
      case ' ':
        p.isPlaying ? p.pause() : p.start();
        break;
      case 'Arrow Left':
        p.prev();
        break;
      case 'Arrow Right':
        p.next();
        break;
      case 'Escape':
        if (Navigator.canPop(context)) Navigator.pop(context);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarouselProvider>();
    final current = provider.playingDeck.isEmpty ? null : provider.playingDeck[provider.currentIndex];
    final total = provider.playingDeck.length;
    final idx = provider.playingDeck.isEmpty ? 0 : provider.currentIndex + 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (e) => _handleKey(e, provider),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // 霓虹渐变背景 + 模糊玻璃层
                Container(
                  width: 520,
                  height: 360,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: 520,
                    height: 360,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: Colors.cyanAccent),
                              const SizedBox(width: 8),
                              const Text('Floating Player', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70),
                                onPressed: () {
                                  // 桌面端优先隐藏窗口；否则退回路由
                                  final ws = WindowService();
                                  ws.hideFloatingWindow();
                                  if (Navigator.canPop(context)) Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (current == null)
                            const Expanded(child: Center(child: Text('没有可播放的卡片', style: TextStyle(color: Colors.white))))
                          else ...[
                            Text(current.word, style: const TextStyle(fontSize: 28, color: Colors.white, fontFamily: 'Inter')),
                            const SizedBox(height: 6),
                            Text(current.phonetic, style: const TextStyle(fontSize: 18, color: Colors.white70)),
                            const SizedBox(height: 10),
                            Text(current.chinese, style: const TextStyle(fontSize: 16, color: Colors.white)),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: provider.prev),
                                const SizedBox(width: 12),
                                IconButton(icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white), onPressed: provider.isPlaying ? provider.pause : provider.start),
                                const SizedBox(width: 12),
                                IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: provider.next),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // 进度条
                            LinearProgressIndicator(
                              value: total == 0 ? 0 : (idx / total),
                              minHeight: 6,
                              color: Colors.cyanAccent,
                              backgroundColor: Colors.white24,
                            ),
                            const SizedBox(height: 8),
                            Text('AI 推荐 词 $idx / $total', style: const TextStyle(color: Colors.white70)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}