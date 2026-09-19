import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../services/download_service.dart';
import '../widgets/tactile_3d_wrapper.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({Key? key}) : super(key: key);

  @override
  State<StorageManagementScreen> createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  final ThemeService _theme = ThemeService();
  final LanguageService _lang = LanguageService();
  final DownloadService _downloadService = DownloadService();
  static const MethodChannel _nativeChannel = MethodChannel('com.abhishekpal.abhisuno/native');

  double _tempCacheMB = 0.0;
  double _permStorageMB = 0.0;
  double _deviceTotalGB = 0.0;
  double _deviceFreeGB = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageData();
  }

  Future<void> _loadStorageData() async {
    setState(() => _isLoading = true);
    final tempSize = await _downloadService.getTemporaryCacheSizeInMB();
    final permSize = await _downloadService.getPermanentStorageSizeInMB();

    try {
      final Map<dynamic, dynamic>? storageMap =
          await _nativeChannel.invokeMethod<Map<dynamic, dynamic>>('getStorageInfo');
      if (storageMap != null) {
        final totalB = (storageMap['totalBytes'] as num?)?.toDouble() ?? 0.0;
        final freeB = (storageMap['freeBytes'] as num?)?.toDouble() ?? 0.0;
        _deviceTotalGB = totalB / (1024 * 1024 * 1024);
        _deviceFreeGB = freeB / (1024 * 1024 * 1024);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _tempCacheMB = tempSize;
        _permStorageMB = permSize;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    await _downloadService.clearTemporaryCache();
    await _loadStorageData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E5FF),
          content: Text(
            _lang.isHindi ? 'कैश सफलतापूर्वक साफ़ हो गया!' : 'Cache cleared successfully!',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Future<void> _openDownloadsFolder() async {
    try {
      await _nativeChannel.invokeMethod('openDownloadsFolder');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _lang.isHindi
                  ? 'फोल्डर: Music/AbhiSuno'
                  : 'Folder path: Music/AbhiSuno',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_theme, _lang]),
      builder: (context, _) {
        final textColor = _theme.textColor;
        final subtextColor = _theme.subtextColor;
        final cardColor = _theme.cardBg;
        final isHindi = _lang.isHindi;

        final totalUsedDeviceGB = (_deviceTotalGB - _deviceFreeGB).clamp(0.0, _deviceTotalGB);
        final permGB = _permStorageMB / 1024.0;
        final tempGB = _tempCacheMB / 1024.0;

        return Scaffold(
          backgroundColor: _theme.scaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isHindi ? 'स्टोरेज प्रबंधन' : 'Storage Management',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: _theme.backgroundDecoration,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // Storage Overview Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isHindi ? 'डिवाइस स्टोरेज' : 'Device Storage',
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '${_deviceFreeGB.toStringAsFixed(1)} GB ${isHindi ? "खाली" : "free"}',
                                  style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Segmented Storage Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                height: 10,
                                child: Row(
                                  children: [
                                    if (_deviceTotalGB > 0) ...[
                                      // App Songs (Cyan)
                                      Expanded(
                                        flex: ((permGB / _deviceTotalGB) * 1000).clamp(1.0, 1000.0).toInt(),
                                        child: Container(color: const Color(0xFF00E5FF)),
                                      ),
                                      // Cache (Pink)
                                      Expanded(
                                        flex: ((tempGB / _deviceTotalGB) * 1000).clamp(1.0, 1000.0).toInt(),
                                        child: Container(color: const Color(0xFFFF2A6D)),
                                      ),
                                      // Other storage
                                      Expanded(
                                        flex: (((totalUsedDeviceGB - permGB - tempGB) / _deviceTotalGB) * 1000)
                                            .clamp(0.0, 1000.0)
                                            .toInt(),
                                        child: Container(color: Colors.white24),
                                      ),
                                      // Free storage
                                      Expanded(
                                        flex: ((_deviceFreeGB / _deviceTotalGB) * 1000).clamp(0.0, 1000.0).toInt(),
                                        child: Container(color: Colors.white10),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStorageStat(
                                  color: const Color(0xFF00E5FF),
                                  label: isHindi ? 'डाउनलोड गाने' : 'Songs',
                                  val: '${_permStorageMB.toStringAsFixed(1)} MB',
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                ),
                                _buildStorageStat(
                                  color: const Color(0xFFFF2A6D),
                                  label: isHindi ? 'अस्थायी कैश' : 'Temp Cache',
                                  val: '${_tempCacheMB.toStringAsFixed(1)} MB',
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                ),
                                _buildStorageStat(
                                  color: Colors.white38,
                                  label: isHindi ? 'कुल स्टोरेज' : 'Total Space',
                                  val: '${_deviceTotalGB.toStringAsFixed(0)} GB',
                                  textColor: textColor,
                                  subtextColor: subtextColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Clear Cache Action
                      Tactile3DWrapper(
                        onTap: _clearCache,
                        scaleElevation: 1.05,
                        glowColor: const Color(0xFF00E5FF),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF00E5FF).withOpacity(0.15),
                                ),
                                child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF00E5FF), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHindi ? 'अस्थायी कैश साफ़ करें' : 'Clear Temporary Cache',
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isHindi ? 'सर्च और स्ट्रीमिंग का गैर-ज़रूरी डेटा हटाएं' : 'Frees ${_tempCacheMB.toStringAsFixed(1)} MB instantly',
                                      style: TextStyle(color: subtextColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Open Native Music/AbhiSuno Folder
                      Tactile3DWrapper(
                        onTap: _openDownloadsFolder,
                        scaleElevation: 1.05,
                        glowColor: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFB300).withOpacity(0.15),
                                ),
                                child: const Icon(Icons.folder_open_rounded, color: Color(0xFFFFB300), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHindi ? 'डाउनलोड फ़ोल्डर खोलें' : 'Open Music Folder',
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Internal Storage > Music > AbhiSuno',
                                      style: TextStyle(color: subtextColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded, color: Colors.white38, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStorageStat({
    required Color color,
    required String label,
    required String val,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: subtextColor, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
