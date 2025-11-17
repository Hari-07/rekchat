import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

import 'view_model.dart';

enum DataStates { empty, fetchingResponse, executingCode, receivedData, error }

class AppStateViewModel extends ViewModel {
  final TextEditingController queryTextFieldController =
      TextEditingController();

  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> uploadedFiles = [];

  Iterable<String> get columns => data.firstOrNull?.keys ?? [];

  bool isUploadingFiles = false;
  DataStates dataState = DataStates.empty;

  void uploadFiles(FilePickerResult result) async {
    final dio = Dio();
    final formData = FormData();

    for (PlatformFile file in result.files) {
      if (file.path != null) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(file.path!, filename: file.name),
          ),
        );
      }
    }

    isUploadingFiles = true;
    notifyListeners();

    try {
      final response = await dio.post(
        'http://127.0.0.1:8001/upload-file',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: (sent, total) {
          print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      // Store the file information returned by the backend
      if (response.data != null) {
        uploadedFiles = List<Map<String, dynamic>>.from(response.data);
        isUploadingFiles = false;
        notifyListeners();
      }
    } catch (e) {
      isUploadingFiles = false;
      print('Upload error: $e');
    }
  }

  void submitQuery() async {
    final query = queryTextFieldController.text;
    final dio = Dio();
    dataState = DataStates.fetchingResponse;
    notifyListeners();

    try {
      final response = await dio.post<ResponseBody>(
        'http://127.0.0.1:8001/submit-query-stream?query=$query',
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data!.stream;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonData = line.substring(6).trim();
            if (jsonData.isNotEmpty) {
              final eventData = jsonDecode(jsonData) as Map<String, dynamic>;

              // TODO: Acutally parse the eventData
              if (eventData['type'] == 'status') {
                dataState = DataStates.executingCode;
                notifyListeners();
              } else if (eventData['type'] == 'complete') {
                _handleFinalResult(eventData);
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      print(e);
      dataState = DataStates.empty;
    }
  }

  void _handleFinalResult(Map<String, dynamic> eventData) {
    if (eventData['success'] == true) {
      dataState = DataStates.receivedData;
      data = [];
      final resultData = eventData['result'];

      if (resultData is List) {
        for (final ele in resultData) {
          final typedEle = ele as Map<String, dynamic>;
          data.add(typedEle);
        }
      } else {
        data = [resultData as Map<String, dynamic>];
      }
    } else {
      print('Error: ${eventData['explanation']}');
      dataState = DataStates.empty;
      data = [];
    }

    notifyListeners();
  }
}
