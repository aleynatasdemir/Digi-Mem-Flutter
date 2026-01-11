import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Backend URL - Platform bazlı otomatik ayarlama
  // Android Emulator: 10.0.2.2
  // iOS Simulator/Windows/Web: localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5299';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5299';
    }
    // iOS, Windows, macOS, Linux için localhost
    return 'http://localhost:5299';
  }
  
  // Auth Endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  
  // Memory Endpoints
  static const String memories = '/api/memories';
  static const String memoriesStats = '/api/memories/stats';
  
  // User Endpoints
  static const String userProfile = '/api/user/profile';
  
  // Upload Endpoints
  static const String upload = '/api/upload';
  
  // Summaries Endpoints
  static const String summariesWeeks = '/api/summaries/weeks';
  static const String summariesCollageWeekly = '/api/summaries/collage/weekly';
  static const String summariesCollageMonthly = '/api/summaries/collage/monthly';
  
  // Spotify Endpoints
  static const String spotifyStatus = '/api/spotify/status';
  static const String spotifyConnect = '/api/spotify/connect';
  static const String spotifyDisconnect = '/api/spotify/disconnect';
  static const String spotifySync = '/api/spotify/sync';
  static const String spotifyTracks = '/api/spotify/tracks';
}
