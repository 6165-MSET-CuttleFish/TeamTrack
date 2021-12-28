import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/functions/Extensions.dart';

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
        startDate = getTimestampFromString(json['startDate']),
        endDate = getTimestampFromString(json['endDate']),
        id = json['id'];
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'startDate': startDate.toJson(),
        'endDate': endDate?.toJson(),
        'id': id,
      };
}
