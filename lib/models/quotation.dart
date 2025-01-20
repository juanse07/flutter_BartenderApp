class Quotation {
  final String id;
  final String conntactName;
  final String companyName;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final int numberOfGuests;
  final List<String> servicesRequested;
  final DateTime createdAt;

  Quotation({
    required this.id,
    required this.contactName,
    required this.companyName,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.numberOfGuests,
    required this.servicesRequested,
    required this.createdAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['_id'],
      contactName: json['contactName'],
      companyName: json['companyName'],
      eventDate: DateTime.parse(json['eventDate']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      numberOfGuests: json['numberOfGuests'],
      servicesRequested: List<String>.from(json['servicesRequested']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}