import 'package:flutter/material.dart';
import 'db/emergency_db.dart';
import 'db/emergency_card_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';


/// Defines where the alert came from
enum AlertSource { abnormal, fall }

///  Emergency Card UI (Tab-friendly)
/// - No Scaffold
/// - No AppBar
/// - Works inside HomePage IndexedStack
class EmergencyCardPage extends StatefulWidget {
  final String? uid;

  const EmergencyCardPage({super.key, this.uid});

  @override
  State<EmergencyCardPage> createState() => _EmergencyCardPageState();
}


class _EmergencyCardPageState extends State<EmergencyCardPage>
    with AutomaticKeepAliveClientMixin {
  late String _uid;

  // SOS & TEST numbers
  static const String kSosPhone =
      '0554358805'; // Example SOS number for testing
  static const String kTestPhone =
      '0554358805'; // Put your test number here, then clear it later if needed

  // Brand
  static const gold = Color(0xFFD4AF37);
  static const black = Color(0xFF0B0F19);
  static const black2 = Color(0xFF141927);
  static const card = Color(0xFF0F121A);

  /// Queue a fall alert if an abnormal dialog is already open
  bool _queuedFall = false;
  int _queuedFallTs = 0;

  /// Tracks which alert opened the current dialog
  AlertSource? _currentAlertSource;

  /// UI-only mock data
  String healthStatus = '...'; // Health status from Firebase RTDB
  String fullName = "";
  String idNumber = "";
  String bloodType = "";
  String age = "";
  String nationality = "";
  String allergies = "";
  String chronic = "";
  String meds = "";
  String emergencyContact = "";
  String emergencyPhone = "";
  String _lastHealthStatus = "";

  // Supported blood types
  static const List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  Widget _lettersOnlyField(
    TextEditingController c,
    String hint, {
    int maxLen = 40,
  }) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.name,
      inputFormatters: [
        // Allows Arabic/English letters, spaces, hyphen, apostrophe, and dot
        FilteringTextInputFormatter.allow(
          RegExp(r"[A-Za-z\u0600-\u06FF\s\-\.'’]"),
        ),
        LengthLimitingTextInputFormatter(maxLen),
      ],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: black2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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

  /// Numeric-only field (ID/Age/Phone)
  Widget _numField(TextEditingController c, String hint, {int maxLen = 20}) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLen),
      ],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: black2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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

  /// Blood dropdown (same style as your fields)
  Widget _bloodDropdown({
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: black2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue.isEmpty ? null : currentValue,
          isExpanded: true,
          dropdownColor: black2,
          hint: const Text(
            "Blood type",
            style: TextStyle(color: Colors.white54),
          ),
          iconEnabledColor: gold,
          items: _bloodTypes
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(color: Colors.white)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  String? _selectedBloodType;

  /// RTDB reference for sensor readings and health status


  final DatabaseReference _sensorRef =
  FirebaseDatabase.instance.ref().child('Predections');

  final Telephony _telephony = Telephony.instance;
  final DatabaseReference _fallRef =
  FirebaseDatabase.instance.ref().child('fall');

  /// Dialog and alert control flags
  StreamSubscription<DatabaseEvent>? _rtdbSub;
  bool _alertActive = false;
  bool _userPressedOk = false;
  Timer? _sosTimer;
  DateTime? _lastAlertAt;
  StreamSubscription<DatabaseEvent>? _fallSub;

  String fallStatus = "NONE";
  int fallTimestamp = 0;

  /// Prevent duplicate fall events
  int _lastFallTimestamp = 0;

  /// Store the latest SOS payload for later sending
  String _preparedSOSMessage = "";
  double? _lastLat;
  double? _lastLng;

  // popup control
  bool _dialogOpen = false;
  bool _alreadyTriggered = false;
  bool _dialogClosing = false;
  bool _isSendingSOS = false;
  /// location error
  String? _locError;

  /// countdown (3 min = 180s)
  int _secondsLeft = 180;

  String _lastPendingKey = "";
  String _lastStatusSeen = "";

  String _getCurrentUid() {
    return widget.uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _uid = _getCurrentUid();
    _loadFromDB();
    _startListeners();
  }

  StreamSubscription<DatabaseEvent>? _predSub;

  void _stopListeners() {
    _predSub?.cancel();
    _predSub = null;
    _fallSub?.cancel();
    _fallSub = null;
    _sosTimer?.cancel();
    _sosTimer = null;
  }

  void _startListeners() {
    _stopListeners();
    _listenToHealthStatus();
    _listenToFallStatus();
  }


  void _listenToHealthStatus() {
    _predSub = _sensorRef.onValue.listen((event) async {
      final v = event.snapshot.child('HealthStatus').value;
      final hs = (v ?? '...').toString().trim().toUpperCase();

      if (!mounted) return;

      setState(() => healthStatus = hs);

      if (hs == "ABNORMAL" && _lastHealthStatus != "ABNORMAL") {
        _lastHealthStatus = hs;

        if (_dialogOpen || _dialogClosing) return;

        await _loadFromDB();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _dialogOpen || _dialogClosing) return;
          _currentAlertSource = AlertSource
              .abnormal; // Set alert source before opening the dialog
          _showAreYouOkDialog();
        });
      }

      _lastHealthStatus = hs;
    });
  }

  void _listenToFallStatus() {
    _fallSub = _fallRef.onValue.listen((event) async {
      if (!mounted) return;

      final raw = event.snapshot.value;

      // Fall data is expected to be a map
      final Map data = (raw is Map) ? raw : {};

      final statusUpper = (data['status'] ?? "NONE")
          .toString()
          .trim()
          .toUpperCase();

      final ts = int.tryParse((data['timestamp'] ?? "0").toString()) ?? 0;

      setState(() {
        fallStatus = statusUpper;
        fallTimestamp = ts;
      });

      // Allow a new alert after fall status returns to NONE
      if (statusUpper == "NONE") {
        _lastFallTimestamp = 0;
        return;
      }

      if (statusUpper == "PENDING") {
        if (ts == 0) return;
        if (ts == _lastFallTimestamp) return;

        if (_dialogOpen || _dialogClosing) {
          _queuedFall = true;
          _queuedFallTs = ts;
          return;
        }

        _lastFallTimestamp = ts;
        await _loadFromDB();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _dialogOpen || _dialogClosing) return;
          _currentAlertSource =
              AlertSource.fall; // Set alert source before opening the dialog
          _showAreYouOkDialog();
        });
      }
    });
  }

  Future<void> _setFallStatus(String status) async {
    await _fallRef.update({
      'status': status.toUpperCase(),
      'verifiedAt': ServerValue.timestamp,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  void didUpdateWidget(covariant EmergencyCardPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newUid = _getCurrentUid();
    if (_uid != newUid) {
      _uid = newUid;

      _stopListeners();

      _dialogOpen = false;
      _dialogClosing = false;
      _isSendingSOS = false;
      _queuedFall = false;
      _queuedFallTs = 0;
      _lastHealthStatus = "";
      _lastFallTimestamp = 0;
      _currentAlertSource = null;
      healthStatus = '...';
      fallStatus = "NONE";
      fallTimestamp = 0;

      _loadFromDB();
      _startListeners();
    }
  }

  Future<void> _getMyLocationOnce() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locError = "GPS OFF";
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _locError = "Location denied";
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _locError = "Denied forever";
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      _locError = null;
    } catch (e) {
      _locError = "Failed: $e";
    }
  }

  void _showAreYouOkDialog() async {
    if (_dialogOpen || _dialogClosing) return;
    _dialogOpen = true;
    _dialogClosing = false;

    // reset
    _secondsLeft = 180;
    _locError = null;
    _lastLat = null;
    _lastLng = null;

    // Get the initial location before opening the dialog
    await _getMyLocationOnce();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Start the countdown timer only once while the dialog is open
            _sosTimer ??= Timer.periodic(const Duration(seconds: 1), (t) async {
              if (!mounted) return;

              if (_secondsLeft > 0) {
                _secondsLeft--;
                setDialogState(() {});
                return;
              }

              // became 0
              // became 0
              t.cancel();
              _sosTimer = null;

              if (_isSendingSOS || _dialogClosing) return;
              _dialogClosing = true;

              if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                Navigator.of(ctx, rootNavigator: true).pop();
              }
              _dialogOpen = false;

              await _triggerSOS();
            });

            // format mm:ss
            final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
            final ss = (_secondsLeft % 60).toString().padLeft(2, '0');

            final bool locOk =
                _lastLat != null && _lastLng != null && _locError == null;

            final String? mapUrl = (_lastLat != null && _lastLng != null)
                ? "https://www.google.com/maps/search/?api=1&query=${_lastLat!.toStringAsFixed(5)},${_lastLng!.toStringAsFixed(5)}"
                : null;


            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: gold.withOpacity(0.20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 22,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.redAccent.withOpacity(0.12),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Are you okay?",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: gold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: gold.withOpacity(0.22)),
                          ),
                          child: Text(
                            "$mm:$ss",
                            style: const TextStyle(
                              color: gold,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Status card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: black2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gold.withOpacity(0.14)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.health_and_safety_rounded,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "HealthStatus: $healthStatus",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Location card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: black2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gold.withOpacity(0.14)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                locOk
                                    ? Icons.location_on_rounded
                                    : Icons.location_off_rounded,
                                color: locOk ? gold : Colors.white54,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Location",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  // Refresh current location
                                  await _getMyLocationOnce();
                                  setDialogState(() {});
                                },
                                child: const Text("Refresh"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          locOk
                              ? GestureDetector(
                            onTap: () async {
                              if (mapUrl != null) {
                                final uri = Uri.parse(mapUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                            child: Text(
                              "Open location in Google Maps",
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                                height: 1.2,
                              ),
                            ),
                          )
                              : Text(
                            _locError ?? "Not available",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),

                          // If GPS is off, show a button to open location settings
                          if ((_locError ?? "").toLowerCase().contains(
                            "gps off",
                          )) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await Geolocator.openLocationSettings();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: gold,
                                  side: BorderSide(
                                    color: gold.withOpacity(0.55),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  "Turn on GPS",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () async {
                                if (_dialogClosing) return;

                                _dialogClosing = true;
                                _sosTimer?.cancel();
                                _sosTimer = null;

                                if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                                  Navigator.of(ctx, rootNavigator: true).pop();
                                }

                                _dialogOpen = false;

                                if (_currentAlertSource == AlertSource.fall) {
                                  unawaited(_setFallStatus("OK"));
                                }

                                _snack("OK ✅");
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: gold,
                                side: BorderSide(color: gold.withOpacity(0.55)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "I'm OK",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_isSendingSOS || _dialogClosing) return;

                                _dialogClosing = true;
                                _sosTimer?.cancel();
                                _sosTimer = null;

                                if (Navigator.of(ctx, rootNavigator: true).canPop()) {
                                  Navigator.of(ctx, rootNavigator: true).pop();
                                }

                                _dialogOpen = false;

                                if (_currentAlertSource == AlertSource.fall) {
                                  unawaited(_setFallStatus("CONFIRMED"));
                                }

                                await _triggerSOS();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Need Help",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _dialogOpen = false;
      _dialogClosing = false;

      if (_queuedFall && !_dialogOpen) {
        _queuedFall = false;
        _currentAlertSource = AlertSource.fall;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _dialogOpen || _dialogClosing) return;
          _showAreYouOkDialog();
        });
      }
    });
  }
  Future<void> _sendSmsAuto({
    required String phone,
    required String message,
  }) async {
    try {
      final bool? granted = await _telephony.requestSmsPermissions;

      debugPrint("SMS permission = $granted");
      debugPrint("SMS phone = $phone");
      debugPrint("SMS message = $message");

      if (granted != true) {
        _snack("SMS permission denied");
        return;
      }

      await _telephony.sendSms(
        to: phone,
        message: message,
        statusListener: (status) {
          debugPrint("SMS status = $status");
        },
      );

      _snack("SMS request submitted");
    } catch (e) {
      debugPrint("SMS error = $e");
      _snack("Failed to send SMS: $e");
    }
  }

  Future<void> _triggerSOS() async {
    if (_isSendingSOS) return;
    _isSendingSOS = true;

    try {
      _uid = _getCurrentUid();
      await _loadFromDB();

      String phone = "";

      if (kTestPhone.trim().isNotEmpty) {
        phone = kTestPhone.trim();
      } else if (emergencyPhone.trim().isNotEmpty) {
        phone = emergencyPhone.trim();
      } else {
        phone = kSosPhone.trim();
      }

      if (phone.isEmpty) {
        _snack("No SOS/Test number set");
        return;
      }

      if (phone.startsWith("05")) {
        phone = "966${phone.substring(1)}";
      } else if (phone.startsWith("+")) {
        phone = phone.substring(1);
      }

      _prepareSOSPayload();

      debugPrint("FINAL SMS phone = $phone");
      debugPrint("FINAL SMS body = $_preparedSOSMessage");

      await _sendSmsAuto(
        phone: phone,
        message: _preparedSOSMessage,
      );
    } finally {
      _isSendingSOS = false;
    }
  }
  void _prepareSOSPayload() {
    final statusText = healthStatus.trim().isEmpty ? "-" : healthStatus;
    final nameText = fullName.trim().isEmpty ? "-" : fullName;
    final bloodText = bloodType.trim().isEmpty ? "-" : bloodType;
    final phoneText = emergencyPhone.trim().isEmpty ? "-" : emergencyPhone;
    final allergyText = allergies.trim().isEmpty ? "-" : allergies;
    final chronicText = chronic.trim().isEmpty ? "-" : chronic;

    final locationLink = (_lastLat != null && _lastLng != null)
        ? "https://maps.google.com/?q=${_lastLat!.toStringAsFixed(5)},${_lastLng!.toStringAsFixed(5)}"
        : "Unavailable";

    _preparedSOSMessage =
    "Moeen Team Alert\n"
        "Status:$statusText \n"
         "Name:$nameText\n"
         "Blood:$bloodText\n"
        "Phone:$phoneText\n"
        "Allergy:$allergyText\n"
        "Chronic:$chronicText\n"
        "Location:$locationLink";

    debugPrint("🚨 SOS READY:\n$_preparedSOSMessage");
  }

  @override
  void dispose() {
    _stopListeners();
    super.dispose();
  }
  bool _isProfileReady = false;

  bool _profileHasBasics() {
    return fullName.trim().isNotEmpty &&
        idNumber.trim().length == 10 &&
        emergencyPhone.trim().length == 10 &&
        bloodType.trim().isNotEmpty;
  }


  Future<void> _loadFromDB() async {
    _uid = _getCurrentUid();

    final saved = await EmergencyDB.instance.getCard(_uid);

    if (saved == null) {
      setState(() {
        fullName = "";
        idNumber = "";
        bloodType = "";
        age = "";
        nationality = "";
        allergies = "";
        chronic = "";
        meds = "";
        emergencyContact = "";
        emergencyPhone = "";
        _isProfileReady = false;
      });
      return;
    }

    setState(() {
      fullName = saved.fullName;
      idNumber = saved.idNumber;
      bloodType = saved.bloodType;
      age = saved.age;
      nationality = saved.nationality;
      allergies = saved.allergies;
      chronic = saved.chronic;
      meds = saved.meds;
      emergencyContact = saved.emergencyContact;
      emergencyPhone = saved.emergencyPhone;
      _isProfileReady = _profileHasBasics();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _header(),
              const SizedBox(height: 14),
              _alertBanner(),
              const SizedBox(height: 14),

              _cardShell(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTopRow(),
                    const SizedBox(height: 12),
                    _identityRow(),
                    const SizedBox(height: 12),
                    _gridInfo(),
                    const SizedBox(height: 12),
                    _medicalInfo(),
                    const SizedBox(height: 12),
                    _contactInfo(), // Info only (no call/sms/share/qr)
                  ],
                ),
              ),

              const SizedBox(height: 6),
              _tipsCard(),
            ],
          ),

          // Floating Edit Button (UI only)
          Positioned(right: 18, bottom: 92, child: _fabEdit()),
        ],
      ),
    );
  }

  // ===================== UI blocks =====================

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
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gold.withOpacity(0.25),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              border: Border.all(color: gold.withOpacity(0.22)),
            ),
            child: const Icon(Icons.sos_rounded, color: gold, size: 30),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Emergency Card",
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Keep critical medical info ready for quick help.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  "SOS",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: black2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.redAccent.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "If you faint or get lost, this card helps responders reach your family fast.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTopRow() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "My Emergency Profile",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: gold.withOpacity(0.20)),
          ),
          child: Row(
            children: [
              Icon(Icons.offline_bolt_rounded, color: gold, size: 18),
              SizedBox(width: 6),
              Text(
                _isProfileReady ? "Online" : "Offline",
                style: const TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _identityRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: black2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: gold.withOpacity(0.20)),
            ),
            child: const Icon(Icons.person_rounded, color: gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.trim().isEmpty ? "—" : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "ID: ${idNumber.isEmpty ? "—" : idNumber} • "
                  "Age: ${age.isEmpty ? "—" : age} • "
                  "${nationality.isEmpty ? "—" : nationality}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withOpacity(0.22)),
            ),
            child: Text(
              bloodType.isEmpty ? "—" : bloodType,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridInfo() {
    return Row(
      children: [
        Expanded(
          child: _smallStat(
            icon: Icons.bloodtype_rounded,
            title: "Blood",
            value: bloodType.trim().isEmpty ? "—" : bloodType,
            badgeColor: Colors.redAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _smallStat(
            icon: Icons.medical_information_rounded,
            title: "Allergies",
            value: allergies.trim().isEmpty ? "—" : "Yes",
          ),
        ),
      ],
    );
  }

  Widget _smallStat({
    required IconData icon,
    required String title,
    required String value,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: black2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (badgeColor ?? gold).withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (badgeColor ?? gold).withOpacity(0.22)),
            ),
            child: Icon(icon, color: badgeColor ?? gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicalInfo() {
    return Column(
      children: [
        _infoRow(
          title: "Chronic Conditions",
          value: chronic.trim().isEmpty ? "—" : chronic,
        ),
        const SizedBox(height: 10),
        _infoRow(title: "Medications", value: meds.trim().isEmpty ? "—" : meds),
        const SizedBox(height: 10),
        _infoRow(
          title: "Allergies (details)",
          value: allergies.trim().isEmpty ? "—" : allergies,
        ),
      ],
    );
  }

  /// Contact info only (NO buttons / NO call-sms-share-qr)
  Widget _contactInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: black2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withOpacity(0.20)),
            ),
            child: const Icon(Icons.contact_phone_rounded, color: gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Emergency Contact",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${emergencyContact.trim().isEmpty ? "—" : emergencyContact} • "
                  "${emergencyPhone.trim().isEmpty ? "—" : emergencyPhone}",

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: gold.withOpacity(0.20)),
            ),
            child: const Text(
              "PRIMARY",
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: black2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withOpacity(0.20)),
            ),
            child: const Icon(Icons.notes_rounded, color: gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    return _cardShell(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Quick Tips",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
            ),
          ),
          SizedBox(height: 10),
          _TipRow(
            icon: Icons.water_drop_rounded,
            text: "Stay hydrated and avoid peak heat.",
          ),
          SizedBox(height: 8),
          _TipRow(
            icon: Icons.groups_rounded,
            text: "Stay close to your group, especially after prayers.",
          ),
          SizedBox(height: 8),
          _TipRow(
            icon: Icons.medical_services_rounded,
            text: "If dizzy, sit down and alert someone immediately.",
          ),
        ],
      ),
    );
  }

  Widget _fabEdit() {
    return GestureDetector(
      onTap: _showEditSheet,
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
            Icon(Icons.edit_rounded, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
              "Edit",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardShell({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    return Container(
      padding: padding,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withOpacity(0.20)),
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

  void _snack(String s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  // ===================== Edit Sheet (UI only) =====================

  void _showEditSheet() {
    final nameCtrl = TextEditingController(text: fullName);
    final idCtrl = TextEditingController(text: idNumber);
    final ageCtrl = TextEditingController(text: age);
    final natCtrl = TextEditingController(text: nationality);
    String selectedBlood = bloodType;
    final allergyCtrl = TextEditingController(text: allergies);
    final chronicCtrl = TextEditingController(text: chronic);
    final medsCtrl = TextEditingController(text: meds);
    final ecNameCtrl = TextEditingController(text: emergencyContact);
    final ecPhoneCtrl = TextEditingController(text: emergencyPhone);

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
          child: SingleChildScrollView(
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
                      "Edit Emergency Card",
                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _lettersOnlyField(nameCtrl, "Full name", maxLen: 35),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _numField(idCtrl, "ID number", maxLen: 10)),
                    const SizedBox(width: 10),
                    Expanded(child: _numField(ageCtrl, "Age", maxLen: 2)),
                  ],
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _lettersOnlyField(
                        natCtrl,
                        "Nationality",
                        maxLen: 25,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _bloodDropdown(
                        currentValue: selectedBlood,
                        onChanged: (v) {
                          selectedBlood = v;
                          // Refresh the dropdown inside the bottom sheet
                          (ctx as Element).markNeedsBuild();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _field(
                  allergyCtrl,
                  "Allergies (leave empty if none)",
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                _field(
                  chronicCtrl,
                  "Chronic conditions (leave empty if none)",
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                _field(
                  medsCtrl,
                  "Medications (leave empty if none)",
                  maxLines: 2,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _lettersOnlyField(
                        ecNameCtrl,
                        "Emergency contact name",
                        maxLen: 35,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numField(
                        ecPhoneCtrl,
                        "Emergency phone",
                        maxLen: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: gold,
                            side: BorderSide(color: gold.withOpacity(0.60)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            // 1) Name is required
                            if (nameCtrl.text.trim().isEmpty) {
                              _snack("Please enter your name");
                              return;
                            }

                            // 2) ID is required (must be 10 digits)
                            final id = idCtrl.text.trim();
                            if (id.isEmpty) {
                              _snack("Please enter your ID number");
                              return;
                            }
                            if (id.length != 10) {
                              _snack("ID number must be 10 digits");
                              return;
                            }

                            // 3) Emergency phone is required (must be 10 digits)
                            final ePhone = ecPhoneCtrl.text.trim();
                            if (ePhone.isEmpty) {
                              _snack("Please enter emergency phone");
                              return;
                            }
                            if (ePhone.length != 10) {
                              _snack("Emergency phone must be 10 digits");
                              return;
                            }

                            // Blood type is required
                            if (selectedBlood.trim().isEmpty) {
                              _snack("Please choose blood type");
                              return;
                            }

                            // Update UI with the new values
                            String cleanNoDigits(String s) =>
                                s.replaceAll(RegExp(r'[0-9٠-٩]'), '').trim();

                            setState(() {
                              fullName = nameCtrl.text.trim();
                              idNumber = idCtrl.text.trim();
                              age = ageCtrl.text.trim();
                              nationality = natCtrl.text.trim();
                              bloodType = selectedBlood.trim();
                              allergies = allergyCtrl.text.trim();
                              chronic = chronicCtrl.text.trim();
                              meds = medsCtrl.text.trim();
                              emergencyContact = ecNameCtrl.text.trim();
                              emergencyPhone = ecPhoneCtrl.text.trim();
                            });
                            _uid = _getCurrentUid();
                            final model = EmergencyCardModel(
                              uid: _uid,
                              fullName: fullName,
                              idNumber: idNumber,
                              bloodType: bloodType,
                              age: age,
                              nationality: nationality,
                              allergies: allergies,
                              chronic: chronic,
                              meds: meds,
                              emergencyContact: emergencyContact,
                              emergencyPhone: emergencyPhone,
                            );

                            await EmergencyDB.instance.saveCard(model);
                            setState(() {
                              _isProfileReady = _profileHasBasics();
                            });

                            Navigator.pop(ctx);
                            _snack("Saved ✅ ");
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Save",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: black2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: gold.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gold.withOpacity(0.18)),
          ),
          child: Icon(icon, color: gold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
