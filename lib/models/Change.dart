
import 'package:cloud_firestore/cloud_firestore.dart';

class Change {
  String title;
  String? description;
  Timestamp startDate;
  Timestamp? endDate;
  String id;
  Change({
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.id,
  });
  Change.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        description = json['description'],
        startDate = Timestamp(json['startSeconds'], json['startNanoSeconds']),
        endDate = Timestamp(json['endSeconds'], json['endNanoSeconds']),
        id = json['id'];
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'startSeconds': startDate.seconds,
        'startNanoSeconds': startDate.nanoseconds,
        'endSeconds': endDate?.seconds,
        'endNanoSeconds': endDate?.nanoseconds,
        'id': id,
      };
}