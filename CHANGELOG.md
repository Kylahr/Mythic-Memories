# Changelog

## v1.8.0

### Multi-Table Management
- Organize runs into multiple independent tables (like folders)
- **Tables button** on the filter bar opens the Table Manager panel
- Create, rename, and delete tables freely
- **Active table** (gold dot) receives new M+ run data — set via right-click → "Set Active"
- **Viewed table** (highlighted) controls what's displayed — switch by left-clicking
- Title bar shows the currently viewed table name
- One-time migration wraps existing runs into a default "All Runs" table

### Run Management
- **Move to Table**: right-click a run row → "Move to Table" submenu to move runs between tables
- Context menu order: Favourite → Move to Table → Delete Run
- Right-click context menu disabled in remote view mode

### Remote Table Browsing
- Remote viewers see the owner's active table by default
- **Table dropdown** in view mode title bar lists the remote player's tables
- Selecting a remote table requests and loads that table's data
- **Loading indicator** with animated dots while waiting for remote data
- New comm protocol: `TABLE_LIST_REQ` / `TABLE_LIST_RESP` for discovering remote tables
- `TABLE_REQ` now supports an optional table name parameter (backwards compatible)

### World Tooltip MVP Display
- Hovering over a player in the world shows MVP status in their tooltip
- Gold crown icon + "MVP" label displayed for players in your MVP list
- MVP note shown below the badge if present
- Uses `TooltipDataProcessor` API with `HookScript` fallback

### Technical
- New SavedVariables schema: `tables` array with `activeTableIndex`
- Separated "active" (data input) from "viewed" (display) table concepts
- MVPs and favourites remain global across all tables
- Filters persist across table switches
- All new UI elements integrate with the theme system (teardown/rebuild on switch)

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
