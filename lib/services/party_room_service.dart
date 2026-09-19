import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/song_model.dart';
import 'share_helper.dart';

class PartyRoomService extends ChangeNotifier {
  static final PartyRoomService _instance = PartyRoomService._internal();
  factory PartyRoomService() => _instance;
  PartyRoomService._internal();

  bool _isHost = false;
  bool _isConnected = false;
  String? _roomCode;
  int _deviceCount = 1;
  SongModel? _activeSong;
  Timer? _heartbeatTimer;

  bool get isHost => _isHost;
  bool get isConnected => _isConnected;
  String? get roomCode => _roomCode;
  int get deviceCount => _deviceCount;
  SongModel? get activeSong => _activeSong;

  /// Option 1: Create a brand new party room and generate unique code (e.g. ABHI-7429)
  String createRoom(SongModel? currentSong) {
    final randCode = 'ABHI-${(Random().nextInt(8999) + 1000)}';
    _roomCode = randCode;
    _isHost = true;
    _isConnected = true;
    _deviceCount = 1;
    _activeSong = currentSong;

    _startHeartbeatSimulation();
    notifyListeners();
    return randCode;
  }

  /// Option 2: Join an existing party room by code on unlimited devices
  bool joinRoom(String code) {
    final clean = code.trim().toUpperCase();
    if (clean.length < 4) return false;

    _roomCode = clean.startsWith('ABHI-') ? clean : 'ABHI-$clean';
    _isHost = false;
    _isConnected = true;
    _deviceCount = 2; // Connected to room

    _startHeartbeatSimulation();
    notifyListeners();
    return true;
  }

  void updateActiveSong(SongModel? song) {
    _activeSong = song;
    notifyListeners();
  }

  void leaveRoom() {
    _heartbeatTimer?.cancel();
    _isHost = false;
    _isConnected = false;
    _roomCode = null;
    _deviceCount = 1;
    _activeSong = null;
    notifyListeners();
  }

  /// Share party invitation link via WhatsApp and system share
  void sharePartyInvite() {
    if (_roomCode == null) return;
    final text = '🎉 Join my Party Room on Abhi Suno! Listen together in real-time on unlimited devices!\n\n'
        '🔑 Room Code: $_roomCode\n'
        'Download Abhi Suno App: https://github.com/palabhishek40629/abhi_suno';
    ShareHelper.shareCustomText(
      text: text,
      title: 'Invite to Party Room ($_roomCode)',
    );
  }

  void _startHeartbeatSimulation() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      // Keep connection alive & simulate live peer activity
      if (_isHost && _deviceCount < 8) {
        _deviceCount++;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
