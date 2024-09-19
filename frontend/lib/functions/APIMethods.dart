import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class APIMethods {
  static const TOA_URL = 'https://theorangealliance.org/api';
  static Future getEvents() async {
    final respons = await http.get(
      Uri.parse('$TOA_URL/event'),
      headers: {
        'X-TOA-Key': dotenv.env['TOA_KEY']!,
        'X-Application-Origin': 'TeamTrack',
        'Content-Type': 'application/json',
      },
    );
    return respons;
  }

  static Future getTeams(String id) async {
    final respons = await http.get(
      Uri.parse('$TOA_URL/event/$id/teams'),
      headers: {
        'X-TOA-Key': dotenv.env['TOA_KEY']!,
        'X-Application-Origin': 'TeamTrack',
        'Content-Type': 'application/json',
      },
    );
    //  print(respons.toString());
    return respons;
  }

  static Future<dynamic> getMatches(String id) {
    return http.get(
      Uri.parse('$TOA_URL/event/$id/matches'),
      headers: {
        'X-TOA-Key': dotenv.env['TOA_KEY']!,
        'X-Application-Origin': 'TeamTrack',
        'Content-Type': 'application/json',
      },
    );
    //  print(respons.toString());
  }

  static Future getInfo(String id) async {
    final respons = await http.get(
      Uri.parse('$TOA_URL/event/$id'),
      headers: {
        'X-TOA-Key': dotenv.env['TOA_KEY']!,
        'X-Application-Origin': 'TeamTrack',
        'Content-Type': 'application/json',
      },
    );
    //  print(respons.toString());
    return respons;
  }
}
