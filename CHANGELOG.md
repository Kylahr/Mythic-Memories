# Changelog

## v1.1.1

### UI Polish
- Extended table to the right edge — scrollbar now sits flush against the frame border
- Scrollbar track spans full table card height; thumb constrained to row area below header
- Reduced gap between rows and scrollbar for a tighter layout
- Column headers aligned with row width
- Role column text now matches other columns (was incorrectly white/bold)
- MVP side panel scrollbar track darkened for better thumb visibility

### Color & Style
- Material Design dark theme color pass on all popups and input fields
- Depletion color lightened for better readability
- Crown icons use desaturated base + vibrant vertex colors (gold, blue, green)
- Class colors fixed in world-view popups (UnitClass API fix)
- Note popup titles use neutral base so inline class color codes render correctly
- "Note:" labels consistently yellow across all dialogs
- Filter dropdown background differentiated from popup background

### Features
- Delete Run option added to row right-click context menu with confirmation dialog
- Help panel rewritten with current feature list and inline icon textures

### Scroll & Expand
- Smooth half-row scroll steps
- Expanded tree view rows scroll off smoothly with peek row
- Permanent bottom padding for tree view visibility
- Table no longer jumps when expanding/collapsing bottom rows

### Fixes
- Filter button and help button stay highlighted while their panels are open
- HideAllPopups now properly resets filter and help button states
- Favourite star resized and repositioned (left of filter button, pictogram style)

## v1.1.0
- UI redesign, favourites, advanced filters

## v1.0.1
- Initial release with auto-recording, MVP system, table sharing
