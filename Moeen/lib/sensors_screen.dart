sensors_screen

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../model/sensors.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final DatabaseReference _sensorRef =
  FirebaseDatabase.instance.ref().child('Predections');

  late Box<SensorData> _historyBox;

  int heartRate = 0;
  int spo2 = 0;
  double temperature = 0.0;
  String status = '...';

  @override
  void initState() {
    super.initState();
    _historyBox = Hive.box<SensorData>('sensorHistory');

    // Listen to changes in Realtime Database
    _sensorRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        setState(() {
          heartRate = (data['heartRate'] as num?)?.toInt() ?? 0;
          spo2 = (data['spo2'] as num?)?.toInt() ?? 0;
          temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;

          status = (data['HealthStatus'] as String?) ?? '...';
        });

        _saveToHistory();
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

    // Keep only last 100 records to save space
    if (_historyBox.length > 100) {
      _historyBox.deleteAt(0);
    }
  }

  List<FlSpot> _getChartData(String type) {
    final values = _historyBox.values.toList();
    if (values.isEmpty) return [];

    // Get last 20 readings
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

  Widget buildChartCard(String title, String type, Color color) {
    final data = _getChartData(type);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 200,
                child: data.isEmpty
                    ? Center(
                  child: Text(
                    'No data yet',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
                    : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                      type == 'heartRate' ? 20 : 10,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: data,
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter:
                              (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 2,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
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
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Current Readings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
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

  @override
  void dispose() {
    super.dispose();
  }
}
