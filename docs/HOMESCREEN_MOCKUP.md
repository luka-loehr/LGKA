# New Homescreen Design Mockup

## Overview
This document describes the new homescreen design that replaces the 3-page swipe architecture with a single navigation-based homescreen.

## Design Concept

### Layout Structure
```
┌─────────────────────────────────┐
│  [Medical Icon]  LGKA+  [⚙️]   │  AppBar
├─────────────────────────────────┤
│                                  │
│  ┌───────────────────────────┐  │
│  │   Vertretungsplan         │  │  Large Card
│  │   📅                      │  │  (Primary Feature)
│  │   Heute & Morgen          │  │
│  └───────────────────────────┘  │
│                                  │
│  ┌──────────┐  ┌──────────┐     │
│  │Stundenplan│  │  Wetter  │     │  Medium Cards
│  │  📋      │  │  ☀️      │     │  (2-column grid)
│  └──────────┘  └──────────┘     │
│                                  │
│  ┌───────────────────────────┐  │
│  │   Neuigkeiten             │  │  Medium Card
│  │   📰                      │  │  (Full width)
│  │   Aktuelle Nachrichten    │  │
│  └───────────────────────────┘  │
│                                  │
│           [Footer]               │
└─────────────────────────────────┘
```

## Card Designs

### 1. Vertretungsplan Card (Large, Primary)
- **Size**: Full width, ~180px height
- **Background**: App surface color with primary accent border
- **Content**:
  - Large calendar icon (left side, circular background with primary color)
  - Title: "Vertretungsplan" (bold, large)
  - Subtitle: "Heute & Morgen" (secondary text)
  - Status indicator showing current day availability
  - Arrow icon (right side)
- **Interaction**: Tap to navigate to substitution plan selection
- **Visual**: Prominent shadow, subtle glow on primary color

### 2. Stundenplan Card (Medium, Grid Left)
- **Size**: ~48% width, ~140px height
- **Background**: App surface color
- **Content**:
  - Schedule icon (top, circular background)
  - Title: "Stundenplan" (medium, bold)
  - Subtitle: "Klassen 5-10 & Oberstufe" (small, secondary)
  - Arrow icon (bottom right)
- **Interaction**: Tap to navigate to schedule page

### 3. Wetter Card (Medium, Grid Right)
- **Size**: ~48% width, ~140px height
- **Background**: App surface color
- **Content**:
  - Weather icon (top, circular background)
  - Title: "Wetter" (medium, bold)
  - Subtitle: Current temperature or "Live Daten" (small, secondary)
  - Arrow icon (bottom right)
- **Interaction**: Tap to navigate to weather page
- **Special**: Show current temperature if available

### 4. Neuigkeiten Card (Medium, Full Width)
- **Size**: Full width, ~140px height
- **Background**: App surface color
- **Content**:
  - News icon (left side, circular background)
  - Title: "Neuigkeiten" (medium, bold)
  - Subtitle: "Aktuelle Nachrichten" or latest news preview (small, secondary)
  - Badge showing unread count (if any)
  - Arrow icon (right side)
- **Interaction**: Tap to navigate to news screen

## Visual Specifications

### Colors
- **Background**: `#000000` (pure black)
- **Card Background**: `#1E1E1E` (dark surface)
- **Primary Accent**: User-selected accent color (from theme)
- **Text Primary**: `#FFFFFF` (white)
- **Text Secondary**: `#B3FFFFFF` (70% opacity white)
- **Icon Backgrounds**: Primary accent color in circular containers

### Typography
- **Card Titles**: TitleMedium (16px, bold)
- **Card Subtitles**: BodySmall (12px, secondary color)
- **Primary Card Title**: TitleLarge (22px, bold)

### Spacing
- **Card Padding**: 24px horizontal, 20px vertical
- **Card Gap**: 16px between cards
- **Screen Padding**: 16px on all sides
- **Top Margin**: 24px below app bar

### Animations
- **Card Tap**: Scale animation (0.95x on press)
- **Card Entrance**: Fade-in with staggered delay
- **Haptic Feedback**: Subtle haptic on card tap

## Navigation Flow

```
Homescreen
├── Vertretungsplan Card → Substitution Plan Selection
│   ├── Today → PDF Viewer
│   └── Tomorrow → PDF Viewer
├── Stundenplan Card → Schedule Page
│   ├── Klassen 5-10 → PDF Viewer
│   └── Oberstufe → PDF Viewer
├── Wetter Card → Weather Page
└── Neuigkeiten Card → News Screen
```

## Responsive Behavior

### Small Screens (< 400px width)
- Cards stack vertically
- Full-width cards maintain full width
- Grid cards become full width and stack

### Large Screens (> 600px width)
- Cards maintain grid layout
- Maximum content width: 600px (centered)
- Increased card spacing

## Implementation Notes

### State Management
- Use existing Riverpod providers for data
- Show loading states on cards when data is fetching
- Display error states inline on cards (retry button)

### Performance
- Lazy load data for each section
- Preload data in background when homescreen loads
- Cache card layouts to prevent rebuilds

### Accessibility
- Semantic labels for all cards
- Proper focus order
- Screen reader announcements for status changes

## Example Card States

### Loading State
- Show shimmer effect or loading indicator
- Disable interaction
- Gray out card slightly

### Error State
- Show error icon
- Display retry button
- Keep card interactive for retry

### Empty State
- Show appropriate message
- Maintain card structure
- Disable navigation if no data available

