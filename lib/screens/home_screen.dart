import 'dart:math';
import 'package:flutter/material.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_Note> notes = [];
  final List<String> folders = ['كل الملاحظات', 'الدراسة', 'العمل', 'شخصي'];

  void _newNote() {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';
    setState(() {
      notes.insert(0, _Note(id: id, title: 'ملاحظة جديدة'));
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorScreen(noteId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'JNotes Free',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'الوضع الليلي',
              onPressed: widget.onToggleTheme,
              icon: const Icon(Icons.dark_mode_outlined),
            ),
            IconButton(
              tooltip: 'بحث',
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _newNote,
          icon: const Icon(Icons.add),
          label: const Text('ملاحظة جديدة'),
        ),
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: 0,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.notes_outlined),
                    selectedIcon: Icon(Icons.notes),
                    label: Text('الملاحظات'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.star_border),
                    selectedIcon: Icon(Icons.star),
                    label: Text('المفضلة'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.delete_outline),
                    selectedIcon: Icon(Icons.delete),
                    label: Text('المحذوفة'),
                  ),
                ],
              ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: folders
                            .map((f) => FilterChip(
                                  label: Text(f),
                                  selected: f == 'كل الملاحظات',
                                  onSelected: (_) {},
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  if (notes.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 72),
                            SizedBox(height: 12),
                            Text(
                              'لا توجد ملاحظات بعد',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text('اضغط «ملاحظة جديدة» للبدء'),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final n = notes[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditorScreen(
                                      noteId: n.id,
                                      initialTitle: n.title,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.description_outlined, size: 30),
                                      const Spacer(),
                                      Text(
                                        n.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('ملاحظة • محلية'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: notes.length,
                        ),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: wide ? 300 : 500,
                          mainAxisExtent: 190,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
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
}

class _Note {
  final String id;
  final String title;

  _Note({required this.id, required this.title});
}
