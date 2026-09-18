# 🎵 Abhi Suno - Open Source Hybrid Music App

<p align="center">
  <img src="https://img.shields.io/badge/Developer-Abhishek%20Pal-05D9E8?style=for-the-badge&logo=android" alt="Abhishek Pal"/>
  <img src="https://img.shields.io/badge/License-MIT-FF2A6D?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/100%25-Ad--Free-00E676?style=for-the-badge" alt="Ad-Free"/>
  <img src="https://img.shields.io/badge/Platform-Android%20APK-FF9100?style=for-the-badge" alt="Platform"/>
</p>

---

## 🌟 परिचय (Introduction)
**Abhi Suno** एक प्रीमियम, आधुनिक और 100% ओपन-सोर्स Android म्यूज़िक स्ट्रीमिंग व ऑफलाइन डाउनलोडर ऐप है, जिसे **अभिषेक पाल (Abhishek Pal)** द्वारा डिज़ाइन और विकसित किया गया है।

यह ऐप YouTube Music की तरह बिना किसी विज्ञापन (Ad-Free) के दुनिया भर के करोड़ों गाने—विशेष रूप से **बॉलीवुड, 90s रेट्रो क्लासिक्स, रोमांटिक, पंजाबी बीट्स और लो-फाई (Lo-Fi)**—को ऑनलाइन स्ट्रीम करने और फोन के अंदर सुरक्षित रूप से डाउनलोड करके बिना इंटरनेट के बजाने की पूरी आज़ादी देता है।

---

## ✨ मुख्य विशेषताएँ (Key Features)

* 🎨 **3D "A" Logo & Modern Dark Theme:** YouTube लोगो की जगह आकर्षक 3D "A" अल्फ़ाबेट नियॉन बैज और स्लीक OLED ब्लैक इंटरफ़ेस।
* 🎵 **विशाल हिंदी व इंटरनेशनल संगीत लाइब्रेरी:** अरिजीत सिंह, श्रेया घोषाल, किशोर कुमार, सिद्धू मूसेवाला से लेकर हर नए-पुराने गाने की तुरंत खोज (Search)।
* 🚫 **100% Ad-Free (कोई विज्ञापन नहीं):** गानों के बीच में कोई भी रुकावट, बैनर या पॉप-अप नहीं।
* 💾 **In-App Sandboxed Downloads:** डाउनलोड किए गए गाने सुरक्षित रूप से ऐप के आंतरिक वॉल्ट (`abhi_suno_vault`) में रहते हैं और बिना इंटरनेट (Offline Mode) में कभी भी बजते हैं।
* 🎧 **Background Playback & Lockscreen Notification:** स्क्रीन लॉक होने पर भी गाना लगातार बजता रहता है और लॉकस्क्रीन से ही Next/Previous/Pause किया जा सकता है।
* 📑 **Real-time Lyrics (बोल):** गाने के साथ-साथ स्क्रीन पर बोल देखने की सुविधा।
* 🎚️ **Equalizer & Bass Boost:** अपने कानों के हिसाब से बास और साउंड इफ़ेक्ट्स एडजस्ट करने के लिए कस्टम इक्वलाइज़र।
* 👤 **About Developer:** ऐप में अभिषेक पाल (Abhishek Pal) का प्रोफाइल और ओपन-सोर्स जानकारी।
* 🛡️ **Zero Crash Guarantee:** सुरक्षित एरर-बाउंड्री के साथ बनाया गया मजबूत कोड।

---

## 🚀 अपने फोन के लिए `.apk` फ़ाइल कैसे बनाएं (GitHub Actions से 3 मिनट में)

आपको अपने कंप्यूटर पर कोई भारी सॉफ्टवेयर (Android Studio / Flutter SDK) डालने की ज़रूरत नहीं है। हमने GitHub Actions का ऑटोमेटेड वर्कफ़्लो पहले से जोड़ दिया है:

### स्टेप 1: GitHub पर नया रिपॉजिटरी बनाएं
1. [GitHub.com](https://github.com) पर जाएं और लॉगिन करें।
2. ऊपर दाईं ओर **`+`** आइकन पर क्लिक करके **"New repository"** चुनें।
3. रिपॉजिटरी का नाम लिखें: **`abhi_suno`** और **"Create repository"** पर क्लिक करें।

### स्टेप 2: इस फोल्डर की फाइल्स अपलोड करें
1. GitHub पेज पर **"uploading an existing file"** पर क्लिक करें।
2. अपने Desktop पर रखे **`abhi_suno`** फोल्डर की सभी फाइल्स और फोल्डर्स (जैसे `.github`, `android`, `lib`, `pubspec.yaml` आदि) को ड्रैग करके GitHub पर छोड़ दें।
3. नीचे **"Commit changes"** बटन दबाएं।

### स्टेप 3: 1-Click में APK डाउनलोड करें
1. अपने रिपॉजिटरी में ऊपर **"Actions"** टैब पर क्लिक करें।
2. वहाँ **"Build Abhi Suno APK"** वर्कफ़्लो अपने आप चलना शुरू हो जाएगा (लगभग 2-3 मिनट में हरा टिक ✅ लग जाएगा)।
3. उस पर क्लिक करें, और नीचे **Artifacts** सेक्शन में **`AbhiSuno-v1.0.0-release`** पर क्लिक करके सीधे `.apk` डाउनलोड कर लें!
4. इस `.apk` को अपने फोन में भेजें, इंस्टॉल करें और असीमित संगीत का आनंद लें!

---

## 💻 लोकल डेवलपमेंट (यदि आपके कंप्यूटर पर Flutter है)

```bash
# प्रोजेक्ट डायरेक्टरी में जाएं
cd abhi_suno

# डिपेंडेंसी इनस्टॉल करें
flutter pub get

# डीबग मोड में ऐप चलाएं
flutter run

# सीधे APK बिल्ड करें
flutter build apk --release
```

तैयार APK आपको यहाँ मिलेगी:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 👨‍💻 डेवलपर व कॉपीराइट (Developer Credits)

* **निर्माता व लीड डेवलपर:** **अभिषेक पाल (Abhishek Pal)**
* **लाइसेंस:** [MIT License](LICENSE) (मुक्त और ओपन सोर्स)
* **प्राइवेसी:** यह ऐप किसी भी प्रकार का व्यक्तिगत डेटा एकत्र नहीं करता। 100% प्राइवेसी फ्रेंडली।

---
<p align="center">Made with ❤️ for Music Lovers by <b>Abhishek Pal</b></p>
