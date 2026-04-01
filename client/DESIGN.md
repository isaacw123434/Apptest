# Frontend Design Documentation

This document outlines the design decisions, theme styles, and component usage for the **EndMile** application. The goal is to ensure a consistent, accessible, and modern user interface across the application.

## 1. Design Philosophy

Our design philosophy centers on **simplicity, clarity, and accessibility**. We aim to provide a frictionless experience for users comparing commute options. Key principles include:

- **Clean Layouts**: Using ample whitespace and clear separation of content to reduce cognitive load.
- **Visual Hierarchy**: Using color, typography, and spacing to guide the user's attention to key actions (e.g., "Search") and information (e.g., travel time, cost).
- **Feedback & Interaction**: providing clear visual cues for interactive elements (e.g., hover states, active states on mode filters).
- **Mobile-First**: Designing for touch targets and responsive layouts suitable for mobile devices.

## 2. Color Palette

The application uses a defined color palette to maintain brand identity and visual consistency. Colors are managed in `lib/utils/app_colors.dart`.

### Brand Colors
- **Brand Primary** (`#4F46E5`): Used for primary actions, active states, and key highlights. It conveys trust and professionalism.
- **Brand Dark** (`#3730A3`): Used for backgrounds in headers and contrast elements.
- **Brand Light** (`#E0E7FF`): Used for subtle backgrounds and accents.
- **Brand Hover** (`#4338CA`): A slightly darker shade of the primary brand color for hover states.

### Secondary Colors
- **Secondary (Teal)** (`#0F766E`): Used for success states, eco-friendly indicators (like CO2 savings), and alternative accents.

### Neutrals (Slate)
Used for text, backgrounds, and borders to provide a neutral base.
- **Slate 900** (`#0F172A`): Primary text color (headings, high-contrast text).
- **Slate 800** (`#1E293B`): Secondary text color.
- **Slate 700** (`#334155`): Body text color.
- **Slate 500** (`#64748B`): Muted text, icons, and less important labels.
- **Slate 400** (`#94A3B8`): Disabled states, placeholders.
- **Slate 200** (`#E2E8F0`): Borders and dividers.
- **Slate 100** (`#F1F5F9`): Backgrounds for inputs and cards.
- **Slate 50** (`#F8FAFC`): Main application background (scaffold).

### Utility Colors
- **Blue 50** (`#EFF6FF`): Used for selected states in filters and lists.
- **White** (`#FFFFFF`): Card backgrounds and elevated surfaces.

## 3. Typography

We use the **Inter** font family via `GoogleFonts` for a modern, clean, and highly readable typeface.

- **Headings**:
  - **Size 20, Bold**: Used for the app header title ("EndMile").
  - **Size 16-18, Bold/SemiBold**: Section headers (e.g., "Saved Routes", "Upcoming Journeys").
- **Body Text**:
  - **Size 14, Regular/Medium**: Standard text for inputs, labels, and descriptions.
  - **Size 14, Bold**: Emphasis for values (e.g., time, cost).
- **Small Text**:
  - **Size 10-12, Medium/Bold**: Labels, tags, and secondary information.

## 4. Spacing & Layout

We adhere to an 8-point grid system for spacing and layout to ensure rhythm and consistency.

### Padding
- **Container Padding**: `16px` (`EdgeInsets.all(16)`) is the standard padding for main content containers and cards.
- **Input Padding**: `12px` (`EdgeInsets.all(12)`) for text fields and input rows.
- **Element Padding**: `8px` for smaller internal elements or icon containers.

### Margins & Spacing
- **Section Spacing**: `12px` or `16px` (`SizedBox(height: 12)`) between major sections or form rows.
- **Item Spacing**: `8px` (`SizedBox(width: 8)`) between icons and text, or horizontal list items.

### Shapes & Borders
- **Border Radius**: `12px` (`BorderRadius.circular(12)`) is standard for buttons, input fields, cards, and modal sheets. This provides a friendly and modern aesthetic.
- **Borders**: `1px` width with `Slate 200` color for subtle definition on inputs and cards.

## 5. Component Styling

### Buttons & Interactive Elements
- **Primary Buttons**: Typically use `Brand Primary` background with White text.
- **Mode Filters**:
  - **Default**: White background, Slate border.
  - **Selected**: Blue 50 background, Brand Primary border and icon color.
- **Input Fields**:
  - Background: `Slate 100`
  - Border: `Slate 200`
  - Text: `Slate 900` (input), `Slate 700` (placeholder/read-only)
  - Visual Cue: Colored dot indicator (e.g., Grey for Origin, Black for Destination) to distinguish fields.

### Cards & Surfaces
- **Cards**: White background with optional subtle shadow (`BoxShadow`, blur 4, offset 0,2) or border.
- **Header**: Brand background with shadow for elevation.
- **Scaffold**: `Slate 50` background to differentiate the app canvas from white content cards.

### Icons
- **Library**: `LucideIcons` for a consistent, stroke-based icon style.
- **Sizes**: Typically `20px` for standard icons, `16px` for smaller indicators, `14px` for very small inline icons.
- **Colors**: match text or specific state colors (e.g., Brand for active, Slate 400 for inactive).

## 6. Implementation Notes

- **ThemeData**: defined in `main.dart`, setting the seed color to `AppColors.brand` and using `GoogleFonts.interTextTheme()`.
- **SafeArea**: Used in `HomePage` to ensure content respects device notches and system bars.
- **Responsive**: `Expanded` and `Flexible` widgets are used to ensure layouts adapt to available width.
