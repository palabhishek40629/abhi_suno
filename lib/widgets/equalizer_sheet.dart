import 'package:flutter/material.dart';
import '../services/audio_handler.dart';

class EqualizerSheet extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const EqualizerSheet({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  double _volume = 1.0;
  double _speed = 1.0;
  double _bass = 0.5;
  String _selectedPreset = 'Normal';

  final List<String> _presets = ['Normal', 'Bass Boost', 'Pop', 'Rock', 'Vocal', 'Club'];

  @override
  void initState() {
    super.initState();
    _volume = widget.audioHandler.player.volume;
    _speed = widget.audioHandler.player.speed;
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset == 'Bass Boost') {
        _bass = 0.9;
        widget.audioHandler.setPitch(0.95);
      } else if (preset == 'Vocal') {
        _bass = 0.3;
        widget.audioHandler.setPitch(1.05);
      } else if (preset == 'Club') {
        _bass = 0.8;
        widget.audioHandler.setPitch(1.0);
      } else {
        _bass = 0.5;
        widget.audioHandler.setPitch(1.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Equalizer & Sound Effects',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Presets Horizontal list
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isSelected = preset == _selectedPreset;
                return ChoiceChip(
                  label: Text(preset),
                  selected: isSelected,
                  selectedColor: const Color(0xFF05D9E8),
                  backgroundColor: Colors.white10,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => _applyPreset(preset),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Bass Boost Slider
          Row(
            children: [
              const Icon(Icons.speaker_group_rounded, color: Color(0xFFFF2A6D), size: 20),
              const SizedBox(width: 8),
              const Text('Bass Boost', style: TextStyle(color: Colors.white, fontSize: 14)),
              const Spacer(),
              Text('${(_bass * 100).toInt()}%', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Slider(
            value: _bass,
            min: 0.0,
            max: 1.0,
            activeColor: const Color(0xFFFF2A6D),
            inactiveColor: Colors.white10,
            onChanged: (val) {
              setState(() => _bass = val);
            },
          ),
          const SizedBox(height: 12),
          // Playback Speed Slider
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: Color(0xFF05D9E8), size: 20),
              const SizedBox(width: 8),
              const Text('Playback Speed', style: TextStyle(color: Colors.white, fontSize: 14)),
              const Spacer(),
              Text('${_speed.toStringAsFixed(2)}x', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Slider(
            value: _speed,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            activeColor: const Color(0xFF05D9E8),
            inactiveColor: Colors.white10,
            onChanged: (val) {
              setState(() => _speed = val);
              widget.audioHandler.setSpeed(val);
            },
          ),
          const SizedBox(height: 12),
          // Master Volume Slider
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Master Volume', style: TextStyle(color: Colors.white, fontSize: 14)),
              const Spacer(),
              Text('${(_volume * 100).toInt()}%', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Slider(
            value: _volume,
            min: 0.0,
            max: 1.0,
            activeColor: Colors.white,
            inactiveColor: Colors.white10,
            onChanged: (val) {
              setState(() => _volume = val);
              widget.audioHandler.setVolume(val);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
