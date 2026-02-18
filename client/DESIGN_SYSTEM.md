# Frontend Design System

This document outlines the design system, theme, styles, padding, spacing, and component guidelines for the EndMile application.

## 1. Design Philosophy & Rationale

**Clean & Modern Aesthetic:**
The application aims for a clean, modern, and accessible user interface. We prioritize readability and ease of use, especially for commuters who need quick access to information.

- **Slate Grays:** We use a comprehensive scale of "Slate" grays (`AppColors.slate50` to `AppColors.slate900`) for backgrounds, text, and borders. This provides a neutral, professional base that is easy on the eyes and avoids the harsh contrast of pure black on white.
- **Brand Purple:** The primary brand color (`#4F46E5`) is a vibrant purple/indigo. It is used for primary actions, active states, and key visual elements to draw attention without being overwhelming.
- **Rounded Corners:** We use consistent rounded corners (typically 12px) to soften the UI and make it feel more friendly and modern.
- **Whitespace:** Generous use of padding (16px) and spacing (12px) ensures that content is not cramped and information is easily digestible.
- **Subtle Shadows:** Soft shadows are used to create depth and hierarchy, lifting interactive elements like cards and headers off the background.

## 2. Typography

We use the **Inter** font family via `GoogleFonts.interTextTheme()`. This sans-serif font is highly legible and works well across various screen sizes.

### Type Scale

| Usage | Size | Weight | Color |
| :--- | :--- | :--- | :--- |
| **Header Title** | 20px | Bold (700), Height 1.25 | `Colors.white` |
| **Section Header** | 16px | Bold (700) | `AppColors.slate800` |
| **Input Text** | 14px | Medium (500) | `AppColors.slate900` |
| **Body Text** | 14px | Medium (500) | `AppColors.slate700` |
| **Button Text** | 14px | Bold (700) | `Colors.white` |
| **Secondary Label** | 12px | Regular/Bold | `AppColors.slate500` / `AppColors.slate400` |
| **Small Label** | 10px | Bold (700) | `AppColors.slate500` |

## 3. Colors

All colors are defined in `lib/utils/app_colors.dart`. We use an HSL-based system to define colors, allowing for easier generation of variations (e.g., hover states).

### Brand Colors
- **Primary (`AppColors.brand`)**: `#4F46E5` - Used for primary buttons, active icons, header background, and highlights.
- **Dark (`AppColors.brandDark`)**: `#3730A3` - Used for darker accents (e.g., user avatar background).
- **Light (`AppColors.brandLight`)**: `#E0E7FF` - Used for subtle backgrounds (e.g., icon containers).
- **Blue 50 (`AppColors.blue50`)**: `#EFF6FF` - Used for selected item backgrounds (e.g., active filter mode).

### Secondary Colors
- **Secondary (`AppColors.secondary`)**: `#0F766E` - Used for alternative actions or distinct UI elements (e.g., secondary buttons).

### Neutral Scale (Slate)
- **Background (`AppColors.slate50`)**: `#F8FAFC` - Main scaffold background.
- **Surface (`Colors.white`)**: Card and container backgrounds.
- **Input Background (`AppColors.slate100`)**: `#F1F5F9` - Background for text fields and search inputs.
- **Border (`AppColors.slate200`)**: `#E2E8F0` - Borders for unselected states or dividers.
- **Disabled/Hint (`AppColors.slate400`)**: `#94A3B8` - Icons and text hints.
- **Secondary Text (`AppColors.slate500`)**: `#64748B` - Subtitles and secondary information.
- **Body Text (`AppColors.slate700`)**: `#334155` - Primary content text.
- **Heading Text (`AppColors.slate800`)**: `#1E293B` - Section headings.
- **Strong Text (`AppColors.slate900`)**: `#0F172A` - High-emphasis text.

## 4. Spacing & Layout

We follow a consistent 4px grid system, with key values being multiples of 4.

### Padding
- **Container Padding**: `16px` - Standard padding for cards, sections, and the main container.
- **Element Padding**: `12px` - Internal padding for input fields, buttons, and list items.
- **Small Padding**: `8px` - Padding for smaller elements like icons or tight layouts.

### Gaps (Margins/SizedBox)
- **Section Gap**: `12px` - Space between major sections or input fields.
- **Item Gap**: `8px` - Space between related items (e.g., icon and text).
- **Small Gap**: `4px` - Minimal spacing.

### Border Radius
- **Standard**: `12px` - Used for Cards, Buttons, Input Fields, and Containers.
- **Small**: `8px` - Used for smaller internal elements (e.g., icon backgrounds).
- **Circle**: Used for avatars and status dots.

## 5. Components

### Buttons
- **Primary Button**:
  - Background: Subtle Gradient (AppColors.brand to AppColors.brandDark)
  - Text: White, Bold
  - Radius: 12px
  - Padding: Vertical 12px
  - Elevation: 2
- **Secondary Button**:
  - Background: `AppColors.secondary`
  - Text: White, Bold
  - Radius: 12px
- **Text Button**:
  - Text: `AppColors.brand`, Bold

### Input Fields
- **Style**: Flat, filled style with a 1px `AppColors.slate200` border.
- **Background**: `AppColors.slate100`
- **Text Color**: `AppColors.slate700` (Medium) or `AppColors.slate900` (Medium)
- **Radius**: 12px
- **Padding**: 12px
- **Features**: Often accompanied by a colored dot indicator (e.g., Grey for 'From', Black for 'To').

### Cards (Journey Result, Saved Routes, Upcoming Journeys)
- **Background**: White
- **Border**: 1px solid `AppColors.slate200`
- **Shadow**: Two-shadow system:
  1. Light top highlight: `BoxShadow(color: Colors.white, offset: Offset(0, -1), blurRadius: 0)`
  2. Darker soft shadow: `BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4)`
- **Radius**: 12px
- **Padding**: 16px (outer), 12px (inner list items)

### Header
- **Background**: `AppColors.brand`
- **Text**: White, 20px Bold
- **Shadow**: `BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))`
- **Content**: Title "EndMile" and User Avatar.

### Mode Filter (Toggle)
- **Selected**:
  - Background: `AppColors.blue50`
  - Border: `AppColors.brand`
  - Icon/Text: `AppColors.brand`
- **Unselected**:
  - Background: White
  - Border: `AppColors.slate200`
  - Icon/Text: `AppColors.slate400`
- **Radius**: 12px

## 6. Icons
- **Library**: `lucide_icons` package.
- **Size**: Typically 20px for actions, 16px-18px for indicators.
- **Color**: Matches text color or `AppColors.brand` for active states.
