/**
 * ==========================================================
 * ABHI SUNO (अभी सुनो) - WEB CONFIGURATION
 * Developed by Abhishek Pal (Computer Science & Engineering Student)
 * Support Email: abhisunoji@gmail.com
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
  
  // Official Support Email
  contactEmail: "abhisunoji@gmail.com",
  
  // Direct Download Link for Latest Release APK on GitHub
  downloadUrl: "https://github.com/palabhishek40629/abhi_suno/releases/download/v3.9.0-30/AbhiSuno-v3.9.0-release.apk",
  
  // GitHub Releases Page
  githubReleasesUrl: "https://github.com/palabhishek40629/abhi_suno/releases/latest",
  
  // GitHub Repository
  githubRepoUrl: "https://github.com/palabhishek40629/abhi_suno",
  
  // Live Website URL
  liveWebsiteUrl: "https://palabhishek40629.github.io/abhi_suno/",
  
  // Super Short Shareable Links
  shortUrl: "https://tinyurl.com/abhisuno-apk",
  shortUrlAlias2: "https://tinyurl.com/abhisunoji",
  
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
  setupFeedbackForm();

  const yearElem = document.getElementById("current-year");
  if (yearElem) {
    yearElem.textContent = new Date().getFullYear();
  }
});

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
  const copyToast = document.getElementById("copy-toast");

  // Setup Copy URL Buttons
  const copyShortBtn = document.getElementById("copy-short-url-btn");
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

      // Show Loading State
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

        // Check if FormSubmit sent confirmation or success
        if (data.success === "true" || data.success === true || (data.message && data.message.includes("We've sent you an email"))) {
          showStatus(
            `🎉 बहुत बहुत धन्यवाद, <strong>${name}</strong>! आपका फीडबैक सफलतापूर्वक <strong>${APP_CONFIG.contactEmail}</strong> पर भेज दिया गया है। हम जल्द ही आपसे संपर्क करेंगे।`,
            "success"
          );
          form.reset();
          if (ratingText) ratingText.textContent = "5.0 ★";
        } else {
          // Fallback via mailto
          showStatus(
            `संदेश दर्ज हो गया है! अगर ऑटो-मेल में देरी हो तो आप सीधे <a href="mailto:${APP_CONFIG.contactEmail}?subject=Abhi Suno Feedback&body=${encodeURIComponent(message)}" class="underline font-bold">${APP_CONFIG.contactEmail}</a> पर भी ईमेल कर सकते हैं।`,
            "info"
          );
        }
      } catch (err) {
        console.error("Feedback submit error:", err);
        showStatus(
          `नेटवर्क समस्या! कृपया सीधे ईमेल करें: <a href="mailto:${APP_CONFIG.contactEmail}?subject=Abhi Suno Feedback&body=${encodeURIComponent(message)}" class="underline font-bold text-cyan-400">${APP_CONFIG.contactEmail}</a>`,
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
