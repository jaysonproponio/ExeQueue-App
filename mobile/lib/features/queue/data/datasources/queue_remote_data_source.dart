import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:exequeue_mobile/core/error/exceptions.dart';
import 'package:exequeue_mobile/core/network/api_config.dart';
import 'package:exequeue_mobile/features/queue/data/models/join_queue_result_model.dart';
import 'package:exequeue_mobile/features/queue/data/models/live_board_model.dart';
import 'package:exequeue_mobile/features/queue/data/models/queue_status_model.dart';

abstract class QueueRemoteDataSource {
  Future<QueueStatusModel> getQueueStatus({
    String? queueNumber,
    String? studentName,
  });

  Future<LiveBoardModel> getLiveBoard();

  Future<JoinQueueResultModel> joinQueue({
    required String qrPayload,
    required String studentName,
    required String transactionType,
    required bool manual,
  });
}

class QueueRemoteDataSourceImpl implements QueueRemoteDataSource {
  QueueRemoteDataSourceImpl({required http.Client client}) : _client = client;

  final http.Client _client;

  String get _baseUrl => ApiConfig.baseUrl;

  @override
  Future<QueueStatusModel> getQueueStatus({
    String? queueNumber,
    String? studentName,
  }) async {
    final queryParameters = <String, String>{
      if (queueNumber != null && queueNumber.trim().isNotEmpty)
        'queue_number': queueNumber.trim(),
      if (studentName != null &&
          studentName.trim().isNotEmpty &&
          (queueNumber == null || queueNumber.trim().isEmpty))
        'student_name': studentName.trim(),
    };

    if (queryParameters.isEmpty) {
      throw const ServerException(
        'Queue status request requires a queue number or student name.',
      );
    }

    final uri = Uri.parse(
      '$_baseUrl/queue_status.php',
    ).replace(
      queryParameters: queryParameters,
    );
    final response = await _client
        .get(uri)
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ServerException(
        'Queue status request failed with ${response.statusCode}.',
      );
    }

    return QueueStatusModel.fromJson(_decodeMap(response.body));
  }

  @override
  Future<LiveBoardModel> getLiveBoard() async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/current_queue.php'),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw ServerException(
        'Live board request failed with ${response.statusCode}.',
      );
    }

    return LiveBoardModel.fromJson(_decodeMap(response.body));
  }

  @override
  Future<JoinQueueResultModel> joinQueue({
    required String qrPayload,
    required String studentName,
    required String transactionType,
    required bool manual,
  }) async {
    final requestBody = <String, dynamic>{
      'qr_token': qrPayload,
      'student_name': studentName,
      'transaction_type': transactionType,
      'entry_mode': manual ? 'MANUAL' : 'QR',
    };

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/join_queue.php'),
          headers: const <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException(
        'Join queue request failed with ${response.statusCode}.',
      );
    }

    return JoinQueueResultModel.fromJson(_decodeMap(response.body));
  }

  Map<String, dynamic> _decodeMap(String source) {
    final dynamic decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const ParsingException();
    }

    return Map<String, dynamic>.from(decoded as Map<dynamic, dynamic>);
  }
}
