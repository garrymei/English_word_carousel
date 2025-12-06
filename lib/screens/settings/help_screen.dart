import 'package:flutter/material.dart';
import '../../services/text_import_service.dart';
import '../../utils/template_downloader.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const desc =
        '文本导入（JSON Lines）\n\n'
        '• 每行一个 JSON 对象（UTF‑8）\n'
        '• 支持以 # 开头的注释行\n'
        '• 必填：word, chinese\n'
        '• 可选：phonetic, phrase, phrase_cn, sentence_en, sentence_cn, related(数组), enabled, tags(逗号分隔), tag_ids(逗号分隔), visibility(public 为公共卡)\n'
        '• enabled 支持 true/false, 1/0, yes/no, 是/否, 启用/禁用, 真/假\n\n'
        '示例：\n'
        '{"word":"abandon","chinese":"放弃","phonetic":"əˈbændən","phrase":"abandon hope","sentence_en":"They abandoned the project.","sentence_cn":"他们放弃了这个项目。","enabled":true,"tags":"核心词,动词","related":[{"text":"desert","chinese":"遗弃"},{"text":"quit","chinese":"退出"}]}\n'
        '{"word":"ability","chinese":"能力","enabled":"是","visibility":"public"}\n\n'
        '入口位置：单词卡列表右上角“导入文本”，可先下载模板或直接选择 .txt/.jsonl/.json 文件进行导入。';

    return Scaffold(
      appBar: AppBar(title: const Text('帮助与导入说明')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(desc),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('下载文本模板'),
                  onPressed: () async {
                    final svc = TextImportService();
                    final bytes = svc.buildTemplateBytes();
                    final msg = await TemplateDownloader.saveOrDownload('word_cards_text_template.txt', bytes);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}