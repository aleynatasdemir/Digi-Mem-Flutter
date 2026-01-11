import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../utils/api_constants.dart';
import 'auth_service.dart';

class UploadService {
  final AuthService _authService;

  UploadService(this._authService);

  Future<UploadResponse?> uploadFile(File file, String type) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.upload}');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final token = _authService.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add type parameter
      request.fields['type'] = type;

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UploadResponse.fromJson(data);
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<UploadResponse?> uploadImage(File file) async {
    return uploadFile(file, 'photo');
  }

  Future<UploadResponse?> uploadVideo(File file) async {
    return uploadFile(file, 'video');
  }

  Future<UploadResponse?> uploadAudio(File file) async {
    return uploadFile(file, 'audio');
  }
}

class UploadResponse {
  final String fileUrl;
  final String? thumbnailUrl;
  final String fileName;
  final String mimeType;
  final int fileSize;

  UploadResponse({
    required this.fileUrl,
    this.thumbnailUrl,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      fileUrl: json['fileUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
    };
  }
}
