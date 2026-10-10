import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stroke.dart';
import '../widgets/drawing_canvas.dart';

class EditorScreen extends StatefulWidget {
  final String noteId;
  final String initialTitle;

  const EditorScreen({
    super.key,
    required this.noteId,
    this.initialTitle = 'ملاحظة جديدة',
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _title;
  final List<List<InkStroke>> _pages = [[]];
  int _page = 0;
  DrawingTool _tool = DrawingTool.pen;
  Color _color = Colors.black;
  double _width = 3.0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('note_${widget.noteId}');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw);
      final pages = (data['pages'] as List)
          .map<List<InkStroke>>((page) => (page as List)
              .map((s) => InkStroke.fromJson(Map<String, dynamic>.from(s)))
              .toList())
          .toList();
      if (!mounted) return;
      setState(() {
        _title.text = data['title'] ?? _title.text;
        _pages
          ..clear()
          ..addAll(pages.isEmpty ? [[]] : pages);
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'note_${widget.noteId}',
      jsonEncode({
        'title': _title.text.trim().isEmpty ? 'ملاحظة بدون عنوان' : _title.text,
        'updatedAt': DateTime.now().toIso8601String(),
        'pages': _pages
            .map((page) => page.map((stroke) => stroke.toJson()).toList())
            .toList(),
      }),
    );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ على الجهاز')),
      );
    }
  }

  void _undo() {
    if (_pages[_page].isEmpty) return;
    setState(() => _pages[_page].removeLast());
  }

  void _addPage() {
    setState(() {
      _pages.add([]);
      _page = _pages.length - 1;
    });
  }

  void _deletePage() {
    if (_pages.length == 1) {
      _pages[0].clear();
      setState(() {});
      return;
    }
    setState(() {
      _pages.removeAt(_page);
      _page = (_page - 1).clamp(0, _pages.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _title,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: 'عنوان الملاحظة',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تراجع',
            onPressed: _undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'حفظ',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _Toolbar(
            tool: _tool,
            color: _color,
            width: _width,
            onTool: (v) => setState(() => _tool = v),
            onColor: (v) => setState(() => _color = v),
            onWidth: (v) => setState(() => _width = v),
          ),
          Expanded(
            child: Row(
              children: [
                if (wide)
                  SizedBox(
                    width: 110,
                    child: _PagesPanel(
                      pages: _pages,
                      current: _page,
                      onSelect: (i) => setState(() => _page = i),
                      onAdd: _addPage,
                      onDelete: _deletePage,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            spreadRadius: 1,
                            color: Color(0x22000000),
                          )
                        ],
                      ),
                      child: DrawingCanvas(
                        strokes: _pages[_page],
                        onChanged: (strokes) =>
                            setState(() => _pages[_page] = strokes),
                        tool: _tool,
                        color: _color,
                        strokeWidth: _width,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!wide)
            SizedBox(
              height: 64,
              child: _PagesPanel(
                pages: _pages,
                current: _page,
                onSelect: (i) => setState(() => _page = i),
                onAdd: _addPage,
                onDelete: _deletePage,
              ),
            ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final DrawingTool tool;
  final Color color;
  final double width;
  final ValueChanged<DrawingTool> onTool;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onWidth;

  const _Toolbar({
    required this.tool,
    required this.color,
    required this.width,
    required this.onTool,
    required this.onColor,
    required this.onWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return Material(
      elevation: 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _toolButton(Icons.edit, DrawingTool.pen, 'قلم'),
            _toolButton(Icons.highlight, DrawingTool.highlighter, 'هايلايتر'),
            _toolButton(Icons.auto_fix_high, DrawingTool.eraser, 'ممحاة'),
            const SizedBox(width: 8),
            ...colors.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => onColor(c),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: color == c ? 15 : 12,
                      backgroundColor: c,
                      child: color == c
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                )),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: Row(
                children: [
                  const Icon(Icons.line_weight, size: 18),
                  Expanded(
                    child: Slider(
                      value: width,
                      min: 1,
                      max: 15,
                      onChanged: onWidth,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, DrawingTool value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ChoiceChip(
        selected: tool == value,
        label: Text(label),
        avatar: Icon(icon, size: 18),
        onSelected: (_) => onTool(value),
      ),
    );
  }
}

class _PagesPanel extends StatelessWidget {
  final List<List<InkStroke>> pages;
  final int current;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _PagesPanel({
    required this.pages,
    required this.current,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: pages.length + 2,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == pages.length) {
            return IconButton(
              tooltip: 'صفحة جديدة',
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            );
          }
          if (i == pages.length + 1) {
            return IconButton(
              tooltip: 'حذف الصفحة',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            );
          }
          return InkWell(
            onTap: () => onSelect(i),
            child: Container(
              width: 54,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  width: i == current ? 2 : 1,
                  color: i == current
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                ),
              ),
              alignment: Alignment.center,
              child: Text('${i + 1}'),
            ),
          );
        },
      ),
    );
  }
}
