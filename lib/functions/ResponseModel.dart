import 'dart:convert';

import 'package:flutter/foundation.dart';

class ResponseModel {
  final String id;
  final String object;
  final String model;
  final List choices;

  ResponseModel(
      this.id,
      this.object,
      this.model,
      this.choices,
      );

  ResponseModel copyWith({
    String? id,
    String? object,
    String? model,
    List? choices,
  }) {
    return ResponseModel(
      id ?? this.id,
      object ?? this.object,
      model ?? this.model,
      choices ?? this.choices,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'object': object,
      'model': model,
      'choices': choices,
    };
  }

  factory ResponseModel.fromMap(Map<String, dynamic> map) {
    return ResponseModel(
      map['id'] as String,
      map['object'] as String,
      map['model'] as String,
      List.from(
        (map['choices'] as List),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ResponseModel.fromJson(String source) =>
      ResponseModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ResponseModel(id: $id, object: $object, model: $model, choices: $choices)';
  }

  @override
  bool operator ==(covariant ResponseModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.object == object &&
        other.model == model &&
        listEquals(other.choices, choices);
  }

  @override
  int get hashCode {
    return id.hashCode ^ object.hashCode ^ model.hashCode ^ choices.hashCode;
  }
}