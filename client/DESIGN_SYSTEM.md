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

## 5. Interaction States

**Active (Pressed) State:**
To make the app feel tactile and responsive, we use a "scale down" animation on press.
- **Scale:** 0.96
- **Transition:** 100ms ease-out
- **Usage:** Applied to buttons and interactive cards.
- **Note:** Avoid hover states as they can cause issues on touch screens.

## 6. Components

### Buttons
- **Primary Button**:
  - Background: `AppColors.brand`
  - Text: White, Bold
  - Radius: 12px
  - Padding: Vertical 12px
  - Elevation: 2
  - Interaction: Scale to 0.96 on press.
- **Shiny / Gradient Button (e.g., Save Route)**:
  - Background: Linear Gradient (`AppColors.brandLight` top to `AppColors.brand` bottom)
  - Top Highlight: 1px white opacity border on the top edge.
  - Interaction: Scale to 0.96 on press.
- **Secondary Button**:
  - Background: `AppColors.secondary`
  - Text: White, Bold
  - Radius: 12px
  - Interaction: Scale to 0.96 on press.
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

## 7. Icons
- **Library**: `lucide_icons` package.
- **Size**: Typically 20px for actions, 16px-18px for indicators.
- **Color**: Matches text color or `AppColors.brand` for active states.

## 8. Screen Specific Specifications

### Summary Overview Page

The Summary Overview page is designed for quick scanning and comparison of journey options. It employs a **list-based layout** with card components to present each option clearly.

**Layout & Hierarchy:**
- **Header:** Contains the search summary (From, To, Time) and mode toggles. Uses a white background with a shadow to separate it from the content.
- **Tabs:** "Smart", "Fastest", "Cheapest" tabs allow users to filter results based on their priorities.
- **Result Cards:** Journey options are displayed as cards. The top choice is highlighted with a "TOP CHOICE" banner.

**Timeline Diagram (Horizontal Jigsaw):**
- **Purpose:** To provide a quick visual representation of the journey segments and modes.
- **Design:** Uses a custom "jigsaw" style where segments interlock with an overlap of 12.0.
- **Colors:** Each segment is colored according to the mode's line color (e.g., Purple for Train, Blue for Bus).
- **Text:** White or Black text based on background luminance for readability. 10px Bold for labels, 8px Bold for duration.
- **Why:** The jigsaw shape visually connects the segments, emphasizing the seamless nature of the journey. The horizontal layout saves vertical space, allowing more results to be seen at once.

### Detailed View Page

The Detailed View page provides in-depth information about a specific journey. It uses a **split-screen layout** with a map and a bottom sheet.

**Layout & Hierarchy:**
- **Map Background:** Takes up the full screen, providing geographical context.
- **Bottom Sheet:** A draggable sheet containing the journey details. It starts at 35% height and can be expanded.
- **Header:** Displays the total cost, time, and CO2 savings prominently.

**Timeline Diagram (Vertical Node & Card):**
- **Purpose:** To show the step-by-step itinerary with detailed information for each leg.
- **Design:** A vertical timeline connecting nodes (stops) and segments (travel).
- **Nodes:**
  - **Start:** Green circle with Play icon.
  - **End:** Dark circle with Flag icon.
  - **Intermediate:** 16px white circle with colored border (3px).
  - **Connection:** Connected by a vertical line.
- **Segments:** Cards displaying mode icon, label, duration, and specific details (e.g., platform, bus frequency).
- **Visuals:**
  - **Track:** A 12px grey track (Grey 200) with a 4px colored line runs vertically, guiding the eye.
  - **Icon Halo:** A 40px circle with a 15% opacity background highlights the mode icon (20px).
  - **Cards:** White cards with shadows lift the content off the background.
  - **Padding:** 12px internal padding for cards.
- **Why:** The vertical layout allows for more detailed information (intermediate stops, costs) without cramping the UI. The card design separates distinct legs of the journey.

**Map Design:**
- **Polylines:**
  - **Solid:** For vehicle travel (Train, Bus, Car).
  - **Dotted:** For walking segments.
  - **Width:** 6px for visibility.
- **Markers:**
  - **Start:** Green circle with "Play" icon.
  - **End:** Dark/Black circle with "Flag" icon.
  - **Nodes:** White circles with dark borders for mode changes.
- **Why:** Differentiating line styles helps users distinguish between active (walking) and passive (riding) travel. Distinct markers clearly indicate the start and end points.
