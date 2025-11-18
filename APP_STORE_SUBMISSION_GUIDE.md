# TaskTimer - Complete App Store Submission Guide

## ✅ COMPLETED STEPS

1. ✅ Added privacy descriptions to Info.plist
2. ✅ Created App Store marketing materials (see APP_STORE_LISTING.md)
3. ✅ Drafted privacy policy (see PRIVACY_POLICY.md)

## 📋 NEXT STEPS (In Order)

### 1. Create Apple Developer Account (In Progress)
- Go to: https://developer.apple.com/programs/enroll/
- Choose "Individual" enrollment
- Use a personal Apple ID (not work email)
- Pay $99/year
- **Wait 24-48 hours for approval**

### 2. Host Privacy Policy Online
You need a public URL for your privacy policy. Options:
- **Option A**: Create a GitHub Pages site (free)
  - Create a new repo: `tasktimer-privacy`
  - Enable GitHub Pages in settings
  - Upload PRIVACY_POLICY.md
  - URL will be: `https://yourusername.github.io/tasktimer-privacy`

- **Option B**: Use a personal website if you have one

- **Option C**: Use a simple hosting service (Notion, Google Sites, etc.)

**Action**: Choose option and create public URL

### 3. Create App Icons

**Required Sizes for Mac App Store:**
- 1024x1024px (App Store listing - PNG, no alpha)
- 512x512px @ 1x
- 512x512px @ 2x (1024x1024)
- 256x256px @ 1x
- 256x256px @ 2x (512x512)
- 128x128px @ 1x
- 128x128px @ 2x (256x256)
- 32x32px @ 1x
- 32x32px @ 2x (64x64)
- 16x16px @ 1x
- 16x16px @ 2x (32x32)

**Design Recommendations:**
- Current menu bar icon is simple and clean - good!
- For App Store icon, consider: A clock/timer graphic with task segments
- Use your app's color scheme (greens/blues)
- Tools: Figma, Sketch, or hire a designer on Fiverr ($20-50)

**Where to add in Xcode:**
- Assets.xcassets/AppIcon.appiconset/

### 4. Take App Store Screenshots

**Requirements:**
- At least 3 screenshots
- Recommended sizes: 2880 x 1800 (Retina) or 1440 x 900
- Show your best features

**Suggested Screenshots:**
1. Timeline editor with multiple colorful tasks
2. Focused timer view showing countdown
3. Settings panel
4. Break mode with motivational quote
5. Task editing in action

**How to capture:**
- Run app → Command + Shift + 5 → Select window
- Or use: `screencapture -w screenshot.png`

### 5. Update Bundle Identifier

Once your Apple Developer account is approved:

1. In Xcode, go to project settings → Signing & Capabilities
2. Change Bundle Identifier to: `com.michaelsollami.tasktimer` (or your choice)
3. Select your Team from the dropdown
4. Xcode will automatically create necessary profiles

### 6. Create App Store Connect Listing

Once developer account is active:

1. Go to: https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: macOS
   - **Name**: TaskTimer
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: (select from dropdown - will appear after bundle ID change)
   - **SKU**: tasktimer-001
   - **User Access**: Full Access

4. In the app page, fill out:
   - **App Information**:
     - Name: TaskTimer
     - Subtitle: Visual time management tool
     - Category: Productivity
     - Privacy Policy URL: (your hosted URL from step 2)

   - **Pricing and Availability**:
     - Price: $4.99 (or your choice)
     - Availability: All countries

   - **1.0 Prepare for Submission**:
     - Screenshots: Upload your 3-5 screenshots
     - Description: Copy from APP_STORE_LISTING.md
     - Keywords: timer,pomodoro,productivity,focus,time management
     - Support URL: https://github.com/msollami/TaskTimer
     - Marketing URL: (optional)

   - **App Review Information**:
     - Email: your email
     - Phone: your phone
     - Notes: "TaskTimer is a simple, local-only timer app. No server components. Easy to test - just add a task and start the timer."

### 7. Create Archive & Submit

1. In Xcode:
   - Product → Scheme → Edit Scheme → Run → Release
   - Product → Archive
   - Wait for archive to complete

2. In Organizer window:
   - Select your archive
   - Click "Distribute App"
   - Select "App Store Connect"
   - Upload

3. After upload:
   - Go to App Store Connect
   - Select your build in the "1.0 Prepare for Submission" section
   - Click "Add Build" and select uploaded build
   - Fill in "What's New in This Version": "Initial release"
   - Click "Submit for Review"

### 8. App Review Process

- **Timeline**: Typically 24-48 hours
- **What Apple Tests**:
  - App functionality
  - Sandbox compliance
  - Metadata accuracy
  - Privacy policy

**If Rejected**:
- Read feedback carefully
- Make necessary changes
- Resubmit

## 📊 PRICING RECOMMENDATIONS

**Option 1: $4.99** (Recommended)
- Simple, fair price for the features
- No ongoing complexity
- Good perceived value

**Option 2: $2.99**
- Lower barrier to entry
- Still profitable

**Option 3: Free (Tip Jar)**
- Faster user acquisition
- Optional "Buy me a coffee" ($2.99/$4.99)
- Can convert users later

## 🎯 ESTIMATED TIMELINE

- Account approval: 24-48 hours
- Create assets (icons, screenshots): 4-8 hours
- Set up App Store Connect: 1 hour
- First submission: 30 minutes
- Review process: 24-48 hours

**Total: ~5-6 days from starting account creation to live on App Store**

## ❓ QUESTIONS?

Common issues:
- **Build fails**: Check signing settings, ensure all capabilities are enabled
- **Rejection**: Most common - privacy policy issues, metadata inaccuracy
- **Archive greyed out**: Ensure "Any Mac" is selected as destination

## 📞 NEXT ACTIONS FOR YOU

1. [ ] Sign up for Apple Developer Program
2. [ ] Choose a bundle identifier: ________________
3. [ ] Decide on privacy policy hosting (GitHub Pages?)
4. [ ] Create or commission app icon
5. [ ] Take screenshots

**Let me know when your account is approved and I'll help with the technical submission!**
