import 'dart:convert';
import 'package:http/http.dart' as http;

class LabAnalyzerService {
  LabAnalyzerService({this.baseUrl = 'http://localhost:8000'});

  final String baseUrl;

  Future<Map<String, dynamic>> analyze(Map<String, dynamic> fields) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': fields}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Analyze failed: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }
}






