import 'package:flutter/material.dart';

/// ✅ Emergency Card UI (Tab-friendly)
/// - No Scaffold
/// - No AppBar
/// - Works inside HomePage IndexedStack
class EmergencyCardPage extends StatefulWidget {
const EmergencyCardPage({super.key});

@override
State<EmergencyCardPage> createState() => _EmergencyCardPageState();
}

class _EmergencyCardPageState extends State<EmergencyCardPage>
with AutomaticKeepAliveClientMixin {
// Brand
static const gold = Color(0xFFD4AF37);
static const black = Color(0xFF0B0F19);
static const black2 = Color(0xFF141927);
static const card = Color(0xFF0F121A);

// UI-only mock data
String fullName = "Sheikha";
String idNumber = "—";
String bloodType = "O+";
String age = "22";
String nationality = "Saudi";
String allergies = "None";
String chronic = "None";
String meds = "None";
String emergencyContact = "Father";
String emergencyPhone = "+966 5X XXX XXXX";

@override
bool get wantKeepAlive => true;

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
_contactInfo(), // ✅ Info only (no call/sms/share/qr)
],
),
),

const SizedBox(height: 6),
_tipsCard(),
],
),

// Floating Edit Button (UI only)
Positioned(
right: 18,
bottom: 92,
child: _fabEdit(),
),
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
style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
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
Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
SizedBox(width: 6),
Text(
"SOS",
style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900),
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
child: const Icon(Icons.health_and_safety_rounded, color: Colors.redAccent),
),
const SizedBox(width: 10),
Expanded(
child: Text(
"If you faint or get lost, this card helps responders reach your family fast.\n(UI only)",
style: TextStyle(color: Colors.white.withOpacity(0.75), height: 1.35),
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
child: const Row(
children: [
Icon(Icons.offline_bolt_rounded, color: gold, size: 18),
SizedBox(width: 6),
Text("Offline", style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
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
fullName,
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
"ID: $idNumber • Age: $age • $nationality",
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
bloodType,
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
value: bloodType,
badgeColor: Colors.redAccent,
),
),
const SizedBox(width: 12),
Expanded(
child: _smallStat(
icon: Icons.medical_information_rounded,
title: "Allergies",
value: allergies == "None" ? "None" : "Yes",
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
Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
const SizedBox(height: 4),
Text(
value,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5),
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
_infoRow(title: "Chronic Conditions", value: chronic),
const SizedBox(height: 10),
_infoRow(title: "Medications", value: meds),
const SizedBox(height: 10),
_infoRow(title: "Allergies (details)", value: allergies),
],
);
}

/// ✅ Contact info only (NO buttons / NO call-sms-share-qr)
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
style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5),
),
const SizedBox(height: 4),
Text(
"$emergencyContact • $emergencyPhone",
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5, height: 1.2),
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
style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 0.7, fontSize: 11.5),
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
Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
const SizedBox(height: 6),
Text(
value,
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, height: 1.35),
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
style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15.5),
),
SizedBox(height: 10),
_TipRow(icon: Icons.water_drop_rounded, text: "Stay hydrated and avoid peak heat."),
SizedBox(height: 8),
_TipRow(icon: Icons.groups_rounded, text: "Stay close to your group, especially after prayers."),
SizedBox(height: 8),
_TipRow(icon: Icons.medical_services_rounded, text: "If dizzy, sit down and alert someone immediately."),
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
Text("Edit", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
],
),
),
);
}

Widget _cardShell({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(14)}) {
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
SnackBar(content: Text(s), behavior: SnackBarBehavior.floating, backgroundColor: Colors.black87),
);
}

// ===================== Edit Sheet (UI only) =====================

void _showEditSheet() {
final nameCtrl = TextEditingController(text: fullName);
final idCtrl = TextEditingController(text: idNumber == "—" ? "" : idNumber);
final ageCtrl = TextEditingController(text: age);
final natCtrl = TextEditingController(text: nationality);
final bloodCtrl = TextEditingController(text: bloodType);
final allergyCtrl = TextEditingController(text: allergies == "None" ? "" : allergies);
final chronicCtrl = TextEditingController(text: chronic == "None" ? "" : chronic);
final medsCtrl = TextEditingController(text: meds == "None" ? "" : meds);
final ecNameCtrl = TextEditingController(text: emergencyContact);
final ecPhoneCtrl = TextEditingController(text: emergencyPhone);

showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: black,
shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
),
Row(
children: const [
Icon(Icons.edit_note_rounded, color: gold),
SizedBox(width: 8),
Text("Edit Emergency Card", style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 16)),
],
),
const SizedBox(height: 12),

_field(nameCtrl, "Full name"),
const SizedBox(height: 10),
Row(
children: [
Expanded(child: _field(idCtrl, "ID number (optional)")),
const SizedBox(width: 10),
Expanded(child: _field(ageCtrl, "Age")),
],
),
const SizedBox(height: 10),
Row(
children: [
Expanded(child: _field(natCtrl, "Nationality")),
const SizedBox(width: 10),
Expanded(child: _field(bloodCtrl, "Blood type")),
],
),
const SizedBox(height: 10),

_field(allergyCtrl, "Allergies (leave empty if none)", maxLines: 2),
const SizedBox(height: 10),
_field(chronicCtrl, "Chronic conditions (leave empty if none)", maxLines: 2),
const SizedBox(height: 10),
_field(medsCtrl, "Medications (leave empty if none)", maxLines: 2),
const SizedBox(height: 10),

Row(
children: [
Expanded(child: _field(ecNameCtrl, "Emergency contact name")),
const SizedBox(width: 10),
Expanded(child: _field(ecPhoneCtrl, "Emergency phone")),
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
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
),
child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w900)),
),
),
),
const SizedBox(width: 10),
Expanded(
child: SizedBox(
height: 48,
child: ElevatedButton(
onPressed: () {
setState(() {
fullName = nameCtrl.text.trim().isEmpty ? fullName : nameCtrl.text.trim();
idNumber = idCtrl.text.trim().isEmpty ? "—" : idCtrl.text.trim();
age = ageCtrl.text.trim().isEmpty ? age : ageCtrl.text.trim();
nationality = natCtrl.text.trim().isEmpty ? nationality : natCtrl.text.trim();
bloodType = bloodCtrl.text.trim().isEmpty ? bloodType : bloodCtrl.text.trim();
allergies = allergyCtrl.text.trim().isEmpty ? "None" : allergyCtrl.text.trim();
chronic = chronicCtrl.text.trim().isEmpty ? "None" : chronicCtrl.text.trim();
meds = medsCtrl.text.trim().isEmpty ? "None" : medsCtrl.text.trim();
emergencyContact = ecNameCtrl.text.trim().isEmpty ? emergencyContact : ecNameCtrl.text.trim();
emergencyPhone = ecPhoneCtrl.text.trim().isEmpty ? emergencyPhone : ecPhoneCtrl.text.trim();
});
Navigator.pop(ctx);
_snack("Saved (UI only)");
},
style: ElevatedButton.styleFrom(
backgroundColor: gold,
foregroundColor: Colors.black,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
),
child: const Text("Save", style: TextStyle(fontWeight: FontWeight.w900)),
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
style: TextStyle(color: Colors.white.withOpacity(0.75), height: 1.35, fontWeight: FontWeight.w700),
),
),
],
);
}
}