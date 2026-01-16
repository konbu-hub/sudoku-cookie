# Phase 18 Impl Plan: Title Screen Redesign

## Goals
1.  **Remove**: "クボゲー Vol.1" text.
2.  **Focus**: Make "おしゃべりクッキーのSUDOKU" the main centerpiece.
3.  **Aesthetic**: "Dark/Fallen" (闇落ち) & "Cool".

## Design Approach
- **Typography**:
    - Increase font size significantly (e.g., 32 -> 40+).
    - Use `FontWeight.w900` (Black/Heavy).
    - **Color**: Gradient text or Deep Red/Purple.
    - **Shadows**: Multiple shadows to create depth and a "glow" or "outline" effect.
        - Layer 1: Red/Purple glow (BlurRadius high).
        - Layer 2: Sharp Black outline (Offset small).

## Implementation Details (`lib/screens/title_screen.dart`)
- **Widget**: Replace the existing `Column` of texts with a single, styled `Text` wrapped in effects.
- **Code Snippet**:
```dart
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [Colors.red.shade900, Colors.black],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ).createShader(bounds),
  child: Text(
    'おしゃべりクッキーの\nSUDOKU', 
    // ...
  ),
)
```

## Steps
1.  Modify `TitleScreen.dart`:
    - Delete the `Text('クボゲー Vol.1'...)` widget.
    - Replace the second text with the new styled version.
2.  Verify via Hot Reload.
