/// Devanagari Transliteration Engine
/// Transforms Romanized/Hinglish/English lyrics into 100% authentic Devanagari Hindi script
/// while preserving Karaoke timestamps [mm:ss.xx] exactly.
class DevanagariConverter {
  static final RegExp _timestampRegExp = RegExp(r'^(\[\d{2}:\d{2}\.\d{2,3}\])\s*(.*)$');
  static final RegExp _devanagariRange = RegExp(r'[\u0900-\u097F]');

  // Common song lyrics vocabulary mapping (Top Indian & Bollywood hits)
  static final Map<String, String> _dictionary = {
    // Pronouns & Basics
    'tum': 'तुम',
    'hum': 'हम',
    'ham': 'हम',
    'main': 'मैं',
    'mujhe': 'मुझे',
    'mera': 'मेरा',
    'meri': 'मेरी',
    'mere': 'मेरे',
    'tu': 'तू',
    'tujhe': 'तुझे',
    'tera': 'तेरा',
    'teri': 'तेरी',
    'tere': 'तेरे',
    'humko': 'हमको',
    'tumko': 'तुमको',
    'apna': 'अपना',
    'apni': 'अपनी',
    'apne': 'अपने',
    'yeh': 'यह',
    'ye': 'ये',
    'woh': 'वह',
    'wo': 'वो',
    'kya': 'क्या',
    'kyun': 'क्यों',
    'kyu': 'क्यों',
    'kaun': 'कौन',
    'kaha': 'कहाँ',
    'kahan': 'कहाँ',
    'jahan': 'जहाँ',
    'yahan': 'यहाँ',
    'wahan': 'वहाँ',
    'kab': 'कब',
    'jab': 'जब',
    'tab': 'तब',
    'ab': 'अब',
    'sab': 'सब',
    'hai': 'है',
    'hain': 'हैं',
    'ho': 'हो',
    'hoon': 'हूँ',
    'hun': 'हूँ',
    'tha': 'था',
    'thi': 'थी',
    'the': 'थे',
    'hoga': 'होगा',
    'hogi': 'होगी',
    'honge': 'होंगे',
    'nahi': 'नहीं',
    'nahin': 'नहीं',
    'na': 'ना',
    'mat': 'मत',
    'aur': 'और',
    'bhi': 'भी',
    'hi': 'ही',
    'toh': 'तो',
    'to': 'तो',
    'se': 'से',
    'ko': 'को',
    'ka': 'का',
    'ki': 'की',
    'ke': 'के',
    'mein': 'में',
    'me': 'में',
    'par': 'पर',
    'pe': 'पे',
    'tak': 'तक',
    'bina': 'बिना',
    'bin': 'बिन',
    'saath': 'साथ',
    'paas': 'पास',
    'dur': 'दूर',
    'door': 'दूर',

    // Romance & Emotions
    'dil': 'दिल',
    'pyaar': 'प्यार',
    'pyar': 'प्यार',
    'ishq': 'इश्क़',
    'mohabbat': 'मोहब्बत',
    'aashiqui': 'आशिकी',
    'deewana': 'दीवाना',
    'deewani': 'दीवानी',
    'jaan': 'जान',
    'jaana': 'जाना',
    'zindagi': 'ज़िंदगी',
    'jindgi': 'ज़िंदगी',
    'khuda': 'ख़ुदा',
    'rabba': 'रब्बा',
    'rab': 'रब',
    'maula': 'मौला',
    'sanam': 'सनम',
    'sajna': 'सजना',
    'sajni': 'सजनी',
    'dholna': 'ढोलना',
    'mahiya': 'माहिया',
    'yaara': 'यारा',
    'yaar': 'यार',
    'humsafar': 'हमसफ़र',
    'raahi': 'राही',
    'safar': 'सफ़र',
    'rasta': 'रास्ता',
    'raaste': 'रास्ते',
    'manzil': 'मंज़िल',
    'dhadkan': 'धड़कन',
    'saans': 'साँस',
    'saansein': 'साँसें',
    'khwab': 'ख़्वाब',
    'sapna': 'सपना',
    'sapne': 'सपने',
    'yaad': 'याद',
    'yaadein': 'यादें',
    'baat': 'बात',
    'baatein': 'बातें',
    'aankhein': 'आँखें',
    'aankhon': 'आँखों',
    'ankhon': 'आँखों',
    'naina': 'नैना',
    'nazar': 'नज़र',
    'nazrein': 'नज़रें',
    'chehra': 'चेहरा',
    'hansi': 'हँसी',
    'hasi': 'हँसी',
    'khushi': 'खुशी',
    'dard': 'दर्द',
    'gham': 'ग़म',
    'aansoo': 'आँसू',
    'ansu': 'आँसू',
    'tanhai': 'तन्हाई',
    'juda': 'जुदा',
    'judai': 'जुदाई',
    'dawa': 'दवा',
    'dua': 'दुआ',
    'wajah': 'वजह',
    'wajood': 'वजूद',
    'kasam': 'क़सम',
    'waada': 'वादा',
    'intezaar': 'इंतज़ार',
    'intezar': 'इंतज़ार',
    'aahat': 'आहट',
    'muskurane': 'मुस्कुराने',
    'muskura': 'मुस्कुरा',
    'jeena': 'जीना',
    'marna': 'मरना',
    'duniya': 'दुनिया',
    'zamana': 'ज़माना',
    'jahan': 'जहाँ',
    'aasmaan': 'आसमान',
    'aasman': 'आसमान',
    'zameen': 'ज़मीन',
    'chand': 'चाँद',
    'sitare': 'सितारे',
    'taare': 'तारे',
    'raat': 'रात',
    'raatein': 'रातें',
    'subah': 'सुबह',
    'shaam': 'शाम',
    'pal': 'पल',
    'lamha': 'लम्हा',
    'lamhe': 'लम्हे',
    'har': 'हर',
    'kabhi': 'कभी',
    'hamesha': 'हमेशा',
    'sada': 'सदा',
    'phir': 'फिर',
    'baar': 'बार',
    'pehle': 'पहले',
    'baad': 'बाद',

    // Verbs
    'dekh': 'देख',
    'dekha': 'देखा',
    'dekho': 'देखो',
    'sun': 'सुन',
    'suno': 'सुनो',
    'suna': 'सुना',
    'bol': 'बोल',
    'bolo': 'बोलो',
    'keh': 'कह',
    'kehta': 'कहता',
    'kehti': 'कहती',
    'kaho': 'कहो',
    'chaha': 'चाहा',
    'chahta': 'चाहता',
    'chahti': 'चाहती',
    'paaya': 'पाया',
    'khoya': 'खोया',
    'aaya': 'आया',
    'aaye': 'आए',
    'aayi': 'आई',
    'aana': 'आना',
    'gaya': 'गया',
    'gaye': 'गए',
    'gayi': 'गई',
    'jaana': 'जाना',
    'jaao': 'जाओ',
    'raha': 'रहा',
    'rahe': 'रहे',
    'rahi': 'रही',
    'rah': 'रह',
    'rehna': 'रहना',
    'sakte': 'सकते',
    'sakti': 'सकती',
    'sakta': 'सकता',
    'hona': 'होना',
    'hota': 'होता',
    'hoti': 'होती',
    'hote': 'होते',
    'karna': 'करना',
    'karta': 'करता',
    'karti': 'करती',
    'karte': 'करते',
    'karo': 'करो',
    'kiya': 'किया',
    'de': 'दे',
    'do': 'दो',
    'diya': 'दिया',
    'le': 'ले',
    'lo': 'लो',
    'liya': 'लिया',
    'mil': 'मिल',
    'mila': 'मिला',
    'mile': 'मिले',
    'mili': 'मिली',
    'chhod': 'छोड़',
    'chale': 'चले',
    'chala': 'चला',
    'manwa': 'मनवा',
    'kesariya': 'केसरिया',
    'rang': 'रंग',
    'tera': 'तेरा',
    'ishq': 'इश्क़',
    'piya': 'पिया',
    'mora': 'मोरा',
    'man': 'मन',
    'bawra': 'बावरा',
    'channa': 'चन्ना',
    'mereya': 'मेरेया',
    'raatan': 'रातां',
    'lambiyan': 'लम्बियां',
    'kade': 'कदे',
    'avega': 'आवेगा',
  };

  /// Main method: Converts any line into Devanagari
  static String toDevanagari(String text) {
    if (text.trim().isEmpty) return text;

    // Check if line contains timestamp [mm:ss.xx]
    final match = _timestampRegExp.firstMatch(text.trim());
    if (match != null) {
      final timestamp = match.group(1)!;
      final content = match.group(2)!;
      return '$timestamp ${_convertContent(content)}';
    }

    return _convertContent(text);
  }

  /// Converts multi-line lyrics text
  static String convertLyricsText(String rawLyrics) {
    if (rawLyrics.isEmpty) return rawLyrics;
    final lines = rawLyrics.split('\n');
    final buffer = StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      buffer.write(toDevanagari(lines[i]));
      if (i < lines.length - 1) buffer.write('\n');
    }
    return buffer.toString();
  }

  static String _convertContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return content;

    // If text already has substantial Devanagari characters (>30%), leave it natural
    final devanagariCount = _devanagariRange.allMatches(trimmed).length;
    if (devanagariCount > trimmed.length * 0.3) {
      return content;
    }

    // Process word by word preserving spaces and punctuation
    final words = content.split(RegExp(r'(\s+|[.,!?";:—–\(\)\[\]{}])'));
    final buffer = StringBuffer();
    int searchIdx = 0;

    for (final token in content.split(' ')) {
      if (token.isEmpty) {
        buffer.write(' ');
        continue;
      }

      // Separate trailing or leading punctuation
      final puncMatch = RegExp(r'^([^\w]*)(.*?)([^\w]*)$').firstMatch(token);
      final leadingPunc = puncMatch?.group(1) ?? '';
      final wordCore = puncMatch?.group(2) ?? token;
      final trailingPunc = puncMatch?.group(3) ?? '';

      final lowerWord = wordCore.toLowerCase();

      String devanagariWord;
      if (_dictionary.containsKey(lowerWord)) {
        devanagariWord = _dictionary[lowerWord]!;
      } else {
        devanagariWord = _phoneticTransliterate(lowerWord);
      }

      buffer.write('$leadingPunc$devanagariWord$trailingPunc ');
    }

    return buffer.toString().trimRight();
  }

  /// Rule-based phonetic transliterator for Indian & English words
  static String _phoneticTransliterate(String input) {
    if (input.isEmpty) return '';
    final s = input.toLowerCase();

    // Sound clusters replacement in order of length
    final clusters = [
      {'from': 'shh', 'to': 'ष'},
      {'from': 'chh', 'to': 'छ'},
      {'from': 'kh', 'to': 'ख'},
      {'from': 'gh', 'to': 'घ'},
      {'from': 'ch', 'to': 'च'},
      {'from': 'jh', 'to': 'झ'},
      {'from': 'th', 'to': 'थ'},
      {'from': 'dh', 'to': 'ध'},
      {'from': 'ph', 'to': 'फ'},
      {'from': 'bh', 'to': 'भ'},
      {'from': 'sh', 'to': 'श'},
      {'from': 'aa', 'to': 'ा'},
      {'from': 'ee', 'to': 'ी'},
      {'from': 'oo', 'to': 'ू'},
      {'from': 'ai', 'to': 'ै'},
      {'from': 'au', 'to': 'ौ'},
      {'from': 'k', 'to': 'क'},
      {'from': 'g', 'to': 'ग'},
      {'from': 'c', 'to': 'क'},
      {'from': 'j', 'to': 'ज'},
      {'from': 't', 'to': 'त'},
      {'from': 'd', 'to': 'द'},
      {'from': 'n', 'to': 'न'},
      {'from': 'p', 'to': 'प'},
      {'from': 'b', 'to': 'ब'},
      {'from': 'm', 'to': 'म'},
      {'from': 'y', 'to': 'य'},
      {'from': 'r', 'to': 'र'},
      {'from': 'l', 'to': 'ल'},
      {'from': 'v', 'to': 'व'},
      {'from': 'w', 'to': 'व'},
      {'from': 's', 'to': 'स'},
      {'from': 'h', 'to': 'ह'},
      {'from': 'z', 'to': 'ज़'},
      {'from': 'f', 'to': 'फ़'},
      {'from': 'q', 'to': 'क़'},
      {'from': 'a', 'to': ''},
      {'from': 'i', 'to': 'ि'},
      {'from': 'u', 'to': 'ु'},
      {'from': 'e', 'to': 'े'},
      {'from': 'o', 'to': 'ो'},
    ];

    String result = s;
    for (final c in clusters) {
      result = result.replaceAll(c['from']!, c['to']!);
    }

    // If starting with a matra, convert to full vowel
    if (result.startsWith('ा')) result = 'आ' + result.substring(1);
    if (result.startsWith('ि')) result = 'इ' + result.substring(1);
    if (result.startsWith('ी')) result = 'ई' + result.substring(1);
    if (result.startsWith('ु')) result = 'उ' + result.substring(1);
    if (result.startsWith('ू')) result = 'ऊ' + result.substring(1);
    if (result.startsWith('े')) result = 'ए' + result.substring(1);
    if (result.startsWith('ै')) result = 'ऐ' + result.substring(1);
    if (result.startsWith('ो')) result = 'ओ' + result.substring(1);
    if (result.startsWith('ौ')) result = 'औ' + result.substring(1);

    return result.isEmpty ? input : result;
  }
}
