import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constants.dart';
import 'auth_service.dart';

class SpotifyService extends ChangeNotifier {
  final AuthService _authService;
  bool _isConnected = false;
  String? _lastSyncedAt;
  List<SpotifyTrack> _tracks = [];
  bool _isLoading = false;

  SpotifyService(this._authService) {
    _checkStatus();
  }

  bool get isConnected => _isConnected;
  String? get lastSyncedAt => _lastSyncedAt;
  List<SpotifyTrack> get tracks => _tracks;
  bool get isLoading => _isLoading;

  Future<void> _checkStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.spotifyStatus}'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isConnected = data['connected'] ?? false;
        _lastSyncedAt = data['lastSyncedAt'];
        notifyListeners();
      }
    } catch (e) {
      print('Check Spotify status error: $e');
    }
  }

  Future<String?> getConnectUrl() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.spotifyConnect}'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['authUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('Get Spotify connect URL error: $e');
      return null;
    }
  }

  Future<bool> disconnect() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.spotifyDisconnect}'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        _isConnected = false;
        _lastSyncedAt = null;
        _tracks.clear();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Disconnect Spotify error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> sync() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.spotifySync}'),
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _lastSyncedAt = data['lastSyncedAt'];
        _isLoading = false;
        notifyListeners();
        return data;
      }
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      print('Sync Spotify error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchTracks({int page = 1, int pageSize = 50}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.spotifyTracks}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] ?? data['tracks'] ?? [];
        _tracks = (items as List)
            .map((json) => SpotifyTrack.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Fetch Spotify tracks error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class SpotifyTrack {
  final String id;
  final String spotifyTrackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumArtUrl;
  final String spotifyUri;
  final DateTime playedAt;

  SpotifyTrack({
    required this.id,
    required this.spotifyTrackId,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumArtUrl,
    required this.spotifyUri,
    required this.playedAt,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: json['id'].toString(),
      spotifyTrackId: json['spotifyTrackId'] as String,
      trackName: json['trackName'] as String,
      artistName: json['artistName'] as String,
      albumName: json['albumName'] as String,
      albumArtUrl: json['albumArtUrl'] as String?,
      spotifyUri: json['spotifyUri'] as String,
      playedAt: DateTime.parse(json['playedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotifyTrackId': spotifyTrackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'albumArtUrl': albumArtUrl,
      'spotifyUri': spotifyUri,
      'playedAt': playedAt.toIso8601String(),
    };
  }
}
