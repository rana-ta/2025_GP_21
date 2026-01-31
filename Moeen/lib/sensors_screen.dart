import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/sensors.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  // ✅ RTDB node name = Predections (مثل ما هو عندك)
  final DatabaseReference _sensorRef =
  FirebaseDatabase.instance.ref().child('Predections');

  late Box<SensorData> _historyBox;

  int heartRate = 0;
  int spo2 = 0;
  double temperature = 0.0;
  String status = '...';

  DateTime? _lastSyncAt;

  @override
  void initState() {
    super.initState();
    _historyBox = Hive.box<SensorData>('sensorHistory');

    _sensorRef.onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      setState(() {
        heartRate = (data['heartRate'] as num?)?.toInt() ?? 0;
        spo2 = (data['spo2'] as num?)?.toInt() ?? 0;
        temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
        status = (data['HealthStatus'] as String?) ?? '...';
      });

      _saveToHistory();

      // ✅ مزامنة للفاميلي كل ثانيتين
      final now = DateTime.now();
      if (_lastSyncAt == null || now.difference(_lastSyncAt!).inSeconds >= 2) {
        _lastSyncAt = now;
        await syncPredictionToFamily(data);
      }
    });
  }

  void _saveToHistory() {
    final sensorData = SensorData(
      heartRate: heartRate,
      spo2: spo2,
      ir: 0,
      red: 0,
      status: status,
      timestamp: DateTime.now(),
    );

    _historyBox.add(sensorData);

    if (_historyBox.length > 100) {
      _historyBox.deleteAt(0);
    }
  }

  // ✅ نحدد familyId الصحيح اللي نكتب فيه
  Future<String?> _getFamilyIdForWriting(FirebaseFirestore fs, String uid) async {
    final userSnap = await fs.collection('users').doc(uid).get();
    final u = userSnap.data();
    if (u == null) return null;

    // الأولوية: familyId (عضو/منضم) ثم familyCode (تراكر)
    final familyId = (u['familyId'] as String?)?.trim();
    if (familyId != null && familyId.isNotEmpty) return familyId;

    final familyCode = (u['familyCode'] as String?)?.trim();
    if (familyCode != null && familyCode.isNotEmpty) return familyCode;

    return null;
  }

  // ✅ هذا الربط اللي يخلي FamilyPage يعرض قراءاتك (HR/Temp/SpO2)
  Future<void> syncPredictionToFamily(Map<dynamic, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fs = FirebaseFirestore.instance;

    final familyId = await _getFamilyIdForWriting(fs, user.uid);
    if (familyId == null || familyId.isEmpty) return;

    final hr = (data['heartRate'] as num?)?.toInt() ?? 0;
    final s = (data['spo2'] as num?)?.toInt() ?? 0;
    final t = (data['temperature'] as num?)?.toDouble() ?? 0.0;
    final hs = (data['HealthStatus'] as String?) ?? '...';

    // ✅ نخزن status بصيغة ok/abnormal عشان كرت الفاملي يفهمها
    final isAbnormal = hs.toLowerCase() != 'normal';

    await fs
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(user.uid)
        .set({
      'hr': hr,
      'spo2': s.toDouble(),
      'tempC': t,
      'status': isAbnormal ? 'abnormal' : 'ok',
      'healthUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // (اختياري) charts عندك.. تركتها كما هي
  List<FlSpot> _getChartData(String type) {
    final values = _historyBox.values.toList();
    if (values.isEmpty) return [];

    final recentData =
    values.length > 20 ? values.sublist(values.length - 20) : values;

    return recentData.asMap().entries.map((entry) {
      double value = 0;
      switch (type) {
        case 'heartRate':
          value = entry.value.heartRate.toDouble();
          break;
        case 'spo2':
          value = entry.value.spo2.toDouble();
          break;
      }
      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  Widget buildCurrentValueCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusCard() {
    final isOk = status.toLowerCase() == 'normal';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isOk
                ? [Colors.green.withOpacity(0.1), Colors.white.withOpacity(0.3)]
                : [Colors.red.withOpacity(0.1), Colors.white.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOk ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOk ? Icons.check : Icons.warning,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isOk ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Current Readings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: buildCurrentValueCard(
                    'Heart Rate',
                    '$heartRate bpm',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildCurrentValueCard(
                    'SpO2',
                    '$spo2%',
                    Icons.air,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: buildCurrentValueCard(
                    'Temperature',
                    '${temperature.toStringAsFixed(1)} °C',
                    Icons.device_thermostat,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            buildStatusCard(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last updated: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
