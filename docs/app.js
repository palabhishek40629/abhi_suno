/**
 * ==========================================================
 * ABHI SUNO (अभी सुनो) - WEB CONFIGURATION & NO-CODE ADMIN CMS
 * Developed by Abhishek Pal (Computer Science & Engineering Student)
 * Support Email: abhisunoji@gmail.com
 * ==========================================================
 */

// Default Configuration Object
const DEFAULT_CONFIG = {
  appName: "Abhi Suno",
  appNameHindi: "अभी सुनो",
  version: "v3.9.0 Master Edition",
  fileSize: "66 MB",
  minAndroid: "Android 7.0+",
  packageName: "com.abhishekpal.abhisuno",
  developerName: "Abhishek Pal",
  developerTitle: "Computer Science & Engineering Student",
  contactEmail: "abhisunoji@gmail.com",
  
  // Direct Download Link for Latest Release APK on GitHub
  downloadUrl: "https://github.com/palabhishek40629/abhi_suno/releases/download/v3.9.0-30/AbhiSuno-v3.9.0-release.apk",
  githubReleasesUrl: "https://github.com/palabhishek40629/abhi_suno/releases/latest",
  githubRepoUrl: "https://github.com/palabhishek40629/abhi_suno",
  liveWebsiteUrl: "https://palabhishek40629.github.io/abhi_suno/",
  
  // Short Links
  shortUrl: "https://tinyurl.com/abhisuno-apk",
  shortUrlAlias2: "https://tinyurl.com/abhisunoji",
  
  description: "बिना किसी विज्ञापन (Ad-Free) के लाखों गाने सुनें, ऑफलाइन डाउनलोड करें, और दोस्तों के साथ पार्टी रूम में एक साथ संगीत का आनंद लें!",
  apkFileName: "AbhiSuno-v3.9.0-release.apk",
  
  // Announcement Banner
  announcementEnabled: false,
  announcementText: "🎉 Abhi Suno v3.9.0 Master Edition New Update Live!"
};

// Active Working Config (Merged with localStorage if available)
let APP_CONFIG = { ...DEFAULT_CONFIG };

// Load Saved Custom Config from LocalStorage
try {
  const saved = localStorage.getItem("abhi_suno_custom_config");
  if (saved) {
    const parsed = JSON.parse(saved);
    APP_CONFIG = { ...APP_CONFIG, ...parsed };
  }
} catch (_) {}

/**
 * Initialize DOM Elements and Event Listeners
 */
document.addEventListener("DOMContentLoaded", () => {
  applyConfig();
  setupQrCode();
  setupFaqAccordion();
  setupDownloadFlow();
  setupFeedbackForm();
  setupAdminSystem();

  const yearElem = document.getElementById("current-year");
  if (yearElem) {
    yearElem.textContent = new Date().getFullYear();
  }
});

/**
 * Apply Config to DOM Elements
 */
function applyConfig() {
  document.title = `${APP_CONFIG.appName} (${APP_CONFIG.appNameHindi}) - Download Official Android APK | ${APP_CONFIG.version}`;

  // App Name
  document.querySelectorAll(".app-name").forEach(el => {
    el.textContent = APP_CONFIG.appName;
  });

  // App Version
  document.querySelectorAll(".app-version").forEach(el => {
    el.textContent = APP_CONFIG.version;
  });

  // File Size
  document.querySelectorAll(".app-size").forEach(el => {
    el.textContent = APP_CONFIG.fileSize;
  });

  // Requirements
  document.querySelectorAll(".app-req").forEach(el => {
    el.textContent = APP_CONFIG.minAndroid;
  });

  // Package Name
  document.querySelectorAll(".app-package").forEach(el => {
    el.textContent = APP_CONFIG.packageName;
  });

  // Tagline / Description
  document.querySelectorAll(".app-desc").forEach(el => {
    el.textContent = APP_CONFIG.description;
  });

  // Main download button link
  const mainBtn = document.getElementById("main-download-btn");
  if (mainBtn) {
    mainBtn.href = APP_CONFIG.downloadUrl;
  }

  // Modal direct link
  const modalDirectLink = document.getElementById("modal-direct-link");
  if (modalDirectLink) {
    modalDirectLink.href = APP_CONFIG.downloadUrl;
  }

  // Announcement Banner
  const banner = document.getElementById("admin-announcement-banner");
  const bannerText = document.getElementById("announcement-text");
  if (banner && bannerText) {
    if (APP_CONFIG.announcementEnabled && APP_CONFIG.announcementText) {
      bannerText.textContent = APP_CONFIG.announcementText;
      banner.classList.remove("hidden");
    } else {
      banner.classList.add("hidden");
    }
  }

  // Update QR Code
  setupQrCode();
}

function setupQrCode() {
  const qrImg = document.getElementById("qr-code-img");
  if (qrImg) {
    const targetUrl = encodeURIComponent(APP_CONFIG.downloadUrl);
    qrImg.src = `https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${targetUrl}&margin=4`;
  }
}

function setupDownloadFlow() {
  const mainBtn = document.getElementById("main-download-btn");
  const modal = document.getElementById("download-modal");
  const closeModalBtn = document.getElementById("close-modal-btn");
  const modalDirectLink = document.getElementById("modal-direct-link");

  if (!mainBtn || !modal) return;

  if (modalDirectLink) {
    modalDirectLink.href = APP_CONFIG.downloadUrl;
  }

  mainBtn.addEventListener("click", (e) => {
    modal.classList.remove("hidden");
    setTimeout(() => {
      window.location.href = APP_CONFIG.downloadUrl;
    }, 1000);
  });

  if (closeModalBtn) {
    closeModalBtn.addEventListener("click", () => {
      modal.classList.add("hidden");
    });
  }

  modal.addEventListener("click", (e) => {
    if (e.target === modal) {
      modal.classList.add("hidden");
    }
  });
}

function setupFaqAccordion() {
  const faqItems = document.querySelectorAll(".faq-item");

  faqItems.forEach(item => {
    const btn = item.querySelector(".faq-btn");
    const content = item.querySelector(".faq-content");
    const icon = btn.querySelector("i");

    btn.addEventListener("click", () => {
      const isOpen = !content.classList.contains("hidden");

      document.querySelectorAll(".faq-content").forEach(c => c.classList.add("hidden"));
      document.querySelectorAll(".faq-btn i").forEach(i => {
        i.classList.remove("rotate-180");
      });

      if (!isOpen) {
        content.classList.remove("hidden");
        icon.classList.add("rotate-180");
      }
    });
  });
}

/**
 * Setup Interactive Feedback Form & Star Rating
 */
function setupFeedbackForm() {
  const form = document.getElementById("feedback-form");
  const submitBtn = document.getElementById("fb-submit-btn");
  const statusBox = document.getElementById("fb-status");
  const starBtns = document.querySelectorAll(".star-btn");
  const ratingInput = document.getElementById("fb-rating");
  const ratingText = document.getElementById("rating-text");
  const copyBtn = document.getElementById("copy-web-url-btn");
  const copyShortBtn = document.getElementById("copy-short-url-btn");
  const copyToast = document.getElementById("copy-toast");

  // Setup Copy URL Buttons
  if (copyShortBtn) {
    copyShortBtn.addEventListener("click", () => {
      navigator.clipboard.writeText(APP_CONFIG.shortUrl).then(() => {
        if (copyToast) {
          copyToast.textContent = "✓ शॉर्ट लिंक कॉपी हो गया (tinyurl.com/abhisuno-apk)!";
          copyToast.classList.remove("hidden");
          setTimeout(() => {
            copyToast.classList.add("hidden");
          }, 2500);
        }
      }).catch(() => {
        prompt("शॉर्ट लिंक कॉपी करें:", APP_CONFIG.shortUrl);
      });
    });
  }

  if (copyBtn) {
    copyBtn.addEventListener("click", () => {
      navigator.clipboard.writeText(APP_CONFIG.liveWebsiteUrl).then(() => {
        if (copyToast) {
          copyToast.textContent = "✓ पूरा लिंक कॉपी हो गया!";
          copyToast.classList.remove("hidden");
          setTimeout(() => {
            copyToast.classList.add("hidden");
          }, 2500);
        }
      }).catch(() => {
        prompt("वेबसाइट लिंक कॉपी करें:", APP_CONFIG.liveWebsiteUrl);
      });
    });
  }

  // Setup Star Rating Selection
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

  // Handle Form Submission
  if (form) {
    form.addEventListener("submit", async (e) => {
      e.preventDefault();

      const name = document.getElementById("fb-name")?.value?.trim() || "";
      const email = document.getElementById("fb-email")?.value?.trim() || "";
      const category = document.getElementById("fb-category")?.value || "";
      const rating = ratingInput?.value || "5";
      const message = document.getElementById("fb-message")?.value?.trim() || "";

      if (!name || !email || !message) {
        showStatus("कृपया सभी आवश्यक फ़ील्ड भरें।", "error");
        return;
      }

      const originalBtnHtml = submitBtn.innerHTML;
      submitBtn.disabled = true;
      submitBtn.innerHTML = `<i class="fa-solid fa-circle-notch fa-spin"></i> <span>भेज रहा है...</span>`;

      try {
        const payload = {
          name: name,
          email: email,
          category: category,
          rating: `${rating} / 5 Stars`,
          message: message,
          _subject: `Abhi Suno Feedback from ${name} [${category}]`,
          _template: "table"
        };

        const res = await fetch(`https://formsubmit.co/ajax/${APP_CONFIG.contactEmail}`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json"
          },
          body: JSON.stringify(payload)
        });

        const data = await res.json();

        if (data.success === "true" || data.success === true || (data.message && data.message.includes("We've sent you an email"))) {
          showStatus(
            `🎉 बहुत बहुत धन्यवाद, <strong>${name}</strong>! आपका फीडबैक सफलतापूर्वक <strong>${APP_CONFIG.contactEmail}</strong> पर भेज दिया गया है।`,
            "success"
          );
          form.reset();
          if (ratingText) ratingText.textContent = "5.0 ★";
        } else {
          showStatus(
            `संदेश दर्ज हो गया है! अगर ऑटो-मेल में देरी हो तो आप सीधे <a href="mailto:${APP_CONFIG.contactEmail}?subject=Abhi Suno Feedback&body=${encodeURIComponent(message)}" class="underline font-bold">${APP_CONFIG.contactEmail}</a> पर भी ईमेल कर सकते हैं।`,
            "info"
          );
        }
      } catch (err) {
        console.error("Feedback submit error:", err);
        showStatus(
          `कृपया सीधे ईमेल करें: <a href="mailto:${APP_CONFIG.contactEmail}?subject=Abhi Suno Feedback&body=${encodeURIComponent(message)}" class="underline font-bold text-cyan-400">${APP_CONFIG.contactEmail}</a>`,
          "error"
        );
      } finally {
        submitBtn.disabled = false;
        submitBtn.innerHTML = originalBtnHtml;
      }
    });
  }

  function showStatus(htmlMsg, type) {
    if (!statusBox) return;
    statusBox.classList.remove("hidden", "bg-emerald-950/80", "border-emerald-500/50", "text-emerald-200", "bg-rose-950/80", "border-rose-500/50", "text-rose-200", "bg-cyan-950/80", "border-cyan-500/50", "text-cyan-200");

    if (type === "success") {
      statusBox.classList.add("bg-emerald-950/80", "border", "border-emerald-500/50", "text-emerald-200");
    } else if (type === "info") {
      statusBox.classList.add("bg-cyan-950/80", "border", "border-cyan-500/50", "text-cyan-200");
    } else {
      statusBox.classList.add("bg-rose-950/80", "border", "border-rose-500/50", "text-rose-200");
    }

    statusBox.innerHTML = htmlMsg;
    statusBox.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }
}

/**
 * ==========================================================
 * NO-CODE ADMIN CMS SYSTEM
 * Developed for Abhishek Pal (abhisunoji@gmail.com)
 * ==========================================================
 */
function setupAdminSystem() {
  const adminNavBtn = document.getElementById("admin-login-nav-btn");
  const loginModal = document.getElementById("admin-login-modal");
  const closeLoginBtn = document.getElementById("close-admin-login-btn");
  const loginForm = document.getElementById("admin-login-form");
  const loginError = document.getElementById("admin-login-error");

  const panelModal = document.getElementById("admin-panel-modal");
  const closePanelBtn = document.getElementById("close-admin-panel-btn");
  const settingsForm = document.getElementById("admin-settings-form");
  const panelAlert = document.getElementById("admin-panel-alert");

  const floatingDock = document.getElementById("admin-floating-dock");
  const dockOpenPanelBtn = document.getElementById("dock-open-panel-btn");
  const dockLogoutBtn = document.getElementById("dock-logout-btn");
  const adminLogoutBtn = document.getElementById("admin-logout-btn");
  const adminResetBtn = document.getElementById("admin-reset-btn");
  const downloadConfigBtn = document.getElementById("admin-download-config-btn");

  // Check if Admin is already logged in
  const isLoggedIn = sessionStorage.getItem("abhi_suno_admin_logged_in") === "true";
  if (isLoggedIn && floatingDock) {
    floatingDock.classList.remove("hidden");
  }

  // Open Login Modal
  if (adminNavBtn) {
    adminNavBtn.addEventListener("click", () => {
      if (sessionStorage.getItem("abhi_suno_admin_logged_in") === "true") {
        openAdminPanel();
      } else {
        if (loginModal) loginModal.classList.remove("hidden");
      }
    });
  }

  // Close Login Modal
  if (closeLoginBtn && loginModal) {
    closeLoginBtn.addEventListener("click", () => {
      loginModal.classList.add("hidden");
    });
  }

  // Handle Login Form Submit
  if (loginForm) {
    loginForm.addEventListener("submit", (e) => {
      e.preventDefault();
      const email = document.getElementById("admin-email-input")?.value?.trim()?.toLowerCase() || "";
      const password = document.getElementById("admin-password-input")?.value?.trim() || "";
      const savedPwd = localStorage.getItem("abhi_suno_admin_pwd") || "abhi@2026";

      if (email === "abhisunoji@gmail.com" && password === savedPwd) {
        sessionStorage.setItem("abhi_suno_admin_logged_in", "true");
        if (loginModal) loginModal.classList.add("hidden");
        if (floatingDock) floatingDock.classList.remove("hidden");
        if (loginError) loginError.classList.add("hidden");
        openAdminPanel();
      } else {
        if (loginError) {
          loginError.textContent = "गलत ईमेल या पासवर्ड! केवल abhisunoji@gmail.com और सही पासवर्ड से लॉगिन करें।";
          loginError.classList.remove("hidden");
        }
      }
    });
  }

  // Open Admin Panel
  function openAdminPanel() {
    if (!panelModal) return;

    // Populate Fields with current config
    const setVal = (id, val) => {
      const el = document.getElementById(id);
      if (el) el.value = val || "";
    };

    setVal("cfg-app-name", APP_CONFIG.appName);
    setVal("cfg-app-version", APP_CONFIG.version);
    setVal("cfg-download-url", APP_CONFIG.downloadUrl);
    setVal("cfg-file-size", APP_CONFIG.fileSize);
    setVal("cfg-min-android", APP_CONFIG.minAndroid);
    setVal("cfg-package-name", APP_CONFIG.packageName);
    setVal("cfg-description", APP_CONFIG.description);

    const bannerCheck = document.getElementById("cfg-announcement-enabled");
    if (bannerCheck) bannerCheck.checked = !!APP_CONFIG.announcementEnabled;
    setVal("cfg-announcement-text", APP_CONFIG.announcementText || "");

    const newPwdInput = document.getElementById("cfg-new-password");
    if (newPwdInput) newPwdInput.value = "";

    panelModal.classList.remove("hidden");
  }

  // Close Admin Panel
  if (closePanelBtn && panelModal) {
    closePanelBtn.addEventListener("click", () => {
      panelModal.classList.add("hidden");
    });
  }

  if (dockOpenPanelBtn) {
    dockOpenPanelBtn.addEventListener("click", openAdminPanel);
  }

  // Handle Save Settings
  if (settingsForm) {
    settingsForm.addEventListener("submit", (e) => {
      e.preventDefault();

      const getVal = (id) => document.getElementById(id)?.value?.trim() || "";

      APP_CONFIG.appName = getVal("cfg-app-name") || APP_CONFIG.appName;
      APP_CONFIG.version = getVal("cfg-app-version") || APP_CONFIG.version;
      APP_CONFIG.downloadUrl = getVal("cfg-download-url") || APP_CONFIG.downloadUrl;
      APP_CONFIG.fileSize = getVal("cfg-file-size") || APP_CONFIG.fileSize;
      APP_CONFIG.minAndroid = getVal("cfg-min-android") || APP_CONFIG.minAndroid;
      APP_CONFIG.packageName = getVal("cfg-package-name") || APP_CONFIG.packageName;
      APP_CONFIG.description = getVal("cfg-description") || APP_CONFIG.description;

      const bannerCheck = document.getElementById("cfg-announcement-enabled");
      APP_CONFIG.announcementEnabled = bannerCheck ? bannerCheck.checked : false;
      APP_CONFIG.announcementText = getVal("cfg-announcement-text") || APP_CONFIG.announcementText;

      // Handle Password Change
      const newPwd = getVal("cfg-new-password");
      if (newPwd.length >= 4) {
        localStorage.setItem("abhi_suno_admin_pwd", newPwd);
      }

      // Save to localStorage
      try {
        localStorage.setItem("abhi_suno_custom_config", JSON.stringify(APP_CONFIG));
      } catch (err) {
        console.error("Storage error:", err);
      }

      // Apply Live Changes Immediately
      applyConfig();

      // Show Success Feedback
      if (panelAlert) {
        panelAlert.className = "p-3 rounded-xl text-xs font-semibold bg-emerald-950/90 border border-emerald-500/50 text-emerald-200 block";
        panelAlert.innerHTML = `✓ बहुत बढ़िया! सभी बदलाव बिना किसी कोडिंग के तुरंत वेबसाइट पर लागू हो गए हैं।`;
        setTimeout(() => {
          panelAlert.className = "hidden";
          if (panelModal) panelModal.classList.add("hidden");
        }, 1600);
      }
    });
  }

  // Handle Reset Defaults
  const doReset = () => {
    if (confirm("क्या आप सच में सभी सेटिंग्स को डिफ़ॉल्ट पर रीसेट करना चाहते हैं?")) {
      localStorage.removeItem("abhi_suno_custom_config");
      localStorage.removeItem("abhi_suno_admin_pwd");
      APP_CONFIG = { ...DEFAULT_CONFIG };
      applyConfig();
      if (panelModal) panelModal.classList.add("hidden");
      alert("सेटिंग्स डिफ़ॉल्ट पर रीसेट हो गई हैं!");
    }
  };

  if (adminResetBtn) adminResetBtn.addEventListener("click", doReset);

  // Handle Logout
  const doLogout = () => {
    sessionStorage.removeItem("abhi_suno_admin_logged_in");
    if (floatingDock) floatingDock.classList.add("hidden");
    if (panelModal) panelModal.classList.add("hidden");
    alert("एडमिन पैनल से सफलतापूर्वक लॉगआउट हो गया।");
  };

  if (adminLogoutBtn) adminLogoutBtn.addEventListener("click", doLogout);
  if (dockLogoutBtn) dockLogoutBtn.addEventListener("click", doLogout);

  // Handle Download Config File
  if (downloadConfigBtn) {
    downloadConfigBtn.addEventListener("click", () => {
      const jsonStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(APP_CONFIG, null, 2));
      const dlAnchor = document.createElement("a");
      dlAnchor.setAttribute("href", jsonStr);
      dlAnchor.setAttribute("download", "abhisuno-config.json");
      document.body.appendChild(dlAnchor);
      dlAnchor.click();
      dlAnchor.remove();
    });
  }
}
