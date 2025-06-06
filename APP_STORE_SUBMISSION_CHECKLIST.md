# 🍎 App Store Submission Checklist for LGKA App

## 📋 Pre-Submission Requirements

### ✅ Apple Developer Account Setup
- [ ] Apple Developer Program membership ($99/year)
- [ ] Banking information added to App Store Connect
- [ ] Tax information completed
- [ ] All agreements signed

### ✅ App Information
- **App Name**: LGKA (or "LGKA - Digitaler Vertretungsplan")
- **Bundle ID**: `com.lgka`
- **Primary Language**: German (Deutsch)
- **Category**: Education
- **Age Rating**: 4+ (All Ages)

---

## 🔨 Build Process

### iOS Build
```bash
./build_ios_release.sh
```

### macOS Build
```bash
./build_macos_release.sh
```

---

## 📱 App Store Connect Setup

### 1. Create App Record
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Apps → "+" → New App
3. Select: ✅ iOS ✅ macOS
4. Enter app information

### 2. Required Assets

#### App Icons (✅ Already generated)
- iOS: 1024×1024px
- macOS: 1024×1024px

#### Screenshots Needed
**iOS (iPhone 16 Pro Max - 1320×2868px)**:
- [ ] Today's schedule view
- [ ] Tomorrow's schedule view
- [ ] Info/About screen
- [ ] PDF viewing (if possible)

**macOS (1280×800px minimum)**:
- [ ] Main app window
- [ ] PDF opened in macOS
- [ ] App in action

#### App Description (German)
```
LGKA - Digitaler Vertretungsplan

Einfacher und schneller Zugriff auf den Vertretungsplan des Lessing Gymnasiums Karlsruhe.

Funktionen:
• Vertretungsplan für heute und morgen
• Automatisches Herunterladen und Caching
• Offline-Zugriff auf heruntergeladene Pläne
• Moderne, benutzerfreundliche Oberfläche
• Unterstützt iPhone, iPad und Mac

Entwickelt speziell für Schüler, Lehrer und Eltern des Lessing Gymnasiums Karlsruhe.
```

#### Keywords (German)
```
Vertretungsplan,Schule,Lessing Gymnasium,Karlsruhe,Stundenplan,Bildung,Schüler
```

### 3. App Privacy
- [ ] Data collection practices (likely "No data collected")
- [ ] Network usage disclosure

### 4. Age Rating
- [ ] Set to 4+ (suitable for all ages)

---

## 🚀 Submission Process

### iOS Submission
1. **Archive in Xcode**:
   - Open `ios/Runner.xcworkspace`
   - Select "Any iOS Device (arm64)"
   - Product → Archive
   
2. **Upload to App Store**:
   - Window → Organizer
   - Select your archive
   - "Distribute App" → "App Store Connect"
   - Follow upload wizard

### macOS Submission
1. **Archive in Xcode**:
   - Open `macos/Runner.xcworkspace`
   - Select "My Mac"
   - Product → Archive
   
2. **Upload to App Store**:
   - Window → Organizer
   - Select your archive
   - "Distribute App" → "App Store Connect"
   - Follow upload wizard

### Final Steps
1. **Add builds to versions** in App Store Connect
2. **Submit for review**
3. **Wait for approval** (typically 1-7 days)
4. **Release** (automatic or manual)

---

## 🛡️ App Review Guidelines Compliance

### ✅ Your app complies with:
- **Guideline 1.1**: No objectionable content
- **Guideline 2.1**: App functions as described
- **Guideline 4.0**: No spam or duplicate apps
- **Guideline 5.1**: Privacy compliance (no personal data collection)

### 🎯 Educational App Benefits:
- Educational apps often get favorable review treatment
- School-specific apps are generally well-received
- Clear utility and purpose

---

## 📊 Pricing Strategy

### Recommended Approach:
- **Price**: FREE
- **Reasoning**: 
  - School community service
  - Wider adoption
  - No ongoing costs to maintain
  - Educational/public service nature

---

## 🎉 Post-Launch

### Marketing
- [ ] Share with school community
- [ ] Social media announcement
- [ ] School newsletter/website feature

### Monitoring
- [ ] Check App Store reviews
- [ ] Monitor download statistics
- [ ] Watch for bug reports

### Updates
- [ ] Plan regular updates
- [ ] Feature enhancements
- [ ] iOS/macOS compatibility updates

---

## 🔗 Useful Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [TestFlight](https://developer.apple.com/testflight/) (for beta testing)

---

**🎯 Estimated Timeline**: 2-3 weeks from submission to App Store availability
**💰 Total Cost**: $99/year (Apple Developer Program)
**🏆 Success Rate**: Very high for educational apps like yours! 