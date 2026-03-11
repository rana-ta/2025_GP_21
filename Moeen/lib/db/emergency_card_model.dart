class EmergencyCardModel {
  final String uid;
  final String fullName;
  final String idNumber;
  final String bloodType;
  final String age;
  final String nationality;
  final String allergies;
  final String chronic;
  final String meds;
  final String emergencyContact;
  final String emergencyPhone;

  EmergencyCardModel({
    required this.uid,
    required this.fullName,
    required this.idNumber,
    required this.bloodType,
    required this.age,
    required this.nationality,
    required this.allergies,
    required this.chronic,
    required this.meds,
    required this.emergencyContact,
    required this.emergencyPhone,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'idNumber': idNumber,
    'bloodType': bloodType,
    'age': age,
    'nationality': nationality,
    'allergies': allergies,
    'chronic': chronic,
    'meds': meds,
    'emergencyContact': emergencyContact,
    'emergencyPhone': emergencyPhone,
  };

  factory EmergencyCardModel.fromMap(Map<String, dynamic> map) {
    return EmergencyCardModel(
      uid: (map['uid'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      idNumber: (map['idNumber'] ?? '').toString(),
      bloodType: (map['bloodType'] ?? '').toString(),
      age: (map['age'] ?? '').toString(),
      nationality: (map['nationality'] ?? '').toString(),
      allergies: (map['allergies'] ?? '').toString(),
      chronic: (map['chronic'] ?? '').toString(),
      meds: (map['meds'] ?? '').toString(),
      emergencyContact: (map['emergencyContact'] ?? '').toString(),
      emergencyPhone: (map['emergencyPhone'] ?? '').toString(),
    );
  }
}
