import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

void main() async {
  final seasonKey = '2021';
  final url = 'https://theorangealliance.org/api';

  await dotenv.load(fileName: '.env');

  final respon = await http.get(
    Uri.parse('$url/seasons'),
    headers: {
      'X-TOA-Key': dotenv.env['TOA_KEY']!,
      'X-Application-Origin': 'TeamTrack',
      'Content-Type': 'application/json',
    },
  );
  final bo = (json.decode(respon.body) as List);

  final response = await http.get(
    Uri.parse('$url/event'),
    headers: {
      'X-TOA-Key': dotenv.env['TOA_KEY']!,
      'X-Application-Origin': 'TeamTrack',
      'Content-Type': 'application/json',
    },
  );
  final body = (json.decode(response.body) as List)
      .where((element) => element['state_prov'] == 'CA')
      .toList();

  final respons = await http.get(
    Uri.parse('$url/team/8802'),
    headers: {
      'X-TOA-Key': dotenv.env['TOA_KEY']!,
      'X-Application-Origin': 'TeamTrack',
      'Content-Type': 'application/json',
    },
  );
  final bod = (json.decode(respons.body) as List);
}
