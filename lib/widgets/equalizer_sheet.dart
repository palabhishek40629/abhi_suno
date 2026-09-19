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
  double _surround3D = 0.6;
  bool _isSurroundEnabled = true;
  String _selectedPreset = 'Normal';

  // 10 Frequency Bands (Hz): 32Hz, 64Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz
  final List<String> _bandLabels = [
    '32Hz', '64Hz', '125Hz', '250Hz', '500Hz',
    '1kHz', '2kHz', '4kHz', '8kHz', '16kHz'
  ];

  late List<double> _bandValues;

  final Map<String, List<double>> _presetBands = {
    'Normal': [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
    'Car Ultra-Bass': [0.95, 0.90, 0.85, 0.60, 0.50, 0.45, 0.50, 0.60, 0.75, 0.85],
    'Vocal Booster': [0.35, 0.40, 0.50, 0.65, 0.85, 0.90, 0.85, 0.75, 0.60, 0.50],
    'Rock Stage': [0.80, 0.75, 0.60, 0.45, 0.55, 0.70, 0.80, 0.85, 0.85, 0.80],
    'Acoustic Live': [0.55, 0.50, 0.55, 0.65, 0.70, 0.75, 0.70, 0.65, 0.70, 0.75],
    'Dolby Atmos 360°': [0.85, 0.80, 0.70, 0.60, 0.65, 0.75, 0.85, 0.90, 0.95, 0.90],
  };

  @override
  void initState() {
    super.initState();
    _volume = widget.audioHandler.player.volume;
    _bandValues = List<double>.from(_presetBands['Normal']!);
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (_presetBands.containsKey(preset)) {
        _bandValues = List<double>.from(_presetBands[preset]!);
      }
      if (preset == 'Car Ultra-Bass') {
        _bass = 0.95;
        _isSurroundEnabled = true;
        _surround3D = 0.85;
        widget.audioHandler.setPitch(0.96);
      } else if (preset == 'Vocal Booster') {
        _bass = 0.35;
        _isSurroundEnabled = false;
        widget.audioHandler.setPitch(1.04);
      } else if (preset == 'Rock Stage') {
        _bass = 0.80;
        _isSurroundEnabled = true;
        _surround3D = 0.70;
        widget.audioHandler.setPitch(1.0);
      } else if (preset == 'Dolby Atmos 360°') {
        _bass = 0.85;
        _isSurroundEnabled = true;
        _surround3D = 1.0;
        widget.audioHandler.setPitch(1.0);
      } else {
        _bass = 0.50;
        _isSurroundEnabled = true;
        _surround3D = 0.50;
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
        const primaryCyan = Color(0xFF00E5FF);
        const primaryPink = Color(0xFFFF2A6D);

        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: primaryCyan, width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [primaryCyan, primaryPink]),
                        ),
                        child: const Icon(Icons.equalizer_rounded, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lang.t('equalizer'),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '10-Band Studio EQ + 3D Surround',
                            style: TextStyle(color: primaryCyan, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Presets Choice Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetBands.keys.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final preset = _presetBands.keys.elementAt(index);
                    final isSelected = preset == _selectedPreset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: isSelected,
                      selectedColor: primaryCyan,
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => _applyPreset(preset),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // 10-Band EQ Vertical Sliders in a Horizontal Scroll
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '+${((_bandValues[i] - 0.5) * 24).toInt()}dB',
                            style: TextStyle(
                              color: _bandValues[i] > 0.5 ? primaryCyan : subtextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                  activeTrackColor: primaryCyan,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: _bandValues[i],
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) {
                                    setState(() {
                                      _bandValues[i] = val;
                                      _selectedPreset = 'Custom';
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bandLabels[i],
                            style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bass Boost & 3D Spatial Surround Dials
              Row(
                children: [
                  // Bass Boost Slider
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryPink.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.speaker_rounded, color: primaryPink, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _lang.t('bass'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                '${(_bass * 100).toInt()}%',
                                style: const TextStyle(color: primaryPink, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          Slider(
                            value: _bass,
                            min: 0.0,
                            max: 1.0,
                            activeColor: primaryPink,
                            inactiveColor: Colors.white12,
                            onChanged: (val) {
                              setState(() {
                                _bass = val;
                                _selectedPreset = 'Custom';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 3D Spatial Surround
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryCyan.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.surround_sound_rounded, color: primaryCyan, size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                '3D Surround',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                '${(_surround3D * 100).toInt()}%',
                                style: const TextStyle(color: primaryCyan, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          Slider(
                            value: _surround3D,
                            min: 0.0,
                            max: 1.0,
                            activeColor: primaryCyan,
                            inactiveColor: Colors.white12,
                            onChanged: (val) {
                              setState(() {
                                _surround3D = val;
                                _selectedPreset = 'Custom';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Master Volume Control
              Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Text(_lang.t('volume'), style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: primaryCyan,
                      inactiveColor: Colors.white10,
                      onChanged: (val) {
                        setState(() => _volume = val);
                        widget.audioHandler.player.setVolume(val);
                      },
                    ),
                  ),
                  Text('${(_volume * 100).toInt()}%', style: TextStyle(color: subtextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
