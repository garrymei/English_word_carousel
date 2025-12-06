import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import '../providers/word_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/carousel_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user == null)
              const Text('未登录')
            else ...[
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(user.username ?? '未知用户名'),
                subtitle: Text(user.email),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    // 清理本地状态
                    context.read<WordProvider>().clear();
                    context.read<TagProvider>().clear();
                    context.read<CarouselProvider>().reset();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}