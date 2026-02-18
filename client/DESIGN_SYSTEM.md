# Frontend Design System & Decisions

This document serves as the comprehensive guide for the EndMile application's frontend design, including our core design philosophy, key architectural decisions, and the detailed style guide (colors, typography, spacing).

---

## 1. Design Decisions & Rationale

Our design choices are driven by the need to present complex journey data in a way that is instantly understandable and actionable for commuters.

### 1.1 The "Jigsaw" Timeline Visualization
**Decision:** We implemented a custom "Jigsaw" style visualization for journey segments (see `TimelineSummaryView`).
**Why:** Standard linear timelines often fail to show the *connection* and *flow* between different modes of transport. The jigsaw pieces, with their interlocking connectors, visually represent a seamless journey where one mode hands off to the next. The proportional width of segments (where space allows) gives users an intuitive sense of time distribution.

### 1.2 Color-Coded Badge System
**Decision:** We use a strict color-coding system for badges to highlight key decision factors.
- **Emerald Green (Top Choice / Low Emissions):** Green is universally associated with "Good" or "Go". We use it to draw attention to the most recommended route and environmentally friendly options.
- **Royal Blue (Least Risky):** Blue conveys trust and stability. We use it for the "Least Risky" badge to reassure users about reliability without the urgency of a "warning" color.
**Why:** Users need to scan multiple options quickly. Color-coded badges allow them to filter information at a glance without reading every detail.

### 1.3 Contextual Dot Indicators
**Decision:** Input fields for "From" and "To" locations are paired with colored dot indicators (Grey for Start, Black for End).
**Why:** This mirrors the visual language of the map markers. By linking the input field to the map visual, we reduce cognitive load and help users instantly orient themselves.

### 1.4 "Slate" Neutral Scale
**Decision:** We avoided pure black (`#000000`) in favor of a deep "Slate" gray (`AppColors.slate900` - `#0F172A`) for text and strong elements.
**Why:** Pure black on white can cause eye strain due to high contrast. The Slate scale provides a softer, more modern, and professional aesthetic while maintaining excellent readability.

---

## 2. Colors

Colors are central to our brand and usability. Defined in `lib/utils/app_colors.dart`.

### Brand Identity
- **Primary Brand (`#4F46E5`)**: The core violet/indigo used for primary buttons, active states, and headers.
- **Brand Dark (`#3730A3`)**: Used for depth and emphasis.
- **Brand Light (`#E0E7FF`)**: Used for subtle backgrounds and hover states.
- **Secondary Teal (`#0F766E`)**: used for alternative actions.

### Status & Badge Colors
*Hardcoded in widgets like `JourneyBadges` and `JourneyResultCard`.*
- **Emerald (Success/Eco)**:
  - Background: `#ECFDF5` (Emerald 50)
  - Text/Icon: `#047857` (Emerald 700)
  - Border: `#D1FAE5` (Emerald 100)
- **Blue (Info/Safety)**:
  - Background: `#EFF6FF` (Blue 50)
  - Text/Icon: `#1D4ED8` (Blue 700)
  - Border: `#DBEAFE` (Blue 100)

### Neutral Scale (Slate)
- **Surface (`#F8FAFC` / `#FFFFFF`)**: Backgrounds for pages and cards.
- **Borders (`#E2E8F0`)**: Subtle dividers and container borders.
- **Text**:
  - **Strong**: `#0F172A` (Headings, Input Text)
  - **Body**: `#334155` (Primary Content)
  - **Subtle**: `#64748B` (Secondary Labels, Hints)

---

## 3. Typography

Font Family: **Inter** (via `GoogleFonts.interTextTheme`).

### Hierarchy
| Element | Size | Weight | Color | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Cost Display** | 24px | Bold (700) | `slate900` | Journey price in result card header. |
| **Page Header** | 20px | Bold (700) | `White` | Main app bar title. |
| **Duration** | 18px | Bold (700) | `slate900` | Total journey time. |
| **Section Title** | 16px | Bold (700) | `slate800` | "Saved Routes", "Upcoming Journeys". |
| **Input Text** | 14px | Bold (700) | `slate900` | User typed text in search fields. |
| **Body / Labels** | 14px | Medium (500) | `slate700` | General content. |
| **Small Metadata** | 12px | Medium (500) | `slate500` | "Via...", Time ranges, Secondary details. |
| **Tiny / Badge** | 10px | Bold (700) | Colored | Text inside badges and timeline segments. |

---

## 4. Spacing & Layout

We adhere to a **4px grid**, with `12px` and `16px` being the most common values.

### Padding
- **Card/Container Padding**: `16px` (Standard for `JourneyResultCard`, `SearchForm` container).
- **Element Padding**: `12px` (Input fields, List items).
- **Icon Container**: `8px` (Backgrounds for icons in lists).

### Margins
- **Section Spacing**: `16px` (Between cards).
- **Item Spacing**: `12px` (Between inputs, between list rows).
- **Internal Gap**: `8px` (Between icon and text).

### Border Radius
- **Standard**: `12px` (Cards, Buttons, Inputs).
- **Small**: `8px` (Icon backgrounds).
- **Badge**: `4px` (Small info tags).
- **Pill**: `3px` (Progress bars/Caps).

### Shadows
- **Card Shadow**: `BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))` - Gives a lifted effect.
- **Subtle Shadow**: `BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))` - For list items.

---

## 5. Components & Visualizations

### 5.1 Journey Result Card
A complex container that summarizes a trip option.
- **Structure**: Header (Cost/Time) -> Timeline Schematic -> Badges -> Optional "Top Choice" Footer.
- **Top Choice Banner**: Full-width footer in Emerald 50 with "TOP CHOICE" text.
- **Interaction**: Tap anywhere to view details.

### 5.2 Search Form
- **Inputs**: Flat style, filled `slate100` background, no visible border unless focused (implied), `12px` radius.
- **Mode Filter**: Expandable dropdown. Selected items turn `Blue 50` with `Brand` colored borders.

### 5.3 Progress Bar (Upcoming Journeys)
Used to show journey progress.
- **Track**: Height `6px`, Color `slate100`, Radius `3px`.
- **Fill**: Height `6px`, Color `brand`, Radius `3px`.

### 5.4 Saved Route Item
- **Layout**: Row with Icon Box + Text.
- **Icon Box**: `brandLight` background with `brand` icon.
- **Container**: White background, `slate100` border, subtle shadow.
