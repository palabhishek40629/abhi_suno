/**
 * ==========================================================
 * ABHI SUNO (अभी सुनो) - WEB CONFIGURATION
 * Developed by Abhishek Pal (Computer Science & Engineering Student)
 * ==========================================================
 */
const APP_CONFIG = {
  appName: "Abhi Suno",
  appNameHindi: "अभी सुनो",
  version: "v3.9.0 Master Edition",
  fileSize: "66 MB",
  minAndroid: "Android 7.0+",
  packageName: "com.abhishekpal.abhisuno",
  developerName: "Abhishek Pal",
  developerTitle: "Computer Science & Engineering Student",
  
  // Direct Download Link for Latest Release APK on GitHub
  downloadUrl: "https://github.com/palabhishek40629/abhi_suno/releases/download/v3.9.0-30/AbhiSuno-v3.9.0-release.apk",
  
  // GitHub Releases Page
  githubReleasesUrl: "https://github.com/palabhishek40629/abhi_suno/releases/latest",
  
  // GitHub Repository
  githubRepoUrl: "https://github.com/palabhishek40629/abhi_suno",
  
  // Tagline
  description: "बिना किसी विज्ञापन (Ad-Free) के लाखों गाने सुनें, ऑफलाइन डाउनलोड करें, और दोस्तों के साथ पार्टी रूम में एक साथ संगीत का आनंद लें!",
  
  // File Name
  apkFileName: "AbhiSuno-v3.9.0-release.apk"
};

/**
 * Initialize DOM Elements and Event Listeners
 */
document.addEventListener("DOMContentLoaded", () => {
  setupQrCode();
  setupFaqAccordion();
  setupDownloadFlow();

  const yearElem = document.getElementById("current-year");
  if (yearElem) {
    yearElem.textContent = new Date().getFullYear();
  }
});

function setupQrCode() {
  const qrImg = document.getElementById("qr-code-img");
  if (qrImg) {
    // Generate QR code pointing to direct APK download URL
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
    // Show countdown modal
    modal.classList.remove("hidden");

    // Automatically trigger the download
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
