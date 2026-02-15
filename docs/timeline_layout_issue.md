# Timeline Layout Issue: Text Cutoff

## Problem Description

The timeline diagram (implemented as `HorizontalJigsawSchematic`) in the summary view occasionally exhibits text cutoff issues on certain devices. This manifests as labels or duration text being partially hidden or ellipsized unexpectedly, especially on devices with larger font settings or different screen densities.

## Root Cause Analysis

The root cause of this issue lies in the width calculation logic within `HorizontalJigsawSchematic`.

The widget uses a `TextPainter` to measure the width of the text content before rendering. However, the `TextPainter` is initialized without the `textScaleFactor` (or `textScaler` in newer Flutter versions) from the `MediaQuery`. By default, `TextPainter` assumes a text scale factor of 1.0.

Conversely, the `Text` widget used for rendering automatically applies the system's text scale factor (e.g., if the user has set "Large Text" in accessibility settings).

This mismatch means that on devices with scaled text:
1.  **Measurement:** `TextPainter` calculates the width for the text at its base size (e.g., 10.0 logical pixels).
2.  **Rendering:** `Text` widget renders the text at a scaled size (e.g., 12.0 or 14.0 logical pixels).
3.  **Result:** The container allocated for the text is too narrow, causing the text to be clipped or wrapped incorrectly.

## Best Practice Solution

To resolve this issue, the `TextPainter` must be made aware of the current text scaling settings. This ensures that the measured width matches the rendered width.

### Implementation Steps

1.  **Retrieve Text Scaler:** Obtain the current `TextScaler` (or `textScaleFactor` for older Flutter versions) from `MediaQuery`.
2.  **Pass to TextPainter:** Provide this scaler to the `TextPainter` constructor.
3.  **Add Safety Buffer:** Include a small safety margin to account for potential minor rendering differences (like anti-aliasing or font hinting).
4.  **Handle Overflow:** Explicitly set `overflow: TextOverflow.ellipsis` on the `Text` widget to fail gracefully.

### Code Example

In `client/lib/screens/horizontal_jigsaw_schematic.dart`:

```dart
// OLD CODE (Causing the issue)
/*
final textPainter = TextPainter(
  text: TextSpan(
    text: displayText,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    ),
  ),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout();
*/

// NEW CODE (Fix)
final textScaler = MediaQuery.textScalerOf(context); // Or MediaQuery.of(context).textScaleFactor for older Flutter

final textPainter = TextPainter(
  text: TextSpan(
    text: displayText,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    ),
  ),
  textDirection: TextDirection.ltr,
  textScaler: textScaler, // crucial for correct measurement
  maxLines: 1,
)..layout();

// ...

// When calculating minW, add a small buffer
double minW = (paddingLeft + maxContentWidth + paddingRight + 0.5).ceilToDouble() + 2.0; // Added +2.0 safety buffer
```

By implementing these changes, the layout calculation will accurately reflect the user's text settings, ensuring that the text is fully visible on all devices.
