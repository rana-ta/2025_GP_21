import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:moeen/sensors_screen.dart';
import 'SettingsPage.dart';
import 'package:url_launcher/url_launcher.dart';

/// ==============================
/// Brand tokens
/// ==============================
class _Brand {
  static const gold = Color(0xFFD4AF37);
  static const black = Color(0xFF0B0F19);
  static const black2 = Color(0xFF141927);
  static const card = Color(0xFF141927);
}

class FamilyTrackerTab extends StatefulWidget {
  const FamilyTrackerTab({super.key});

  @override
  State<FamilyTrackerTab> createState() => _FamilyTrackerTabState();
}

class _FamilyTrackerTabState extends State<FamilyTrackerTab> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _Brand.black,
      body: SizedBox.shrink(),
    );
  }
}

class DuasTab extends StatelessWidget {
  const DuasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Duas', style: TextStyle(color: Colors.white)),
    );
  }
}

class ChatBotPage extends StatelessWidget {
  const ChatBotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Chat Bot', style: TextStyle(color: Colors.white)),
    );
  }
}

///  (Vitals)
class VitalsTab extends StatelessWidget {
  const VitalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SectionTitle('Vitals'),
        SensorScreen(),
      ],
    );
  }
}

class EmergencyCardPage extends StatelessWidget {
  const EmergencyCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SectionTitle('Emergency'),
        SizedBox(height: 12),
        CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: —', style: TextStyle(color: Colors.white)),
              SizedBox(height: 6),
              Text('Blood Type: —', style: TextStyle(color: Colors.white)),
              SizedBox(height: 6),
              Text('Allergies: —', style: TextStyle(color: Colors.white)),
              SizedBox(height: 6),
              Text(
                'Emergency Contact: —',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Home Page with BottomNavigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  late final AssetImage _bg = const AssetImage('assets/images/kab.jpg');

  // BottomNavigationBar
  final List<Widget> _pages = const [
    HomeTab(), // 0 Home
    FamilyTrackerTab(), // 1 Family
    DuasTab(), // 2 Duas
    ChatBotPage(), // 3 Chat
    VitalsTab(), // 4 Vitals
    EmergencyCardPage(), // 5 Emergency
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_bg, context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _Brand.black,
        appBar: AppBar(
          backgroundColor: _Brand.black.withOpacity(0.9),
          elevation: 4,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_moeen.png',
                height: 40,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.favorite, color: _Brand.gold, size: 50),
              ),
              const SizedBox(width: 8),
              const Text(
                'Moeen',
                style: TextStyle(
                  color: _Brand.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10.0),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: _Brand.gold),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: _bg,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.40)),
            ),
            IndexedStack(index: _index, children: _pages),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: _Brand.black.withOpacity(0.95),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _Brand.gold,
          unselectedItemColor: Colors.white70,
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Family',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Duas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_rounded),
              label: 'Vitals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sos_rounded),
              label: 'Emergency',
            ),
          ],
        ),
      ),
    );
  }
}

/// HomeTab
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab>
    with AutomaticKeepAliveClientMixin {
  final PageController _page = PageController(viewportFraction: 0.88);
  int _current = 0;

  int tawaf = 0;
  int sai = 0;
  final int totalLaps = 7;

  final List<_DuaItem> _duas = const [
    _DuaItem('O Allah, make it easy and accept from us.'),
    _DuaItem('Our Lord, grant us good in this world and the Hereafter.'),
    _DuaItem('O Turner of hearts, keep my heart firm upon Your path.'),
    _DuaItem('My Lord, forgive me, my parents, and the believers.'),
  ];

  final List<_DiscoveryCard> _cards = const [
    _DiscoveryCard(
      title: 'How to perform Umrah',
      subtitle: 'Guidance for Umrah steps',
      url:
          'https://www.islamic-relief.org.uk/resources/knowledge-base/umrah/how-to-perform-umrah/',
      icon: Icons.verified,
    ),
    _DiscoveryCard(
      title: 'Ministry of Health Guide',
      subtitle: 'Health guidance for pilgrims (PDF)',
      url:
          'https://www.moh.gov.sa/awarenessplateform/SeasonalAndFestivalHealth/Documents/004.pdf',
      icon: Icons.policy,
    ),
    _DiscoveryCard(
      title: 'Common Mistakes',
      subtitle: 'What to avoid during Hajj and Umrah',
      url:
          'https://www.muslimpro.com/common-mistakes-committed-during-umrah-and-hajj/',
      icon: Icons.mosque,
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        const SectionTitle('Discover Umrah & Hajj'),
        const SizedBox(height: 10),
        _buildDiscoverySlider(),

        const SizedBox(height: 20),
        const SectionTitle('Suggested Duas'),
        const SizedBox(height: 10),
        _buildSuggestedDuas(),

        const SizedBox(height: 20),
        const SectionTitle('Tawaf & Sa’i Counter'),
        const SizedBox(height: 10),
        _buildCounters(),
      ],
    );
  }

  Widget _buildDiscoverySlider() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _page,
            itemCount: _cards.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _DiscoveryTile(card: _cards[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cards.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: active ? 20 : 8,
              decoration: BoxDecoration(
                color: active ? _Brand.gold : Colors.white24,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSuggestedDuas() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _duas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (_, i) {
        final d = _duas[i];
        return CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  d.text,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.4,
                    fontSize: 13.5,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCounters() {
    return Column(
      children: [
        _buildTawafCard(
          'Tawaf',
          tawaf,
          onInc: () => setState(
            () => tawaf = (tawaf < totalLaps) ? tawaf + 1 : totalLaps,
          ),
          onDec: () => setState(() => tawaf = (tawaf > 0) ? tawaf - 1 : 0),
          onReset: () => setState(() => tawaf = 0),
        ),
        const SizedBox(height: 12),
        _buildTawafCard(
          'Sa’i',
          sai,
          onInc: () =>
              setState(() => sai = (sai < totalLaps) ? sai + 1 : totalLaps),
          onDec: () => setState(() => sai = (sai > 0) ? sai - 1 : 0),
          onReset: () => setState(() => sai = 0),
        ),
      ],
    );
  }

  Widget _buildTawafCard(
    String title,
    int current, {
    required VoidCallback onInc,
    required VoidCallback onDec,
    required VoidCallback onReset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _Brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Brand.gold.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          RepaintBoundary(
            child: CircularProgress(
              progress: current / totalLaps,
              size: 120,
              stroke: 10,
              center: Text(
                "$current/$totalLaps",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: onInc,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Brand.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 24,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: onDec,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Brand.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.remove,
                              size: 24,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: onReset,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _Brand.gold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: _Brand.gold,
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Discovery Tile
class _DiscoveryCard {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;

  const _DiscoveryCard({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
  });
}

class _DiscoveryTile extends StatelessWidget {
  final _DiscoveryCard card;

  const _DiscoveryTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return CardShell(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final uri = Uri.parse(card.url);
          bool ok = false;
          try {
            ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
            if (!ok) {
              ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {
            ok = false;
          }
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open link'),
                backgroundColor: Colors.black87,
              ),
            );
          }
        },
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: _Brand.black2,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(card.icon, color: _Brand.gold, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: _Brand.gold),
          ],
        ),
      ),
    );
  }
}

/// Widgets
class CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: const EdgeInsets.only(bottom: 12),
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

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _Brand.gold,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class CircularProgress extends StatelessWidget {
  final double progress;
  final double size;
  final double stroke;
  final Widget center;

  const CircularProgress({
    required this.progress,
    required this.size,
    required this.stroke,
    required this.center,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CircularProgressPainter(progress, stroke),
      child: Center(child: center),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double stroke;

  _CircularProgressPainter(this.progress, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint base = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final Paint active = Paint()
      ..shader =
          const LinearGradient(colors: [_Brand.gold, Colors.amberAccent])
              .createShader(
        Rect.fromCircle(
          center: size.center(Offset.zero),
          radius: size.width / 2,
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - (stroke / 2);

    canvas.drawCircle(center, radius, base);

    final sweep = 2 * math.pi * progress.clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.stroke != stroke;
}

class _DuaItem {
  final String text;

  const _DuaItem(this.text);
}
