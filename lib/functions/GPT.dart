import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> sendChatGPTRequest(String input) async {
  final String apiUrl = 'https://api.openai.com/v1/completions'; // Replace with the actual API endpoint

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  final Map<String, String> body = {
    'messages': json.encode([
      {'role': 'system', 'content': 'You are a helpful assistant.'},
      {'role': 'user', 'content': input},
    ]),
  };

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: headers,
    body: json.encode(body),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> messages = data['choices'][0]['message']['content'];
    return messages.join('\n');
  } else {
    throw Exception('Failed to communicate with the ChatGPT API');
  }
}
