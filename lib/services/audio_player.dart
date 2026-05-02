import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Audio playback service for MAIBS Companion.
/// Plays TTS audio from the server over HTTP.
class CompanionAudio extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  String? _currentUrl;
  bool _isPlaying = false;

  /// Base URL for audio files (e.g. http://100.64.0.1:8432)
  String _serverBase = 'http://localhost:8432';

  PlayerState get state => _state;
  bool get isPlaying => _isPlaying;
  String? get currentUrl => _currentUrl;

  /// Configure the server URL for audio fetching.
  void configure(String serverBase) {
    _serverBase = serverBase;
  }

  /// Convert a local audio path (from TouchEnvelope.audioUrl) to server URL.
  /// Extracts filename and builds: http://host:8432/audio/filename.wav
  String _toServerUrl(String localPath) {
    final filename = localPath.split('/').last;
    return '$_serverBase/audio/$filename';
  }

  /// Play audio from a local path (as provided by TouchEnvelope.audioUrl).
  Future<void> play(String localPath) async {
    final url = _toServerUrl(localPath);

    // Stop any current playback
    if (_isPlaying) {
      await _player.stop();
    }

    _currentUrl = url;
    _isPlaying = true;
    notifyListeners();

    try {
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('Audio playback error: $e');
      _isPlaying = false;
      _currentUrl = null;
      notifyListeners();
    }
  }

  /// Pause current playback.
  Future<void> pause() async {
    await _player.pause();
    _state = PlayerState.paused;
    notifyListeners();
  }

  /// Resume paused playback.
  Future<void> resume() async {
    await _player.resume();
    _state = PlayerState.playing;
    notifyListeners();
  }

  /// Stop and reset.
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _state = PlayerState.stopped;
    _currentUrl = null;
    notifyListeners();
  }

  /// Seek to a position.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  CompanionAudio() {
    // Listen for state changes
    _player.onPlayerStateChanged.listen((state) {
      _state = state;
      if (state == PlayerState.completed) {
        _isPlaying = false;
        _currentUrl = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
