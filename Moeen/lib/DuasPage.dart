import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  static const gold = Color(0xFFD4AF37);
  static const black = Color(0xFF0B0F19);
  static const black2 = Color(0xFF141927);

  final _searchCtrl = TextEditingController();
  final List<String> chips = const ['All', 'Tawaf', 'Sa’i', 'General'];

  int _chipIndex = 0;
  List<DuaModel> _duas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDuas();
    _searchCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadDuas() async {
    final data = await DuaDatabase.instance.getAllDuas();
    if (!mounted) return;
    setState(() {
      _duas = data;
      _loading = false;
    });
  }

  List<DuaModel> get _filteredDuas {
    final tag = chips[_chipIndex];
    final query = _searchCtrl.text.trim().toLowerCase();

    return _duas.where((d) {
      final matchTag = tag == 'All' || d.tag == tag;
      final matchSearch = query.isEmpty ||
          d.title.toLowerCase().contains(query) ||
          d.text.toLowerCase().contains(query);

      return matchTag && matchSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _iconForTag(String tag) {
    if (tag == 'Tawaf') return Icons.sync_rounded;
    if (tag == 'Sa’i') return Icons.directions_walk_rounded;
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: black.withOpacity(0.75),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _header(),
              const SizedBox(height: 14),
              _searchBar(),
              const SizedBox(height: 12),
              _chipsRow(),
              const SizedBox(height: 14),
              _sectionTitle('My Duas'),
              const SizedBox(height: 10),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: gold))
                  : _duaList(),
            ],
          ),
          Positioned(
            right: 18,
            bottom: 80,
            child: _fab(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: black2.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.menu_book_rounded, color: gold, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Duas Library\nSave and access your duas offline',
              style: TextStyle(
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search dua...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white60),
        filled: true,
        fillColor: black2.withOpacity(0.88),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: gold.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: gold),
        ),
      ),
    );
  }

  Widget _chipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(chips.length, (i) {
          final active = _chipIndex == i;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(chips[i]),
              selected: active,
              onSelected: (_) => setState(() => _chipIndex = i),
              selectedColor: gold.withOpacity(0.25),
              backgroundColor: black2.withOpacity(0.88),
              labelStyle: TextStyle(
                color: active ? gold : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              side: BorderSide(color: gold.withOpacity(0.25)),
            ),
          );
        }),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: gold,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _duaList() {
    final list = _filteredDuas;

    if (list.isEmpty) {
      return const Text(
        'No duas found.',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: list.map((dua) => _duaCard(dua)).toList(),
    );
  }

  Widget _duaCard(DuaModel dua) {
    return Card(
      color: black2.withOpacity(0.88),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: gold.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(_iconForTag(dua.tag), color: gold),
        title: Text(
          dua.title.isEmpty ? 'Untitled Dua' : dua.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          dua.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () async {
            await DuaDatabase.instance.deleteDua(dua.id!);
            _loadDuas();
          },
        ),
        onTap: () => _openDuaPreview(dua),
      ),
    );
  }

  Widget _fab() {
    return FloatingActionButton.extended(
      backgroundColor: gold,
      foregroundColor: Colors.black,
      onPressed: () => _showAddDuaSheet(),
      icon: const Icon(Icons.add),
      label: const Text(
        'Add Dua',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddDuaSheet({DuaModel? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final textCtrl = TextEditingController(text: existing?.text ?? '');
    String tag = existing?.tag ?? 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, StateSetter setSheetState) {
            final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null ? 'Create Dua' : 'Edit Dua',
                    style: const TextStyle(
                      color: gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _inputField(titleCtrl, 'Title'),
                  const SizedBox(height: 10),
                  _inputField(textCtrl, 'Write your dua...', maxLines: 4),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: tag,
                    dropdownColor: black2,
                    iconEnabledColor: gold,
                    items: const [
                      DropdownMenuItem(value: 'General', child: Text('General')),
                      DropdownMenuItem(value: 'Tawaf', child: Text('Tawaf')),
                      DropdownMenuItem(value: 'Sa’i', child: Text('Sa’i')),
                    ],
                    onChanged: (value) {
                      setSheetState(() {
                        tag = value ?? 'General';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final text = textCtrl.text.trim();

                        if (text.isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Please write the dua.')),
                          );
                          return;
                        }

                        if (existing == null) {
                          await DuaDatabase.instance.insertDua(
                            DuaModel(
                              title: titleCtrl.text.trim(),
                              text: text,
                              tag: tag,
                              sortOrder: _duas.length,
                            ),
                          );
                        } else {
                          await DuaDatabase.instance.updateDua(
                            existing.copyWith(
                              title: titleCtrl.text.trim(),
                              text: text,
                              tag: tag,
                            ),
                          );
                        }

                        if (!mounted) return;
                        Navigator.pop(sheetContext);
                        _loadDuas();
                      },
                      child: Text(existing == null ? 'Save' : 'Update'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _inputField(
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: black2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gold.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold),
        ),
      ),
    );
  }

  void _openDuaPreview(DuaModel dua) {
    showModalBottomSheet(
      context: context,
      backgroundColor: black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dua.title.isEmpty ? 'Untitled Dua' : dua.title,
                style: const TextStyle(
                  color: gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                dua.text,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: dua.text));
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showAddDuaSheet(existing: dua);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class DuaModel {
  final int? id;
  final String title;
  final String text;
  final String tag;
  final int sortOrder;

  DuaModel({
    this.id,
    required this.title,
    required this.text,
    required this.tag,
    required this.sortOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'tag': tag,
      'sort_order': sortOrder,
    };
  }

  factory DuaModel.fromMap(Map<String, dynamic> map) {
    return DuaModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      tag: map['tag'] as String? ?? 'General',
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  DuaModel copyWith({
    String? title,
    String? text,
    String? tag,
    int? sortOrder,
  }) {
    return DuaModel(
      id: id,
      title: title ?? this.title,
      text: text ?? this.text,
      tag: tag ?? this.tag,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class DuaDatabase {
  DuaDatabase._init();

  static final DuaDatabase instance = DuaDatabase._init();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'duas.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );

    return _database!;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE duas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        text TEXT NOT NULL,
        tag TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.insert('duas', {
      'title': 'Entering the Masjid',
      'text': 'Allahumma iftah li abwaba rahmatik.',
      'tag': 'General',
      'sort_order': 0,
    });

    await db.insert('duas', {
      'title': 'Between Rukn & Maqam',
      'text': 'Rabbana aatina fid-dunya hasanah wa fil-akhirati hasanah wa qina adhaban-nar.',
      'tag': 'Tawaf',
      'sort_order': 1,
    });

    await db.insert('duas', {
      'title': 'Sa’i Intention',
      'text': 'O Allah, I seek Your acceptance and mercy during Sa’i.',
      'tag': 'Sa’i',
      'sort_order': 2,
    });
  }

  Future<List<DuaModel>> getAllDuas() async {
    final db = await database;

    final result = await db.query(
      'duas',
      orderBy: 'sort_order ASC, id ASC',
    );

    return result.map((map) => DuaModel.fromMap(map)).toList();
  }

  Future<void> insertDua(DuaModel dua) async {
    final db = await database;

    await db.insert(
      'duas',
      dua.toMap()..remove('id'),
    );
  }

  Future<void> updateDua(DuaModel dua) async {
    final db = await database;

    await db.update(
      'duas',
      dua.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [dua.id],
    );
  }

  Future<void> deleteDua(int id) async {
    final db = await database;

    await db.delete(
      'duas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
