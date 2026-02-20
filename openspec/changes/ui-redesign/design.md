# Design: AIBank UI Redesign

## Overview

This redesign transforms AIBank from a functional demo into a polished product by introducing the Swift Fox brand identity, implementing a comprehensive design system with Lloyds-inspired green and Monzo-inspired coral accents, and optimizing the UI for at-a-glance financial insight. The technical approach centers on a complete `BankTheme` overhaul providing design tokens (colors, typography, spacing, radii, elevation), horizontal account cards with tap-to-query interactions, and compact inline transaction tables—all integrated into the GenUI catalog without breaking existing A2UI message processing.

## Architecture

### Components Affected
- `lib/theme/bank_theme.dart` — complete redesign with new ColorScheme, TextTheme, CardTheme, and design token constants
- `lib/catalog/account_card.dart` — replace ListTile with 180×120px gradient card with InkWell tap handler
- `lib/catalog/transaction_list.dart` — replace ListTile list with compact 3-column table with scroll constraint
- `lib/catalog/account_overview.dart` — wrap account cards in horizontal ListView with constrained height
- `lib/catalog/credit_card_summary.dart` — apply new card styling, coral progress bar
- `lib/catalog/savings_summary.dart` — apply new card styling, coral pill badge for interest rate
- `lib/catalog/mortgage_detail.dart` — apply new table layout styling
- `lib/screens/chat_screen.dart` — support horizontal scroll containers and message bubbles with tap callbacks
- `app/pubspec.yaml` — add `google_fonts` dependency

### New Components
- `lib/widgets/brand_logo.dart` — Swift Fox logo widget using CustomPaint
- Design token constants in `BankTheme` (radii, elevation, gradient definitions)

## Technical Decisions

### Decision: Google Fonts for Typography

**Chosen:** Add `google_fonts: ^6.2.1` to pubspec.yaml, use `GoogleFonts.merriweather()` for headers and `GoogleFonts.inter()` for body text, with serif and sans-serif fallbacks.

**Alternatives considered:**
- System fonts only — rejected because Merriweather serif adds heritage feel that system fonts lack; Inter provides better consistency across platforms than default sans-serif
- Custom font assets — rejected because `google_fonts` package handles caching, fallbacks, and licensing automatically

**Rationale:** The serif/sans-serif combination creates visual hierarchy and brand personality. `google_fonts` provides automatic font loading with minimal overhead and built-in fallback mechanisms.

### Decision: AccountCard Tap Interaction via Global Callback

**Chosen:** Pass a global `Function(String accountName)? onAccountTap` callback through the catalog item's `widgetBuilder` context using a custom catalog factory wrapper or by accessing a `ChatScreen` method via a singleton/provider pattern.

**Alternatives considered:**
- Store callback in GenUI surface data model — rejected because A2UI data schema should remain pure data, not behavior
- Use Flutter's `Navigator` context to find ancestor `ChatScreen` — rejected because tight coupling to widget tree structure is brittle
- Global event bus — rejected because adds unnecessary dependency and makes data flow harder to trace

**Rationale:** Since GenUI catalog widgets are instantiated via `widgetBuilder` callbacks and don't have direct access to `ChatScreen`'s `_sendMessage`, we use a pragmatic approach: expose a static callback in a shared module (`lib/catalog/catalog_callbacks.dart`) that `ChatScreen` sets during initialization. This allows `AccountCard` to invoke `CatalogCallbacks.onAccountTap?.call(accountName)`, which triggers `_sendMessage("Show transactions for $accountName")`. This is simple, testable, and doesn't require GenUI framework changes.

### Decision: Swift Fox Logo with CustomPaint

**Chosen:** Implement Swift Fox as a stateless widget with `CustomPaint` and a custom `CustomPainter` drawing geometric shapes (triangles for ears, circle for face, small details for eyes/nose).

**Alternatives considered:**
- SVG asset with `flutter_svg` package — rejected because adds dependency; simple geometric fox can be drawn with canvas primitives
- PNG asset — rejected because scales poorly and increases app size
- Icon font — rejected because custom mascot doesn't fit icon font format

**Rationale:** CustomPaint provides resolution-independent rendering without external dependencies, perfect for a simple geometric logo. The fox shape (two triangle ears, circular face, coral accent dots) is ~50 lines of paint code.

### Decision: Transaction Table with Manual Row Layout

**Chosen:** Build transaction table with `Column` of `Row` widgets rather than `DataTable` widget. Header row uses primary green background; data rows alternate white/light-gray. Wrap in `ConstrainedBox(maxHeight: 400)` + `SingleChildScrollView(scrollDirection: Axis.vertical)`.

**Alternatives considered:**
- `DataTable` widget — rejected because requires complex column definitions, doesn't easily support alternating row colors, and has inflexible styling
- `Table` widget — rejected because harder to style individual rows and doesn't support scroll overflow cleanly
- Third-party data grid packages — rejected because adds dependency and overkill for simple 3-column display

**Rationale:** Manual row layout with `Row` widgets provides full styling control (alternating backgrounds, exact column widths via `Expanded` flex ratios, padding, text alignment). `ConstrainedBox` ensures table doesn't exceed chat message height; `SingleChildScrollView` handles overflow. This approach is simple, predictable, and theme-consistent.

### Decision: BankTheme Design Tokens as Static Constants

**Chosen:** Define design tokens as `static const` values in `BankTheme` class—border radii (`cardRadius = 24.0`, `panelRadius = 16.0`, `buttonRadius = 8.0`), elevation levels (`elevationResting = 2.0`, `elevationInteractive = 4.0`, `elevationModal = 8.0`), and gradient definitions as static methods returning `LinearGradient` instances.

**Alternatives considered:**
- Extension methods on ThemeData — rejected because harder to discover and use in non-widget contexts
- Separate `DesignTokens` class — rejected because splits theme config across multiple files
- Theme extensions via `ThemeData.extensions` — rejected because adds boilerplate and requires theme context access

**Rationale:** Static constants in `BankTheme` make tokens easily accessible via `BankTheme.cardRadius` anywhere in the codebase. Co-locating tokens with ColorScheme/TextTheme in the same file creates a single source of truth for all visual styling.

### Decision: Horizontal Account Card Scroll in AccountOverview

**Chosen:** Replace vertical `Column` of account cards with `SizedBox(height: 140)` containing `ListView.builder(scrollDirection: Axis.horizontal, itemBuilder: ...)` with 12px horizontal padding between cards.

**Alternatives considered:**
- `PageView` with snap behavior — rejected because users expect free scroll for financial overview, not paged navigation
- `SingleChildScrollView` with `Row` — rejected because ListView.builder provides better performance with many accounts (lazy loading)
- Keep vertical layout — rejected because horizontal cards enable at-a-glance multi-account view without scrolling

**Rationale:** Horizontal scroll maximizes screen real estate for the chat conversation while presenting all accounts in a compact, swipeable gallery. 140px container height accommodates 120px cards + padding. ListView.builder supports arbitrary account counts efficiently.

## Data Flow

### Account Card Tap → Chat Message Flow

1. User taps `AccountCard` widget rendered in `AccountOverview` surface
2. `InkWell.onTap` in `AccountCard` calls `CatalogCallbacks.onAccountTap?.call(accountName)`
3. `ChatScreen._initState` has set `CatalogCallbacks.onAccountTap = _sendMessage` 
4. `_sendMessage("Show transactions for $accountName")` is invoked
5. Message appears in `_messages` list as `UserMessage`
6. `_conversation.sendRequest(msg)` sends to agent via A2uiContentGenerator
7. Agent processes request and returns A2UI surface message with `TransactionList` component
8. `_processor` deserializes message, adds surface to conversation
9. `onSurfaceAdded` callback updates `_surfaceIds`, triggering rebuild
10. `GenUiSurface` renders `TransactionList` inline in chat

### Typography Cascade

1. `MaterialApp` applies `BankTheme.light` ThemeData
2. `BankTheme.light.textTheme` defines headline/body styles using `GoogleFonts.merriweather()` and `GoogleFonts.inter()`
3. Widgets access styles via `Theme.of(context).textTheme.headlineSmall`, `bodyMedium`, etc.
4. Currency amounts explicitly override with `TextStyle(fontFamily: 'monospace')` for tabular figures
5. Font loading: google_fonts package fetches fonts on first use, caches locally; fallbacks (Georgia, system sans-serif) apply if network fails

### GenUI Surface Rendering with New Layouts

1. Agent sends A2UI surface message (e.g., `AccountOverview` with list of account data)
2. `A2uiMessageProcessor` matches `surfaceId` to catalog item (`accountOverviewItem()`)
3. `widgetBuilder(CatalogItemContext)` extracts data, builds horizontal `ListView` of `AccountCard` widgets
4. Each `AccountCard` reads theme colors via `Theme.of(context).colorScheme.primary` and applies gradient
5. `ChatScreen` wraps surface in `SizedBox(height: 320)` (or dynamic height if needed)
6. Surface renders inline in chat conversation's vertical ListView

## API Changes

No API changes to backend agent or GenUI framework. All changes are Flutter UI layer only.

**Catalog interface preserved:**
- `CatalogItem` schemas remain unchanged (accountName, accountType, balance, currency, etc.)
- `widgetBuilder` signatures unchanged, just implementation updated
- A2UI message format unchanged

**New internal API:**
- `lib/catalog/catalog_callbacks.dart` exposes `static Function(String)? onAccountTap` for ChatScreen to set

## Dependencies

**New dependencies:**
- `google_fonts: ^6.2.1` — for Merriweather and Inter font loading

**No new dependencies:**
- Swift Fox logo uses CustomPaint (built-in)
- All UI components use flutter/material.dart widgets
- No flutter_svg or additional packages required

**pubspec.yaml update:**
```yaml
dependencies:
  google_fonts: ^6.2.1
  # ... existing dependencies
```

## Migration / Backwards Compatibility

**Backwards compatible:** All existing GenUI surfaces continue to render. Old data models work unchanged.

**Visual breaking changes:** Existing users will see completely new visual styling, but no functional regressions.

**No data migration required:** Theme changes affect only presentation layer.

**Deployment strategy:**
1. Update pubspec.yaml, run `flutter pub get`
2. Add `brand_logo.dart` and `catalog_callbacks.dart`
3. Update `bank_theme.dart` with new theme
4. Update catalog widgets incrementally (account_card, transaction_list, etc.)
5. Update `chat_screen.dart` to set callback and support new layouts
6. Test all scenarios from specs.md
7. Deploy as standard app update

## Testing Strategy

### Spec Scenario Coverage

| Spec Scenario | Test Type | Validation |
|---|---|---|
| Swift Fox Logo Renders in App Bar | Widget test | Check AppBar contains BrandLogo widget with correct colors |
| Primary Green Applied to App Elements | Golden test | Snapshot AppBar, buttons, cards; verify #006B3D color |
| Accent Coral Applied to CTAs | Golden test | Snapshot progress bars, badges; verify #FF6B6B color |
| Header Typography Using Merriweather | Widget test | Extract TextStyle from headline, verify fontFamily contains 'Merriweather' |
| Body Typography Using Inter | Widget test | Extract TextStyle from body text, verify fontFamily contains 'Inter' |
| Currency Typography Using Monospace | Widget test | Extract TextStyle from amounts, verify fontFamily is 'monospace' |
| Border Radius Tokens | Widget test | Check CardTheme has shape with 16px radius; AccountCard has 24px ClipRRect |
| Account Card Dimensions and Layout | Widget test | Render AccountCard, measure size (expect ~180×120), verify child layout order |
| Account Card Gradient Background | Widget test | Extract BoxDecoration, verify gradient stops #006B3D → #00A86B |
| Account Card Tap Ripple Effect | Widget test | Tap AccountCard, verify InkWell shows ripple with 24px border radius |
| Account Card Sends Agent Message on Tap | Integration test | Tap card, verify _sendMessage called with "Show transactions for X" |
| Multiple Account Cards in Horizontal Scroll | Widget test | Render AccountOverview with 5 accounts, verify ListView.horizontal, measure scroll extent |
| Transaction Table Layout | Widget test | Render TransactionList, verify Column contains header Row + data Rows, check column widths |
| Transaction Table Header Styling | Widget test | Extract header Row decoration, verify green background + white text |
| Transaction Row Alternating Backgrounds | Widget test | Verify even rows white, odd rows #F9F9F9 |
| Transaction Amount Formatting and Color | Widget test | Render transaction with positive/negative amounts, verify color green/red, text right-aligned |
| Transaction Table Scroll Container | Widget test | Render 50 transactions, verify ConstrainedBox maxHeight=400, verify SingleChildScrollView present |
| ChatScreen Renders Horizontal Account Card Container | Widget test | Render ChatScreen with AccountOverview surface, verify SizedBox(height: 140) with horizontal ListView |
| ChatScreen Renders Constrained Transaction Table | Widget test | Render ChatScreen with TransactionList surface, verify ConstrainedBox + ClipRRect |

### Unit Tests
- `BankTheme.cardGradient()` returns correct LinearGradient with green shades
- `BrandLogo` painter draws correct geometric shapes (verify paint calls in mock canvas)
- `CatalogCallbacks.onAccountTap` invocation triggers expected side effect

### Widget Tests
- AccountCard renders with all props (accountName, accountType, balance, currency)
- TransactionList renders with empty list (shows "No transactions")
- AccountOverview builds horizontal ListView with correct number of children

### Integration Tests
- Full flow: launch app → agent sends AccountOverview → tap account card → agent sends TransactionList → table renders inline
- Verify scrolling works in both horizontal (account cards) and vertical (transaction table, chat messages)
- Verify theme applies consistently across all catalog widgets

### Visual Regression Tests
- Golden file tests for AccountCard, TransactionList, AccountOverview, ChatScreen with surfaces
- Compare before/after snapshots to catch unintended style changes

### Accessibility Tests
- Color contrast: verify text/background ratios meet WCAG AA (4.5:1 for body, 3:1 for large headers)
- Semantics: verify AccountCard has semantic label "Account name, balance £X.XX, tap to view transactions"
- Touch targets: verify InkWell on AccountCard meets 48×48px minimum

## Edge Cases

### Very Long Account Name
- **Problem:** Account name "My Emergency Savings and Travel Fund" exceeds card width
- **Solution:** Use `Text` with `overflow: TextOverflow.ellipsis, maxLines: 2` in AccountCard layout. Reserve 160px width for text, allowing 2 lines before truncation.
- **Testing:** Widget test with 50-character account name, verify no layout overflow.

### Narrow Mobile Screen (320px width)
- **Problem:** Transaction table columns cramped; Description column text truncates heavily
- **Solution:** Date 20%, Description 50%, Amount 30% flex ratios. Description uses `overflow: TextOverflow.ellipsis`. Full description available via tap (future enhancement) or scrollable detail view.
- **Testing:** Widget test with 320px constraint, verify table renders without overflow errors.

### Missing Google Fonts (Network Failure)
- **Problem:** google_fonts package fails to load Merriweather/Inter due to network or cache issue
- **Solution:** `GoogleFonts.merriweather(fallback: ['Georgia', 'serif'])` and `GoogleFonts.inter(fallback: ['Roboto', 'sans-serif'])` ensure graceful degradation.
- **Testing:** Mock network failure in test, verify fallback fonts apply, app remains visually acceptable.

### Zero or Negative Balances
- **Problem:** Negative balance "-£500.00" in AccountCard needs clear visual treatment
- **Solution:** Apply `TextStyle(color: BankTheme.negative)` (red) for negative balances, `BankTheme.positive` (green) for positive. Card gradient remains green (represents bank itself, not balance sign).
- **Testing:** Widget test with negative balance, verify text color is red (#D32F2F).

### Transaction Table with No Data
- **Problem:** Agent returns empty transactions list
- **Solution:** TransactionList `widgetBuilder` checks `items.isEmpty`, returns `Text('No transactions found')` styled with theme bodyMedium.
- **Testing:** Widget test with empty items array, verify empty state message appears.

### Transaction Table with 100+ Rows
- **Problem:** Large transaction history causes performance lag or extreme scroll height
- **Solution:** ConstrainedBox(maxHeight: 400) ensures table never exceeds chat message height. ListView.builder (if refactored for rows) could improve performance, but manual Row in Column is acceptable for <200 rows (typical use case).
- **Testing:** Performance test with 200 transaction rows, measure frame rendering time (target <16ms per frame for 60fps).

### Horizontal Scroll Not Discoverable
- **Problem:** User with 5 accounts doesn't realize cards scroll horizontally
- **Solution:** Add `physics: BouncingScrollPhysics()` to ListView for iOS-style bounce, indicating scroll. First/last card partially visible (show 2.5 cards on screen) to hint at more content. Optional: add horizontal scroll indicator (PageIndicator dots).
- **Testing:** Manual testing with 5 accounts, verify partial card visibility, verify scroll physics feel natural.

### High Contrast / Accessibility Mode
- **Problem:** Coral #FF6B6B on white background may not meet WCAG AA contrast ratio (3:1 for large text)
- **Solution:** Coral used only for large accent elements (badges, progress bars > 18pt). For small text, use `BankTheme.positive` green (#1B8A3A) which meets 4.5:1 ratio. In high-contrast mode (detected via `MediaQuery.of(context).highContrast`), darken coral to #CC5555.
- **Testing:** Accessibility audit in Flutter DevTools, verify all text meets WCAG AA standards.

### AccountCard Tap During Network Request
- **Problem:** User taps account card twice rapidly, sending duplicate messages
- **Solution:** Disable tap (set `InkWell.onTap = null`) during active request, re-enable when response received. Use loading indicator or shimmer on card to show pending state.
- **Future enhancement:** Track pending state in ChatScreen, pass `isPending` prop to AccountCard.
- **Testing:** Integration test with simulated slow network, verify double-tap doesn't send duplicate messages.

## Component Implementation Details

### 1. BankTheme Overhaul

**File:** `lib/theme/bank_theme.dart`

**Structure:**
```dart
class BankTheme {
  // Color constants
  static const primaryGreen = Color(0xFF006B3D);
  static const accentCoral = Color(0xFFFF6B6B);
  static const textDark = Color(0xFF1A1A1A);
  static const backgroundLight = Color(0xFFF5F5F5);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const positive = Color(0xFF1B8A3A);
  static const negative = Color(0xFFD32F2F);

  // Radius constants
  static const double cardRadius = 24.0;
  static const double panelRadius = 16.0;
  static const double buttonRadius = 8.0;

  // Elevation constants
  static const double elevationResting = 2.0;
  static const double elevationInteractive = 4.0;
  static const double elevationModal = 8.0;

  // Gradient definitions
  static LinearGradient cardGradient() => LinearGradient(
    colors: [primaryGreen, Color(0xFF00A86B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme data
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.light(
      primary: primaryGreen,
      secondary: accentCoral,
      surface: surfaceWhite,
      background: backgroundLight,
      error: negative,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textDark,
      onBackground: textDark,
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.merriweather(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
      headlineMedium: GoogleFonts.merriweather(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
      headlineSmall: GoogleFonts.merriweather(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textDark),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: textDark),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: textDark),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textDark),
    ),
    cardTheme: CardThemeData(
      elevation: elevationResting,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(panelRadius)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        elevation: elevationResting,
      ),
    ),
  );
}
```

**Imports:** Add `import 'package:google_fonts/google_fonts.dart';`

**Fallbacks:** GoogleFonts automatically includes fallbacks; if font fails to load, Material defaults apply.

### 2. Swift Fox Logo Widget

**File:** `lib/widgets/brand_logo.dart`

**Widget:**
```dart
class BrandLogo extends StatelessWidget {
  final double size;
  
  const BrandLogo({super.key, this.size = 40.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwiftFoxPainter(),
      ),
    );
  }
}

class _SwiftFoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()
      ..color = BankTheme.primaryGreen
      ..style = PaintingStyle.fill;
    
    final coralPaint = Paint()
      ..color = BankTheme.accentCoral
      ..style = PaintingStyle.fill;

    // Draw circle face
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.35,
      greenPaint,
    );

    // Draw left ear (triangle)
    final leftEar = Path()
      ..moveTo(size.width * 0.3, size.height * 0.25)
      ..lineTo(size.width * 0.2, size.height * 0.05)
      ..lineTo(size.width * 0.4, size.height * 0.15)
      ..close();
    canvas.drawPath(leftEar, greenPaint);

    // Draw right ear (triangle)
    final rightEar = Path()
      ..moveTo(size.width * 0.7, size.height * 0.25)
      ..lineTo(size.width * 0.8, size.height * 0.05)
      ..lineTo(size.width * 0.6, size.height * 0.15)
      ..close();
    canvas.drawPath(rightEar, greenPaint);

    // Coral ear tips
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.05), size.width * 0.05, coralPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.05), size.width * 0.05, coralPaint);

    // Eyes (white with coral highlight)
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.45), size.width * 0.06, whitePaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.45), size.width * 0.06, whitePaint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.45), size.width * 0.03, coralPaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.45), size.width * 0.03, coralPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

**Integration:** Add `BrandLogo()` to AppBar in `ChatScreen`:
```dart
AppBar(
  title: Row(
    children: [
      const BrandLogo(size: 32),
      const SizedBox(width: 8),
      const Text('AIBank'),
    ],
  ),
)
```

### 3. AccountCard Thin Horizontal Card

**File:** `lib/catalog/account_card.dart`

**Changes:**
- Replace `Card` + `ListTile` with `Container` + `BoxDecoration` with gradient
- Add `InkWell` with `borderRadius: BorderRadius.circular(BankTheme.cardRadius)`
- Call `CatalogCallbacks.onAccountTap?.call(accountName)` in `onTap`
- Layout: Icon at top-left, account name, balance (large bold), account type label at bottom

**Implementation sketch:**
```dart
CatalogItem accountCardItem() {
  // schema unchanged
  return CatalogItem(
    name: 'AccountCard',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final accountName = map['accountName'] as String? ?? '';
      final accountType = map['accountType'] as String? ?? '';
      final balance = map['balance'] as String? ?? '0.00';
      final currency = map['currency'] as String? ?? '£';
      
      final isNegative = balance.startsWith('-');
      final balanceColor = isNegative ? BankTheme.negative : BankTheme.positive;

      return SizedBox(
        width: 180,
        height: 120,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(BankTheme.cardRadius),
            onTap: () => CatalogCallbacks.onAccountTap?.call(accountName),
            child: Container(
              decoration: BoxDecoration(
                gradient: BankTheme.cardGradient(),
                borderRadius: BorderRadius.circular(BankTheme.cardRadius),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                  const Spacer(),
                  Text(
                    accountName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currency$balance',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const Spacer(),
                  Text(
                    accountType,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
```

**Note:** Balance color displayed as white on green gradient for readability; semantic color (green/red) used elsewhere in UI.

### 4. TransactionList Compact Table

**File:** `lib/catalog/transaction_list.dart`

**Changes:**
- Replace `Column` of `ListTile` with `Column` containing header `Row` + data `Row`s
- Header: green background, white text, bold
- Data rows: alternating white/#F9F9F9 backgrounds
- Column widths: Date 25%, Description 50%, Amount 25% via `Expanded` with flex
- Wrap in `ConstrainedBox(maxHeight: 400)` + `SingleChildScrollView(scrollDirection: Axis.vertical)`
- Amount: right-aligned, monospace, color-coded green (credits) / red (debits)

**Implementation sketch:**
```dart
CatalogItem transactionListItem() {
  // schema unchanged
  return CatalogItem(
    name: 'TransactionList',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final items = (map['items'] as List?) ?? const [];
      
      if (items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No transactions found', style: Theme.of(context).textTheme.bodyMedium),
        );
      }

      final headerRow = Container(
        color: BankTheme.primaryGreen,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Expanded(flex: 25, child: Text('Date', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            Expanded(flex: 50, child: Text('Description', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            Expanded(flex: 25, child: Text('Amount', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      );

      final dataRows = items.asMap().entries.map((entry) {
        final index = entry.key;
        final tx = entry.value as Map<String, Object?>;
        final date = tx['date'] as String? ?? '';
        final description = tx['description'] as String? ?? '';
        final amount = tx['amount'] as String? ?? '0.00';
        final type = tx['type'] as String? ?? 'credit';
        
        final isDebit = type == 'debit';
        final amountColor = isDebit ? BankTheme.negative : BankTheme.positive;
        final amountText = '${isDebit ? '-' : '+'}£$amount';
        final bgColor = index.isEven ? Colors.white : const Color(0xFFF9F9F9);

        return Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              Expanded(flex: 25, child: Text(date, style: const TextStyle(fontSize: 12))),
              Expanded(flex: 50, child: Text(description, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
              Expanded(flex: 25, child: Text(amountText, textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: amountColor, fontWeight: FontWeight.w600))),
            ],
          ),
        );
      }).toList();

      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [headerRow, ...dataRows],
          ),
        ),
      );
    },
  );
}
```

### 5. AccountOverview Horizontal Scroll

**File:** `lib/catalog/account_overview.dart`

**Changes:**
- Replace vertical `Column` of account text with horizontal `ListView.builder`
- Container height: 140px (accommodates 120px cards + padding)
- Net worth header remains at top (vertical Column: net worth Text + horizontal ListView)

**Implementation sketch:**
```dart
CatalogItem accountOverviewItem() {
  // schema unchanged
  return CatalogItem(
    name: 'AccountOverview',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final accounts = (map['accounts'] as List?) ?? const [];
      final netWorth = map['netWorth'] as String? ?? '0.00';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Net worth: £$netWorth',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index] as Map<String, Object?>;
                // Return AccountCard widget (instantiate manually or via catalog)
                // For simplicity, inline the card here (or extract to shared builder)
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: accountCardWidget(account),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

Widget accountCardWidget(Map<String, Object?> data) {
  // Reuse AccountCard logic or call accountCardItem().widgetBuilder(...)
  // For cleaner approach, extract AccountCard widget into separate class
}
```

**Better approach:** Extract `AccountCard` as a standalone widget class that takes props, used by both `accountCardItem()` and `accountOverviewItem()`.

### 6. ChatScreen Modifications

**File:** `lib/screens/chat_screen.dart`

**Changes:**
1. Import `lib/catalog/catalog_callbacks.dart`
2. In `initState()`, set `CatalogCallbacks.onAccountTap = _sendMessage;`
3. In `dispose()`, clear `CatalogCallbacks.onAccountTap = null;`
4. Modify surface rendering: keep `SizedBox(height: 320)` but allow dynamic height for AccountOverview (test if 320 is sufficient or use intrinsic height)
5. Add message bubble styling (optional): wrap user/AI messages in `Container` with subtle background tint + `ClipRRect(borderRadius: 16)`

**Implementation sketch:**
```dart
@override
void initState() {
  super.initState();
  CatalogCallbacks.onAccountTap = _sendMessage; // <-- ADD THIS
  // ... existing init code
}

@override
void dispose() {
  CatalogCallbacks.onAccountTap = null; // <-- ADD THIS
  // ... existing dispose code
}

void _sendMessage(String text) {
  // Extract existing _send() logic into reusable method
  final msg = UserMessage.text(text);
  setState(() => _messages.insert(0, msg));
  _conversation?.sendRequest(msg);
  _fetchFallbackData(text);
}

// Update surface rendering to support ClipRRect
..._surfaceIds.map((id) => _processor == null
    ? const SizedBox.shrink()
    : ClipRRect(
        borderRadius: BorderRadius.circular(BankTheme.panelRadius),
        child: SizedBox(height: 320, child: GenUiSurface(host: _processor!, surfaceId: id)),
      )),
```

### 7. Catalog Callbacks Shared Module

**File:** `lib/catalog/catalog_callbacks.dart` (NEW)

**Purpose:** Provide global callback mechanism for catalog widgets to communicate with ChatScreen.

**Implementation:**
```dart
class CatalogCallbacks {
  static void Function(String accountName)? onAccountTap;
}
```

**Usage:**
- ChatScreen sets callback in initState
- AccountCard invokes callback in onTap
- Simple, testable, no complex dependency injection

### 8. Other Catalog Widgets Theme Updates

**Files:** `credit_card_summary.dart`, `savings_summary.dart`, `mortgage_detail.dart`

**Changes:**
- Apply `BankTheme.cardRadius` to ClipRRect or BoxDecoration borderRadius
- Use `Theme.of(context).colorScheme.primary` for green accents
- Use `Theme.of(context).colorScheme.secondary` (coral) for progress bars, badges
- Use `Theme.of(context).textTheme.bodyMedium` for body text
- Use `TextStyle(fontFamily: 'monospace')` for currency amounts
- Add `elevation: BankTheme.elevationResting` to card containers

**Example (CreditCardSummary):**
```dart
return Card(
  elevation: BankTheme.elevationResting,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BankTheme.cardRadius)),
  child: Container(
    decoration: BoxDecoration(
      gradient: BankTheme.cardGradient(),
      borderRadius: BorderRadius.circular(BankTheme.cardRadius),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Credit Card', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
        Text('£$balance', style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        LinearProgressIndicator(
          value: utilization,
          backgroundColor: Colors.white30,
          valueColor: AlwaysStoppedAnimation(BankTheme.accentCoral),
        ),
      ],
    ),
  ),
);
```

**Note:** Each widget updated incrementally, following same pattern: gradient background, theme text styles, coral accents, monospace currency.

## Open Questions (Resolved in Design)

All open questions from proposal resolved as follows:

1. **Swift Fox mascot approved?** — Yes, proceed with CustomPaint geometric fox.
2. **Coral usage?** — CTAs, progress bars, accent details only (10% ratio). Not in card gradients.
3. **System fonts or google_fonts?** — google_fonts for Merriweather/Inter with fallbacks.
4. **Account tap sends message or pre-loads data?** — Sends agent message "Show transactions for X".
5. **Transaction table columns?** — Basic Date | Description | Amount (3-column).
6. **Logo placement?** — App bar next to title text.

## Performance Considerations

- **Google Fonts loading:** Fonts cached after first load; fallbacks prevent layout shift
- **CustomPaint logo:** Minimal overhead (~50 canvas operations), renders in <1ms
- **Horizontal ListView:** Lazy rendering; only visible cards built
- **Transaction table scroll:** ConstrainedBox prevents unbounded height; SingleChildScrollView handles overflow efficiently
- **Gradient rendering:** Linear gradients are GPU-accelerated, negligible performance impact

**Target:** 60fps on all interactions, <100ms tap response time, smooth scrolling.

## Security & Privacy

No security implications. All changes are UI presentation layer. No new network requests, no data storage changes, no credential handling.

## Future Enhancements (Out of Scope)

- Dark mode theme variant with lighter green (#00A86B primary) and muted coral
- Animated transitions (account card tap → transaction table slide-in)
- Swipe-to-delete gesture on transaction rows
- Account card customization (user-selected gradient colors)
- Chart widgets (spending trends, account balance over time)
- Advanced CustomPaint logo with subtle animations (ear twitch, eye blink)

