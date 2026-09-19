/**
 * =========================================================================
 * ABHI SUNO (अभी सुनो) - ADVANCED NO-CODE CMS & CLOUD STORAGE ENGINE
 * Developed for Abhishek Pal (abhisunoji@gmail.com)
 * Features:
 *   - Full No-Code Content & Media Customization
 *   - Single-Click Up / Down Reordering (▲ / ▼)
 *   - Public / Private Visibility Toggle (🌐 / 🔒)
 *   - 15GB Google Drive Link Auto-Converter
 *   - Local Image Upload & Instant Base64 Preview
 *   - Full Mobile & Desktop Responsive
 * =========================================================================
 */

// Default Master Configuration & Content State
const DEFAULT_CMS_DATA = {
  // App & General
  appName: "Abhi Suno",
  appNameHindi: "अभी सुनो",
  version: "v3.9.0 Master Edition",
  fileSize: "66 MB",
  minAndroid: "Android 7.0+",
  packageName: "com.abhishekpal.abhisuno",
  developerName: "अभिषेक पाल (Abhishek Pal)",
  developerTitle: "Computer Science & Engineering Student",
  contactEmail: "abhisunoji@gmail.com",
  adminPassword: "abhi@2026",
  
  // Hero Section
  heroTitlePrefix: "संगीत का असली मज़ा,",
  heroTitleHighlight: "Abhi Suno",
  heroTitleSuffix: "के साथ!",
  heroDescription: "बिना किसी विज्ञापन (Ad-Free) के लाखों गाने सुनें, ऑफलाइन डाउनलोड करें, और दोस्तों के साथ पार्टी रूम ('सुनो साथ में') में एक साथ गाने का आनंद लें!",
  heroPosterImage: "assets/images/abhishek_promo.jpg",
  heroRating: "4.9",
  heroDownloadsText: "100K+ Downloads",
  
  // Downloads & Links
  downloadUrl: "https://github.com/palabhishek40629/abhi_suno/releases/download/v3.9.0-30/AbhiSuno-v3.9.0-release.apk",
  githubReleasesUrl: "https://github.com/palabhishek40629/abhi_suno/releases/latest",
  githubRepoUrl: "https://github.com/palabhishek40629/abhi_suno",
  liveWebsiteUrl: "https://palabhishek40629.github.io/abhi_suno/",
  shortUrl: "https://tinyurl.com/abhisuno-apk",
  shortUrlAlias2: "https://tinyurl.com/abhisunoji",
  
  // Announcement Banner
  announcement: {
    enabled: false,
    text: "🎉 Abhi Suno Master Edition New Update Live!"
  },
  
  // Dynamic Features List (Single-click Reorder + Public/Private)
  features: [
    {
      id: "feat-1",
      title: "पार्टी रूम ('सुनो साथ में')",
      desc: "दोस्तों के साथ 1 कोड से जुड़ें और सभी के फोन पर एक ही समय पर एक साथ गाना बजाएं। रियल-टाइम पल्स सिंक!",
      icon: "fa-solid fa-users-rays",
      color: "cyan",
      isPublic: true
    },
    {
      id: "feat-2",
      title: "सैंडबॉक्स्ड ऑफलाइन डाउनलोड्स",
      desc: "बिना इंटरनेट के कभी भी सुनें। गाने ऐप के अंदर सुरक्षित सेव होते हैं और कभी डिलीट नहीं होते।",
      icon: "fa-solid fa-cloud-arrow-down",
      color: "indigo",
      isPublic: true
    },
    {
      id: "feat-3",
      title: "100% Ad-Free (बिना विज्ञापन)",
      desc: "गाने के बीच में कोई रुकावट नहीं, न ही कोई वीडियो ओवरहेड। शुद्ध हाई-डेफिनिशन 320kbps ऑडियो।",
      icon: "fa-solid fa-ban",
      color: "teal",
      isPublic: true
    },
    {
      id: "feat-4",
      title: "21+ भारतीय व विदेशी भाषाएँ",
      desc: "हिंदी, भोजपुरी, पंजाबी, हरियाणवी, तेलुगु, तमिल, इंग्लिश सहित 21+ भाषाओं का समर्पित चयन केंद्र।",
      icon: "fa-solid fa-language",
      color: "purple",
      isPublic: true
    },
    {
      id: "feat-5",
      title: "3D डायनामिक टेक्टाइल UI",
      desc: "नियॉन ग्लो, 3D एलिवेशन बटन्स, लाइव इक्वलाइज़र बार्स और स्प्लिट-टैप फास्ट कंट्रोल।",
      icon: "fa-solid fa-cube",
      color: "amber",
      isPublic: true
    },
    {
      id: "feat-6",
      title: "डायरेक्ट प्लेएबल शेयर लिंक",
      desc: "व्हाट्सएप पर शेयर करने पर सामने वाले को सीधे 1-क्लिक में बजने वाला लिंक मिलता है।",
      icon: "fa-solid fa-share-nodes",
      color: "rose",
      isPublic: true
    }
  ],
  
  // Dynamic Screenshots / Media Gallery (Single-click Reorder + Public/Private)
  gallery: [
    {
      id: "gal-1",
      title: "Official Promo Poster",
      subtitle: "Abhishek Pal & Abhi Suno 3D",
      image: "assets/images/abhishek_promo.jpg",
      isPublic: true
    },
    {
      id: "gal-2",
      title: "3D Emblem Badge",
      subtitle: "Master Edition Iconography",
      image: "assets/images/emblem.png",
      isPublic: true
    },
    {
      id: "gal-3",
      title: "Full Poster Art",
      subtitle: "Studio Music Player Artwork",
      image: "assets/images/startup_poster.png",
      isPublic: true
    },
    {
      id: "gal-4",
      title: "App Icon Wide",
      subtitle: "HD Resolution Branding",
      image: "assets/images/logo_wide.png",
      isPublic: true
    }
  ],
  
  // Dynamic FAQs List (Single-click Reorder + Public/Private)
  faqs: [
    {
      id: "faq-1",
      question: "क्या Abhi Suno ऐप सच में 100% फ्री और ऐड-फ्री है?",
      answer: "हाँ, बिल्कुल! Abhi Suno पूरी तरह से ओपन-सोर्स और नॉन-कमर्शियल ऐप है। इसमें न तो कोई ऑडियो ऐड आता है और न ही कोई बैनर ऐड।",
      isPublic: true
    },
    {
      id: "faq-2",
      question: "डाउनलोड करने पर क्रोम 'File might be harmful' क्यों दिखाता है?",
      answer: "Google Chrome किसी भी ऐसी APK फाइल को जो सीधे प्ले स्टोर के बाहर से डाउनलोड होती है, चेतावनी दिखाता है। यह सामान्य सुरक्षा नियम है। हमारी APK 100% साफ और वायरस-मुक्त है, आप निडर होकर 'Download anyway' चुन सकते हैं।",
      isPublic: true
    },
    {
      id: "faq-3",
      question: "पार्टी रूम ('सुनो साथ में') कैसे काम करता है?",
      answer: "प्रोफाइल स्क्रीन में 'पार्टी रूम बनाएं' दबाने पर 6-अंकों का कोड मिलता है। अपने दोस्तों को वह कोड दें या व्हाट्सएप पर इनवाइट भेजें। वे 'रूम से जुड़ें' में वह कोड डालेंगे और सभी के फोन में एक साथ वही गाना बजने लगेगा!",
      isPublic: true
    },
    {
      id: "faq-4",
      question: "नया वर्जन आने पर ऐप कैसे अपडेट करें?",
      answer: "ऐप के अंदर सेटिंग्स में 'Check for Updates' विकल्प मौजूद है, या आप कभी भी इसी वेबसाइट पर आकर नया APK डाउनलोड करके इंस्टॉल कर सकते हैं। आपका पुराना डेटा और डाउनलोड्स सुरक्षित रहेंगे।",
      isPublic: true
    }
  ]
};

// Active Reactive CMS State
let CMS = { ...DEFAULT_CMS_DATA };

// Load Saved Custom State from LocalStorage
try {
  const savedState = localStorage.getItem("abhi_suno_full_cms_v1");
  if (savedState) {
    const parsed = JSON.parse(savedState);
    CMS = { ...DEFAULT_CMS_DATA, ...parsed };
  }
} catch (e) {
  console.warn("CMS state load error:", e);
}

/**
 * Boot Initialization
 */
document.addEventListener("DOMContentLoaded", () => {
  renderAll();
  setupEventListeners();
  setupFeedbackForm();
  setupAdminCMS();

  const yearElem = document.getElementById("current-year");
  if (yearElem) {
    yearElem.textContent = new Date().getFullYear();
  }
});

/**
 * Master Render Function (Syncs State to DOM)
 */
function renderAll() {
  renderHeroAndMeta();
  renderFeatures();
  renderGallery();
  renderFaqs();
  renderAnnouncement();
  setupQrCode();
}

/**
 * Render Hero, Headers, Titles & Downloads
 */
function renderHeroAndMeta() {
  document.title = `${CMS.appName} (${CMS.appNameHindi}) - Download Official Android APK | ${CMS.version}`;

  // App Name
  document.querySelectorAll(".app-name").forEach(el => el.textContent = CMS.appName);
  document.querySelectorAll(".app-version").forEach(el => el.textContent = CMS.version);
  document.querySelectorAll(".app-size").forEach(el => el.textContent = CMS.fileSize);
  document.querySelectorAll(".app-req").forEach(el => el.textContent = CMS.minAndroid);
  document.querySelectorAll(".app-package").forEach(el => el.textContent = CMS.packageName);

  // Hero Descriptions
  const heroDescEl = document.getElementById("hero-desc");
  if (heroDescEl) heroDescEl.textContent = CMS.heroDescription;

  // Hero Poster Image
  const heroPosterEl = document.getElementById("hero-poster-img");
  if (heroPosterEl && CMS.heroPosterImage) {
    heroPosterEl.src = CMS.heroPosterImage;
  }

  // Developer Avatar Image
  const devAvatarEl = document.getElementById("dev-avatar-img");
  if (devAvatarEl && CMS.heroPosterImage) {
    devAvatarEl.src = CMS.heroPosterImage;
  }

  // Download Button Links
  const mainBtn = document.getElementById("main-download-btn");
  if (mainBtn) mainBtn.href = CMS.downloadUrl;

  const modalDirectLink = document.getElementById("modal-direct-link");
  if (modalDirectLink) modalDirectLink.href = CMS.downloadUrl;

  // Short link elements
  const shortUrlEl = document.getElementById("short-web-url");
  if (shortUrlEl) shortUrlEl.textContent = CMS.shortUrl;
}

/**
 * Render Announcement Banner
 */
function renderAnnouncement() {
  const banner = document.getElementById("admin-announcement-banner");
  const bannerText = document.getElementById("announcement-text");
  if (banner && bannerText) {
    if (CMS.announcement && CMS.announcement.enabled && CMS.announcement.text) {
      bannerText.textContent = CMS.announcement.text;
      banner.classList.remove("hidden");
    } else {
      banner.classList.add("hidden");
    }
  }
}

/**
 * Render Dynamic Features with Public/Private Support
 */
function renderFeatures() {
  const container = document.getElementById("features-container");
  if (!container) return;

  const isAdmin = sessionStorage.getItem("abhi_suno_admin_logged_in") === "true";
  
  // Filter by public unless in admin mode
  const displayFeatures = CMS.features.filter(f => isAdmin || f.isPublic !== false);

  if (displayFeatures.length === 0) {
    container.innerHTML = `<div class="col-span-3 text-center py-10 text-slate-500 text-sm">कोई फीचर उपलब्ध नहीं है।</div>`;
    return;
  }

  const colorMap = {
    cyan: { bg: "bg-cyan-500/10", border: "border-cyan-500/20", hoverBorder: "hover:border-cyan-500/50", text: "text-cyan-400", hoverBg: "group-hover:bg-cyan-500", hoverText: "group-hover:text-slate-950" },
    indigo: { bg: "bg-indigo-500/10", border: "border-indigo-500/20", hoverBorder: "hover:border-indigo-500/50", text: "text-indigo-400", hoverBg: "group-hover:bg-indigo-500", hoverText: "group-hover:text-white" },
    teal: { bg: "bg-teal-500/10", border: "border-teal-500/20", hoverBorder: "hover:border-teal-500/50", text: "text-teal-400", hoverBg: "group-hover:bg-teal-500", hoverText: "group-hover:text-slate-950" },
    purple: { bg: "bg-purple-500/10", border: "border-purple-500/20", hoverBorder: "hover:border-purple-500/50", text: "text-purple-400", hoverBg: "group-hover:bg-purple-500", hoverText: "group-hover:text-white" },
    amber: { bg: "bg-amber-500/10", border: "border-amber-500/20", hoverBorder: "hover:border-amber-500/50", text: "text-amber-400", hoverBg: "group-hover:bg-amber-500", hoverText: "group-hover:text-slate-950" },
    rose: { bg: "bg-rose-500/10", border: "border-rose-500/20", hoverBorder: "hover:border-rose-500/50", text: "text-rose-400", hoverBg: "group-hover:bg-rose-500", hoverText: "group-hover:text-white" }
  };

  container.innerHTML = displayFeatures.map(f => {
    const c = colorMap[f.color] || colorMap.cyan;
    const privateBadge = !f.isPublic && isAdmin ? 
      `<span class="ml-2 bg-amber-500/20 text-amber-300 border border-amber-500/40 text-[10px] font-bold px-2 py-0.5 rounded-full"><i class="fa-solid fa-lock mr-1"></i>Private</span>` : "";

    return `
      <div class="p-6 rounded-2xl bg-slate-900/70 border border-slate-800 ${c.hoverBorder} transition-all group hover:-translate-y-1 relative">
        <div class="flex items-center justify-between mb-4">
          <div class="w-12 h-12 rounded-xl ${c.bg} border ${c.border} flex items-center justify-center ${c.text} text-xl ${c.hoverBg} ${c.hoverText} transition-colors">
            <i class="${f.icon || 'fa-solid fa-star'}"></i>
          </div>
          ${privateBadge}
        </div>
        <h3 class="text-lg font-bold text-white mb-2">${escapeHtml(f.title)}</h3>
        <p class="text-slate-400 text-sm leading-relaxed">${escapeHtml(f.desc)}</p>
      </div>
    `;
  }).join("");
}

/**
 * Render Dynamic Gallery / Screenshots with Public/Private Support
 */
function renderGallery() {
  const container = document.getElementById("gallery-container");
  if (!container) return;

  const isAdmin = sessionStorage.getItem("abhi_suno_admin_logged_in") === "true";
  const displayGallery = CMS.gallery.filter(g => isAdmin || g.isPublic !== false);

  if (displayGallery.length === 0) {
    container.innerHTML = `<div class="col-span-4 text-center py-8 text-slate-500 text-sm">कोई मीडिया उपलब्ध नहीं है।</div>`;
    return;
  }

  container.innerHTML = displayGallery.map(g => {
    const privateBadge = !g.isPublic && isAdmin ? 
      `<span class="absolute top-3 right-3 bg-amber-950/90 text-amber-300 border border-amber-500/40 text-[10px] font-bold px-2 py-0.5 rounded-full z-10"><i class="fa-solid fa-lock mr-1"></i>Private</span>` : "";

    return `
      <div class="rounded-2xl overflow-hidden border border-slate-800 bg-slate-900 p-2 shadow-xl hover:scale-[1.02] transition-transform relative group">
        ${privateBadge}
        <div class="aspect-[4/5] rounded-xl overflow-hidden bg-slate-950 flex flex-col items-center justify-center text-center relative">
          <img src="${g.image}" alt="${escapeHtml(g.title)}" class="w-full h-full object-cover rounded-xl" onerror="this.src='assets/images/logo.png'">
          <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950 via-slate-950/80 to-transparent p-3 pt-6 text-left">
            <span class="text-xs font-bold text-white block truncate">${escapeHtml(g.title)}</span>
            <span class="text-[10px] text-cyan-300 block truncate">${escapeHtml(g.subtitle || '')}</span>
          </div>
        </div>
      </div>
    `;
  }).join("");
}

/**
 * Render Dynamic FAQs with Public/Private Support
 */
function renderFaqs() {
  const container = document.getElementById("faqs-container");
  if (!container) return;

  const isAdmin = sessionStorage.getItem("abhi_suno_admin_logged_in") === "true";
  const displayFaqs = CMS.faqs.filter(faq => isAdmin || faq.isPublic !== false);

  if (displayFaqs.length === 0) {
    container.innerHTML = `<div class="text-center py-6 text-slate-500 text-sm">कोई सवाल उपलब्ध नहीं है।</div>`;
    return;
  }

  container.innerHTML = displayFaqs.map((faq, idx) => {
    const privateBadge = !faq.isPublic && isAdmin ? 
      `<span class="ml-2 bg-amber-500/20 text-amber-300 border border-amber-500/40 text-[10px] font-bold px-2 py-0.5 rounded-full"><i class="fa-solid fa-lock mr-1"></i>Private</span>` : "";

    return `
      <div class="faq-item border border-slate-800 rounded-xl bg-slate-900/60 overflow-hidden mb-3">
        <button type="button" class="faq-btn w-full p-5 text-left flex items-center justify-between font-semibold text-slate-200 hover:text-cyan-400 transition-colors">
          <span class="flex items-center">${escapeHtml(faq.question)} ${privateBadge}</span>
          <i class="fa-solid fa-chevron-down text-xs transition-transform duration-200"></i>
        </button>
        <div class="faq-content hidden px-5 pb-5 text-sm text-slate-400 leading-relaxed border-t border-slate-800/60 pt-3">
          ${escapeHtml(faq.answer)}
        </div>
      </div>
    `;
  }).join("");

  setupFaqAccordion();
}

function setupQrCode() {
  const qrImg = document.getElementById("qr-code-img");
  if (qrImg) {
    const targetUrl = encodeURIComponent(CMS.downloadUrl);
    qrImg.src = `https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${targetUrl}&margin=4`;
  }
}

function setupEventListeners() {
  setupDownloadFlow();

  // Copy buttons
  const copyShortBtn = document.getElementById("copy-short-url-btn");
  const copyBtn = document.getElementById("copy-web-url-btn");
  const copyToast = document.getElementById("copy-toast");

  if (copyShortBtn) {
    copyShortBtn.addEventListener("click", () => {
      navigator.clipboard.writeText(CMS.shortUrl).then(() => {
        if (copyToast) {
          copyToast.textContent = "✓ शॉर्ट लिंक कॉपी हो गया (tinyurl.com/abhisuno-apk)!";
          copyToast.classList.remove("hidden");
          setTimeout(() => copyToast.classList.add("hidden"), 2500);
        }
      });
    });
  }

  if (copyBtn) {
    copyBtn.addEventListener("click", () => {
      navigator.clipboard.writeText(CMS.liveWebsiteUrl).then(() => {
        if (copyToast) {
          copyToast.textContent = "✓ पूरा लिंक कॉपी हो गया!";
          copyToast.classList.remove("hidden");
          setTimeout(() => copyToast.classList.add("hidden"), 2500);
        }
      });
    });
  }
}

function setupDownloadFlow() {
  const mainBtn = document.getElementById("main-download-btn");
  const modal = document.getElementById("download-modal");
  const closeModalBtn = document.getElementById("close-modal-btn");
  const modalDirectLink = document.getElementById("modal-direct-link");

  if (!mainBtn || !modal) return;

  if (modalDirectLink) modalDirectLink.href = CMS.downloadUrl;

  mainBtn.addEventListener("click", (e) => {
    modal.classList.remove("hidden");
    setTimeout(() => {
      window.location.href = CMS.downloadUrl;
    }, 1000);
  });

  if (closeModalBtn) {
    closeModalBtn.addEventListener("click", () => modal.classList.add("hidden"));
  }

  modal.addEventListener("click", (e) => {
    if (e.target === modal) modal.classList.add("hidden");
  });
}

function setupFaqAccordion() {
  const faqItems = document.querySelectorAll(".faq-item");
  faqItems.forEach(item => {
    const btn = item.querySelector(".faq-btn");
    const content = item.querySelector(".faq-content");
    const icon = btn?.querySelector("i");
    if (!btn || !content) return;

    btn.onclick = () => {
      const isOpen = !content.classList.contains("hidden");
      document.querySelectorAll(".faq-content").forEach(c => c.classList.add("hidden"));
      document.querySelectorAll(".faq-btn i").forEach(i => i.classList.remove("rotate-180"));

      if (!isOpen) {
        content.classList.remove("hidden");
        if (icon) icon.classList.add("rotate-180");
      }
    };
  });
}

/**
 * Setup Feedback Form
 */
function setupFeedbackForm() {
  const form = document.getElementById("feedback-form");
  const submitBtn = document.getElementById("fb-submit-btn");
  const statusBox = document.getElementById("fb-status");
  const starBtns = document.querySelectorAll(".star-btn");
  const ratingInput = document.getElementById("fb-rating");
  const ratingText = document.getElementById("rating-text");

  if (starBtns.length > 0) {
    starBtns.forEach(btn => {
      btn.addEventListener("click", () => {
        const rating = parseInt(btn.getAttribute("data-rating"), 10);
        if (ratingInput) ratingInput.value = rating;
        if (ratingText) ratingText.textContent = `${rating}.0 ★`;

        starBtns.forEach(s => {
          const sRating = parseInt(s.getAttribute("data-rating"), 10);
          const icon = s.querySelector("i");
          if (icon) {
            if (sRating <= rating) {
              icon.className = "fa-solid fa-star text-amber-400";
            } else {
              icon.className = "fa-regular fa-star text-slate-600";
            }
          }
        });
      });
    });
  }

  if (form) {
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const name = document.getElementById("fb-name")?.value?.trim() || "";
      const email = document.getElementById("fb-email")?.value?.trim() || "";
      const category = document.getElementById("fb-category")?.value || "";
      const rating = ratingInput?.value || "5";
      const message = document.getElementById("fb-message")?.value?.trim() || "";

      if (!name || !email || !message) return;

      const origHtml = submitBtn.innerHTML;
      submitBtn.disabled = true;
      submitBtn.innerHTML = `<i class="fa-solid fa-circle-notch fa-spin"></i> <span>भेज रहा है...</span>`;

      try {
        const payload = {
          name, email, category,
          rating: `${rating} / 5 Stars`,
          message,
          _subject: `Abhi Suno Feedback from ${name} [${category}]`,
          _template: "table"
        };

        const res = await fetch(`https://formsubmit.co/ajax/${CMS.contactEmail}`, {
          method: "POST",
          headers: { "Content-Type": "application/json", "Accept": "application/json" },
          body: JSON.stringify(payload)
        });
        const data = await res.json();

        if (statusBox) {
          statusBox.className = "p-4 rounded-xl text-sm bg-emerald-950/80 border border-emerald-500/50 text-emerald-200 block";
          statusBox.innerHTML = `🎉 बहुत बहुत धन्यवाद, <strong>${escapeHtml(name)}</strong>! आपका फीडबैक सफलतापूर्वक <strong>${CMS.contactEmail}</strong> पर भेज दिया गया है।`;
          form.reset();
        }
      } catch (err) {
        if (statusBox) {
          statusBox.className = "p-4 rounded-xl text-sm bg-rose-950/80 border border-rose-500/50 text-rose-200 block";
          statusBox.innerHTML = `सीधे ईमेल करें: <a href="mailto:${CMS.contactEmail}?subject=Abhi Suno Feedback" class="underline font-bold">${CMS.contactEmail}</a>`;
        }
      } finally {
        submitBtn.disabled = false;
        submitBtn.innerHTML = origHtml;
      }
    });
  }
}

/**
 * =========================================================================
 * ADVANCED NO-CODE CMS ADMIN ENGINE (Tabs, Reorder, Upload, Visibility)
 * =========================================================================
 */
function setupAdminCMS() {
  const adminNavBtn = document.getElementById("admin-login-nav-btn");
  const loginModal = document.getElementById("admin-login-modal");
  const closeLoginBtn = document.getElementById("close-admin-login-btn");
  const loginForm = document.getElementById("admin-login-form");
  const loginError = document.getElementById("admin-login-error");

  const panelModal = document.getElementById("admin-panel-modal");
  const closePanelBtn = document.getElementById("close-admin-panel-btn");
  const floatingDock = document.getElementById("admin-floating-dock");
  const dockOpenPanelBtn = document.getElementById("dock-open-panel-btn");
  const dockLogoutBtn = document.getElementById("dock-logout-btn");
  const adminLogoutBtn = document.getElementById("admin-logout-btn");

  // Check login state
  const isLoggedIn = sessionStorage.getItem("abhi_suno_admin_logged_in") === "true";
  if (isLoggedIn && floatingDock) {
    floatingDock.classList.remove("hidden");
  }

  // Admin Login open/close
  if (adminNavBtn) {
    adminNavBtn.addEventListener("click", () => {
      if (sessionStorage.getItem("abhi_suno_admin_logged_in") === "true") {
        openCmsPanel();
      } else {
        if (loginModal) loginModal.classList.remove("hidden");
      }
    });
  }

  if (closeLoginBtn && loginModal) {
    closeLoginBtn.addEventListener("click", () => loginModal.classList.add("hidden"));
  }

  // Handle Login
  if (loginForm) {
    loginForm.addEventListener("submit", (e) => {
      e.preventDefault();
      const email = document.getElementById("admin-email-input")?.value?.trim()?.toLowerCase() || "";
      const password = document.getElementById("admin-password-input")?.value?.trim() || "";
      const savedPwd = localStorage.getItem("abhi_suno_admin_pwd") || CMS.adminPassword || "abhi@2026";

      if (email === "abhisunoji@gmail.com" && password === savedPwd) {
        sessionStorage.setItem("abhi_suno_admin_logged_in", "true");
        if (loginModal) loginModal.classList.add("hidden");
        if (floatingDock) floatingDock.classList.remove("hidden");
        if (loginError) loginError.classList.add("hidden");
        renderAll(); // Re-render with private items visible to admin
        openCmsPanel();
      } else {
        if (loginError) {
          loginError.textContent = "गलत पासवर्ड! केवल abhisunoji@gmail.com और सही पासवर्ड से लॉगिन करें।";
          loginError.classList.remove("hidden");
        }
      }
    });
  }

  // Open CMS Panel
  function openCmsPanel() {
    if (!panelModal) return;
    populateCmsInputs();
    renderCmsFeaturesTab();
    renderCmsGalleryTab();
    renderCmsFaqsTab();
    panelModal.classList.remove("hidden");
  }

  if (closePanelBtn && panelModal) {
    closePanelBtn.addEventListener("click", () => panelModal.classList.add("hidden"));
  }

  if (dockOpenPanelBtn) {
    dockOpenPanelBtn.addEventListener("click", openCmsPanel);
  }

  // Logout
  const doLogout = () => {
    sessionStorage.removeItem("abhi_suno_admin_logged_in");
    if (floatingDock) floatingDock.classList.add("hidden");
    if (panelModal) panelModal.classList.add("hidden");
    renderAll();
    alert("एडमिन पैनल से सफलतापूर्वक लॉगआउट हो गया।");
  };

  if (adminLogoutBtn) adminLogoutBtn.addEventListener("click", doLogout);
  if (dockLogoutBtn) dockLogoutBtn.addEventListener("click", doLogout);

  // Setup Admin Tabs Switching
  setupCmsTabs();

  // Setup Image File Upload Handlers (Hero Poster & Gallery)
  setupImageUploaders();

  // Setup Google Drive Converter Tool
  setupGoogleDriveTools();

  // Setup Save / Backup Handlers
  setupCmsSaveAndBackup();
}

/**
 * Switch Admin CMS Tabs
 */
function setupCmsTabs() {
  const tabBtns = document.querySelectorAll(".cms-tab-btn");
  const tabPanes = document.querySelectorAll(".cms-tab-pane");

  tabBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      const targetTab = btn.getAttribute("data-tab");

      tabBtns.forEach(b => {
        b.classList.remove("border-cyan-400", "text-cyan-400", "bg-cyan-500/10");
        b.classList.add("text-slate-400", "border-transparent");
      });
      btn.classList.add("border-cyan-400", "text-cyan-400", "bg-cyan-500/10");
      btn.classList.remove("text-slate-400", "border-transparent");

      tabPanes.forEach(pane => {
        if (pane.id === `tab-${targetTab}`) {
          pane.classList.remove("hidden");
        } else {
          pane.classList.add("hidden");
        }
      });
    });
  });
}

/**
 * Populate General CMS Form Inputs
 */
function populateCmsInputs() {
  const setVal = (id, val) => {
    const el = document.getElementById(id);
    if (el) el.value = val || "";
  };

  setVal("cms-app-name", CMS.appName);
  setVal("cms-app-version", CMS.version);
  setVal("cms-download-url", CMS.downloadUrl);
  setVal("cms-file-size", CMS.fileSize);
  setVal("cms-min-android", CMS.minAndroid);
  setVal("cms-package-name", CMS.packageName);
  setVal("cms-hero-desc", CMS.heroDescription);
  setVal("cms-poster-url", CMS.heroPosterImage);

  // Announcement
  const annCheck = document.getElementById("cms-ann-enabled");
  if (annCheck) annCheck.checked = !!(CMS.announcement && CMS.announcement.enabled);
  setVal("cms-ann-text", (CMS.announcement && CMS.announcement.text) || "");

  // Update poster preview
  const preview = document.getElementById("cms-poster-preview");
  if (preview && CMS.heroPosterImage) {
    preview.src = CMS.heroPosterImage;
  }
}

/**
 * Setup Local Image File Uploaders with instant Base64 preview
 */
function setupImageUploaders() {
  // Hero Poster File Input
  const posterFileInput = document.getElementById("cms-poster-file-input");
  const posterUrlInput = document.getElementById("cms-poster-url");
  const posterPreview = document.getElementById("cms-poster-preview");

  if (posterFileInput) {
    posterFileInput.addEventListener("change", (e) => {
      const file = e.target.files[0];
      if (!file) return;

      if (file.size > 8 * 1024 * 1024) {
        alert("कृपया 8 MB से कम साइज की इमेज चुनें।");
        return;
      }

      const reader = new FileReader();
      reader.onload = (event) => {
        const dataUrl = event.target.result;
        CMS.heroPosterImage = dataUrl;
        if (posterUrlInput) posterUrlInput.value = "[Local Uploaded Image]";
        if (posterPreview) posterPreview.src = dataUrl;
        // Live update on hero section
        renderHeroAndMeta();
      };
      reader.readAsDataURL(file);
    });
  }

  // URL input change for poster
  if (posterUrlInput) {
    posterUrlInput.addEventListener("input", (e) => {
      const url = e.target.value.trim();
      if (url && url !== "[Local Uploaded Image]") {
        CMS.heroPosterImage = convertGoogleDriveLink(url);
        if (posterPreview) posterPreview.src = CMS.heroPosterImage;
        renderHeroAndMeta();
      }
    });
  }
}

/**
 * 15GB Google Drive Link Auto-Converter
 * Converts standard Google Drive view/share URLs to direct download & image streaming URLs!
 */
function convertGoogleDriveLink(url) {
  if (!url) return url;
  const match = url.match(/\/file\/d\/([a-zA-Z0-9_-]+)/) || url.match(/id=([a-zA-Z0-9_-]+)/);
  if (match && match[1]) {
    const fileId = match[1];
    return `https://drive.google.com/uc?export=download&id=${fileId}`;
  }
  return url;
}

/**
 * Setup Google Drive 15GB Tools Tab
 */
function setupGoogleDriveTools() {
  const convertInput = document.getElementById("drive-input-url");
  const convertBtn = document.getElementById("drive-convert-btn");
  const resultBox = document.getElementById("drive-convert-result");
  const resultInput = document.getElementById("drive-result-url");
  const copyBtn = document.getElementById("drive-copy-btn");
  const setAsApkBtn = document.getElementById("drive-set-as-apk-btn");

  if (convertBtn && convertInput) {
    convertBtn.addEventListener("click", () => {
      const raw = convertInput.value.trim();
      if (!raw) {
        alert("कृपया अपना Google Drive शेयर लिंक पेस्ट करें।");
        return;
      }

      const direct = convertGoogleDriveLink(raw);
      if (resultInput) resultInput.value = direct;
      if (resultBox) resultBox.classList.remove("hidden");
    });
  }

  if (copyBtn && resultInput) {
    copyBtn.addEventListener("click", () => {
      navigator.clipboard.writeText(resultInput.value).then(() => {
        alert("✓ डायरेक्ट ड्राइव लिंक कॉपी हो गया!");
      });
    });
  }

  if (setAsApkBtn && resultInput) {
    setAsApkBtn.addEventListener("click", () => {
      CMS.downloadUrl = resultInput.value;
      const apkInput = document.getElementById("cms-download-url");
      if (apkInput) apkInput.value = resultInput.value;
      renderHeroAndMeta();
      alert("✓ डायरेक्ट डाउनलोड लिंक APK बटन पर सेट हो गया!");
    });
  }
}

/**
 * Render Features Manager Tab in CMS (Single-Click Reorder & Public/Private)
 */
function renderCmsFeaturesTab() {
  const container = document.getElementById("cms-features-list");
  if (!container) return;

  container.innerHTML = CMS.features.map((feat, idx) => {
    const isFirst = idx === 0;
    const isLast = idx === CMS.features.length - 1;
    const publicState = feat.isPublic !== false;

    return `
      <div class="p-4 rounded-xl bg-slate-950 border border-slate-800 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 mb-2" data-id="${feat.id}">
        <div class="flex items-center gap-3 flex-1 min-w-0">
          <div class="w-10 h-10 rounded-lg bg-slate-900 border border-slate-700 flex items-center justify-center text-cyan-400 shrink-0">
            <i class="${feat.icon || 'fa-solid fa-star'}"></i>
          </div>
          <div class="truncate">
            <div class="text-xs font-bold text-white flex items-center gap-2">
              <span class="truncate">${escapeHtml(feat.title)}</span>
              <span class="${publicState ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40' : 'bg-amber-500/20 text-amber-300 border-amber-500/40'} border text-[10px] px-2 py-0.5 rounded-full">
                ${publicState ? '🌐 Public' : '🔒 Private'}
              </span>
            </div>
            <p class="text-[11px] text-slate-400 truncate">${escapeHtml(feat.desc)}</p>
          </div>
        </div>

        <div class="flex items-center gap-1.5 self-end sm:self-auto shrink-0">
          <!-- Up Button -->
          <button type="button" class="btn-feat-up p-1.5 rounded-lg bg-slate-900 hover:bg-cyan-500/20 text-slate-300 hover:text-cyan-300 text-xs transition-colors ${isFirst ? 'opacity-30 cursor-not-allowed' : ''}" data-idx="${idx}" ${isFirst ? 'disabled' : ''} title="ऊपर ले जाएं">
            <i class="fa-solid fa-arrow-up"></i>
          </button>
          <!-- Down Button -->
          <button type="button" class="btn-feat-down p-1.5 rounded-lg bg-slate-900 hover:bg-cyan-500/20 text-slate-300 hover:text-cyan-300 text-xs transition-colors ${isLast ? 'opacity-30 cursor-not-allowed' : ''}" data-idx="${idx}" ${isLast ? 'disabled' : ''} title="नीचे ले जाएं">
            <i class="fa-solid fa-arrow-down"></i>
          </button>
          <!-- Visibility Toggle -->
          <button type="button" class="btn-feat-toggle px-2 py-1 rounded-lg text-xs font-medium transition-colors ${publicState ? 'bg-slate-900 hover:bg-amber-950 text-slate-300 hover:text-amber-300' : 'bg-amber-900/40 text-amber-300'}" data-idx="${idx}" title="पब्लिक या प्राइवेट करें">
            <i class="fa-solid ${publicState ? 'fa-eye' : 'fa-eye-slash'} mr-1"></i> ${publicState ? 'छिपाएं' : 'दिखाएं'}
          </button>
          <!-- Delete -->
          <button type="button" class="btn-feat-del p-1.5 rounded-lg bg-slate-900 hover:bg-rose-950 text-slate-400 hover:text-rose-400 text-xs transition-colors" data-idx="${idx}" title="हटाएं">
            <i class="fa-solid fa-trash-can"></i>
          </button>
        </div>
      </div>
    `;
  }).join("");

  // Attach Listeners
  container.querySelectorAll(".btn-feat-up").forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute("data-idx"), 10);
      if (idx > 0) {
        const temp = CMS.features[idx];
        CMS.features[idx] = CMS.features[idx - 1];
        CMS.features[idx - 1] = temp;
        renderCmsFeaturesTab();
        renderFeatures();
      }
    };
  });

  container.querySelectorAll(".btn-feat-down").forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute("data-idx"), 10);
      if (idx < CMS.features.length - 1) {
        const temp = CMS.features[idx];
        CMS.features[idx] = CMS.features[idx + 1];
        CMS.features[idx + 1] = temp;
        renderCmsFeaturesTab();
        renderFeatures();
      }
    };
  });

  container.querySelectorAll(".btn-feat-toggle").forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute("data-idx"), 10);
      CMS.features[idx].isPublic = !CMS.features[idx].isPublic;
      renderCmsFeaturesTab();
      renderFeatures();
    };
  });

  container.querySelectorAll(".btn-feat-del").forEach(btn => {
    btn.onclick = () => {
      const idx = parseInt(btn.getAttribute("data-idx"), 10);
      if (confirm("क्या आप सच में इस फीचर को हटाना चाहते हैं?")) {
        CMS.features.splice(idx, 1);
        renderCmsFeaturesTab();
        renderFeatures();
      }
    };
  });

  // Add Feature Button
  const addBtn = document.getElementById("cms-add-feature-btn");
  if (addBtn) {
    addBtn.onclick = () => {
      const title = prompt("नए फीचर का नाम:");
      if (!title) return;
      const desc = prompt("फीचर का विवरण:") || "";

      CMS.features.push({
        id: `feat-${Date.now()}`,
        title,
        desc,
        icon: "fa-solid fa-sparkles",
        color: "cyan",
        isPublic: true
      });
      renderCmsFeaturesTab();
      renderFeatures();
    };
  }
}

/**
 * Render Gallery / Media Manager Tab in CMS
 */
function renderCmsGalleryTab() {
  const container = document.getElementById("cms-gallery-list");
  if (!container) return;

  container.innerHTML = CMS.gallery.map((item, idx) => {
    const isFirst = idx === 0;
    const isLast = idx === CMS.gallery.length - 1;
    const publicState = item.isPublic !== false;

    return `
      <div class="p-3 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-between gap-3 mb-2">
        <div class="flex items-center gap-3 min-w-0">
          <img src="${item.image}" alt="${escapeHtml(item.title)}" class="w-12 h-12 rounded-lg object-cover bg-slate-900 border border-slate-700 shrink-0">
          <div class="truncate">
            <div class="text-xs font-bold text-white flex items-center gap-2">
              <span class="truncate">${escapeHtml(item.title)}</span>
              <span class="${publicState ? 'bg-emerald-500/20 text-emerald-300' : 'bg-amber-500/20 text-amber-300'} text-[10px] px-1.5 py-0.2 rounded font-bold">
                ${publicState ? 'Public' : 'Private'}
              </span>
            </div>
            <span class="text-[10px] text-slate-400 block truncate">${escapeHtml(item.subtitle || '')}</span>
          </div>
        </div>

        <div class="flex items-center gap-1 shrink-0">
          <button type="button" class="btn-gal-up p-1.5 rounded-lg bg-slate-900 text-slate-300 hover:text-cyan-300 text-xs ${isFirst ? 'opacity-30' : ''}" data-idx="${idx}" ${isFirst ? 'disabled' : ''}><i class="fa-solid fa-arrow-up"></i></button>
          <button type="button" class="btn-gal-down p-1.5 rounded-lg bg-slate-900 text-slate-300 hover:text-cyan-300 text-xs ${isLast ? 'opacity-30' : ''}" data-idx="${idx}" ${isLast ? 'disabled' : ''}><i class="fa-solid fa-arrow-down"></i></button>
          <button type="button" class="btn-gal-toggle px-2 py-1 rounded-lg text-xs bg-slate-900 text-slate-300" data-idx="${idx}">${publicState ? 'छिपाएं' : 'दिखाएं'}</button>
          <button type="button" class="btn-gal-del p-1.5 rounded-lg bg-slate-900 text-rose-400 hover:bg-rose-950 text-xs" data-idx="${idx}"><i class="fa-solid fa-trash-can"></i></button>
        </div>
      </div>
    `;
  }).join("");

  // Gallery Listeners
  container.querySelectorAll(".btn-gal-up").forEach(b => {
    b.onclick = () => {
      const idx = parseInt(b.getAttribute("data-idx"), 10);
      if (idx > 0) {
        const t = CMS.gallery[idx];
        CMS.gallery[idx] = CMS.gallery[idx - 1];
        CMS.gallery[idx - 1] = t;
        renderCmsGalleryTab();
        renderGallery();
      }
    };
  });

  container.querySelectorAll(".btn-gal-down").forEach(b => {
    b.onclick = () => {
      const idx = parseInt(b.getAttribute("data-idx"), 10);
      if (idx < CMS.gallery.length - 1) {
        const t = CMS.gallery[idx];
        CMS.gallery[idx] = CMS.gallery[idx + 1];
        CMS.gallery[idx + 1] = t;
        renderCmsGalleryTab();
        renderGallery();
      }
    };
  });

  container.querySelectorAll(".btn-gal-toggle").forEach(b => {
    b.onclick = () => {
      const idx = parseInt(b.getAttribute("data-idx"), 10);
      CMS.gallery[idx].isPublic = !CMS.gallery[idx].isPublic;
      renderCmsGalleryTab();
      renderGallery();
    };
  });

  container.querySelectorAll(".btn-gal-del").forEach(b => {
    b.onclick = () => {
      const idx = parseInt(b.getAttribute("data-idx"), 10);
      if (confirm("इस फोटो को गैलरी से हटाएं?")) {
        CMS.gallery.splice(idx, 1);
        renderCmsGalleryTab();
        renderGallery();
      }
    };
  });

  // Add Image File to Gallery
  const galFileInput = document.getElementById("cms-add-gallery-file");
  if (galFileInput) {
    galFileInput.onchange = (e) => {
      const file = e.target.files[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (event) => {
        const title = prompt("फोटो का शीर्षक (Title):", file.name.replace(/\.[^/.]+$/, "")) || "Screenshot";
        CMS.gallery.push({
          id: `gal-${Date.now()}`,
          title,
          subtitle: "App Screenshot",
          image: event.target.result,
          isPublic: true
        });
        renderCmsGalleryTab();
        renderGallery();
      };
      reader.readAsDataURL(file);
    };
  }

  // Add Google Drive Image URL to Gallery
  const addDriveImgBtn = document.getElementById("cms-add-gallery-url-btn");
  if (addDriveImgBtn) {
    addDriveImgBtn.onclick = () => {
      const rawUrl = prompt("Google Drive शेयर लिंक या इमेज का URL डालें:");
      if (!rawUrl) return;
      const imgUrl = convertGoogleDriveLink(rawUrl.trim());
      const title = prompt("फोटो का शीर्षक (Title):") || "Media Preview";

      CMS.gallery.push({
        id: `gal-${Date.now()}`,
        title,
        subtitle: "Cloud Image",
        image: imgUrl,
        isPublic: true
      });
      renderCmsGalleryTab();
      renderGallery();
    };
  }
}

/**
 * Render FAQs Manager Tab in CMS
 */
function renderCmsFaqsTab() {
  const container = document.getElementById("cms-faqs-list");
  if (!container) return;

  container.innerHTML = CMS.faqs.map((faq, idx) => {
    const isFirst = idx === 0;
    const isLast = idx === CMS.faqs.length - 1;
    const publicState = faq.isPublic !== false;

    return `
      <div class="p-3 rounded-xl bg-slate-950 border border-slate-800 flex items-start justify-between gap-3 mb-2">
        <div class="truncate flex-1">
          <div class="text-xs font-bold text-white flex items-center gap-2">
            <span class="truncate">${escapeHtml(faq.question)}</span>
            <span class="${publicState ? 'bg-emerald-500/20 text-emerald-300' : 'bg-amber-500/20 text-amber-300'} text-[10px] px-1.5 py-0.2 rounded font-bold">
              ${publicState ? 'Public' : 'Private'}
            </span>
          </div>
          <p class="text-[11px] text-slate-400 truncate mt-0.5">${escapeHtml(faq.answer)}</p>
        </div>

        <div class="flex items-center gap-1 shrink-0">
          <button type="button" class="btn-faq-up p-1.5 rounded-lg bg-slate-900 text-slate-300 hover:text-cyan-300 text-xs ${isFirst ? 'opacity-30' : ''}" data-idx="${idx}" ${isFirst ? 'disabled' : ''}><i class="fa-solid fa-arrow-up"></i></button>
          <button type="button" class="btn-faq-down p-1.5 rounded-lg bg-slate-900 text-slate-300 hover:text-cyan-300 text-xs ${isLast ? 'opacity-30' : ''}" data-idx="${idx}" ${isLast ? 'disabled' : ''}><i class="fa-solid fa-arrow-down"></i></button>
          <button type="button" class="btn-faq-toggle px-2 py-1 rounded-lg text-xs bg-slate-900 text-slate-300" data-idx="${idx}">${publicState ? 'छिपाएं' : 'दिखाएं'}</button>
          <button type="button" class="btn-faq-del p-1.5 rounded-lg bg-slate-900 text-rose-400 hover:bg-rose-950 text-xs" data-idx="${idx}"><i class="fa-solid fa-trash-can"></i></button>
        </div>
      </div>
    `;
  }).join("");

  // FAQ Listeners
  container.querySelectorAll(".btn-faq-up").forEach(b => {
    b.onclick = () => {
      const idx = parseInt(b.getAttribute("data-idx"), 10);
      if (idx > 0) {
        const t = CMS.faqs[idx];
        CMS.faqs[idx] = CMS.faqs[idx - 1];
        CMS.faqs[idx - 1] = t;
        renderCmsFaqsTab();
        renderFaqs();
      }
    };
  });

  container.querySelectorAll(".btn-faq-down").forEach(b => {
    b.onclick = () => {
      const idx = parseInt(b.getAttribute("data-idx"), 10);
      if (idx < CMS.faqs.length - 1) {
        const t = CMS.faqs[idx];
        CMS.faqs[idx] = CMS.faqs[idx + 1];
        CMS.faqs[idx + 1] = t;
        renderCmsFaqsTab();
        renderFaqs();
      }
    };
  });

  container.querySelectorAll(".btn-faq-toggle").forEach(b => {
    b.onclick = () => {
      const idx = parseInt(b.getAttribute("data-idx"), 10);
      CMS.faqs[idx].isPublic = !CMS.faqs[idx].isPublic;
      renderCmsFaqsTab();
      renderFaqs();
    };
  });

  container.querySelectorAll(".btn-faq-del").forEach(b => {
    b.onclick = () => {
      const idx = parseInt(b.getAttribute("data-idx"), 10);
      if (confirm("इस FAQ को हटाएं?")) {
        CMS.faqs.splice(idx, 1);
        renderCmsFaqsTab();
        renderFaqs();
      }
    };
  });

  // Add FAQ
  const addFaqBtn = document.getElementById("cms-add-faq-btn");
  if (addFaqBtn) {
    addFaqBtn.onclick = () => {
      const q = prompt("नया सवाल (Question):");
      if (!q) return;
      const a = prompt("उसका जवाब (Answer):") || "";
      CMS.faqs.push({
        id: `faq-${Date.now()}`,
        question: q,
        answer: a,
        isPublic: true
      });
      renderCmsFaqsTab();
      renderFaqs();
    };
  }
}

/**
 * Setup Save All Changes, Backup, and Reset Handlers
 */
function setupCmsSaveAndBackup() {
  const saveBtn = document.getElementById("cms-save-all-btn");
  const resetBtn = document.getElementById("cms-reset-all-btn");
  const backupBtn = document.getElementById("cms-backup-btn");
  const restoreFileInput = document.getElementById("cms-restore-file");
  const alertBox = document.getElementById("cms-save-alert");

  if (saveBtn) {
    saveBtn.addEventListener("click", () => {
      const getVal = (id) => document.getElementById(id)?.value?.trim() || "";

      CMS.appName = getVal("cms-app-name") || CMS.appName;
      CMS.version = getVal("cms-app-version") || CMS.version;
      CMS.downloadUrl = getVal("cms-download-url") || CMS.downloadUrl;
      CMS.fileSize = getVal("cms-file-size") || CMS.fileSize;
      CMS.minAndroid = getVal("cms-min-android") || CMS.minAndroid;
      CMS.packageName = getVal("cms-package-name") || CMS.packageName;
      CMS.heroDescription = getVal("cms-hero-desc") || CMS.heroDescription;

      // Poster URL if entered
      const posterUrl = getVal("cms-poster-url");
      if (posterUrl && posterUrl !== "[Local Uploaded Image]") {
        CMS.heroPosterImage = convertGoogleDriveLink(posterUrl);
      }

      // Announcement
      const annCheck = document.getElementById("cms-ann-enabled");
      CMS.announcement = {
        enabled: annCheck ? annCheck.checked : false,
        text: getVal("cms-ann-text") || ""
      };

      // Password change
      const newPwd = getVal("cms-new-password");
      if (newPwd && newPwd.length >= 4) {
        CMS.adminPassword = newPwd;
        localStorage.setItem("abhi_suno_admin_pwd", newPwd);
      }

      // Persist to LocalStorage
      try {
        localStorage.setItem("abhi_suno_full_cms_v1", JSON.stringify(CMS));
      } catch (err) {
        console.error("Local storage error:", err);
      }

      // Live Re-render
      renderAll();

      if (alertBox) {
        alertBox.className = "p-3.5 rounded-xl bg-emerald-950/90 border border-emerald-500/50 text-emerald-200 text-xs font-bold block animate-fade-in";
        alertBox.innerHTML = `✓ बधाई हो! सभी बदलाव, रीऑर्डर, फोटो और सेटिंग्स तुरंत वेबसाइट पर लाइव लागू हो गए हैं।`;
        setTimeout(() => {
          alertBox.className = "hidden";
        }, 2500);
      }
    });
  }

  // Backup JSON
  if (backupBtn) {
    backupBtn.addEventListener("click", () => {
      const jsonStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(CMS, null, 2));
      const dlAnchor = document.createElement("a");
      dlAnchor.setAttribute("href", jsonStr);
      dlAnchor.setAttribute("download", `abhisuno-cms-backup-${Date.now()}.json`);
      document.body.appendChild(dlAnchor);
      dlAnchor.click();
      dlAnchor.remove();
    });
  }

  // Restore JSON
  if (restoreFileInput) {
    restoreFileInput.addEventListener("change", (e) => {
      const file = e.target.files[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (event) => {
        try {
          const imported = JSON.parse(event.target.result);
          CMS = { ...DEFAULT_CMS_DATA, ...imported };
          localStorage.setItem("abhi_suno_full_cms_v1", JSON.stringify(CMS));
          renderAll();
          openCmsPanel();
          alert("✓ बैकअप फाइल सफलतापूर्वक रीस्टोर हो गई!");
        } catch (err) {
          alert("अमान्य JSON फाइल!");
        }
      };
      reader.readAsText(file);
    });
  }

  // Reset Defaults
  if (resetBtn) {
    resetBtn.addEventListener("click", () => {
      if (confirm("क्या आप सच में सभी कंटेंट और सेटिंग्स को मूल डिफ़ॉल्ट पर रीसेट करना चाहते हैं?")) {
        localStorage.removeItem("abhi_suno_full_cms_v1");
        localStorage.removeItem("abhi_suno_admin_pwd");
        CMS = { ...DEFAULT_CMS_DATA };
        renderAll();
        populateCmsInputs();
        renderCmsFeaturesTab();
        renderCmsGalleryTab();
        renderCmsFaqsTab();
        alert("सभी सेटिंग्स मूल रूप में रीसेट हो गई हैं!");
      }
    });
  }
}

function escapeHtml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
