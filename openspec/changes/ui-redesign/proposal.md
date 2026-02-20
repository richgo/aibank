# Proposal: AIBank UI Redesign

## Intent

The current AIBank Flutter app presents a functional but visually basic banking interface using default Material Design components. Users interact with full-width ListTile-based account cards and vertical transaction lists that occupy significant screen space, resulting in a utilitarian experience that lacks personality and modern fintech polish.

This redesign addresses three core problems:

1. **Lack of Brand Identity**: The app has no distinctive visual identity or mascot that makes it memorable or trustworthy. Users need emotional connection and visual cues that signal both heritage/stability and modern innovation.

2. **Inefficient Space Usage**: Current account cards use full-width ListTile layouts. Multiple accounts quickly create visual clutter and require excessive scrolling. Users need to see their full financial picture at a glance.

3. **Transaction Display UX Gap**: Transaction lists render as separate vertical panels, disconnecting them from the account context. When a user asks about an account, the transactions should appear inline in the chat conversation as a compact, scannable table—not as a separate widget.

The goal is to transform AIBank from a functional demo into a polished product that combines the trustworthiness of traditional British banking (Lloyds' heritage) with the delightful, modern UX of contemporary fintech (Monzo's clarity and personality).

## Scope

### In Scope

- **New Brand Identity**: Invention of an original animal mascot/logo — the **Swift Fox** — that symbolizes the fusion of traditional banking heritage with modern fintech agility
- **Theme System Overhaul**: Complete redesign of `BankTheme` color palette, typography, spacing constants, and component defaults blending Lloyds (deep green, trustworthy) and Monzo (coral, playful, rounded) design languages
- **Horizontal Thin Account Cards**: Transform `AccountCard` into slim, horizontally-scrolling cards with compact layouts, rounded corners, gradient backgrounds, and tap ripple effects
- **Inline Transaction Tables**: Redesign `TransactionList` to render as a compact, scrollable `DataTable`-style table optimised for inline display within the chat conversation window
- **Visual Polish**: Rounded corners, elevation/shadows, gradient accents, and clean typography across all catalog widgets
- **ChatScreen Layout Adjustments**: Modify `ChatScreen` to accommodate horizontal account card lists and inline transaction tables

### Out of Scope

- Navigation changes (tabs, bottom nav) — single-screen chat interface remains
- Multi-language support or accessibility enhancements beyond color contrast
- Responsive web/desktop layouts (mobile-first only)
- Animated transitions or complex micro-interactions
- User authentication UI or onboarding flows
- Chart/graph widgets for financial data
- Dark mode theme variant
- Backend API or agent changes
- GenUI framework modifications

## Approach

### 1. Brand Foundation — The Swift Fox

**Mascot Concept**: **The Swift Fox**
- **Symbolism**: Combines agility and speed (modern fintech) with cleverness and reliability (traditional banking wisdom). Bridges Lloyds' noble horse with Monzo's modern identity.
- **Visual Style**: Geometric, minimalist design with rounded edges — echoing Monzo's friendly aesthetic while maintaining sophisticated proportions
- **Color Treatment**: Primary form in deep forest green (`#006B3D`) with coral (`#FF6B6B`) accent details (ears, tail tip, eye highlight)
- **Personality**: Alert, intelligent, approachable — a guardian of your finances that is both swift and trustworthy
- **Implementation**: Rendered as a `CustomPaint` widget or inline SVG in a new `lib/widgets/brand_logo.dart`

### 2. Design Language Fusion

**Color Palette**:
| Token | Value | Usage |
|---|---|---|
| Primary Green | `#006B3D` | App bar, primary buttons, card gradients |
| Accent Coral | `#FF6B6B` | CTAs, progress bars, positive accents |
| Text Dark | `#1A1A1A` | Primary text |
| Background Light | `#F5F5F5` | Screen background |
| Surface White | `#FFFFFF` | Card surfaces |
| Success Green | `#1B8A3A` | Positive balances |
| Error Red | `#D32F2F` | Negative balances, alerts |

**Typography**:
- **Headers** (account names, section titles): `Merriweather` or Georgia fallback — serif weight conveys heritage
- **Body** (descriptions, chat text): `Inter` or system sans-serif (SF Pro/Roboto) — modern clarity
- **Currency amounts**: `JetBrains Mono` or `monospace` — tabular figures, clean scannable alignment

**Spacing & Shape**:
- Border Radius: `24px` for account cards, `16px` for panels, `8px` for buttons
- Elevation: `2dp` resting, `4dp` on hover/tap, `8dp` for modals
- Standard Padding: `16px` (default), `12px` (compact), `24px` (spacious)

### 3. Component Redesign

**AccountCard — Thin Horizontal Card**:
- Dimensions: `~180px wide × 120px tall`
- Layout: account type icon (top-left) + account name + large bold balance (center) + account type label (bottom)
- Gradient background (green shades, `#006B3D` → `#00A86B`)
- `InkWell` with `borderRadius: 24px` ripple on tap
- Tap sends agent message: `"Show transactions for [accountName]"`
- Displayed in a horizontal `ListView` within the chat surface, height `~140px`

**TransactionList — Inline Chat Table**:
- Replaces vertical `ListTile` list with a compact grid table
- Columns: `Date (25%) | Description (50%) | Amount (25%)`
- Alternating row backgrounds (white / `#F9F9F9`)
- Amount column: right-aligned, color-coded green/red, monospace font
- Wrapped in `ConstrainedBox(maxHeight: 400)` with `SingleChildScrollView` for overflow
- Header row in primary green with white text

**Other Widgets (apply new theme)**:
- `CreditCardSummary`: card-shaped with gradient, coral progress bar
- `SavingsSummary`: lighter green tint, interest rate badge (coral pill)
- `MortgageDetail`: structured table layout with payment breakdown rows

### 4. ChatScreen Modifications

- Account card lists: wrap in `SizedBox(height: 140)` + `ListView.builder(scrollDirection: Axis.horizontal)`
- Transaction tables: wrap in `ConstrainedBox(maxHeight: 400)` with internal scroll
- Chat message bubbles: add subtle background tint for user vs AI messages
- `ClipRRect(borderRadius: 16)` around GenUI surfaces for consistency

### 5. Theme as Source of Truth

`BankTheme` will be the single source for all design tokens — colors, text styles, border radii, shadows, gradients, and component defaults — eliminating inline styling across widgets.

## Impact

### Files to Modify
| File | Change |
|---|---|
| `lib/theme/bank_theme.dart` | Complete overhaul: new `ColorScheme`, `TextTheme`, card/button defaults, gradient defs, radius constants |
| `lib/catalog/account_card.dart` | Replace `ListTile` with thin horizontal gradient card + tap handler |
| `lib/catalog/transaction_list.dart` | Replace `ListTile` list with scrollable table layout |
| `lib/catalog/account_overview.dart` | Update to use horizontal card scroll container |
| `lib/catalog/credit_card_summary.dart` | Apply new rounded card style, coral progress bar |
| `lib/catalog/savings_summary.dart` | Apply new style, interest rate badge |
| `lib/catalog/mortgage_detail.dart` | Apply new table layout style |
| `lib/screens/chat_screen.dart` | Add horizontal scroll support, constrained table container, message bubble styling |

### Files to Create
| File | Purpose |
|---|---|
| `lib/widgets/brand_logo.dart` | Swift Fox logo widget (`CustomPaint` or SVG) |

### Dependencies
- **No new required dependencies** — design achievable with existing `flutter/material.dart`
- **Optional**: `google_fonts` for custom Inter/Merriweather typography
- **Optional**: `flutter_svg` if logo is SVG-based

## Risks

1. **Mascot Subjectivity**: The Swift Fox may not resonate. Alternatives (owl = wisdom, stag = nobility, heron = patience) should be ready as backups.
2. **Color Clash**: Balancing deep green + coral risks visual noise. Recommended ratio: 70% green, 20% neutral white/gray, 10% coral accent only.
3. **Horizontal Scroll Discoverability**: Users with many accounts may not discover horizontal scrolling without scroll indicators.
4. **Table Readability**: Three-column table may be cramped on narrow screens (<375px); consider truncating description column.
5. **GenUI Surface Sizing**: New widget dimensions must be validated against `SizedBox(height: 320)` wrapper in `ChatScreen` — may need dynamic height or unconstrained rendering.

## Open Questions

1. Is the **Swift Fox** mascot concept approved, or should alternatives be explored?
2. Should coral be used only for CTAs, or also in gradients and card accents?
3. Use **system fonts** or add `google_fonts` dependency for Inter/Merriweather?
4. Confirm: tapping an account card sends an **agent message** ("Show transactions for X") — or pre-load transaction data in the card model?
5. Transaction table columns — basic `Date | Description | Amount` or extended with `Category` or `Balance After`?
6. Should the `brand_logo.dart` widget replace the app title text in the AppBar, or appear separately on a splash/header?
