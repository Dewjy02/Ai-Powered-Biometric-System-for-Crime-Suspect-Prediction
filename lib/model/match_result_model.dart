class MatchResultModel {
  final String nic;
  final String name;
  final String passportId;
  final String profileUrl;
  final double score;

  MatchResultModel({
    required this.nic,
    required this.name,
    required this.passportId,
    required this.profileUrl,
    required this.score,
  });

  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    return MatchResultModel(
      nic: json['nic'],
      name: json['name'],
      passportId: json['passportId'].toString(),
      profileUrl: json['profileUrl'],
      score: (json['score'] as num).toDouble(),
    );
  }
}
