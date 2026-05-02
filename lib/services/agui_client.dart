import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Touch envelope — matches Python TouchEnvelope dataclass.
class TouchEnvelope {
  final String id;
  final String format;
  final String emotionalTemperature;
  final Map<String, dynamic> payload;
  final String timestamp;

  TouchEnvelope({
    required this.id,
    required this.format,
    required this.emotionalTemperature,
    required this.payload,
    required this.timestamp,
  });

  factory TouchEnvelope.fromJson(Map<String, dynamic> json) {
    return TouchEnvelope(
      id: json['id'] ?? '',
      format: json['format'] ?? 'status',
      emotionalTemperature: json['emotional_temperature'] ?? 'neutral',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }

  String get headline => payload['headline'] ?? '';
  String get body => payload['body'] ?? '';
  String? get audioUrl => payload['audio_url'];
}

/// AG-UI Client — persistent SSE + HTTP REST to ThinkPad.
class AguiClient extends ChangeNotifier {
  String _host = 'localhost';
  int _port = 8432;
  bool _connected = false;
  String _mode = 'heart';

  final List<TouchEnvelope> _cards = [];
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _a2uiWidgets = [];

  // State
  bool get connected => _connected;
  String get mode => _mode;
  List<TouchEnvelope> get cards => List.unmodifiable(_cards);
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  List<Map<String, dynamic>> get a2uiWidgets => List.unmodifiable(_a2uiWidgets);

  String get serverUrl => 'http://$_host:$_port';

  // ── SSE Stream ──

  StreamController<TouchEnvelope>? _cardController;
  StreamSubscription? _sseSubscription;

  Stream<TouchEnvelope> get cardStream {
    _cardController ??= StreamController.broadcast();
    return _cardController!.stream;
  }

  void connect(String host, int port) {
    _host = host;
    _port = port;
    _startSSE();
    _checkHealth();
  }

  void disconnect() {
    _sseSubscription?.cancel();
    _connected = false;
    notifyListeners();
  }

  void _startSSE() async {
    final url = Uri.parse('$serverUrl/stream');
    try {
      final request = http.Request('GET', url);
      final response = await http.Client().send(request);

      _connected = true;
      notifyListeners();

      _sseSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '♥') return; // heartbeat
            try {
              final json = jsonDecode(data);
              final card = TouchEnvelope.fromJson(json);
              _cards.insert(0, card);
              if (_cards.length > 100) _cards.removeLast();
              _cardController?.add(card);
              notifyListeners();
            } catch (_) {}
          }
        },
        onError: (e) {
          _connected = false;
          notifyListeners();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _connected = false;
      notifyListeners();
    }
  }

  void _checkHealth() async {
    try {
      final resp = await http.get(Uri.parse('$serverUrl/health'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _mode = data['mode'] ?? 'heart';
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── AG-UI Run (POST) ──

  Future<String> sendMessage(String content) async {
    _messages.add({'role': 'user', 'content': content});

    final body = jsonEncode({
      'messages': _messages,
      'runId': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    try {
      final resp = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode == 200) {
        final text = await _parseSSEOneShot(resp.body);
        _messages.add({'role': 'assistant', 'content': text});
        notifyListeners();
        return text;
      } else {
        final error = 'Error: ${resp.statusCode}';
        _messages.add({'role': 'assistant', 'content': error});
        notifyListeners();
        return error;
      }
    } catch (e) {
      final error = 'Connection failed: $e';
      _messages.add({'role': 'assistant', 'content': error});
      notifyListeners();
      return error;
    }
  }

  Future<String> _parseSSEOneShot(String body) async {
    final buffer = StringBuffer();
    _a2uiWidgets.clear(); // reset widgets for this response
    for (final line in body.split('\n')) {
      if (line.startsWith('data: ')) {
        try {
          final json = jsonDecode(line.substring(6));
          if (json['type'] == 'TEXT_MESSAGE_CONTENT') {
            buffer.write(json['delta'] ?? '');
          } else if (json['type'] == 'A2UI_WIDGET') {
            _a2uiWidgets.add(Map<String, dynamic>.from(json));
          }
        } catch (_) {}
      }
    }
    return buffer.toString();
  }

  // ── Mode Toggle ──

  Future<void> setMode(String mode) async {
    try {
      await http.post(Uri.parse('$serverUrl/mode/$mode'));
      _mode = mode;
      notifyListeners();
    } catch (_) {}
  }

  // ── Decisions ──

  Future<void> decide(String id, String choice) async {
    try {
      await http.post(Uri.parse('$serverUrl/decide/$id/$choice'));
      await fetchDecideQueue();
    } catch (_) {}
  }

  List<Map<String, dynamic>> _decideItems = [];
  List<Map<String, dynamic>> get decideItems => _decideItems;

  Future<void> fetchDecideQueue() async {
    try {
      final resp = await http.get(Uri.parse('$serverUrl/decide/queue'));
      final data = jsonDecode(resp.body);
      _decideItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  // ── Agents ──

  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> get agents => _agents;

  Future<void> fetchAgentStatus() async {
    try {
      final resp = await http.get(Uri.parse('$serverUrl/agents/status'));
      final data = jsonDecode(resp.body);
      _agents = List<Map<String, dynamic>>.from(data['agents'] ?? []);
      notifyListeners();
    } catch (_) {}
  }
}
