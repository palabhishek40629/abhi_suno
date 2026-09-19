import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import 'audio_handler.dart';
import 'share_helper.dart';

class PartyRoomService extends ChangeNotifier {
  static final PartyRoomService _instance = PartyRoomService._internal();
  factory PartyRoomService() => _instance;
  PartyRoomService._internal() {
    _myDeviceId = 'dev_${Random().nextInt(899999) + 100000}';
  }

  late final String _myDeviceId;
  AbhiAudioHandler? audioHandler;

  bool _isHost = false;
  bool _isConnected = false;
  String? _roomCode;
  String? _currentTopic;
  int _deviceCount = 1;
  SongModel? _activeSong;
  bool _isSyncing = false;

  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  WebSocket? _webSocket;
  http.Client? _streamClient;
  StreamSubscription? _streamSubscription;
  final Set<String> _knownPeers = {};

  bool get isHost => _isHost;
  bool get isConnected => _isConnected;
  String? get roomCode => _roomCode;
  int get deviceCount => max(_deviceCount, _knownPeers.length);
  SongModel? get activeSong => _activeSong;

  String _cleanTopic(String code) {
    final clean = code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    return 'abhisuno_party_$clean';
  }

  /// Option 1: Create a brand new party room and generate unique code (e.g. ABHI-7429)
  String createRoom(SongModel? currentSong) {
    leaveRoom(); // clean any prior session

    final randCode = 'ABHI-${(Random().nextInt(8999) + 1000)}';
    _roomCode = randCode;
    _currentTopic = _cleanTopic(randCode);
    _isHost = true;
    _isConnected = true;
    _knownPeers.clear();
    _knownPeers.add(_myDeviceId);
    _deviceCount = 1;
    _activeSong = currentSong;

    _connectToTopic(_currentTopic!);
    _startHeartbeat(isHost: true);

    // Broadcast host initial state
    if (currentSong != null) {
      _broadcastEvent({
        'event': 'host_ready',
        'senderId': _myDeviceId,
        'song': currentSong.toJson(),
        'isPlaying': audioHandler?.isPlaying ?? false,
      });
    }

    notifyListeners();
    return randCode;
  }

  /// Option 2: Join an existing party room by code on unlimited devices
  bool joinRoom(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.length < 4) return false;

    leaveRoom(); // clean prior session

    _roomCode = clean.startsWith('ABHI-') ? clean : 'ABHI-$clean';
    _currentTopic = _cleanTopic(_roomCode!);
    _isHost = false;
    _isConnected = true;
    _knownPeers.clear();
    _knownPeers.add(_myDeviceId);
    _deviceCount = 2; // At least host + self

    _connectToTopic(_currentTopic!);
    _startHeartbeat(isHost: false);

    // Announce join to host and ask for current state
    _broadcastEvent({
      'event': 'join',
      'senderId': _myDeviceId,
    });

    // Also immediately fetch the most recent message from topic history
    _fetchLatestState();

    notifyListeners();
    return true;
  }

  /// Broadcast song change to all devices in the room
  void onLocalSongChanged(SongModel song) {
    if (!_isConnected || _isSyncing) return;
    _activeSong = song;
    notifyListeners();

    _broadcastEvent({
      'event': 'play',
      'senderId': _myDeviceId,
      'song': song.toJson(),
      'positionMs': 0,
    });
  }

  /// Broadcast pause event
  void onLocalPause() {
    if (!_isConnected || _isSyncing) return;
    _broadcastEvent({
      'event': 'pause',
      'senderId': _myDeviceId,
    });
  }

  /// Broadcast resume event
  void onLocalResume() {
    if (!_isConnected || _isSyncing) return;
    _broadcastEvent({
      'event': 'resume',
      'senderId': _myDeviceId,
    });
  }

  void leaveRoom() {
    if (_isConnected && _currentTopic != null) {
      _broadcastEvent({
        'event': 'leave',
        'senderId': _myDeviceId,
      });
    }

    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _streamSubscription?.cancel();
    _webSocket?.close();
    _webSocket = null;
    _streamClient?.close();
    _streamClient = null;

    _isHost = false;
    _isConnected = false;
    _roomCode = null;
    _currentTopic = null;
    _deviceCount = 1;
    _activeSong = null;
    _knownPeers.clear();
    notifyListeners();
  }

  /// Share party invitation link via WhatsApp and system share
  void sharePartyInvite() {
    if (_roomCode == null) return;
    final text = '🎉 Join my Party Room on Abhi Suno! Listen together in real-time on unlimited devices!\n\n'
        '🔑 Room Code: $_roomCode\n\n'
        '📲 Download Abhi Suno App: https://github.com/palabhishek40629/abhi_suno';
    ShareHelper.shareCustomText(
      text: text,
      title: 'Invite to Party Room ($_roomCode)',
    );
  }

  Future<void> _broadcastEvent(Map<String, dynamic> data) async {
    if (_currentTopic == null) return;
    try {
      final uri = Uri.parse('https://ntfy.sh/$_currentTopic');
      await http.post(
        uri,
        body: jsonEncode(data),
        headers: {
          'Title': 'PartySync',
          'Priority': 'urgent',
        },
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> _fetchLatestState() async {
    if (_currentTopic == null) return;
    try {
      final uri = Uri.parse('https://ntfy.sh/$_currentTopic/json?poll=1');
      final resp = await http.get(uri).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final lines = const LineSplitter().convert(resp.body);
        for (final line in lines.reversed) {
          if (line.trim().isEmpty) continue;
          try {
            final outer = jsonDecode(line);
            if (outer is Map && outer.containsKey('message')) {
              final payload = jsonDecode(outer['message'] as String);
              if (payload is Map<String, dynamic>) {
                _handleIncomingEvent(payload);
                break;
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _connectToTopic(String topic) async {
    _streamSubscription?.cancel();
    _webSocket?.close();
    _webSocket = null;
    _streamClient?.close();
    _streamClient = null;

    // 1. High-speed WebSocket connection first
    try {
      final wsUri = Uri.parse('wss://ntfy.sh/$topic/ws');
      _webSocket = await WebSocket.connect(wsUri.toString()).timeout(const Duration(seconds: 5));
      _streamSubscription = _webSocket!.listen(
        (data) {
          if (data is String && data.trim().isNotEmpty) {
            try {
              final outer = jsonDecode(data);
              if (outer is Map && outer.containsKey('message')) {
                final msg = outer['message'] as String;
                final payload = jsonDecode(msg);
                if (payload is Map<String, dynamic>) {
                  _handleIncomingEvent(payload);
                }
              }
            } catch (_) {}
          }
        },
        onError: (_) => _reconnectStreamLater(topic),
        onDone: () => _reconnectStreamLater(topic),
        cancelOnError: true,
      );
      return;
    } catch (_) {
      // WebSocket failed, fallback to HTTP streaming
    }

    // 2. Fallback: HTTP streaming SSE
    _streamClient = http.Client();
    try {
      final request = http.Request('GET', Uri.parse('https://ntfy.sh/$topic/json'));
      final response = await _streamClient!.send(request);

      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isEmpty) return;
          try {
            final outer = jsonDecode(line);
            if (outer is Map && outer.containsKey('message')) {
              final msg = outer['message'] as String;
              final payload = jsonDecode(msg);
              if (payload is Map<String, dynamic>) {
                _handleIncomingEvent(payload);
              }
            }
          } catch (_) {}
        },
        onError: (_) {
          _reconnectStreamLater(topic);
        },
        onDone: () {
          _reconnectStreamLater(topic);
        },
        cancelOnError: true,
      );
    } catch (_) {
      _reconnectStreamLater(topic);
    }
  }

  void _reconnectStreamLater(String topic) {
    if (!_isConnected || _currentTopic != topic) return;
    Future.delayed(const Duration(seconds: 4), () {
      if (_isConnected && _currentTopic == topic) {
        _connectToTopic(topic);
      }
    });
  }

  void _handleIncomingEvent(Map<String, dynamic> event) {
    final senderId = event['senderId']?.toString();
    if (senderId != null) {
      _knownPeers.add(senderId);
      _deviceCount = max(_deviceCount, _knownPeers.length);
      notifyListeners();
    }

    // Don't echo own events back to player
    if (senderId == _myDeviceId) return;

    final type = event['event']?.toString();

    switch (type) {
      case 'join':
        // If we are host, respond with our current song and state
        if (_isHost && _activeSong != null) {
          _broadcastEvent({
            'event': 'state_sync',
            'senderId': _myDeviceId,
            'song': _activeSong!.toJson(),
            'isPlaying': audioHandler?.isPlaying ?? false,
          });
        }
        break;

      case 'state_sync':
      case 'host_ready':
      case 'play':
        if (event.containsKey('song') && event['song'] is Map) {
          try {
            final songMap = Map<String, dynamic>.from(event['song'] as Map);
            final song = SongModel.fromJson(songMap);
            _activeSong = song;
            notifyListeners();

            if (audioHandler != null && audioHandler?.currentSong?.id != song.id) {
              _isSyncing = true;
              audioHandler?.playSong(song, queue: [song]);
              Future.delayed(const Duration(milliseconds: 600), () {
                _isSyncing = false;
              });
            }
          } catch (_) {}
        }
        break;

      case 'pause':
        if (audioHandler != null && (audioHandler?.isPlaying ?? false)) {
          _isSyncing = true;
          audioHandler?.pause();
          Future.delayed(const Duration(milliseconds: 600), () {
            _isSyncing = false;
          });
        }
        break;

      case 'resume':
        if (audioHandler != null && !(audioHandler?.isPlaying ?? true)) {
          _isSyncing = true;
          audioHandler?.play();
          Future.delayed(const Duration(milliseconds: 600), () {
            _isSyncing = false;
          });
        }
        break;

      case 'leave':
        if (senderId != null) {
          _knownPeers.remove(senderId);
          _deviceCount = max(1, _knownPeers.length);
          notifyListeners();
        }
        break;

      case 'heartbeat':
        if (event.containsKey('count')) {
          final count = int.tryParse(event['count'].toString()) ?? 1;
          _deviceCount = max(_deviceCount, count);
          notifyListeners();
        }
        break;
    }
  }

  void _startHeartbeat({required bool isHost}) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      _broadcastEvent({
        'event': 'heartbeat',
        'senderId': _myDeviceId,
        'count': max(_deviceCount, _knownPeers.length),
        if (isHost && _activeSong != null) 'song': _activeSong!.toJson(),
      });
    });

    // Also periodic poll every 12s as a fallback sync safeguard
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      _fetchLatestState();
    });
  }

  @override
  void dispose() {
    leaveRoom();
    super.dispose();
  }
}
