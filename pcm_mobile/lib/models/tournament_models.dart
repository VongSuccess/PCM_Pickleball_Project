class TournamentDetailModel {
  final int id;
  final String name;
  final String format;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? entryFee;
  final double? prizePool;

  TournamentDetailModel({
    required this.id,
    required this.name,
    required this.format,
    required this.status,
    this.startDate,
    this.endDate,
    this.entryFee,
    this.prizePool,
  });

  factory TournamentDetailModel.fromJson(Map<String, dynamic> json) {
    return TournamentDetailModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      format: json['format'] ?? '',
      status: json['status'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      entryFee: json['entryFee']?.toDouble(),
      prizePool: json['prizePool']?.toDouble(),
    );
  }
}

class MatchModel {
  final int id;
  final int? tournamentId;
  final String? roundName;
  final String? date;
  final String? startTime;
  final String? team1Player1Id;
  final String? team1Player1Name;
  final String? team2Player1Id;
  final String? team2Player1Name;
  final int? score1;
  final int? score2;
  final String? winningSide;
  final String? status;

  MatchModel({
    required this.id,
    this.tournamentId,
    this.roundName,
    this.date,
    this.startTime,
    this.team1Player1Id,
    this.team1Player1Name,
    this.team2Player1Id,
    this.team2Player1Name,
    this.score1,
    this.score2,
    this.winningSide,
    this.status,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? 0,
      tournamentId: json['tournamentId'],
      roundName: json['roundName'],
      date: json['date'],
      startTime: json['startTime'],
      team1Player1Id: json['team1_Player1Id'] ?? json['team1Player1Id'],
      team1Player1Name: json['team1Player1Name'],
      team2Player1Id: json['team2_Player1Id'] ?? json['team2Player1Id'],
      team2Player1Name: json['team2Player1Name'],
      score1: json['score1'],
      score2: json['score2'],
      winningSide: json['winningSide'],
      status: json['status'],
    );
  }
}
