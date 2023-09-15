import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teamtrack/functions/Functions.dart';
import 'package:teamtrack/functions/Extensions.dart';

import 'GameModel.dart';

class GPTModel {
  Team team;

  GPTModel({
    required this.team
  });

  String returnModelFeedback() {
    return "GPT";
  }
}
