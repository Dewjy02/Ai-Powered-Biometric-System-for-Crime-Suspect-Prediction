class Citizen {
  final String profileUrl;
  final String nic;
  final int passportId;
  final String name;
  final String dateOfBirth;
  final String address;
  final int mobileNumber;
  final String fingerPrintId;
  final String fingerPrintBase64;

  Citizen({
    required this.profileUrl,
    required this.passportId, 
    required this.nic,
    required this.name,
    required this.dateOfBirth,
    required this.address,
    required this.mobileNumber,
    required this.fingerPrintId,
    required this.fingerPrintBase64,
  });

  factory Citizen.fromMap(Map<String, dynamic> data) {
    return Citizen(
      profileUrl: data['profileUrl'] ?? '',
      nic: data['nic'] ?? '',
      passportId: data['passportId'] ?? '',
      name: data['name'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      address: data['address'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      fingerPrintId: data['fingerPrintId'] ?? '',
      fingerPrintBase64: data['fingerPrintBase64']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileUrl': profileUrl,
      'nic': nic,
      'passportId' : passportId,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'mobileNumber': mobileNumber,
      'fingerPrintId': fingerPrintId,
      'fingerPrintBase64':fingerPrintBase64,
    };
  }
}
