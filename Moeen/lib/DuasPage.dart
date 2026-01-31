import 'package:flutter/material.dart';

class DuasPage extends StatefulWidget {
const DuasPage({super.key});

@override
State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
// Brand
static const gold = Color(0xFFD4AF37);
static const black = Color(0xFF0B0F19);
static const black2 = Color(0xFF141927);
static const card = Color(0xFF0F121A);

final _searchCtrl = TextEditingController();
int _chipIndex = 0;

// ✅ شلنا My Duas عشان تخفيف + مثل طلبك "شل التولز"
final List<String> chips = const ['All', 'Tawaf', 'Sa’i', 'General'];

// ✅ 4 أدعية فقط
final List<_DuaUi> duaList = const [
_DuaUi(
title: 'Entering the Masjid',
text: 'Allahumma iftah li abwaba rahmatik.',
tag: 'General',
icon: Icons.mosque_rounded,
),
_DuaUi(
title: 'Between Rukn & Maqam',
text: 'Rabbana aatina fid-dunya hasanah…',
tag: 'Tawaf',
icon: Icons.sync_rounded,
),
_DuaUi(
title: 'For Ease',
text: 'Allahumma la sahla illa ma ja’altahu sahla…',
tag: 'General',
icon: Icons.auto_awesome_rounded,
),
_DuaUi(
title: 'Sa’i Intention',
text: 'O Allah, I seek Your acceptance and mercy…',
tag: 'Sa’i',
icon: Icons.directions_walk_rounded,
),
];

@override
void dispose() {
_searchCtrl.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Container(
color: Colors.transparent, // HomePage already has bg
child: Stack(
children: [
ListView(
padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
children: [
_header(),
const SizedBox(height: 14),
_searchBar(),
const SizedBox(height: 12),
_chipsRow(),
const SizedBox(height: 14),

_featuredCard(),
const SizedBox(height: 14),

_sectionTitle('Recommended Duas'),
const SizedBox(height: 10),
_duaGrid(),
],
),

// Floating Add Button (UI only)
Positioned(
right: 18,
bottom: 92,
child: _fab(),
),
],
),
);
}

// ================= UI Blocks =================

Widget _header() {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: card.withOpacity(0.95),
borderRadius: BorderRadius.circular(22),
border: Border.all(color: gold.withOpacity(0.22)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.45),
blurRadius: 18,
offset: const Offset(0, 12),
),
],
),
child: Row(
children: [
// Icon capsule
Container(
width: 54,
height: 54,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
gold.withOpacity(0.22),
Colors.white.withOpacity(0.06),
],
),
border: Border.all(color: gold.withOpacity(0.22)),
),
child: const Icon(Icons.menu_book_rounded, color: gold, size: 30),
),
const SizedBox(width: 12),

const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Duas Library',
style: TextStyle(
color: gold,
fontWeight: FontWeight.w900,
fontSize: 18,
letterSpacing: 0.2,
),
),
SizedBox(height: 4),
Text(
'Save, organize, and access your duas instantly during Umrah.',
style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
),
],
),
),

Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
decoration: BoxDecoration(
color: gold.withOpacity(0.12),
borderRadius: BorderRadius.circular(999),
border: Border.all(color: gold.withOpacity(0.22)),
),
child: const Row(
children: [
Icon(Icons.offline_bolt_rounded, color: gold, size: 18),
SizedBox(width: 6),
Text(
'Offline',
style: TextStyle(color: gold, fontWeight: FontWeight.w900),
),
],
),
),
],
),
);
}

Widget _searchBar() {
return Container(
decoration: BoxDecoration(
color: black2,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: gold.withOpacity(0.18)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.25),
blurRadius: 10,
offset: const Offset(0, 8),
),
],
),
child: TextField(
controller: _searchCtrl,
style: const TextStyle(color: Colors.white),
decoration: InputDecoration(
prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
// ✅ شلينا زر الفلاتر (التولز)
hintText: 'Search dua by title or keyword…',
hintStyle: const TextStyle(color: Colors.white54),
filled: true,
fillColor: Colors.transparent,
contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide(color: gold.withOpacity(0.0)),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: const BorderSide(color: gold, width: 1.2),
),
),
),
);
}

Widget _chipsRow() {
return SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: List.generate(chips.length, (i) {
final active = i == _chipIndex;
return Padding(
padding: const EdgeInsetsDirectional.only(end: 8),
child: ChoiceChip(
label: Text(chips[i]),
selected: active,
onSelected: (_) => setState(() => _chipIndex = i),
backgroundColor: black2,
selectedColor: gold.withOpacity(0.22),
side: BorderSide(color: gold.withOpacity(active ? 0.7 : 0.18)),
labelStyle: TextStyle(
color: active ? gold : Colors.white70,
fontWeight: FontWeight.w900,
),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
),
);
}),
),
);
}

Widget _featuredCard() {
return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(22),
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
gold.withOpacity(0.20),
black2.withOpacity(0.98),
],
),
border: Border.all(color: gold.withOpacity(0.22)),
boxShadow: [
BoxShadow(
color: gold.withOpacity(0.12),
blurRadius: 22,
spreadRadius: 1,
offset: const Offset(0, 12),
),
BoxShadow(
color: Colors.black.withOpacity(0.35),
blurRadius: 14,
offset: const Offset(0, 10),
),
],
),
child: Row(
children: [
Container(
width: 54,
height: 54,
decoration: BoxDecoration(
color: black.withOpacity(0.35),
borderRadius: BorderRadius.circular(18),
border: Border.all(color: Colors.white.withOpacity(0.10)),
),
child: const Icon(Icons.auto_awesome_rounded, color: gold, size: 28),
),
const SizedBox(width: 12),

const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Featured Dua',
style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15.5),
),
SizedBox(height: 6),
Text(
'“O Allah, grant me sincerity, ease, and acceptance…”',
style: TextStyle(color: Colors.white70, height: 1.35),
),
],
),
),

// ✅ بدل أي أدوات كثير، خليتها بسيطة
const SizedBox(width: 10),
_miniIconBtn(Icons.bookmark_border_rounded),
],
),
);
}

Widget _duaGrid() {
final tag = chips[_chipIndex];
final filtered = (tag == 'All')
? duaList
    : duaList.where((d) => d.tag == tag).toList();

// ✅ ملاحظة: لو فلتر يطلع 0 عناصر، نخلي عرض لطيف بدل Grid فاضي
if (filtered.isEmpty) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: black2,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: gold.withOpacity(0.18)),
),
child: const Text(
'No duas in this category yet.',
style: TextStyle(color: Colors.white70),
),
);
}

return GridView.builder(
itemCount: filtered.length,
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
mainAxisSpacing: 12,
crossAxisSpacing: 12,
// ✅ أهم تعديل: نخلي الكرت أعلى شوي عشان ما يضغط Row الأخير
childAspectRatio: 0.86,
),
itemBuilder: (_, i) => _duaCard(filtered[i]),
);
}

Widget _duaCard(_DuaUi d) {
return InkWell(
borderRadius: BorderRadius.circular(20),
onTap: () => _openDuaPreview(d),
child: Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: card.withOpacity(0.98),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: gold.withOpacity(0.20)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.35),
blurRadius: 14,
offset: const Offset(0, 10),
),
],
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// top row
Row(
children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: black2,
borderRadius: BorderRadius.circular(14),
border: Border.all(color: gold.withOpacity(0.18)),
),
child: Icon(d.icon, color: gold, size: 20),
),
const Spacer(),
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
decoration: BoxDecoration(
color: gold.withOpacity(0.12),
borderRadius: BorderRadius.circular(999),
border: Border.all(color: gold.withOpacity(0.22)),
),
child: Text(
d.tag,
style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 11.5),
),
),
],
),

const SizedBox(height: 10),

Text(
d.title,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5),
),
const SizedBox(height: 6),

Expanded(
child: Text(
d.text,
maxLines: 4, // ✅ أقل عشان ما يضغط أسفل
overflow: TextOverflow.fade,
style: const TextStyle(color: Colors.white70, height: 1.35),
),
),

const SizedBox(height: 10),

// ✅ حل الأوفر فلو: أزرار "أيقونات" بدل Copy/Save نصّي
Row(
children: [
Expanded(child: _iconPill(Icons.copy_rounded, 'Copy')),
const SizedBox(width: 8),
Expanded(child: _iconPill(Icons.bookmark_border_rounded, 'Save')),
],
),
],
),
),
);
}

Widget _sectionTitle(String t) {
return Text(
t,
style: const TextStyle(color: gold, fontSize: 16.5, fontWeight: FontWeight.w900),
);
}

Widget _fab() {
return GestureDetector(
onTap: _showAddDuaSheet,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
decoration: BoxDecoration(
color: gold,
borderRadius: BorderRadius.circular(999),
boxShadow: [
BoxShadow(
color: gold.withOpacity(0.25),
blurRadius: 22,
offset: const Offset(0, 12),
),
BoxShadow(
color: Colors.black.withOpacity(0.35),
blurRadius: 16,
offset: const Offset(0, 10),
),
],
),
child: const Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(Icons.add_rounded, color: Colors.black, size: 22),
SizedBox(width: 8),
Text('Add Dua', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
],
),
),
);
}

static Widget _miniIconBtn(IconData i) {
return Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.25),
borderRadius: BorderRadius.circular(14),
border: Border.all(color: Colors.white.withOpacity(0.10)),
),
child: Icon(i, color: gold, size: 20),
);
}

// ✅ زر مضبوط ما يسبب overflow حتى لو الشاشة ضيقة
Widget _iconPill(IconData icon, String label) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
decoration: BoxDecoration(
color: black2,
borderRadius: BorderRadius.circular(14),
border: Border.all(color: gold.withOpacity(0.18)),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(icon, color: gold, size: 16),
const SizedBox(width: 6),
Flexible(
child: Text(
label,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 12.5),
),
),
],
),
);
}

// ================= Bottom Sheets / Dialog UI only =================

void _showAddDuaSheet() {
final titleCtrl = TextEditingController();
final textCtrl = TextEditingController();
String cat = 'General';

showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: black,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
),
builder: (ctx) {
final pad = MediaQuery.of(ctx).viewInsets.bottom;
return Padding(
padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + pad),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 44,
height: 4,
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
color: Colors.white24,
borderRadius: BorderRadius.circular(99),
),
),
Row(
children: const [
Icon(Icons.edit_note_rounded, color: gold),
SizedBox(width: 8),
Text(
'Create a Dua',
style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 16),
),
],
),
const SizedBox(height: 12),

_sheetField(titleCtrl, hint: 'Title (optional)'),
const SizedBox(height: 10),
_sheetField(textCtrl, hint: 'Write your dua…', maxLines: 5),
const SizedBox(height: 10),

Row(
children: [
const Text('Category:', style: TextStyle(color: Colors.white70)),
const SizedBox(width: 10),
DropdownButton<String>(
value: cat,
dropdownColor: black2,
underline: const SizedBox.shrink(),
iconEnabledColor: gold,
items: const [
DropdownMenuItem(value: 'Tawaf', child: Text('Tawaf', style: TextStyle(color: Colors.white))),
DropdownMenuItem(value: 'Sa’i', child: Text('Sa’i', style: TextStyle(color: Colors.white))),
DropdownMenuItem(value: 'General', child: Text('General', style: TextStyle(color: Colors.white))),
],
onChanged: (v) => setState(() => cat = v ?? 'General'),
),
],
),

const SizedBox(height: 12),
Row(
children: [
Expanded(
child: SizedBox(
height: 48,
child: OutlinedButton(
onPressed: () => Navigator.pop(ctx),
style: OutlinedButton.styleFrom(
foregroundColor: gold,
side: BorderSide(color: gold.withOpacity(0.6)),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
),
child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w900)),
),
),
),
const SizedBox(width: 10),
Expanded(
child: SizedBox(
height: 48,
child: ElevatedButton(
onPressed: () => Navigator.pop(ctx),
style: ElevatedButton.styleFrom(
backgroundColor: gold,
foregroundColor: Colors.black,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
),
child: const Text('Save (UI)', style: TextStyle(fontWeight: FontWeight.w900)),
),
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

Widget _sheetField(TextEditingController c, {required String hint, int maxLines = 1}) {
return TextField(
controller: c,
maxLines: maxLines,
style: const TextStyle(color: Colors.white),
decoration: InputDecoration(
hintText: hint,
hintStyle: const TextStyle(color: Colors.white54),
filled: true,
fillColor: black2,
contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(color: gold.withOpacity(0.18)),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: const BorderSide(color: gold, width: 1.2),
),
),
);
}

void _openDuaPreview(_DuaUi d) {
showModalBottomSheet(
context: context,
backgroundColor: black,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
),
builder: (ctx) {
return Padding(
padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 44,
height: 4,
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
color: Colors.white24,
borderRadius: BorderRadius.circular(99),
),
),
Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: black2,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: gold.withOpacity(0.18)),
),
child: Icon(d.icon, color: gold),
),
const SizedBox(width: 10),
Expanded(
child: Text(
d.title,
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
),
),
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
decoration: BoxDecoration(
color: gold.withOpacity(0.12),
borderRadius: BorderRadius.circular(999),
border: Border.all(color: gold.withOpacity(0.22)),
),
child: Text(d.tag, style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 12)),
),
],
),
const SizedBox(height: 12),

Container(
width: double.infinity,
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: black2,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: gold.withOpacity(0.18)),
),
child: Text(
d.text,
style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 14.5),
),
),

const SizedBox(height: 12),
Row(
children: [
Expanded(
child: SizedBox(
height: 48,
child: OutlinedButton.icon(
onPressed: () => Navigator.pop(ctx),
style: OutlinedButton.styleFrom(
foregroundColor: gold,
side: BorderSide(color: gold.withOpacity(0.55)),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
),
icon: const Icon(Icons.copy_rounded),
label: const Text('Copy (UI)', style: TextStyle(fontWeight: FontWeight.w900)),
),
),
),
const SizedBox(width: 10),
Expanded(
child: SizedBox(
height: 48,
child: ElevatedButton.icon(
onPressed: () => Navigator.pop(ctx),
style: ElevatedButton.styleFrom(
backgroundColor: gold,
foregroundColor: Colors.black,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
),
icon: const Icon(Icons.bookmark_rounded),
label: const Text('Save (UI)', style: TextStyle(fontWeight: FontWeight.w900)),
),
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

// UI only model
class _DuaUi {
final String title;
final String text;
final String tag;
final IconData icon;
const _DuaUi({
required this.title,
required this.text,
required this.tag,
required this.icon,
});
}