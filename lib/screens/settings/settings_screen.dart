import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/carousel_config.dart';
import '../../providers/carousel_provider.dart';
import '../../services/settings_service.dart';
import 'help_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _svc = SettingsService();
  late CarouselConfig _cfg;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _svc.loadConfig();
    setState(() { _cfg = c; _loading = false; });
  }

  Future<void> _saveAndApply() async {
    await _svc.saveConfig(_cfg);
    // 同步到 Provider
    if (mounted) {
      context.read<CarouselProvider>().applyConfig(_cfg);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final voices = const ['en-US','en-GB'];
    final modes = const ['5min','10min','20min','1h','forever'];

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Voice
          ListTile(
            title: const Text('语音语言'),
            trailing: DropdownButton<String>(
              value: _cfg.voice,
              items: voices.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _cfg = CarouselConfig(
                shuffle: _cfg.shuffle,
                intervalSeconds: _cfg.intervalSeconds,
                showRelated: _cfg.showRelated,
                selectedTagIds: _cfg.selectedTagIds,
                voice: v ?? _cfg.voice,
                autoPlaySound: _cfg.autoPlaySound,
                durationMode: _cfg.durationMode,
                loopForever: _cfg.loopForever,
              )),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('帮助与导入说明'),
            subtitle: const Text('查看文本导入规则与示例'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
          ),
          const Divider(),
          // Auto play
          SwitchListTile(
            title: const Text('自动发音'),
            value: _cfg.autoPlaySound,
            onChanged: (val) => setState(() => _cfg = CarouselConfig(
              shuffle: _cfg.shuffle,
              intervalSeconds: _cfg.intervalSeconds,
              showRelated: _cfg.showRelated,
              selectedTagIds: _cfg.selectedTagIds,
              voice: _cfg.voice,
              autoPlaySound: val,
              durationMode: _cfg.durationMode,
              loopForever: _cfg.loopForever,
            )),
          ),
          const Divider(),
          // Duration mode
          ListTile(
            title: const Text('时长模式'),
            trailing: DropdownButton<String>(
              value: _cfg.durationMode,
              items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _cfg = CarouselConfig(
                shuffle: _cfg.shuffle,
                intervalSeconds: _cfg.intervalSeconds,
                showRelated: _cfg.showRelated,
                selectedTagIds: _cfg.selectedTagIds,
                voice: _cfg.voice,
                autoPlaySound: _cfg.autoPlaySound,
                durationMode: v ?? _cfg.durationMode,
                loopForever: (v ?? _cfg.durationMode) == 'forever',
              )),
            ),
          ),
          const Divider(),
          // Interval seconds
          ListTile(
            title: const Text('每张间隔 (秒)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() => _cfg = CarouselConfig(
                    shuffle: _cfg.shuffle,
                    intervalSeconds: (_cfg.intervalSeconds - 1).clamp(1, 60),
                    showRelated: _cfg.showRelated,
                    selectedTagIds: _cfg.selectedTagIds,
                    voice: _cfg.voice,
                    autoPlaySound: _cfg.autoPlaySound,
                    durationMode: _cfg.durationMode,
                    loopForever: _cfg.loopForever,
                  )),
                ),
                Text('${_cfg.intervalSeconds}s'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _cfg = CarouselConfig(
                    shuffle: _cfg.shuffle,
                    intervalSeconds: (_cfg.intervalSeconds + 1).clamp(1, 60),
                    showRelated: _cfg.showRelated,
                    selectedTagIds: _cfg.selectedTagIds,
                    voice: _cfg.voice,
                    autoPlaySound: _cfg.autoPlaySound,
                    durationMode: _cfg.durationMode,
                    loopForever: _cfg.loopForever,
                  )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Cache cleanup
          ElevatedButton.icon(
            icon: const Icon(Icons.cleaning_services),
            label: const Text('清理音频缓存'),
            onPressed: () async {
              await _svc.clearAudioCache();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清理缓存（过期/LRU）')));
            },
          ),
          const SizedBox(height: 12),
          // Save
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('保存设置并应用'),
            onPressed: _saveAndApply,
          ),
        ],
      ),
    );
  }
}