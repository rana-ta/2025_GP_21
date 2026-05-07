import 'dart:async';

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
  DatabaseReference? _sensorRef;
  StreamSubscription<DatabaseEvent>? _sensorSub;

  final TextEditingController _deviceController = TextEditingController();
  String? linkedDeviceId;

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
    _listenToMyDevice();
  }

  Future<String?> _getCurrentUserDeviceId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final deviceId = (doc.data()?['deviceId'] as String?)?.trim();

    if (mounted) {
      setState(() {
        linkedDeviceId = deviceId;
      });
    }

    return deviceId;
  }

  Future<bool> _deviceExists(String deviceId) async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('devices')
        .child(deviceId)
        .get();

    return snapshot.exists;
  }

  Future<void> _linkDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final deviceId = _deviceController.text.trim().toUpperCase();

    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Device ID')),
      );
      return;
    }

    final exists = await _deviceExists(deviceId);

    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not found')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'deviceId': deviceId,
    });

    await _sensorSub?.cancel();

    setState(() {
      linkedDeviceId = deviceId;
      status = '...';
      heartRate = 0;
      spo2 = 0;
      temperature = 0.0;
    });

    await _listenToMyDevice();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device linked successfully')),
    );
  }

  Future<void> _listenToMyDevice() async {
    final deviceId = await _getCurrentUserDeviceId();

    if (deviceId == null || deviceId.isEmpty) {
      if (!mounted) return;
      setState(() {
        status = 'No device linked';
      });
      return;
    }

    await _sensorSub?.cancel();

    _sensorRef = FirebaseDatabase.instance
        .ref()
        .child('devices')
        .child(deviceId)
        .child('predictions');

    _sensorSub = _sensorRef!.onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      if (!mounted) return;
      setState(() {
        heartRate = (data['heartRate'] as num?)?.toInt() ?? 0;
        spo2 = (data['spo2'] as num?)?.toInt() ?? 0;
        temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
        status = (data['HealthStatus'] as String?) ?? '...';
      });

      _saveToHistory();

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

  Future<String?> _getFamilyIdForWriting(
      FirebaseFirestore fs,
      String uid,
      ) async {
    final userSnap = await fs.collection('users').doc(uid).get();
    final u = userSnap.data();
    if (u == null) return null;

    final familyId = (u['familyId'] as String?)?.trim();
    if (familyId != null && familyId.isNotEmpty) return familyId;

    final familyCode = (u['familyCode'] as String?)?.trim();
    if (familyCode != null && familyCode.isNotEmpty) return familyCode;

    return null;
  }

  Future<void> syncPredictionToFamily(Map<dynamic, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fs = FirebaseFirestore.instance;

    final familyId = await _getFamilyIdForWriting(fs, user.uid);
    if (familyId == null || familyId.isEmpty) return;

    final deviceId = await _getCurrentUserDeviceId();

    final hr = (data['heartRate'] as num?)?.toInt() ?? 0;
    final s = (data['spo2'] as num?)?.toInt() ?? 0;
    final t = (data['temperature'] as num?)?.toDouble() ?? 0.0;
    final hs = (data['HealthStatus'] as String?) ?? '...';

    final isAbnormal = hs.toLowerCase() != 'normal';

    await fs
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(user.uid)
        .set({
      'deviceId': deviceId,
      'hr': hr,
      'spo2': s.toDouble(),
      'tempC': t,
      'status': isAbnormal ? 'abnormal' : 'ok',
      'healthUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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

  Widget buildDeviceLinkCard() {
    final bool hasDevice = linkedDeviceId != null && linkedDeviceId!.isNotEmpty;

    return Card(
      elevation: 4,
      color: const Color(0xFF0F121A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: hasDevice
            ? Row(
          children: [
            const Icon(
              Icons.watch_rounded,
              color: Color(0xFFD4AF37),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Linked Device: $linkedDeviceId',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  linkedDeviceId = null;
                  _deviceController.clear();
                });
              },
              child: const Text(
                'Change',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link Your Device',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the Device ID printed on your sticker.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Device ID',
                hintText: 'Example: SD001',
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF141927),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: const Color(0xFFD4AF37).withOpacity(0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _linkDevice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Link Device',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isOk ? Colors.green : Colors.red,
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

  @override
  void dispose() {
    _sensorSub?.cancel();
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _listenToMyDevice();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildDeviceLinkCard(),
            const SizedBox(height: 16),
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
