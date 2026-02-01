class CourtModel {
  final int id;
  final String name;
  final String? description;
  final double pricePerHour;
  final bool isActive;

  CourtModel({
    required this.id,
    required this.name,
    this.description,
    required this.pricePerHour,
    required this.isActive,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }
}

class BookingModel {
  final int id;
  final String courtName;
  final String memberId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;

  BookingModel({
    required this.id,
    required this.courtName,
    required this.memberId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      courtName: json['courtName'] ?? '',
      memberId: json['memberId'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class TournamentModel {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String format;
  final double entryFee;
  final double prizePool;
  final String status;
  final int participantCount;
  final bool isJoined;

  TournamentModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    required this.participantCount,
    required this.isJoined,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'],
      name: json['name'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      format: json['format'] ?? '',
      entryFee: (json['entryFee'] ?? 0).toDouble(),
      prizePool: (json['prizePool'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      participantCount: json['participantCount'] ?? 0,
      isJoined: json['isJoined'] ?? false,
    );
  }
}

class TournamentParticipantModel {
  final int id;
  final String teamName;
  final String memberName;
  final bool paymentStatus;
  final DateTime registeredDate;

  TournamentParticipantModel({
    required this.id,
    required this.teamName,
    required this.memberName,
    required this.paymentStatus,
    required this.registeredDate,
  });

  factory TournamentParticipantModel.fromJson(Map<String, dynamic> json) {
    return TournamentParticipantModel(
      id: json['id'],
      teamName: json['teamName'] ?? '',
      memberName: json['memberName'] ?? '',
      paymentStatus: json['paymentStatus'] ?? false,
      registeredDate: DateTime.parse(json['registeredDate']),
    );
  }
}
