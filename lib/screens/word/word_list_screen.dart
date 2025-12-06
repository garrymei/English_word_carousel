import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../services/excel_import_service.dart';
import '../../services/text_import_service.dart';
import '../../utils/template_downloader.dart';
import '../../providers/word_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/empty_state.dart';
import 'word_edit_screen.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});
  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  bool onlyEnabled = false;
  bool _selecting = false;
  final Set<String> _selected = {};
  String? _lastUid;
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    print('WordListScreen: initState');
    // 监听身份状态变化：当 AuthProvider 完成初始化且 userId 就绪后再加载词卡
    _authListener = () {
      final auth = context.read<AuthProvider>();
      print('WordListScreen: Auth listener called. Initializing: ${auth.initializing}, userId: ${auth.userId}');
      if (auth.initializing) return;
      final uid = auth.userId;
      _lastUid = uid;
      print('WordListScreen: Loading words for userId: $uid (onlyEnabled=$onlyEnabled)');
      context.read<WordProvider>().loadWords(onlyEnabled: onlyEnabled, userId: uid).then((_) {
        print('WordListScreen: Words loaded successfully. Count: ${context.read<WordProvider>().words.length}');
      }).catchError((e) {
        print('WordListScreen: Error loading words: $e');
      });
    };
    context.read<AuthProvider>().addListener(_authListener!);
    // 首帧后主动触发一次，覆盖进入页面时的当前身份态
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('WordListScreen: postFrame load trigger');
      // 直接按当前身份触发一次加载，避免监听未触发导致空列表
      final uid = context.read<AuthProvider>().userId;
      await context.read<WordProvider>().loadWords(onlyEnabled: onlyEnabled, userId: uid, personalOnly: true);
      _authListener!.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('WordListScreen: didChangeDependencies');
    final provider = context.read<WordProvider>();
    final uid = context.read<AuthProvider>().userId;
    if (!provider.loading && provider.words.isEmpty) {
      print('WordListScreen: fallback loadWords');
      provider.loadWords(onlyEnabled: onlyEnabled, userId: uid, personalOnly: true);
    }
  }

  @override
  void dispose() {
    if (_authListener != null) {
      Provider.of<AuthProvider>(context, listen: false).removeListener(_authListener!);
      _authListener = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WordProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('单词卡列表'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('只看启用', style: TextStyle(fontSize: 12)),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: onlyEnabled,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) async {
                      setState(() => onlyEnabled = v);
                      final uid = context.read<AuthProvider>().userId;
                      await provider.loadWords(onlyEnabled: onlyEnabled, userId: uid, personalOnly: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final uid = context.read<AuthProvider>().userId;
              await provider.loadWords(onlyEnabled: onlyEnabled, userId: uid, personalOnly: true);
            },
          ),
          if (_selecting)
            IconButton(
              tooltip: '全选',
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  _selected
                    ..clear()
                    ..addAll(provider.words.map((w) => w.id));
                });
              },
            ),
          if (_selecting)
            IconButton(
              tooltip: '批量删除',
              icon: const Icon(Icons.delete_forever),
              onPressed: _selected.isEmpty
                  ? null
                  : () async {
                      await context.read<WordProvider>().deleteMany(_selected.toList());
                      setState(() {
                        _selected.clear();
                        _selecting = false;
                      });
                    },
            ),
          IconButton(
            tooltip: _selecting ? '退出选择' : '选择',
            icon: Icon(_selecting ? Icons.close : Icons.checklist),
            onPressed: () => setState(() {
              _selecting = !_selecting;
              if (!_selecting) _selected.clear();
            }),
          ),
          PopupMenuButton<String>(
            tooltip: '更多',
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'download_excel_template') {
                final svc = ExcelImportService();
                final bytes = svc.buildTemplateBytes(chineseHeaders: true);
                final msg = await TemplateDownloader.saveOrDownload('word_cards_template.xlsx', bytes);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              } else if (val == 'download_text_template') {
                final svc = TextImportService();
                final bytes = svc.buildTemplateBytes();
                final msg = await TemplateDownloader.saveOrDownload('word_cards_text_template.txt', bytes);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              } else if (val == 'import_excel') {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['xlsx'],
                    withData: true,
                  );
                  if (result == null || result.files.isEmpty) return;
                  final file = result.files.first;
                  final data = file.bytes;
                  if (data == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择 .xlsx 文件')));
                    return;
                  }
                  final uid = context.read<AuthProvider>().userId;
                  final svc = ExcelImportService();
                  final res = await svc.importFromBytes(Uint8List.fromList(data), userId: uid);
                  final provider = context.read<WordProvider>();
                  await provider.loadWords(onlyEnabled: onlyEnabled, userId: uid);
                  final errHint = res.errors.isEmpty ? '' : '\n错误示例：${res.errors.take(3).join('；')}';
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('导入成功 ${res.importedCount} 条${errHint}')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
                  }
                }
              } else if (val == 'import_text') {
                final controller = TextEditingController();
                final proceed = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Theme.of(context).dialogBackgroundColor,
                  builder: (ctx) {
                    final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
                    final maxH = MediaQuery.of(ctx).size.height * (kIsWeb ? 0.8 : 0.9);
                    final maxW = kIsWeb ? 800.0 : 600.0;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: viewInsets + 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxH, maxWidth: maxW),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('粘贴文本导入 (JSON Lines)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text(
                                '说明：每行一个 JSON 对象；必填字段 word、chinese；\n可选字段 phonetic、phrase、phrase_cn、sentence_en、sentence_cn、related(数组)、enabled、tags(逗号分隔)、tag_ids(逗号分隔)、visibility(public 为公共)。\n支持以 # 开头的注释行。',
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    minLines: kIsWeb ? 10 : 6,
                                    maxLines: kIsWeb ? 20 : 12,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: '在此粘贴 JSON Lines 文本，每行一个 JSON 对象',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      final svc = TextImportService();
                                      final bytes = svc.buildTemplateBytes();
                                      final msg = await TemplateDownloader.saveOrDownload('word_cards_text_template.txt', bytes);
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                      }
                                    },
                                    child: const Text('下载模板'),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('取消'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('导入'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );

                if (proceed != true) return;
                try {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入要导入的文本')));
                    return;
                  }
                  final uid = context.read<AuthProvider>().userId;
                  final svc = TextImportService();
                  final res = await svc.importFromString(text, userId: uid);
                  final provider = context.read<WordProvider>();
                  await provider.loadWords(onlyEnabled: onlyEnabled, userId: uid);
                  final errHint = res.errors.isEmpty ? '' : '\n错误示例：${res.errors.take(3).join('；')}';
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('导入成功 ${res.importedCount} 条${errHint}')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
                  }
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'download_excel_template', child: Text('下载导入模版 (Excel)')),
              PopupMenuItem(value: 'download_text_template', child: Text('下载文本模版 (JSONL)')),
              PopupMenuItem(value: 'import_excel', child: Text('导入 Excel')),
              PopupMenuItem(value: 'import_text', child: Text('导入文本')),
            ],
          ),
          
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.words.isEmpty
                    ? const EmptyState(message: '还没有单词卡，点击右下角 + 创建')
                    : ListView.builder(
                        itemCount: provider.words.length,
                        itemBuilder: (context, i) {
                          final w = provider.words[i];
                          final selected = _selected.contains(w.id);
                          return ListTile(
                            leading: _selecting
                                ? Checkbox(
                                  value: selected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selected.add(w.id);
                                      } else {
                                        _selected.remove(w.id);
                                      }
                                    });
                                  },
                                )
                                : null,
                            title: Text('${w.word}  ${w.phonetic}'),
                            subtitle: Text(w.chinese),
                            onTap: () async {
                              if (_selecting) {
                                setState(() {
                                  if (selected) {
                                    _selected.remove(w.id);
                                  } else {
                                    _selected.add(w.id);
                                  }
                                });
                              } else {
                                final changed = await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => WordEditScreen(initial: w)),
                                );
                                if (changed == true) {
                                  // Provider 内部已刷新
                                }
                              }
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: w.enabled,
                                  onChanged: (v) => provider.toggleEnabled(w.id, v),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      final changed = await Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => WordEditScreen(initial: w)),
                                      );
                                      if (changed == true) {}
                                    } else if (val == 'delete') {
                                      await context.read<WordProvider>().deleteWord(w.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('编辑')),
                                    PopupMenuItem(value: 'delete', child: Text('删除')),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WordEditScreen()),
          );
          if (created == true) {}
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}