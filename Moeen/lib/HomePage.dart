import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moeen/sensors_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'DuasPage.dart';
import 'SettingsPage.dart';
import 'FamilyTrackerTab.dart';
import 'ChatBotPage.dart';
import 'EmergencyCardPage.dart';

/// ==============================
/// Brand tokens
/// ==============================
class _Brand {
  static const gold = Color(0xFFD4AF37);
  static const black = Color(0xFF0B0F19);
  static const black2 = Color(0xFF141927);
  static const card = Color(0xFF141927);
}

/// ==============================
/// Fixed Coordinates (Makkah)
/// ==============================
/// ✅ Kaaba Center (approx)
const LatLng KAABA_CENTER = LatLng(21.422487, 39.826206);

/// ✅ Safa & Marwa
const LatLng SAFA_POINT = LatLng(21.42183, 39.82749);
const LatLng MARWA_POINT = LatLng(21.42524, 39.82726);

/// ==============================
/// Vitals
/// ==============================
class VitalsTab extends StatelessWidget {
  const VitalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: const [
        SectionTitle('Vitals'),
        SizedBox(height: 10),
        SensorScreen(),
      ],
    );
  }
}

/// ==============================
/// Home Page with BottomNavigation
/// ==============================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  late final AssetImage _bg = const AssetImage('assets/images/kab.jpg');

  late final List<Widget> _pages = const [
    HomeTab(), // 0 Home
    FamilyTrackerTab(), // 1 Family
    DuasPage(), // 2 Duas
    ChatBotPage(), // 3 Chat
    VitalsTab(), // 4 Vitals
    EmergencyCardPage() // 5 Emergency
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
                const Icon(Icons.favorite, color: _Brand.gold, size: 40),
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
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Family'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Duas'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.monitor_heart_rounded), label: 'Vitals'),
            BottomNavigationBarItem(icon: Icon(Icons.sos_rounded), label: 'Emergency'),
          ],
        ),
      ),
    );
  }
}

/// ==============================
/// HomeTab
/// ==============================
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
  final PageController _page = PageController(viewportFraction: 0.88);
  int _current = 0;

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
      title: 'Health Guide',
      subtitle: 'Health guidance for pilgrims ',
      url:
      'https://www.emro.who.int/media/news/general-health-advice-and-guidelines-for-pilgrims.html',
      icon: Icons.policy,
    ),
    _DiscoveryCard(
      title: 'Common Mistakes',
      subtitle: 'What to avoid during Hajj and Umrah',
      url: 'https://www.muslimpro.com/common-mistakes-committed-during-umrah-and-hajj/',
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
        const SizedBox(height: 12),

        // ✅ Prayer times (same home page)
        const PrayerTimesHeroCard(),
        const SizedBox(height: 20),

        const SectionTitle('Suggested Duas'),
        const SizedBox(height: 10),
        _buildSuggestedDuas(),
        const SizedBox(height: 20),

        const SectionTitle('Auto Counter (GPS)'),
        const SizedBox(height: 10),
        const TawafAutoCounterCard(),
        const SizedBox(height: 12),
        const SaiAutoCounterCard(),
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
        childAspectRatio: 1.18,
      ),
      itemBuilder: (_, i) {
        final d = _duas[i];
        return CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  d.text,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.4,
                    fontSize: 13.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: _Brand.gold, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Quick Dua",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("Add Dua"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Brand.gold,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        ),
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
/// ==============================
/// Prayer Times Hero Card (FINAL EN - NO OVERFLOW)
/// ==============================
/// ==============================
/// Prayer Times Hero Card (FINAL EN - NO OVERFLOW)
/// ==============================
class PrayerTimesHeroCard extends StatefulWidget {
  const PrayerTimesHeroCard({super.key});

  @override
  State<PrayerTimesHeroCard> createState() => _PrayerTimesHeroCardState();
}

class _PrayerTimesHeroCardState extends State<PrayerTimesHeroCard> {
  Map<String, DateTime>? _t;
  String _place = "Saudi Arabia";
  bool _loading = true;

  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_t != null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // fallback: Makkah
    double lat = 21.422487, lng = 39.826206;
    String place = "Makkah";

    final ok = await _ensureLocationPermission();
    if (ok) {
      try {
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        lat = p.latitude;
        lng = p.longitude;
        place = "Your location";
      } catch (_) {
        // keep fallback
      }
    }

    final now = DateTime.now();
    final url = Uri.parse(
      "https://api.aladhan.com/v1/timings/${now.millisecondsSinceEpoch ~/ 1000}"
          "?latitude=$lat&longitude=$lng&method=4",
    );

    try {
      final res = await http.get(url);
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      final data = (m["data"] as Map<String, dynamic>);
      final timings = (data["timings"] as Map<String, dynamic>);

      DateTime parseHHmm(String v) {
        final s = v.toString().split(" ").first.trim();
        final p = s.split(":");
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(p[0]),
          int.parse(p[1]),
        );
      }

      _t = {
        "fajr": parseHHmm(timings["Fajr"]),
        "sunrise": parseHHmm(timings["Sunrise"]),
        "dhuhr": parseHHmm(timings["Dhuhr"]),
        "asr": parseHHmm(timings["Asr"]),
        "maghrib": parseHHmm(timings["Maghrib"]),
        "isha": parseHHmm(timings["Isha"]),
      };

      if (!mounted) return;
      setState(() {
        _place = place;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _t = null;
        _place = place;
      });
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied &&
        perm != LocationPermission.deniedForever;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
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
        child: SizedBox(
          height: 268, // ✅ FINAL: fixes overflow without shrinking spacing
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/images/sky.jpg",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: _Brand.black2),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.72),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Row
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: Colors.white.withOpacity(0.9), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _load,
                      icon: Icon(Icons.refresh_rounded,
                          color: Colors.white.withOpacity(0.92)),
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      constraints:
                      const BoxConstraints.tightFor(width: 40, height: 40),
                    ),
                  ],
                ),
              ),

              // ✅ Fixed content area (prevents overflow always)
              Positioned(
                top: 52,
                left: 12,
                right: 12,
                bottom: 12,
                child: _loading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: _Brand.gold.withOpacity(0.95),
                  ),
                )
                    : (_t == null
                    ? Center(
                  child: Text(
                    "Failed to load prayer times",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PrayerCenter(times: _t!),
                    const SizedBox(height: 14),
                    _PrayerStrip(times: _t!),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== Center: next prayer + countdown =====
class _PrayerCenter extends StatelessWidget {
  final Map<String, DateTime> times;
  const _PrayerCenter({required this.times});

  @override
  Widget build(BuildContext context) {
    final next = _nextPrayer(times);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Time left until ${_label(next.key)}",
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _countdown(next.remaining),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

/// ===== Strip: same level, only next prayer is gold =====
class _PrayerStrip extends StatelessWidget {
  final Map<String, DateTime> times;
  const _PrayerStrip({required this.times});

  @override
  Widget build(BuildContext context) {
    final next = _nextPrayer(times);

    final items = const [
      ("fajr", "Fajr", Icons.nights_stay_rounded),
      ("sunrise", "Sunrise", Icons.wb_sunny_rounded),
      ("dhuhr", "Dhuhr", Icons.wb_sunny_outlined),
      ("asr", "Asr", Icons.cloud_outlined),
      ("maghrib", "Maghrib", Icons.wb_twilight_rounded),
      ("isha", "Isha", Icons.nightlight_round),
    ];

    return SizedBox(
      height: 88, // ✅ ثابت ويضمن نفس المستوى للجميع
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.map((e) {
          final key = e.$1;
          final label = e.$2;
          final icon = e.$3;

          final active = key == next.key;
          final color = active ? _Brand.gold : Colors.white70;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _Brand.gold.withOpacity(0.10) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active ? _Brand.gold.withOpacity(0.45) : Colors.white10,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(height: 6),

                    // ✅ يمنع تكسير النص (Maghrib وغيرها)
                    SizedBox(
                      height: 16,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    SizedBox(
                      height: 16,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _fmtTime(times[key]!),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ✅ مؤشر للصلاة القادمة فقط (على نفس المستوى)

                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
/// ==============================
/// Prayer Helpers (EN labels)
/// ==============================
String _fmtTime(DateTime dt) {
  int h = dt.hour % 12;
  if (h == 0) h = 12;
  final m = dt.minute.toString().padLeft(2, "0");
  final ap = dt.hour >= 12 ? "PM" : "AM";
  return "$h:$m $ap";
}

String _countdown(Duration d) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours.toString();
  final m = (d.inMinutes % 60).toString().padLeft(2, "0");
  final s = (d.inSeconds % 60).toString().padLeft(2, "0");
  return "$h:$m:$s";
}

String _label(String k) {
  switch (k) {
    case "fajr":
      return "Fajr";
    case "sunrise":
      return "Sunrise";
    case "dhuhr":
      return "Dhuhr";
    case "asr":
      return "Asr";
    case "maghrib":
      return "Maghrib";
    case "isha":
      return "Isha";
    default:
      return k;
  }
}

class _Next {
  final String key;
  final DateTime at;
  final Duration remaining;
  _Next(this.key, this.at, this.remaining);
}

_Next _nextPrayer(Map<String, DateTime> t) {
  final now = DateTime.now();
  final order = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"];

  for (final k in order) {
    final at = t[k]!;
    if (at.isAfter(now)) return _Next(k, at, at.difference(now));
  }

  final fajr = t["fajr"]!.add(const Duration(days: 1));
  return _Next("fajr", fajr, fajr.difference(now));
}
/// ==============================
/// GPS Tawaf Counter UI (GPS ONLY)
/// ==============================
class TawafAutoCounterCard extends StatefulWidget {
  const TawafAutoCounterCard({super.key});

  @override
  State<TawafAutoCounterCard> createState() => _TawafAutoCounterCardState();
}

class _TawafAutoCounterCardState extends State<TawafAutoCounterCard> {
  static const gold = _Brand.gold;

  bool running = false;
  StreamSubscription<Position>? _posSub;

  final TawafGpsCounter _counter = TawafGpsCounter(
    centerLat: KAABA_CENTER.lat,
    centerLng: KAABA_CENTER.lng,
    totalLaps: 7,
  );

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (running) {
      _stop();
      setState(() => running = false);
      return;
    }

    _counter.reset();

    final ok = await _ensureLocationPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS permission not available / Location OFF')),
      );
      return;
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((p) {
      _counter.onPoint(lat: p.latitude, lng: p.longitude, accuracy: p.accuracy);
      if (mounted) setState(() {});
    });

    setState(() => running = true);
  }

  void _stop() {
    _posSub?.cancel();
    _posSub = null;
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CardShell(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StartRitualButton(
            title: "Start your Tawaf",
            subtitle: running ? "Tracking GPS…" : "Tap to start GPS counting",
            icon: Icons.sync_rounded,
            running: running,
            onTap: _toggle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Tawaf: ${_counter.laps}/7",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _tag("GPS"),
              const SizedBox(width: 8),
              _tag(running ? "LIVE" : "IDLE"),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _counter.progress01,
            minHeight: 10,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(gold),
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 8),
          const Text(
            "Note: Tawaf needs real movement around the Kaaba center (indoor testing won't work well).",
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.30)),
      ),
      child: Text(
        t,
        style: const TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 0.6),
      ),
    );
  }
}

/// ==============================
/// GPS Sa'i Counter UI (GPS ONLY)
/// ==============================
class SaiAutoCounterCard extends StatefulWidget {
  const SaiAutoCounterCard({super.key});

  @override
  State<SaiAutoCounterCard> createState() => _SaiAutoCounterCardState();
}

class _SaiAutoCounterCardState extends State<SaiAutoCounterCard> {
  static const gold = _Brand.gold;

  bool running = false;
  StreamSubscription<Position>? _posSub;

  final SaiGpsCounter _counter = SaiGpsCounter(
    pointA: SAFA_POINT,
    pointB: MARWA_POINT,
    totalLegs: 7,
    reachMeters: 20,
  );

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (running) {
      _stop();
      setState(() => running = false);
      return;
    }

    _counter.reset();

    final ok = await _ensureLocationPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS permission not available / Location OFF')),
      );
      return;
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      ),
    ).listen((p) {
      _counter.onPoint(LatLng(p.latitude, p.longitude), accuracy: p.accuracy);
      if (mounted) setState(() {});
    });

    setState(() => running = true);
  }

  void _stop() {
    _posSub?.cancel();
    _posSub = null;
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CardShell(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StartRitualButton(
            title: "Start your Sa’i",
            subtitle: running ? "Tracking… reach Safa then Marwa" : "Tap to start GPS counting",
            icon: Icons.directions_walk_rounded,
            running: running,
            onTap: _toggle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Sa’i: ${_counter.legs}/7",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _tag("GPS"),
              const SizedBox(width: 8),
              _tag(running ? "LIVE" : "IDLE"),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _counter.progress01,
            minHeight: 10,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(gold),
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 8),
          Text(
            "Safa: (${SAFA_POINT.lat.toStringAsFixed(5)}, ${SAFA_POINT.lng.toStringAsFixed(5)})\n"
                "Marwa: (${MARWA_POINT.lat.toStringAsFixed(5)}, ${MARWA_POINT.lng.toStringAsFixed(5)})",
            style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.30)),
      ),
      child: Text(
        t,
        style: const TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 0.6),
      ),
    );
  }
}

/// ==============================
/// Logic: Tawaf via GPS angle accumulation
/// ==============================
class TawafGpsCounter {
  final int totalLaps;
  final double centerLat;
  final double centerLng;

  int laps = 0;
  double _acc = 0;
  double? _prevTheta;

  TawafGpsCounter({
    required this.centerLat,
    required this.centerLng,
    this.totalLaps = 7,
  });

  void reset() {
    laps = 0;
    _acc = 0;
    _prevTheta = null;
  }

  void onPoint({
    required double lat,
    required double lng,
    double? accuracy,
  }) {
    if (accuracy != null && accuracy > 25) return;

    final theta = _thetaAroundCenter(lat, lng);

    if (_prevTheta != null) {
      var d = _unwrapDelta(theta - _prevTheta!);
      _acc += d;

      const twoPi = 2 * math.pi;
      while (_acc.abs() >= twoPi) {
        laps += 1;
        _acc -= twoPi * _acc.sign;
      }
    }

    _prevTheta = theta;
  }

  double get progress01 {
    const twoPi = 2 * math.pi;
    final partial = (_acc.abs() / twoPi).clamp(0.0, 0.999);
    final v = (laps + partial) / totalLaps;
    return v.clamp(0.0, 1.0);
  }

  double _thetaAroundCenter(double lat, double lng) {
    final dLat = (lat - centerLat) * (math.pi / 180);
    final dLng = (lng - centerLng) * (math.pi / 180) * math.cos(centerLat * math.pi / 180);
    return math.atan2(dLat, dLng);
  }

  double _unwrapDelta(double d) {
    if (d > math.pi) d -= 2 * math.pi;
    if (d < -math.pi) d += 2 * math.pi;
    return d;
  }
}

/// ==============================
/// Logic: Sa'i via reaching endpoints
/// ==============================
class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

enum _Need { a, b }

class SaiGpsCounter {
  final LatLng pointA;
  final LatLng pointB;
  final int totalLegs;

  int legs = 0;
  _Need _need = _Need.a;

  final double reachMeters;

  SaiGpsCounter({
    required this.pointA,
    required this.pointB,
    this.totalLegs = 7,
    this.reachMeters = 20,
  });

  void reset() {
    legs = 0;
    _need = _Need.a;
  }

  void onPoint(LatLng p, {double? accuracy}) {
    if (accuracy != null && accuracy > 25) return;

    final dA = _distanceMeters(p, pointA);
    final dB = _distanceMeters(p, pointB);

    if (_need == _Need.a && dA <= reachMeters) {
      _need = _Need.b;
      return;
    }

    if (_need == _Need.b && dB <= reachMeters) {
      legs += 1;
      _need = _Need.a;
      return;
    }
  }

  double get progress01 => (legs / totalLegs).clamp(0, 1);

  double _distanceMeters(LatLng p1, LatLng p2) {
    const r = 6371000.0;
    final dLat = _deg2rad(p2.lat - p1.lat);
    final dLng = _deg2rad(p2.lng - p1.lng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(p1.lat)) *
            math.cos(_deg2rad(p2.lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * (math.pi / 180);
}

/// ==============================
/// UI: Start button (glowy)
/// ==============================
class StartRitualButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool running;
  final VoidCallback onTap;

  const StartRitualButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.running,
    required this.onTap,
  });

  @override
  State<StartRitualButton> createState() => _StartRitualButtonState();
}

class _StartRitualButtonState extends State<StartRitualButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = _Brand.gold;
    const card = _Brand.card;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final glow = widget.running ? (0.35 + 0.25 * t) : 0.18;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gold.withOpacity(0.30)),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(glow),
                  blurRadius: widget.running ? 22 : 10,
                  spreadRadius: widget.running ? 1.5 : 0.4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gold.withOpacity(widget.running ? 1 : 0.75),
                        Colors.amberAccent.withOpacity(widget.running ? 1 : 0.45),
                      ],
                    ),
                  ),
                  child: Icon(widget.icon, color: Colors.black, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.70)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(widget.running ? 1 : 0.20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.running ? "STOP" : "START",
                    style: TextStyle(
                      color: widget.running ? Colors.black : gold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ==============================
/// Discovery Tile
/// ==============================
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
            if (!ok) ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            ok = false;
          }
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot open link'), backgroundColor: Colors.black87),
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
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13.5),
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

/// ==============================
/// Shared Widgets
/// ==============================
class CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CardShell({required this.child, this.padding = const EdgeInsets.all(14), super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
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

class _DuaItem {
  final String text;
  const _DuaItem(this.text);
}
