# ScamShield 2.0 — Design System Specification

**Document:** `SCAMSHIELD_DESIGN_SYSTEM.md`  
**Brand Identity:** Premium Fintech Security & AI Threat Detection  
**Core Aesthetic:** Deep Teal, Navy, Aqua highlights | Crisp Light & Independent Dark  
**Primary Typeface:** Inter (Google Fonts / Bundled Font Assets)  
**Base Spacing Unit:** 4 logical pixels  
**Version:** 2.0.0-phase00  

---

## 1. Brand Identity & Visual Philosophy

ScamShield 2.0 is designed as a **tier-one fintech security application**. It avoids oversaturated neon gradients, generic primary blues, and childish icons. The design communicates authority, precision, calm security, and immediate risk clarity.

### Core Visual Principles
1. **Calm Authority:** Clean layouts, restrained contrast, and authoritative deep navy and teal tones.
2. **Instant Threat Cognition:** Risk ratings use unmistakable semantic tokens (Low, Medium, High, Critical) always accompanied by clear legible labels.
3. **Independent Dark Mode:** Dark mode is designed from the ground up using nuanced slate-teal surfaces (`#101820`, `#192630`, `#22343F`), rather than naive color inversion.
4. **Accessible Touch & Text:** Strictly respects Android's system text scaling, high-contrast settings, and 48+ dp touch targets.

---

## 2. Color Palette & Semantic Tokens

### A. Light Theme Palette

| Token Name | Hex Code | Visual Swatch | Applied Usage |
| :--- | :--- | :--- | :--- |
| **Primary** | `#086B73` | Deep Teal | Main action buttons, active navigation tab, primary icons, key borders |
| **Navy** | `#102A43` | Deep Navy | Brand headers, primary headings, emphasized text, prominent cards |
| **Aqua** | `#A8EDF3` | Soft Aqua | Subtle highlights, active container backgrounds, badge tints |
| **Background** | `#F4F7FA` | Off-White Slate | Main page background, scaffold surface |
| **Surface** | `#FFFFFF` | Pure White | Elevated cards, input fields, modals, bottom navigation bar |
| **Raised Surface** | `#F8FAFC` | Subtle Gray | Nested cards, segmented control backgrounds, secondary containers |
| **Text Primary** | `#17212B` | Dark Slate | Headings, hero copy, body text, form input text |
| **Text Secondary** | `#486581` | Muted Navy | Subtitles, supporting copy, labels, timestamps |
| **Text Muted** | `#829AB1` | Neutral Gray | Placeholders, inactive icons, helper text |
| **Border** | `#D9E2EC` | Crisp Divider | Card outlines, text field borders, list dividers |

### B. Dark Theme Palette

| Token Name | Hex Code | Visual Swatch | Applied Usage |
| :--- | :--- | :--- | :--- |
| **Primary** | `#65D4D8` | Luminous Teal | Main action buttons, active tab indicators, glowing accents |
| **Background** | `#101820` | Obsidian Teal | Main page background, scaffold surface |
| **Surface** | `#192630` | Midnight Slate | Elevated cards, input field fill, bottom navigation bar |
| **Raised Surface**| `#22343F` | Deep Teal Gray | Modals, nested cards, elevated dialogs, card hover states |
| **Text Primary** | `#F1F5F9` | Crisp Off-White | Headings, titles, main body content |
| **Text Secondary** | `#B4C2CC` | Slate Gray | Subheadings, secondary copy, input hints |
| **Text Muted** | `#627D98` | Muted Blue-Gray | Inactive tabs, disabled states, subtle borders |
| **Border** | `#2B3E4C` | Subtle Divider | Card borders, text field borders, dividers |

### C. Semantic Risk Severity Colors

> [!IMPORTANT]
> Risk severity colors are visual tokens only. Backend risk classifications (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL` or `SAFE`, `SUSPICIOUS`, `SCAM`) remain authoritative. Every risk badge must display a clear text label alongside the color token.

| Severity | Label | Token Hex | Dark Hex | Background Tint (Light) | Background Tint (Dark) | Applied Usage |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Low** | Lower Observed Risk | `#21845A` | `#38A169` | `#E6F4EA` | `#132B20` | Safe messages, verified contacts, low-risk calls |
| **Medium** | Caution Advised | `#B7791F` | `#ECC94B` | `#FEF3C7` | `#2D2614` | Suspicious links, urgency cues, unverified calls |
| **High** | Elevated Risk | `#D65A31` | `#F07844` | `#FFEDD5` | `#331B10` | Impersonation signals, fake invoices, threat cues |
| **Critical** | Very High Assessed Risk | `#B42332` | `#E53E3E` | `#FEE2E2` | `#331418` | Known fraud numbers, credential theft, OTP demands |

---

## 3. Typography Specification — Inter

Primary typeface is **Inter** across all typography scales.

```text
Font Family: Inter
Fallbacks: Roboto, -apple-system, BlinkMacSystemFont, sans-serif
```

### Type Hierarchy Scale

| Element | Size | Weight | Line Height | Letter Spacing | Material 3 Mapping |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Landing Hero** | 32–36 px | Bold (700) | 1.15 | -0.8 px | `displayLarge` |
| **Main Screen Title** | 26–30 px | Bold (700) | 1.20 | -0.5 px | `headlineLarge` |
| **Section Heading** | 20–22 px | Semibold (600) | 1.25 | -0.3 px | `headlineMedium` |
| **Subsection Title** | 18–20 px | Semibold (600) | 1.30 | -0.2 px | `headlineSmall` |
| **Card Title** | 16–18 px | Semibold (600) | 1.35 | 0.0 px | `titleLarge` |
| **Subheading / Accent**| 15–16 px | Medium (500) | 1.40 | 0.0 px | `titleMedium` |
| **Body (Regular)** | 15–16 px | Regular (400) | 1.50 | +0.1 px | `bodyLarge` |
| **Body (Dense)** | 14 px | Regular (400) | 1.45 | +0.15 px | `bodyMedium` |
| **Supporting / Caption**| 13–14 px | Regular (400) | 1.40 | +0.2 px | `bodySmall` |
| **Button Text** | 15–16 px | Semibold (600) | 1.00 | +0.4 px | `labelLarge` |
| **Badge Label** | 11–12 px | Bold (700) | 1.00 | +0.6 px | `labelMedium` |
| **Micro Caption** | 10–11 px | Semibold (600) | 1.00 | +0.8 px | `labelSmall` |

### Accessibility & Layout Guidelines
* Respect system font scaling (`MediaQuery.textScalerOf(context)`).
* Avoid fixed-height containers (`SizedBox(height: 40)`) that clip multi-line text when font size scales up.
* Never use ALL CAPS for paragraphs or subtitles; reserve uppercase exclusively for short tags/badges (e.g., `CRITICAL`, `TEXT`).

---

## 4. Spacing Scale & Elevation

### Spacing Tokens (4px Grid)

```text
xxs:  4.0 px
xs:   8.0 px
sm:  12.0 px
md:  16.0 px
lg:  20.0 px
xl:  24.0 px
xxl: 32.0 px
```

* **Horizontal Screen Margin:** `20.0` to `24.0 px`
* **Card Padding:** `16.0` to `20.0 px`
* **Card Corner Radius:** `16.0` to `20.0 px`
* **Button Height:** `50.0` to `56.0 px`
* **Button Corner Radius:** `12.0` to `16.0 px`
* **Badge Corner Radius:** `999.0 px` (Fully rounded pill)
* **Maximum Content Width:** `720.0 px` (Responsive tablet / desktop centring)

### Elevation & Shadows
* Minimalist, crisp styling: cards use subtle borders (`1px solid outlineVariant`) instead of heavy blurry drop shadows.
* Light mode card border: `#D9E2EC` with optional `BoxShadow(color: Color(0x08102A43), blurRadius: 8, offset: Offset(0, 2))`.
* Dark mode card border: `#2B3E4C` with zero shadow to maintain clean OLED black/dark gray contrast.

---

## 5. Reusable Component Inventory

| Component | Target File | Purpose & Behavior |
| :--- | :--- | :--- |
| `ScamShieldCard` | `lib/widgets/common/scamshield_card.dart` | Primary content container with rounded corners, responsive padding, and subtle borders. |
| `RiskBadge` | `lib/widgets/common/risk_badge.dart` | Displays risk level with semantic icon, color token, and readable label. |
| `ScamShieldBrandMark` | `lib/widgets/brand_mark.dart` | Official shield icon and logo mark with scalable sizing and theme support. |
| `ThemeModeToggle` | `lib/widgets/theme_mode_toggle.dart` | Clean animated toggle for switching between Light and Dark mode. |
| `PrimaryButton` | `lib/widgets/common/primary_button.dart` | 52px high filled button with loading state spinner and disabled state. |
| `SecondaryButton` | `lib/widgets/common/secondary_button.dart` | Outlined action button with teal border and theme-aware foreground. |
| `SkeletonLoader` | `lib/widgets/skeleton_loaders.dart` | Shimmer animated cards for initial loading of dashboard, history, and results. |
| `SentinelLiveCard` | `lib/widgets/sentinel_live_card.dart` | Replaces `GuardianLiveRiskCard` with Sentinel brand and real-time audio status. |
| `ScamShieldErrorBoundary` | `lib/widgets/scamshield_error_boundary.dart` | Catches unhandled UI render crashes and shows clean recovery screen. |
| `EmptyStateWidget` | `lib/widgets/common/empty_state.dart` | Friendly illustration, message, and action CTA when lists have zero items. |
| `ErrorNoticeCard` | `lib/widgets/common/error_notice_card.dart` | Displays network/server errors with a safe "Try Again" retry action. |

---

## 6. Implementation Architecture in Flutter

When implemented in Phase 01:
* `app_colors.dart` will export the exact Light, Dark, and Semantic Risk color constants.
* `app_typography.dart` will build text styles using the `Inter` font family with proper weights.
* `app_theme.dart` will provide `lightTheme` and `darkTheme` with full `MaterialThemeData` configurations (Cards, InputDecorations, ElevatedButtons, NavigationBars, AppBars).
