import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/queue_status.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'http://localhost/exequeue/backend/api';

  final http.Client _client;

  Future<QueueStatusData> fetchQueueStatus({
    String studentName = 'Juan Dela Cruz',
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/queue_status.php?student_name=${Uri.encodeComponent(studentName)}',
      );
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return QueueStatusData.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    return QueueStatusData.demo();
  }

  Future<LiveBoardData> fetchLiveBoard() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/current_queue.php'),
      );

      if (response.statusCode == 200) {
        return LiveBoardData.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return LiveBoardData.demo();
  }

  Future<String> joinQueueFromQr(
    String qrPayload, {
    String studentName = 'Juan Dela Cruz',
    String transactionType = 'Tuition Payment',
    bool manual = false,
  }) async {
    final requestBody = <String, dynamic>{
      'qr_token': qrPayload,
      'student_name': studentName,
      'transaction_type': transactionType,
      'entry_mode': manual ? 'MANUAL' : 'QR',
    };

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/join_queue.php'),
        headers: const <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        return payload['queue_number'] as String? ?? 'A021';
      }
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    return 'A021';
  }

  void dispose() {
    _client.close();
  }
}
