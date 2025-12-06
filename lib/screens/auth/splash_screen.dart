import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // AuthProvider 在构造时已开始 _bootstrap，这里监听完成后跳转
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      // 若仍在初始化，等到状态变化后再判断跳转
      if (auth.initializing) {
        auth.addListener(_onAuthReady);
      } else {
        _navigate(auth);
      }
    });
  }

  void _onAuthReady() {
    final auth = context.read<AuthProvider>();
    if (!auth.initializing) {
      auth.removeListener(_onAuthReady);
      _navigate(auth);
    }
  }

  void _navigate(AuthProvider auth) {
    final target = auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}