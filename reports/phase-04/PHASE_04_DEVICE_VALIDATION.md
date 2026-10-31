# ScamShield 2.0 — Phase 04 Device Validation Checklist
## Physical Device Verification for OnePlus CPH2467 (Android 15)

**Target Device**: OnePlus Nord CE 3 5G (CPH2467)  
**OS Version**: Android 15 / OxygenOS 15  
**Screen Resolution**: 2412 x 1080 (~394 ppi), 120Hz Fluid AMOLED  
**Backend**: `https://scamshield-backend-f0wc.onrender.com`  
**Execution Context**: Physical device running active Flutter session via ADB  

---

## 1. Visual Alignment Verification against Reference Images

Compare side-by-side with `analysze ape.jpeg` and `analysze ape.2jpeg.jpeg`:

- [ ] **Header Bar**:
  - Title reads `Analyze` in Inter bold typography.
  - Back arrow is clearly visible on the top-left and functional.
  - Native Android status bar and bottom navigation remain undisturbed.

- [ ] **Hero Card (`Analyze & Stay Safe`)**:
  - Soft teal/cyan container rendered with subtle sparkles.
  - Document-search badge with cyan accent icon.
  - Headline reads: `Analyze & Stay Safe`.
  - Subtitle reads: `Check messages, calls, images, documents and audio with AI to detect scams.`.

- [ ] **Input Mode Selector**:
  - 4 tabs displayed horizontally: `Text`, `Image`, `Document`, `Audio`.
  - Selected tab appears as a solid deep teal pill with white icon and bold label.
  - Inactive tabs appear in neutral soft grey with muted icons.
  - No horizontal overflow on screen.

- [ ] **Bottom Privacy Card**:
  - Soft cyan background with padlock icon.
  - Headline: `Your Privacy Matters`.
  - Text: `Your data is analyzed securely and is not stored on this device.`.

---

## 2. Text Mode Testing

- [ ] **Empty State**:
  - Text area displays `Paste or type a message here...`.
  - Character counter shows `0/5000`.
  - Primary `Analyze ✨ →` button is disabled.

- [ ] **Multilingual Input**:
  - Enter English: `URGENT: Click here to verify your bank account.`
  - Enter Hindi: `तत्काल सूचना: आपका बैंक खाता निलंबित कर दिया गया है।`
  - Enter Telugu: `అత్యవసర సమాచారం: మీ ఖాతా బ్లాక్ చేయబడింది.`
  - Verify character counter increments accurately without truncation or glyph corruption.

- [ ] **Clipboard Integration**:
  - Copy suspicious text in another app.
  - Tap `Paste from Clipboard` utility card.
  - Verify clipboard text populates the text field immediately.

- [ ] **Educational Sample Messages**:
  - Tap `Sample Messages` utility card.
  - Modal opens with 4 scenarios: Bank KYC Scam, Lottery Prize Scam, Part-Time Job Offer, Customs / Courier Scam.
  - Selecting a scenario populates the text box and allows manual review prior to submission.

- [ ] **Submission Lifecycle**:
  - Tap `Analyze ✨ →`.
  - Button transitions to `Analyzing...` with circular spinner.
  - Tap repeatedly to verify duplicate submissions are rejected.
  - On 200 OK: Navigates cleanly to the `AnalysisResultScreen` with authentic risk classification (`SCAM` / `SUSPICIOUS` / `SAFE`), risk score, and recommended safe actions.

---

## 3. Image Mode Testing

- [ ] Switch to `Image` tab.
- [ ] Dropzone displays camera/gallery upload illustration.
- [ ] Heading: `Upload an image or screenshot`.
- [ ] Description: `Supports JPG, PNG, WEBP (Max 10 MB)`.
- [ ] Tap `Take a Photo`: Camera opens or photo picker opens smoothly.
- [ ] Tap `Choose from Gallery`: Gallery selector opens; pick a screenshot or photo (`.png`, `.jpg`).
- [ ] Selected image preview appears with image thumbnail, file name, and file size in MB.
- [ ] Tap `Remove` (red trash icon) -> selection clears and returns to dropzone.
- [ ] Re-select image and tap `Analyze ✨ →` -> real multipart POST `/api/analysis/image` occurs and navigates to genuine result.

---

## 4. Document (PDF) Mode Testing

- [ ] Switch to `Document` tab.
- [ ] Dropzone displays document icon.
- [ ] Heading: `Upload a document (PDF)`.
- [ ] Subtitle: `Supports PDF files (Max 20 MB)`.
- [ ] Tap `Choose PDF File` -> Android system file manager opens filtered to PDFs.
- [ ] Select a `.pdf` file under 20 MB:
  - Document badge, file name, and file size appear.
- [ ] Tap `Sample Documents`:
  - Review sample educational suspicious notices.
- [ ] Tap `Analyze ✨ →` -> real multipart POST `/api/analysis/pdf` occurs and navigates to genuine result.

---

## 5. Audio Mode Testing

- [ ] Switch to `Audio` tab.
- [ ] Dropzone displays microphone icon.
- [ ] Heading: `Record audio or upload a file`.
- [ ] Subtitle: `Supports MP3, WAV, M4A, AAC, OGG (Max 25 MB)`.
- [ ] Tap `Upload Audio`: File manager opens filtered to audio files (`.mp3`, `.wav`, `.m4a`).
- [ ] Selected audio file displays audio badge, file name, and size.
- [ ] Tap `Convert from Video`: Informative dialog explains audio extraction guidance.
- [ ] Tap `Sample Audio`: Educational preview of Digital Arrest and Bank fraud robocall transcripts.
- [ ] Tap `Analyze ✨ →` -> real multipart POST `/api/analysis/audio` occurs and navigates to genuine result.

---

## 6. Theme & Responsive Validation

- [ ] **Dark Mode Toggle**:
  - Open app drawer/settings and toggle Dark Mode.
  - Verify background switches to deep navy/black `#101820`.
  - Hero card adapts to dark cyan `#1A2F3D` with bright aqua accents `#65D4D8`.
  - Input field background adapts to `#192630` with crisp white/light text.
  - Privacy card adapts to `#132E38`.
  - Contrast remains sharp and readable throughout.

- [ ] **Soft Keyboard Interaction**:
  - Focus text input in Text mode.
  - Verify keyboard smoothly pushes content up without RenderFlex overflow.
  - Scrolling remains fluid with 120Hz display refresh.

- [ ] **Navigation & Bottom Bar**:
  - Tap `Analyze` in bottom navigation: Stays on Analyze screen.
  - Tap `Home`: Navigates to Dashboard.
  - Tap `Sentinel`: Navigates to Sentinel live call screen.
  - Tap `History`: Navigates to Analysis History.
  - Frozen screens (Login, Signup, Admin, Sentinel, Landing) remain completely unchanged.
