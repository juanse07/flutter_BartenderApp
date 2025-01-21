class Quotation {
  final String id;
  final String contactName;
  final String eventType;
  final DateTime eventDate;
  final String eventTime;
  final String guestCount;
  final DateTime createdAt;

  Quotation({
    required this.id,
    required this.contactName,
    required this.eventType,
    required this.eventDate,
    required this.eventTime,
    required this.guestCount,
    required this.createdAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['_id'],
      contactName: json['contactName'],
      eventType: json['eventType'],
      eventDate: DateTime.parse(json['eventDate']),
      eventTime: json['eventTime'],
      guestCount: json['guestCount'].toString(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
