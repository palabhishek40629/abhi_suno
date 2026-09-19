import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_handler.dart';
import '../services/language_service.dart';
import '../services/party_room_service.dart';
import '../services/theme_service.dart';
import 'tactile_3d_wrapper.dart';

class PartyRoomCard extends StatefulWidget {
  final AbhiAudioHandler? audioHandler;

  const PartyRoomCard({Key? key, this.audioHandler}) : super(key: key);

  @override
  State<PartyRoomCard> createState() => _PartyRoomCardState();
}

class _PartyRoomCardState extends State<PartyRoomCard> with SingleTickerProviderStateMixin {
  final PartyRoomService _partyService = PartyRoomService();
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  final TextEditingController _joinCodeController = TextEditingController();

  bool _isExpanded = true;
  bool _showJoinInput = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  void _handleCreateRoom() {
    final song = widget.audioHandler?.currentSong;
    final code = _partyService.createRoom(song);
    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFFFF007F),
          content: Text(
            _lang.isHindi
                ? '🎉 पार्टी रूम बन गया! कोड: $code'
                : '🎉 Party Room Created! Code: $code',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    }
  }

  void _handleJoinRoom() {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;

    final success = _partyService.joinRoom(code);
    HapticFeedback.mediumImpact();

    if (mounted) {
      if (success) {
        setState(() {
          _showJoinInput = false;
          _joinCodeController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E676),
            content: Text(
              _lang.isHindi
                  ? '✅ पार्टी रूम से जुड़ गए! असीमित डिवाइस कनेक्टेड।'
                  : '✅ Connected to Party Room! Unlimited devices synced.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              _lang.isHindi ? 'कृपया वैध 4-8 अंकों का कोड दर्ज करें' : 'Please enter a valid room code',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_partyService, _theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final cardColor = _theme.cardBg;
        final isHindi = _lang.isHindi;

        final isConnected = _partyService.isConnected;
        final roomCode = _partyService.roomCode;
        final isHost = _partyService.isHost;
        final deviceCount = _partyService.deviceCount;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected ? const Color(0xFFFF007F) : Colors.white12,
              width: isConnected ? 1.6 : 1.0,
            ),
            boxShadow: [
              if (isConnected)
                BoxShadow(
                  color: const Color(0xFFFF007F).withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF007F), Color(0xFF7C4DFF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF007F).withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.speaker_group_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isHindi ? 'पार्टी रूम ("सुनो साथ में")' : 'Party Room (Listen Together)',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isConnected) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E676).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF00E676)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF00E676),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isHindi ? 'लाइव' : 'LIVE',
                                          style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isConnected
                                  ? (isHost
                                      ? (isHindi ? 'होस्ट • $deviceCount डिवाइस कनेक्टेड' : 'Host • $deviceCount Devices Connected')
                                      : (isHindi ? 'कनेक्टेड • $deviceCount डिवाइस' : 'Connected • $deviceCount Devices'))
                                  : (isHindi ? 'असीमित डिवाइस पर एक साथ गाना बजाएं' : 'Sync music playback across unlimited devices'),
                              style: TextStyle(
                                color: isConnected ? const Color(0xFFFF007F) : subtextColor,
                                fontSize: 12,
                                fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: subtextColor,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Content
              if (_isExpanded) ...[
                const Divider(height: 1, color: Colors.white10),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (isConnected) ...[
                        // Active Room Info Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF007F).withOpacity(0.18),
                                const Color(0xFF7C4DFF).withOpacity(0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFF007F).withOpacity(0.4)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHindi ? 'पार्टी रूम कोड' : 'PARTY ROOM CODE',
                                        style: const TextStyle(
                                          color: Color(0xFFFF007F),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        roomCode ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      // Copy Code Button
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 22),
                                        tooltip: 'Copy Code',
                                        onPressed: () {
                                          if (roomCode != null) {
                                            Clipboard.setData(ClipboardData(text: roomCode));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                duration: const Duration(seconds: 1),
                                                content: Text(isHindi ? 'कोड कॉपी हो गया!' : 'Code copied!'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      // WhatsApp Invite Button
                                      IconButton(
                                        icon: const Icon(Icons.share_rounded, color: Color(0xFF00E676), size: 22),
                                        tooltip: 'WhatsApp Invite',
                                        onPressed: _partyService.sharePartyInvite,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.devices_rounded, color: Color(0xFF00E5FF), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    isHindi
                                        ? '$deviceCount डिवाइस साथ सुन रहे हैं (असीमित जुड़ सकते हैं)'
                                        : '$deviceCount devices listening together (Unlimited)',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Disconnect / Leave Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 18),
                                  label: Text(
                                    isHost
                                        ? (isHindi ? 'पार्टी समाप्त करें' : 'End Party Room')
                                        : (isHindi ? 'पार्टी छोड़ें' : 'Leave Party Room'),
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _partyService.leaveRoom(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // OPTION 1 & OPTION 2 BUTTONS
                        Row(
                          children: [
                            // OPTION 1: GENERATE CODE / CREATE ROOM
                            Expanded(
                              child: Tactile3DWrapper(
                                onTap: _handleCreateRoom,
                                scaleElevation: 1.08,
                                borderRadius: BorderRadius.circular(16),
                                glowColor: const Color(0xFFFF007F),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF007F), Color(0xFFFF5252)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF007F).withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 28),
                                      const SizedBox(height: 6),
                                      Text(
                                        isHindi ? 'पार्टी बनाएं' : 'Create Room',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        isHindi ? '(कोड जनरेट करें)' : '(Generate Code)',
                                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // OPTION 2: JOIN ROOM
                            Expanded(
                              child: Tactile3DWrapper(
                                onTap: () => setState(() => _showJoinInput = !_showJoinInput),
                                scaleElevation: 1.08,
                                borderRadius: BorderRadius.circular(16),
                                glowColor: const Color(0xFF00E5FF),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.login_rounded, color: Colors.black, size: 28),
                                      const SizedBox(height: 6),
                                      Text(
                                        isHindi ? 'रूम से जुड़ें' : 'Join Room',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        isHindi ? '(कोड डालें)' : '(Enter Code)',
                                        style: const TextStyle(color: Colors.black54, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Input field when user taps "Join Room"
                        if (_showJoinInput) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi ? 'पार्टी रूम कोड दर्ज करें:' : 'Enter Party Room Code:',
                                  style: TextStyle(color: subtextColor, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _joinCodeController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                        textCapitalization: TextCapitalization.characters,
                                        decoration: InputDecoration(
                                          hintText: 'e.g. ABHI-8492',
                                          hintStyle: TextStyle(color: subtextColor.withOpacity(0.4), fontSize: 14),
                                          filled: true,
                                          fillColor: Colors.black26,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00E5FF),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      onPressed: _handleJoinRoom,
                                      child: Text(
                                        isHindi ? 'जुड़ें' : 'Connect',
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
