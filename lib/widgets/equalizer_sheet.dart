import 'package:flutter/material.dart';
import '../services/audio_handler.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';

class EqualizerSheet extends StatefulWidget {
  final AbhiAudioHandler audioHandler;

  const EqualizerSheet({Key? key, required this.audioHandler}) : super(key: key);

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  final LanguageService _lang = LanguageService();
  final ThemeService _theme = ThemeService();

  double _volume = 1.0;
  double _bass = 0.5;
  String _selectedPreset = 'Normal';

  final List<String> _presets = ['Normal', 'Bass Boost', 'Pop', 'Rock', 'Vocal', 'Club'];

  @override
  void initState() {
    super.initState();
    _volume = widget.audioHandler.player.volume;
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
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final cardColor = _theme.cardBg;
        final primaryColor = _theme.primaryColor;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
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
                  Text(
                    _lang.t('equalizer'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textColor),
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
                      selectedColor: primaryColor,
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : textColor,
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
                  Text(_lang.t('bass'), style: TextStyle(color: textColor, fontSize: 14)),
                  const Spacer(),
                  Text('%', style: TextStyle(color: subtextColor)),
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
              // Master Volume Slider
              Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Text(_lang.t('volume'), style: TextStyle(color: textColor, fontSize: 14)),
                  const Spacer(),
                  Text('%', style: TextStyle(color: subtextColor)),
                ],
              ),
              Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                activeColor: textColor,
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
      },
    );
  }
}
