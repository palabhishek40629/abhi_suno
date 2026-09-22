/// Devanagari Transliteration Engine
/// Transforms Romanized/Hinglish/English lyrics into 100% authentic Devanagari Hindi script
/// so that the Sudha (AmsSudha) font renders every character with elegance and precision,
/// while preserving Karaoke timestamps [mm:ss.xx] exactly.
class DevanagariConverter {
  static final RegExp _timestampRegExp = RegExp(r'^(\[\d{2}:\d{2}\.\d{2,3}\])\s*(.*)$');
  static final RegExp _devanagariRange = RegExp(r'[\u0900-\u097F]');

  // Comprehensive Song Vocabulary Dictionary (Top Hindi, Urdu, Punjabi, English & Global Tracks)
  // Formatted with 100% precise Hindi grammar, standard matras, anusvara, and chandrabindu
  static final Map<String, String> _dictionary = {
    // English Basics & Pronouns
    'i': 'आई',
    'you': 'यू',
    'he': 'ही',
    'she': 'शी',
    'we': 'वी',
    'they': 'दे',
    'me': 'मी',
    'my': 'माई',
    'your': 'योर',
    'his': 'हिज',
    'her': 'हर',
    'our': 'अवर',
    'us': 'अस',
    'them': 'देम',
    'it': 'इट',
    'this': 'दिस',
    'that': 'दैट',
    'these': 'दीज',
    'those': 'दोज',
    'who': 'हू',
    'what': 'व्हाट',
    'when': 'व्हेन',
    'where': 'व्हेर',
    'why': 'व्हाई',
    'how': 'हाउ',
    'a': 'अ',
    'an': 'एन',
    'the': 'द',
    'am': 'एम',
    'in': 'इन',
    'on': 'ऑन',
    'at': 'एट',
    'to': 'टू',
    'is': 'इज',
    'are': 'आर',
    'was': 'वाज',
    'were': 'वर',
    'be': 'बी',
    'been': 'बीन',
    'being': 'बीइंग',
    'have': 'हैव',
    'has': 'हैज',
    'had': 'हैड',
    'made': 'मेड',
    'make': 'मेक',
    'making': 'मेकिंग',
    'can': 'कैन',
    'could': 'कुड',
    'will': 'विल',
    'would': 'वुड',
    'shall': 'शैल',
    'should': 'शुड',
    'must': 'मस्ट',

    // English Song Keywords & Romance
    'love': 'लव',
    'baby': 'बेबी',
    'babe': 'बेब',
    'heart': 'हार्ट',
    'tonight': 'टुनाइट',
    'never': 'नेवर',
    'forever': 'फॉरएवर',
    'always': 'ऑलवेज',
    'let': 'लेट',
    'go': 'गो',
    'gone': 'गॉन',
    'yeah': 'येह',
    'yes': 'यस',
    'no': 'नो',
    'oh': 'ओह',
    'girl': 'गर्ल',
    'boy': 'बॉय',
    'man': 'मैन',
    'woman': 'वुमन',
    'one': 'वन',
    'two': 'टू',
    'three': 'थ्री',
    'time': 'टाइम',
    'night': 'नाइट',
    'day': 'डे',
    'life': 'लाइफ',
    'feel': 'फील',
    'feeling': 'फीलिंग',
    'world': 'वर्ल्ड',
    'need': 'नीड',
    'want': 'वांट',
    'say': 'से',
    'tell': 'टेल',
    'speak': 'स्पीक',
    'talk': 'टॉक',
    'with': 'विद',
    'without': 'विदाउट',
    'for': 'फॉर',
    'all': 'ऑल',
    'so': 'सो',
    'just': 'जस्ट',
    'like': 'लाइक',
    'know': 'नो',
    'think': 'थिंक',
    'see': 'सी',
    'look': 'लुक',
    'come': 'कम',
    'came': 'केम',
    'good': 'गुड',
    'bad': 'बैड',
    'give': 'गिव',
    'take': 'टेक',
    'back': 'बैक',
    'find': 'फाइंड',
    'here': 'हियर',
    'there': 'देयर',
    'thing': 'थिंग',
    'way': 'वे',
    'well': 'वेल',
    'down': 'डाउन',
    'up': 'अप',
    'right': 'राइट',
    'too': 'टू',
    'any': 'एनी',
    'please': 'प्लीज',
    'sorry': 'सॉरी',
    'hello': 'हैलो',
    'hey': 'हे',
    'hi': 'हाय',
    'dj': 'डीजे',
    'party': 'पार्टी',
    'music': 'म्यूजिक',
    'dance': 'डांस',
    'beat': 'बीट',
    'bass': 'बास',
    'remix': 'रीमिक्स',
    'song': 'सॉन्ग',
    'rock': 'रॉक',
    'pop': 'पॉप',
    'rap': 'रैप',
    'kiss': 'किस',
    'hug': 'हग',
    'smile': 'स्माइल',
    'tears': 'टियर्स',
    'cry': 'क्राई',
    'crying': 'क्राइंग',
    'crazy': 'क्रेजी',
    'beautiful': 'ब्यूटीफुल',
    'pretty': 'प्रिटी',
    'eyes': 'आइज',
    'face': 'फेस',
    'body': 'बॉडी',
    'touch': 'टच',
    'hold': 'होल्ड',
    'close': 'क्लोज',
    'away': 'अवे',
    'stay': 'स्टे',
    'dream': 'ड्रीम',
    'sweet': 'स्वीट',
    'honey': 'हनी',
    'darling': 'डार्लिंग',
    'friend': 'फ्रेंड',
    'together': 'टुगेदर',
    'alone': 'अलोन',
    'shape': 'शेप',
    'of': 'ऑफ',
    'do': 'डू',
    'did': 'डिड',
    'done': 'डन',
    'believer': 'बिलीवर',
    'faded': 'फेडेड',
    'perfect': 'परफेक्ट',
    'closer': 'क्लोज़र',
    'senorita': 'सेनोरिटा',
    'dandelions': 'डैंडेलिओन्स',
    'memories': 'मेमोरीज',
    'someone': 'समवन',
    'liar': 'लायर',
    'thunder': 'थंडर',
    'shallow': 'शैलो',
    'attention': 'अटेंशन',
    'blinding': 'ब्लाइंडिंग',
    'lights': 'लाइट्स',
    'levitating': 'लेविटेटिंग',
    'peaches': 'पीचेस',
    'butter': 'बटर',
    'dynamite': 'डायनामाइट',
    'light': 'लाइट',
    'dark': 'डार्क',
    'fall': 'फॉल',
    'falling': 'फॉलिंग',
    'rise': 'राइज',
    'high': 'हाई',
    'low': 'लो',
    'shine': 'शाइन',
    'star': 'स्टार',
    'stars': 'स्टार्स',
    'moon': 'मून',
    'sky': 'स्काई',
    'sun': 'सन',
    'rain': 'रेन',
    'fire': 'फायर',
    'burn': 'बर्न',
    'cold': 'कोल्ड',
    'hot': 'हॉट',
    'broken': 'ब्रोकन',
    'heal': 'हील',
    'hope': 'होप',
    'pray': 'प्रे',
    'wish': 'विश',
    'believe': 'बिलीव',
    'breath': 'ब्रेथ',
    'breathe': 'ब्रीद',

    // Hindi & Bollywood Pronouns & Particles (Grammatically Perfect)
    'tum': 'तुम',
    'hum': 'हम',
    'ham': 'हम',
    'main': 'मैं',
    'mai': 'मैं',
    'mujhe': 'मुझे',
    'mujhko': 'मुझको',
    'mujhse': 'मुझसे',
    'mujhme': 'मुझमें',
    'mujhpar': 'मुझपर',
    'mera': 'मेरा',
    'meri': 'मेरी',
    'mere': 'मेरे',
    'tu': 'तू',
    'tujhe': 'तुझे',
    'tujhko': 'तुझको',
    'tujhse': 'तुझसे',
    'tujhme': 'तुझमें',
    'tujhpar': 'तुझपर',
    'tera': 'तेरा',
    'teri': 'तेरी',
    'tere': 'तेरे',
    'humko': 'हमको',
    'humse': 'हमसे',
    'tumko': 'तुमको',
    'tumse': 'तुमसे',
    'tumhara': 'तुम्हारा',
    'tumhari': 'तुम्हारी',
    'tumhare': 'तुम्हारे',
    'hamaara': 'हमारा',
    'hamara': 'हमारा',
    'hamari': 'हमारी',
    'hamare': 'हमारे',
    'apna': 'अपना',
    'apni': 'अपनी',
    'apne': 'अपने',
    'aap': 'आप',
    'aapka': 'आपका',
    'aapki': 'आपकी',
    'aapke': 'आपके',
    'aapko': 'आपको',
    'aapse': 'आपसे',
    'khud': 'ख़ुद',
    'khudi': 'ख़ुदी',
    'yeh': 'यह',
    'ye': 'ये',
    'woh': 'वह',
    'wo': 'वो',
    'is': 'इस',
    'iska': 'इसका',
    'iski': 'इसकी',
    'iske': 'इसके',
    'isko': 'इसको',
    'usse': 'उससे',
    'us': 'उस',
    'uska': 'उसका',
    'uski': 'उसकी',
    'uske': 'उसके',
    'usko': 'उसको',
    'unka': 'उनका',
    'unki': 'उनकी',
    'unke': 'उनके',
    'unko': 'उनको',
    'inhe': 'इन्हें',
    'unhe': 'उन्हें',
    'jinhe': 'जिन्हें',
    'kya': 'क्या',
    'kyun': 'क्यों',
    'kyu': 'क्यों',
    'kyuki': 'क्योंकि',
    'kyunki': 'क्योंकि',
    'kaun': 'कौन',
    'kaha': 'कहाँ',
    'kahan': 'कहाँ',
    'jaha': 'जहाँ',
    'jahan': 'जहाँ',
    'yaha': 'यहाँ',
    'yahan': 'यहाँ',
    'waha': 'वहाँ',
    'wahan': 'वहाँ',
    'kab': 'कब',
    'jab': 'जब',
    'tab': 'तब',
    'ab': 'अब',
    'sab': 'सब',
    'sabka': 'सबका',
    'sabki': 'सबकी',
    'sabke': 'सबके',
    'kisi': 'किसी',
    'kisika': 'किसीका',
    'kisiki': 'किसीकी',
    'kisike': 'किसीके',
    'kisiko': 'किसीको',
    'koi': 'कोई',
    'kuch': 'कुछ',
    'kuchh': 'कुछ',
    'itna': 'इतना',
    'itni': 'इतनी',
    'itne': 'इतने',
    'jitna': 'जितना',
    'jitni': 'जितनी',
    'jitne': 'जितने',
    'kitna': 'कितना',
    'kitni': 'कितनी',
    'kitne': 'कितने',
    'aisa': 'ऐसा',
    'aisi': 'ऐसी',
    'aise': 'ऐसे',
    'jaisa': 'जैसा',
    'jaisi': 'जैसी',
    'jaise': 'जैसे',
    'waisa': 'वैसा',
    'waisi': 'वैसी',
    'waise': 'वैसे',
    'kaisa': 'कैसा',
    'kaisi': 'कैसी',
    'kaise': 'कैसे',
    'hai': 'है',
    'hain': 'हैं',
    'ho': 'हो',
    'hoon': 'हूँ',
    'hun': 'हूँ',
    'hu': 'हूँ',
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
    'ya': 'या',
    'lekin': 'लेकिन',
    'magar': 'मगर',
    'parantu': 'परंतु',
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

    // Hindi Romance, Emotions, Nature & Poetry
    'dil': 'दिल',
    'dilon': 'दिलों',
    'pyaar': 'प्यार',
    'pyar': 'प्यार',
    'ishq': 'इश्क़',
    'mohabbat': 'मोहब्बत',
    'aashiqui': 'आशिकी',
    'deewana': 'दीवाना',
    'deewani': 'दीवानी',
    'deewane': 'दीवाने',
    'mastana': 'मस्ताना',
    'mastani': 'मस्तानी',
    'parwana': 'परवाना',
    'jaan': 'जान',
    'jaana': 'जाना',
    'jaane': 'जाने',
    'jaani': 'जानी',
    'zindagi': 'ज़िंदगी',
    'jindgi': 'ज़िंदगी',
    'khuda': 'ख़ुदा',
    'rabba': 'रब्बा',
    'rab': 'रब',
    'maula': 'मौला',
    'allah': 'अल्लाह',
    'ishwar': 'ईश्वर',
    'sanam': 'सनम',
    'sajna': 'सजना',
    'sajni': 'सजनी',
    'dholna': 'ढोलना',
    'mahiya': 'माहिया',
    'soniye': 'सोणिये',
    'soniya': 'सोणिया',
    'yaara': 'यारा',
    'yaar': 'यार',
    'yaari': 'यारी',
    'dost': 'दोस्त',
    'dosti': 'दोस्ती',
    'humsafar': 'हमसफ़र',
    'raahi': 'राही',
    'safar': 'सफ़र',
    'rasta': 'रास्ता',
    'raaste': 'रास्ते',
    'raaston': 'रास्तों',
    'manzil': 'मंज़िल',
    'manzilein': 'मंज़िलें',
    'dhadkan': 'धड़कन',
    'dhadkanein': 'धड़कनें',
    'saans': 'साँस',
    'saansein': 'साँसें',
    'saanson': 'साँसों',
    'khwab': 'ख़्वाब',
    'khwaab': 'ख़्वाब',
    'khwabon': 'ख़्वाबों',
    'sapna': 'सपना',
    'sapne': 'सपने',
    'sapnon': 'सपनों',
    'yaad': 'याद',
    'yaadein': 'यादें',
    'yaadon': 'यादों',
    'baat': 'बात',
    'baatein': 'बातें',
    'baaton': 'बातों',
    'aankhein': 'आँखें',
    'aankhon': 'आँखों',
    'ankhon': 'आँखों',
    'ankhiyon': 'अँखियों',
    'naina': 'नैना',
    'naino': 'नैनों',
    'nazar': 'नज़र',
    'nazrein': 'नज़रें',
    'nazron': 'नज़रों',
    'nigahein': 'निगाहें',
    'nigahon': 'निगाहों',
    'palkein': 'पलकें',
    'palkon': 'पलकों',
    'chehra': 'चेहरा',
    'chehre': 'चेहरे',
    'zulf': 'ज़ुल्फ़',
    'zulfein': 'ज़ुल्फ़ें',
    'zulfon': 'ज़ुल्फ़ों',
    'lab': 'लब',
    'labon': 'लबों',
    'hoth': 'होंठ',
    'hothon': 'होंठों',
    'hansi': 'हँसी',
    'hasi': 'हँसी',
    'khushi': 'खुशी',
    'khushiyan': 'खुशियाँ',
    'dard': 'दर्द',
    'gham': 'ग़म',
    'aansoo': 'आँसू',
    'ansu': 'आँसू',
    'tanhai': 'तन्हाई',
    'tanhaiyan': 'तन्हाइयाँ',
    'juda': 'जुदा',
    'judaa': 'जुदा',
    'judai': 'जुदाई',
    'bewafa': 'बेवफ़ा',
    'bewafai': 'बेवफ़ाई',
    'ruswai': 'रुसवाई',
    'dawa': 'दवा',
    'dua': 'दुआ',
    'duayein': 'दुआएँ',
    'ibadat': 'इबादत',
    'agar': 'अगर',
    'jayenge': 'जाएंगे',
    'jayegi': 'जाएगी',
    'jayega': 'जाएगा',
    'chain': 'चैन',
    'rishta': 'रिश्ता',
    'rishte': 'रिश्ते',
    'naseeb': 'नसीब',
    'wafa': 'वफ़ा',
    'waqt': 'वक़्त',
    'vakt': 'वक़्त',
    'wakt': 'वक़्त',
    'jeete': 'जीते',
    'jeeta': 'जीता',
    'jeeti': 'जीती',
    'saare': 'सारे',
    'saara': 'सारा',
    'saari': 'सारी',
    'ghamon': 'ग़मों',
    'ik': 'इक',
    'ek': 'एक',
    'reh': 'रह',
    'gawara': 'गवारा',
    'roj': 'रोज़',
    'roz': 'रोज़',
    'sabhi': 'सभी',
    'aadha': 'आधा',
    'adha': 'आधा',
    'adhoora': 'अधूरा',
    'adhura': 'अधूरा',
    'poora': 'पूरा',
    'pura': 'पूरा',
    'sambhaala': 'सँभाला',
    'sambhala': 'सँभाला',
    'nikala': 'निकाला',
    'nikal': 'निकाल',
    'nikle': 'निकले',
    'nikli': 'निकली',
    'gam': 'ग़म',
    'shuru': 'शुरू',
    'khatam': 'ख़त्म',
    'khatm': 'ख़त्म',
    'khoob': 'खूब',
    'khoobsurat': 'ख़ूबसूरत',
    'haseen': 'हसीन',
    'afsaana': 'अफ़साना',
    'kahani': 'कहानी',
    'dastaan': 'दास्ताँ',
    'sukoon': 'सुकून',
    'junoon': 'जुनून',
    'fitoor': 'फ़ितूर',
    'mannat': 'मन्नत',
    'jannat': 'जन्नत',
    'tinka': 'तिनका',
    'wajah': 'वजह',
    'wajood': 'वजूद',
    'kasam': 'क़सम',
    'waada': 'वादा',
    'waade': 'वादे',
    'intezaar': 'इंतज़ार',
    'intezar': 'इंतज़ार',
    'aahat': 'आहट',
    'muskurane': 'मुस्कुराने',
    'muskura': 'मुस्कुरा',
    'muskaan': 'मुस्कान',
    'jeena': 'जीना',
    'marna': 'मरना',
    'duniya': 'दुनिया',
    'zamana': 'ज़माना',
    'mehfil': 'महफ़िल',
    'aasmaan': 'आसमान',
    'aasman': 'आसमान',
    'zameen': 'ज़मीन',
    'falak': 'फ़लक',
    'chand': 'चाँद',
    'chaand': 'चाँद',
    'sitare': 'सितारे',
    'sitaron': 'सितारों',
    'taare': 'तारे',
    'taaron': 'तारों',
    'raat': 'रात',
    'raatein': 'रातें',
    'raaton': 'रातों',
    'subah': 'सुबह',
    'shaam': 'शाम',
    'dhoop': 'धूप',
    'chhaon': 'छाँव',
    'hawa': 'हवा',
    'hawaayein': 'हवाएँ',
    'hawaon': 'हवाओं',
    'baadal': 'बादल',
    'badal': 'बादल',
    'barsaat': 'बरसात',
    'baarish': 'बारिश',
    'barish': 'बारिश',
    'bheega': 'भीगा',
    'bheegi': 'भीगी',
    'bheege': 'भीगे',
    'toofan': 'तूफ़ान',
    'samandar': 'समंदर',
    'dariya': 'दरिया',
    'kinara': 'किनारा',
    'kinare': 'किनारे',
    'lehar': 'लहर',
    'lehrein': 'लहरें',
    'pal': 'पल',
    'lamha': 'लम्हा',
    'lamhe': 'लम्हे',
    'lamhon': 'लम्हों',
    'har': 'हर',
    'kabhi': 'कभी',
    'hamesha': 'हमेशा',
    'sada': 'सदा',
    'phir': 'फिर',
    'baar': 'बार',
    'pehle': 'पहले',
    'pehla': 'पहला',
    'pehli': 'पहली',
    'aakhri': 'आख़िरी',
    'baad': 'बाद',
    'aaj': 'आज',
    'kal': 'कल',
    'parson': 'परसों',

    // Hindi Verbs (Conjugated & Authentic)
    'dekh': 'देख',
    'dekha': 'देखा',
    'dekhe': 'देखे',
    'dekhi': 'देखी',
    'dekho': 'देखो',
    'dekhna': 'देखना',
    'dekhne': 'देखने',
    'dekhta': 'देखता',
    'dekhti': 'देखती',
    'dekhte': 'देखते',
    'sun': 'सुन',
    'suno': 'सुनो',
    'suna': 'सुना',
    'sune': 'सुने',
    'suni': 'सुनी',
    'sunna': 'सुनना',
    'sunne': 'सुनने',
    'sunta': 'सुनता',
    'sunti': 'सुनती',
    'sunte': 'सुनते',
    'bol': 'बोल',
    'bolo': 'बोलो',
    'bola': 'बोला',
    'bole': 'बोले',
    'boli': 'बोली',
    'bolna': 'बोलना',
    'keh': 'कह',
    'kehta': 'कहता',
    'kehti': 'कहती',
    'kehte': 'कहते',
    'kaho': 'कहो',
    'kaha': 'कहा',
    'kahe': 'कहे',
    'kehna': 'कहना',
    'chaha': 'चाहा',
    'chahe': 'चाहे',
    'chahi': 'चाही',
    'chahta': 'चाहता',
    'chahti': 'चाहती',
    'chahte': 'चाहते',
    'chahat': 'चाहत',
    'paaya': 'पाया',
    'paaye': 'पाए',
    'paayi': 'पाई',
    'paana': 'पाना',
    'khoya': 'खोया',
    'khoye': 'खोए',
    'khoyi': 'खोई',
    'khona': 'खोना',
    'aaya': 'आया',
    'aaye': 'आए',
    'aayi': 'आई',
    'aana': 'आना',
    'aao': 'आओ',
    'aate': 'आते',
    'aati': 'आती',
    'aata': 'आता',
    'gaya': 'गया',
    'gaye': 'गए',
    'gayi': 'गई',
    'jaao': 'जाओ',
    'jaana': 'जाना',
    'jaane': 'जाने',
    'jaata': 'जाता',
    'jaati': 'जाती',
    'jaate': 'जाते',
    'raha': 'रहा',
    'rahe': 'रहे',
    'rahi': 'रही',
    'rah': 'रह',
    'rehna': 'रहना',
    'rehte': 'रहते',
    'rehta': 'रहता',
    'rehti': 'रहती',
    'sakte': 'सकते',
    'sakti': 'सकती',
    'sakta': 'सकता',
    'sake': 'सके',
    'hona': 'होना',
    'hota': 'होता',
    'hoti': 'होती',
    'hote': 'होते',
    'karna': 'करना',
    'karta': 'करता',
    'karti': 'करती',
    'karte': 'करते',
    'karo': 'करो',
    'kar': 'कर',
    'karne': 'करने',
    'kare': 'करे',
    'karenge': 'करेंगे',
    'kiya': 'किया',
    'kiye': 'किए',
    'kiyi': 'की',
    'de': 'दे',
    'do': 'दो',
    'diya': 'दिया',
    'diye': 'दिए',
    'dena': 'देना',
    'dene': 'देने',
    'le': 'ले',
    'lo': 'लो',
    'liya': 'लिया',
    'liye': 'लिए',
    'lena': 'लेना',
    'lene': 'लेने',
    'mil': 'मिल',
    'mila': 'मिला',
    'mile': 'मिले',
    'mili': 'मिली',
    'milna': 'मिलना',
    'milte': 'मिलते',
    'chhod': 'छोड़',
    'chale': 'चले',
    'chala': 'चला',
    'chali': 'चली',
    'chal': 'चल',
    'chalna': 'चलना',
    'chalne': 'चलने',
    'jo': 'जो',
    'ja': 'जा',
    'zara': 'ज़रा',
    'jara': 'ज़रा',
    'sambhal': 'संभल',
    'haath': 'हाथ',
    'hath': 'हाथ',
    'haathon': 'हाथों',
    'lagaun': 'लगाऊँ',
    'lagau': 'लगाऊँ',
    'jaaun': 'जाऊँ',
    'jaau': 'जाऊँ',
    'bhula': 'भुला',
    'bhul': 'भूल',
    'bhule': 'भूले',
    'bhulana': 'भुलाना',
    'bhulado': 'भुलादो',
    're': 'रे',
    'kesariya': 'केसरिया',
    'rang': 'रंग',
    'rango': 'रंगों',
    'piya': 'पिया',
    'jiya': 'जिया',
    'mora': 'मोरा',
    'man': 'मन',
    'manwa': 'मनवा',
    'bawra': 'बावरा',
    'bana': 'बना',
    'ro': 'रो',
    'roya': 'रोया',
    'roye': 'रोए',
    'hasso': 'हँसो',
    'hasna': 'हँसना',

    // Punjabi & Modern Track Lexicon (Widely used in Bollywood chartbusters)
    'chaleya': 'चलेया',
    'heeriye': 'हीरिये',
    'heer': 'हीर',
    'ranjha': 'राँझा',
    'raatan': 'रातां',
    'lambiyan': 'लम्बियां',
    'kade': 'कदे',
    'avega': 'आवेगा',
    'channa': 'चन्ना',
    'mereya': 'मेरेया',
    'lagda': 'लगदा',
    'lagdi': 'लगदी',
    'sohneya': 'सोहणेया',
    'wakhra': 'वखरा',
    'swag': 'स्वैग',
    'brown': 'ब्राउन',
    'munde': 'मुंडे',
    'munda': 'मुंडा',
    'kudi': 'कुड़ी',
    'akhiyan': 'अखियां',
    'gallan': 'गल्लां',
    'dilbar': 'दिलबर',
    'jatt': 'जट्ट',
    'shava': 'शावा',
    'balle': 'बल्ले',
    'saanu': 'सानू',
    'tainu': 'तैनू',
    'mainu': 'मैनू',
    've': 'वे',
    'ni': 'नी',
    'haan': 'हाँ',
    'winning': 'विनिंग',
    'speech': 'स्पीच',
    'arziyan': 'अर्शियाँ',
    'kun': 'कुन',
    'faya': 'फ़या',
    'fayaa': 'फ़या',
  };

  /// Main method: Converts any single line into authentic Devanagari Hindi
  static String toDevanagari(String text) {
    if (text.trim().isEmpty) return text;

    // Check if line contains Karaoke timestamp [mm:ss.xx]
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

    final buffer = StringBuffer();
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

  /// Advanced syllabic phonetic transliterator for Indian & English words
  static String _phoneticTransliterate(String input) {
    if (input.isEmpty) return '';
    final w = input.toLowerCase();

    // Independent vowels (at word start or after vowel)
    const leadVowels = [
      ('aaa', 'आ'), ('aa', 'आ'), ('ai', 'ऐ'), ('au', 'औ'), ('ay', 'ए'),
      ('ee', 'ई'), ('oo', 'ऊ'), ('ii', 'ई'), ('uu', 'ऊ'),
      ('a', 'अ'), ('i', 'इ'), ('u', 'उ'), ('e', 'ए'), ('o', 'ओ')
    ];

    // Dependent matras (after consonant)
    const matras = [
      ('aaa', 'ा'), ('aa', 'ा'), ('ai', 'ै'), ('au', 'ौ'), ('ay', 'े'),
      ('ee', 'ी'), ('oo', 'ू'), ('ii', 'ी'), ('uu', 'ू'),
      ('e', 'े'), ('o', 'ो'), ('i', 'ि'), ('u', 'ु'), ('a', 'ा')
    ];

    // Consonants & clusters
    const consonants = [
      ('shh', 'ष'), ('chh', 'छ'), ('kh', 'ख'), ('gh', 'घ'), ('ch', 'च'),
      ('jh', 'झ'), ('th', 'थ'), ('dh', 'ध'), ('ph', 'फ़'), ('bh', 'भ'),
      ('sh', 'श'), ('rh', 'ढ़'), ('zh', 'ज़'), ('wh', 'व'),
      ('kk', 'क्क'), ('gg', 'ग्ग'), ('cc', 'च्च'), ('jj', 'ज्ज'),
      ('tt', 'त्त'), ('dd', 'द्द'), ('nn', 'न्न'), ('pp', 'प्प'),
      ('bb', 'ब्ब'), ('mm', 'म्म'), ('yy', 'य्य'), ('rr', 'र्र'),
      ('ll', 'ल्ल'), ('ss', 'स्स'),
      ('k', 'क'), ('g', 'ग'), ('c', 'क'), ('j', 'ज'), ('t', 'त'),
      ('d', 'द'), ('n', 'न'), ('p', 'प'), ('b', 'ब'), ('m', 'म'),
      ('y', 'य'), ('r', 'र'), ('l', 'ल'), ('v', 'व'), ('w', 'व'),
      ('s', 'स'), ('h', 'ह'), ('z', 'ज़'), ('f', 'फ़'), ('q', 'क़'), ('x', 'क्स')
    ];

    final buffer = StringBuffer();
    int i = 0;
    final n = w.length;

    while (i < n) {
      // Check for nasal 'n' before consonants (turn to anusvara ं)
      if (w[i] == 'n' && i + 1 < n && 'kgcjtdpbzs'.contains(w[i + 1]) && buffer.isNotEmpty) {
        buffer.write('ं');
        i++;
        continue;
      }

      // 1. Check if leading or standalone vowel
      if (i == 0 || buffer.isEmpty) {
        bool vMatch = false;
        for (final v in leadVowels) {
          if (w.startsWith(v.$1, i)) {
            buffer.write(v.$2);
            i += v.$1.length;
            vMatch = true;
            break;
          }
        }
        if (vMatch) continue;
      }

      // 2. Check consonant
      bool cMatch = false;
      for (final c in consonants) {
        if (w.startsWith(c.$1, i)) {
          buffer.write(c.$2);
          i += c.$1.length;
          cMatch = true;

          // Now check if a vowel follows this consonant to apply matra
          for (final m in matras) {
            if (w.startsWith(m.$1, i)) {
              if (m.$1 == 'a') {
                // 'a' at the end of a word attaches 'ा', e.g. apna -> अपना, kesariya -> केसरिया
                if (i + 1 == n) {
                  buffer.write('ा');
                }
              } else {
                buffer.write(m.$2);
              }
              i += m.$1.length;
              break;
            }
          }
          break;
        }
      }

      // 3. Standalone vowel in the middle
      if (!cMatch) {
        bool vMatch = false;
        for (final v in leadVowels) {
          if (w.startsWith(v.$1, i)) {
            for (final m in matras) {
              if (m.$1 == v.$1) {
                buffer.write(m.$2);
                vMatch = true;
                i += v.$1.length;
                break;
              }
            }
            if (!vMatch) {
              buffer.write(v.$2);
              vMatch = true;
              i += v.$1.length;
            }
            break;
          }
        }
        if (!vMatch) {
          buffer.write(w[i]);
          i++;
        }
      }
    }

    final result = buffer.toString();
    return result.isEmpty ? input : result;
  }

  /// Cleans raw lyrics by stripping timestamps, LRC metadata headers, and publisher noise,
  /// preserving only the authentic lyrics lines formatted in Devanagari.
  static String cleanLyricsText(String raw) {
    if (raw.isEmpty) return '';
    final lines = raw.split('\n');
    final timestampRegex = RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]');
    final headerRegex = RegExp(r'^\[[a-zA-Z]{2,8}:.*\]$');
    final cleanLines = <String>[];

    for (var line in lines) {
      line = line.replaceAll(timestampRegex, '').trim();
      if (line.isEmpty) continue;
      if (headerRegex.hasMatch(line)) continue;
      if (_isGarbageLine(line)) continue;

      final devanagari = toDevanagari(line);
      if (devanagari.trim().isNotEmpty) {
        cleanLines.add(devanagari);
      }
    }

    return cleanLines.join('\n');
  }

  static bool _isGarbageLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('written by') ||
        lower.contains('गीतकार') ||
        lower.contains('lyrics powered by') ||
        lower.contains('musixmatch') ||
        lower.contains('genius.com') ||
        lower.contains('synced by') ||
        lower.contains('sync by') ||
        lower.contains('translated by') ||
        lower.contains('distributed by') ||
        lower.contains('all rights reserved') ||
        lower.contains('copyright') ||
        lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('www.');
  }
}
