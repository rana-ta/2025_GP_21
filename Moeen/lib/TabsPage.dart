import 'package:flutter/material.dart';
import 'FamilyTrackerTab.dart';
import 'ChatBotPage.dart';


/// ==============================
/// Brand tokens
/// ==============================
class _Brand {
static const gold = Color(0xFFD4AF37);
static const black = Color(0xFF0B0F19);
static const black2 = Color(0xFF141927);
static const card = Color(0xFF0F121A);
}

class TabsPage extends StatefulWidget {
const TabsPage({super.key});

@override
State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
int _index = 0;

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: _Brand.black,
body: IndexedStack(
index: _index,
children: const [
  FamilyTrackerTab(),
DuasTab(),
],
),
bottomNavigationBar: BottomNavigationBar(
backgroundColor: _Brand.black.withOpacity(0.95),
selectedItemColor: _Brand.gold,
unselectedItemColor: Colors.white70,
currentIndex: _index,
onTap: (i) => setState(() => _index = i),
items: const [
BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Family'),
BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Duas'),
],
),
);
}
}

class FamilyTrackerTab extends StatelessWidget {
const FamilyTrackerTab({super.key});

@override
Widget build(BuildContext context) {
return ListView(
padding: const EdgeInsets.all(16),
children: const [
SectionTitle('Family Tracker / Map'),
SizedBox(height: 8),
Center(
child: Text(
'Map preview unavailable',
style: TextStyle(color: Colors.white70),
),
),
],
);
}
}



class DuasTab extends StatelessWidget {
const DuasTab({super.key});

@override
Widget build(BuildContext context) {
return const SizedBox.shrink(); // صفحة فاضية
}
}




class ChatBotPage extends StatefulWidget {
const ChatBotPage({super.key});

@override
State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
int _index = 0;

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: _Brand.black,
appBar: AppBar(
title: const Text('Chat Bot'),
backgroundColor: _Brand.black.withOpacity(0.9),
),
body: Center(
child: Text(
'Chat Bot Content Here',
style: TextStyle(color: Colors.white70, fontSize: 18),
),
),
bottomNavigationBar: BottomNavigationBar(
backgroundColor: _Brand.black.withOpacity(0.95),
selectedItemColor: _Brand.gold,
unselectedItemColor: Colors.white70,
currentIndex: _index,
onTap: (i) => setState(() => _index = i),
items: const [
BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
],
),
);
}
}


class SectionTitle extends StatelessWidget {
final String text;
const SectionTitle(this.text, {super.key});

@override
Widget build(BuildContext context) {
return Text(text,
style: const TextStyle(
color: _Brand.gold, fontSize: 18, fontWeight: FontWeight.w700));
}
}

class CardShell extends StatelessWidget {
final Widget child;
final EdgeInsetsGeometry padding;
const CardShell({required this.child, this.padding = const EdgeInsets.all(14), super.key});

@override
Widget build(BuildContext context) {
return Container(
padding: padding,
decoration: BoxDecoration(
color: _Brand.card,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: _Brand.gold.withOpacity(0.22)),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.35),
blurRadius: 10,
offset: const Offset(0, 8),
),
],
),
child: child,
);
}
}
