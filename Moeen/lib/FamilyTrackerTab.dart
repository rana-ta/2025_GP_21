import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:geolocator/geolocator.dart';

// ✅ OpenStreetMap (بدون API Key / بدون Billing)
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ✅ Open Google Maps (Navigate)
import 'package:url_launcher/url_launcher.dart';

/// ✅ Family Tracker Tab (Real Firebase + Live Location)
/// - No Header
/// ✅ Auto share location when tracker OR joined member (no toggle)
/// ✅ Tracker code يولد أول مرة فقط ولا يتغير
class FamilyTrackerTab extends StatefulWidget {
  const FamilyTrackerTab({super.key});

  @override
  State<FamilyTrackerTab> createState() => _FamilyTtackerTabState();
}

class _FamilyTtackerTabState extends State<FamilyTrackerTab>
    with AutomaticKeepAliveClientMixin {
  // ========= Theme =========
  static const gold = Color(0xFFD4AF37);
  static const black2 = Color(0xFF141927);
  static const card = Color(0xFF141927);

  @override
  bool get wantKeepAlive => true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _codeCtrl = TextEditingController();

  bool _loading = true;
  bool _savingToggle = false;
  bool _joining = false;

  bool trackFamilyEnabled = false; // tracker mode when ON
  bool joined = false; // member joined a family

  String? _uid;
  String? username;

  String? myFamilyCode; // if tracker
  String? myFamilyId; // family joined id (code)

  // ===== live location =====
  StreamSubscription<Position>? _posSub;
  bool _locationOn = false;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  @override
  void initState() {
    super.initState();
    _initStateFromFirestore();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initStateFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _uid = null;
        _loading = false;
      });
      return;
    }

    _uid = user.uid;

    try {
      final snap = await _userDoc.get();
      final data = snap.data() ?? {};

      username = (data['username'] as String?) ?? user.email?.split('@').first;

      trackFamilyEnabled = (data['trackFamily'] as bool?) ?? false;
      myFamilyCode = (data['familyCode'] as String?)?.trim();
      myFamilyId = (data['familyId'] as String?)?.trim();
      joined = myFamilyId != null && myFamilyId!.isNotEmpty;

      // If tracking enabled but no code (old state)
      if (trackFamilyEnabled &&
          (myFamilyCode == null || myFamilyCode!.isEmpty)) {
        await _ensureTrackerSetup();
      }

      // Ensure member doc exists if in a family
      final fam = (myFamilyId != null && myFamilyId!.isNotEmpty)
          ? myFamilyId
          : myFamilyCode;

      if (fam != null && fam.isNotEmpty) {
        await _db
            .collection('families')
            .doc(fam)
            .collection('members')
            .doc(_uid)
            .set({
          'uid': _uid,
          'name': username ?? 'Member',
          'role': trackFamilyEnabled ? 'tracker' : 'member',
          'joinedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // ✅ AUTO share if tracker OR joined
      await _autoShareIfEligible();
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =============================
  // Auto share
  // =============================
  Future<void> _autoShareIfEligible() async {
    final familyId = (myFamilyId != null && myFamilyId!.isNotEmpty)
        ? myFamilyId
        : myFamilyCode;

    final eligible = (trackFamilyEnabled || joined) &&
        familyId != null &&
        familyId.trim().isNotEmpty;

    if (!eligible) {
      await _stopLocationTracking();
      return;
    }

    if (_locationOn && _posSub != null) return;

    await _startLocationTracking(silent: true);
  }

  // =============================
  // Tracker setup
  // =============================
  String _generateFamilyCode() {
    final rnd = Random.secure();
    final number = 100000 + rnd.nextInt(900000);
    return "MOEEN-$number";
  }

  Future<void> _ensureTrackerSetup() async {
    if (_uid == null) return;

    String code = _generateFamilyCode();

    for (int i = 0; i < 4; i++) {
      final famDoc = _db.collection('families').doc(code);
      final famSnap = await famDoc.get();

      if (!famSnap.exists) {
        await famDoc.set({
          'trackerUid': _uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // tracker also appears inside members
        await famDoc.collection('members').doc(_uid).set({
          'uid': _uid,
          'name': username ?? 'Tracker',
          'role': 'tracker',
          'joinedAt': FieldValue.serverTimestamp(),
          'hr': 0,
          'spo2': 0.0,
          'tempC': 0.0,
          'status': 'ok',
          'avatarAsset': null,
          'lastLocation': null,
          'locationUpdatedAt': null,
        }, SetOptions(merge: true));

        await _userDoc.set({
          'trackFamily': true,
          'familyCode': code,
          'familyId': code,
          'role': 'tracker',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        myFamilyCode = code;
        myFamilyId = code;
        joined = true;
        return;
      }

      code = _generateFamilyCode();
    }

    throw Exception("Failed to generate a unique family code.");
  }

  Future<void> _toggleTrackFamily(bool v) async {
    if (_uid == null) {
      _snack("Please login first.");
      return;
    }

    setState(() => _savingToggle = true);

    try {
      if (v) {
        // ✅ إذا عنده كود محفوظ سابقًا لا نولد جديد
        final existing = (myFamilyCode ?? myFamilyId);

        if (existing == null || existing.trim().isEmpty) {
          await _ensureTrackerSetup(); // يولد لأول مرة فقط
        } else {
          // ✅ حدثي وضع التراكر بدون تغيير الكود
          await _userDoc.set({
            'trackFamily': true,
            'familyCode': existing,
            'familyId': existing,
            'role': 'tracker',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // ✅ تأكدي أن وثيقة العائلة موجودة
          await _db.collection('families').doc(existing).set({
            'trackerUid': _uid,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // ✅ تأكدي أن التراكر موجود ضمن members
          await _db
              .collection('families')
              .doc(existing)
              .collection('members')
              .doc(_uid)
              .set({
            'uid': _uid,
            'name': username ?? 'Tracker',
            'role': 'tracker',
            'joinedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          myFamilyCode = existing;
          myFamilyId = existing;
          joined = true;
        }

        setState(() {
          trackFamilyEnabled = true;
          joined = true;
        });

        await _autoShareIfEligible();
      } else {
        await _stopLocationTracking();

        // ✅ لا نحذف familyCode / familyId عشان يثبت نفس الكود
        await _userDoc.set({
          'trackFamily': false,
          'role': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        setState(() {
          trackFamilyEnabled = false;
          joined = (myFamilyId != null && myFamilyId!.trim().isNotEmpty);
          _codeCtrl.clear();
        });
      }
    } catch (_) {
      _snack("Something went wrong. Try again.");
    } finally {
      if (mounted) setState(() => _savingToggle = false);
    }
  }

  // =============================
  // Join Family (Member)
  // =============================
  Future<void> _joinFamily() async {
    if (_uid == null) {
      _snack("Please login first.");
      return;
    }

    final entered = _codeCtrl.text.trim().toUpperCase();
    if (entered.isEmpty) {
      _snack("اكتبي الكود أول");
      return;
    }

    setState(() => _joining = true);

    try {
      final famDoc = _db.collection('families').doc(entered);
      final famSnap = await famDoc.get();

      if (!famSnap.exists) {
        _snack("هذا الكود غير صحيح أو غير موجود");
        return;
      }

      await famDoc.collection('members').doc(_uid).set({
        'uid': _uid,
        'name': username ?? 'Member',
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'hr': 0,
        'spo2': 0.0,
        'tempC': 0.0,
        'status': 'ok',
        'avatarAsset': null,
        'lastLocation': null,
        'locationUpdatedAt': null,
      }, SetOptions(merge: true));

      await _userDoc.set({
        'trackFamily': false,
        'familyId': entered,
        'role': 'member',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        trackFamilyEnabled = false;
        joined = true;
        myFamilyId = entered;
      });

      await _autoShareIfEligible();
      _snack("Joined ✅");
    } catch (_) {
      _snack("تعذر الانضمام. جرّبي مرة ثانية");
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  // =============================
  // Location permissions + tracking
  // =============================
  Future<bool> _ensureLocationPermission({bool silent = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!silent) _snack("فعّلي GPS من الجهاز");
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!silent) _snack("تم رفض صلاحية الموقع");
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!silent) _snack("الصلاحية مرفوضة نهائياً. فعليها من الإعدادات");
      return false;
    }

    return true;
  }

  Future<void> _startLocationTracking({bool silent = false}) async {
    if (_uid == null) return;

    final ok = await _ensureLocationPermission(silent: silent);
    if (!ok) return;

    final familyId = (myFamilyId != null && myFamilyId!.isNotEmpty)
        ? myFamilyId
        : myFamilyCode;

    if (familyId == null || familyId.isEmpty) {
      if (!silent) _snack("لا يوجد Family ID");
      return;
    }

    _posSub?.cancel();

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) async {
      await _db
          .collection('families')
          .doc(familyId)
          .collection('members')
          .doc(_uid)
          .set({
        'lastLocation': {
          'lat': pos.latitude,
          'lng': pos.longitude,
        },
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    if (mounted) setState(() => _locationOn = true);
    if (!silent) _snack("Location sharing ON ✅");
  }

  Future<void> _stopLocationTracking() async {
    await _posSub?.cancel();
    _posSub = null;
    if (mounted) setState(() => _locationOn = false);
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_uid == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _shell(
            child: const Text(
              "Please login first to use Family Tracker.",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          _trackFamilyCard(),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: trackFamilyEnabled
                ? _trackerCard(key: const ValueKey('tracker'))
                : _memberJoinCard(key: const ValueKey('member')),
          ),
          const SizedBox(height: 14),
          if (trackFamilyEnabled || joined) ...[
            _sectionTitle("FAMILY MEMBERS"),
            const SizedBox(height: 10),
            _membersList(),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          t,
          style: const TextStyle(
            color: gold,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _trackFamilyCard() {
    return _shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Track Family",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: "Info",
                onPressed: _showTrackerInfo,
                icon: const Icon(Icons.info_outline_rounded,
                    color: Colors.white60),
              ),
              _savingToggle
                  ? const SizedBox(
                width: 30,
                height: 30,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : Switch(
                value: trackFamilyEnabled,
                activeColor: gold,
                onChanged: (v) => _toggleTrackFamily(v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: black2.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              trackFamilyEnabled
                  ? "You are the tracker. Location sharing is automatic."
                  : "Turn this on to generate your family code and become the tracker.",
              style: const TextStyle(
                color: Colors.white70,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),

        ],
      ),
    );
  }

  Widget _trackerCard({Key? key}) {
    final code = myFamilyCode ?? myFamilyId ?? "—";

    return _shell(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("YOUR FAMILY CODE"),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: black2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    _snack("Copied ✅");
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Share this code with your family to join your group.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberJoinCard({Key? key}) {
    return _shell(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("ENTER FAMILY CODE"),
          const SizedBox(height: 10),
          TextField(
            controller: _codeCtrl,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: "Example: MOEEN-123456",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: black2,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: gold.withOpacity(0.22)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: gold, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.group_add_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _joining ? null : _joinFamily,
              label: _joining
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
                  : const Text(
                "JOIN",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _membersList() {
    final familyId = trackFamilyEnabled
        ? (myFamilyId != null && myFamilyId!.isNotEmpty
        ? myFamilyId
        : myFamilyCode)
        : myFamilyId;

    if (familyId == null || familyId.trim().isEmpty) {
      return _shell(
        child: const Text(
          "No family group found yet.",
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
        ),
      );
    }

    final q = _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .orderBy('joinedAt', descending: false);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _shell(
            child: const Text(
              "No members yet. Share your code to invite family.",
              style:
              TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
            ),
          );
        }

        return Column(
          children: docs.map((d) {
            final data = d.data();

            return _FamilyMemberCard(
              docId: d.id,
              data: data,
              onTrack: () {
                final loc = data['lastLocation'] as Map<String, dynamic>?;
                final lat = (loc?['lat'] as num?)?.toDouble();
                final lng = (loc?['lng'] as num?)?.toDouble();

                if (lat == null || lng == null) {
                  _snack("لا يوجد موقع لهذا العضو بعد");
                  return;
                }

                final name = (data['name'] as String?) ?? 'Member';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberMapPage(
                      name: name,
                      lat: lat,
                      lng: lng,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showTrackerInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card.withOpacity(0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: gold.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "How Track Family Works",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "• Enable Track Family to become the tracker.\n"
                    "• A family code will appear.\n"
                    "• Share it with your family to join.\n"
                    "• Location sharing is automatic once you are in a family.",
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shell({required Widget child, Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }
}

/// ==============================
/// Member Card UI
/// ==============================
class _FamilyMemberCard extends StatelessWidget {
  static const gold = Color(0xFFD4AF37);
  static const card = Color(0xFF141927);

  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onTrack;

  const _FamilyMemberCard({
    required this.docId,
    required this.data,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] as String?) ?? 'Member';

    final hr = (data['hr'] as num?)?.toInt() ?? 0;
    final tempC = ((data['tempC'] as num?) ?? 0).toDouble();
    final spo2 = ((data['spo2'] as num?) ?? 0).toDouble();

    final statusStr = ((data['status'] as String?) ?? 'ok').toLowerCase();
    final isNormal =
        statusStr == 'ok' || statusStr == 'normal' || statusStr == 'healthy';
    final isAbnormal = !isNormal;

    final Color ringColor =
    isAbnormal ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71);

    final IconData rightIcon =
    isAbnormal ? Icons.warning_rounded : Icons.check_circle_rounded;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _avatar(ringColor, data['avatarAsset'] as String?),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                _line(
                  isAbnormal: isAbnormal,
                  icon: Icons.favorite_rounded,
                  text: hr == 0 ? "HR: —" : "HR: $hr bpm",
                ),
                const SizedBox(height: 6),
                _line(
                  isAbnormal: isAbnormal,
                  icon: Icons.thermostat_rounded,
                  text: tempC == 0
                      ? "Temp: —"
                      : "Temp: ${tempC.toStringAsFixed(1)}°C",
                ),
                const SizedBox(height: 6),
                _line(
                  isAbnormal: isAbnormal,
                  icon: Icons.bloodtype_rounded,
                  text: spo2 == 0
                      ? "SpO₂: —"
                      : "SpO₂: ${spo2.toStringAsFixed(0)}%",
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusCircle(icon: rightIcon, color: ringColor),
              const SizedBox(height: 10),
              _actionButton(isAbnormal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line({
    required bool isAbnormal,
    required IconData icon,
    required String text,
  }) {
    final Color c = isAbnormal ? const Color(0xFFE74C3C) : Colors.white70;
    final Color ic = isAbnormal ? const Color(0xFFE74C3C) : Colors.white54;
    final FontWeight w = isAbnormal ? FontWeight.w900 : FontWeight.w700;

    return Row(
      children: [
        Icon(icon, size: 16, color: ic),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: c,
              fontSize: 13.2,
              fontWeight: w,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(Color ringColor, String? avatarAsset) {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 3),
      ),
      child: ClipOval(
        child: avatarAsset == null
            ? Container(
          color: Colors.white10,
          child: const Icon(Icons.person, color: Colors.white70),
        )
            : Image.asset(
          avatarAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.white10,
            child: const Icon(Icons.person, color: Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _statusCircle({required IconData icon, required Color color}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.14),
        border: Border.all(color: color.withOpacity(0.85), width: 2),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  /// ✅ No Health button anymore
  /// ✅ Track button always
  Widget _actionButton(bool isAbnormal) {
    return SizedBox(
      height: 36,
      child: isAbnormal
          ? ElevatedButton(
        onPressed: onTrack, // حتى لو Abnormal افتحي الخريطة
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE74C3C),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          "Track",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
        ),
      )
          : OutlinedButton(
        onPressed: onTrack,
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: BorderSide(color: gold.withOpacity(0.9), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          "Track",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
        ),
      ),
    );
  }
}

/// ==============================
/// Map Page (OpenStreetMap) + Navigate
/// ==============================
class MemberMapPage extends StatelessWidget {
  final String name;
  final double lat;
  final double lng;

  const MemberMapPage({
    super.key,
    required this.name,
    required this.lat,
    required this.lng,
  });

  Future<void> _openNavigate(BuildContext context) async {
    final nav = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final ok = await launchUrl(nav, mode: LaunchMode.externalApplication);

    if (!ok) {
      final web = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      );
      final ok2 = await launchUrl(web, mode: LaunchMode.externalApplication);
      if (!ok2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر فتح خرائط Google")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: const Color(0xFF141927),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: pos,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.moeen.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pos,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _openNavigate(context),
                  icon: const Icon(Icons.navigation_rounded, size: 20),
                  label: const Text(
                    "Navigate",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}