# Tasks: AIBank UI Redesign

## Phase 1: Dependencies & Foundation

- [x] **1.1** Add google_fonts dependency to pubspec.yaml
  Add `google_fonts: ^6.2.1` to the dependencies section in `app/pubspec.yaml` and run `flutter pub get` to install. This enables custom typography (Merriweather for headers, Inter for body text) as required by the "Custom Typography System" spec.

- [x] **1.2** Create catalog callbacks module
  Create `app/lib/catalog/catalog_callbacks.dart` with a static callback field `Function(String accountName)? onAccountTap`. This provides the mechanism for AccountCard tap interactions to communicate with ChatScreen, implementing the "AccountCard Component Interaction" spec requirement.

## Phase 2: Theme System Overhaul

- [x] **2.1** Define new ColorScheme in BankTheme
  Update `app/lib/theme/bank_theme.dart` to replace the existing ColorScheme with the new palette: primary green `#006B3D`, accent coral `#FF6B6B`, background `#F5F5F5`, surface white `#FFFFFF`, text `#1A1A1A`, success green `#1B8A3A`, error red `#D32F2F`. This implements the "Modern Theme Color Palette" spec requirements for primary, accent, and semantic colors.

- [x] **2.2** Add custom typography using GoogleFonts
  In `app/lib/theme/bank_theme.dart`, update the TextTheme to use `GoogleFonts.merriweather()` for headline styles (headlineLarge, headlineMedium, headlineSmall) and `GoogleFonts.inter()` for body styles (bodyLarge, bodyMedium, bodySmall), with appropriate fallbacks (Georgia, system sans-serif). This implements the "Custom Typography System" spec requirement for headers and body text.

- [x] **2.3** Define design token constants
  Add static constants to `BankTheme` class for design tokens: border radii (`cardRadius = 24.0`, `panelRadius = 16.0`, `buttonRadius = 8.0`), elevation levels (`elevationResting = 2.0`, `elevationInteractive = 4.0`, `elevationModal = 8.0`), and spacing (`spacing = 16.0`, `spacingCompact = 12.0`, `spacingSpacious = 24.0`). This implements the "Design Token System" spec for consistent spacing, radii, and elevation.

- [x] **2.4** Add gradient helper methods
  Add static methods to `BankTheme` for gradient definitions: `cardGradient()` returning `LinearGradient` from `#006B3D` to `#00A86B` (top-left to bottom-right), and `lightGradient()` for lighter green tints. These support the "Account Card Gradient Background" spec requirement.

- [x] **2.5** Update CardTheme and AppBarTheme
  In `BankTheme`, configure `CardTheme` with 16px border radius, elevation 2dp, and white surface color. Configure `AppBarTheme` with primary green background, white foreground, and elevation 0. This implements the "Modern Theme Color Palette" spec for app elements and the "Design Token System" spec for card styling.

## Phase 3: Brand Logo Widget

- [x] **3.1** Create BrandLogo widget with CustomPaint
  Create `app/lib/widgets/brand_logo.dart` containing a `BrandLogo` StatelessWidget with a `CustomPainter` implementation. The painter should draw a geometric fox head: two triangle ears (forest green `#006B3D`), circular face (forest green), and coral accent details (`#FF6B6B`) for ear tips, eye highlights. The widget should accept a `size` parameter (default 40×40 logical pixels). This implements the "Swift Fox Brand Logo" spec requirement and "Swift Fox Logo Widget Component" scenario.

## Phase 4: Account Card Redesign

- [ ] **4.1** Rewrite AccountCard as horizontal gradient card
  Replace the existing `app/lib/catalog/account_card.dart` implementation with a new layout: 180px width × 120px height Container with gradient background (using `BankTheme.cardGradient()`), 24px border radius (using `ClipRRect`), displaying account type icon (top-left), account name below icon, balance in large bold text (center), and account type label at bottom. This implements the "Account Card Dimensions and Layout" and "Account Card Gradient Background" spec scenarios.

- [ ] **4.2** Add InkWell tap handler to AccountCard
  Wrap the AccountCard content in an `InkWell` with `onTap` callback that invokes `CatalogCallbacks.onAccountTap?.call(accountName)`. Configure the InkWell with `borderRadius: BorderRadius.circular(24)` to respect card shape and `splashColor: Colors.white.withOpacity(0.3)` for ripple effect. This implements the "Account Card Tap Ripple Effect" and "Account Card Sends Agent Message on Tap" spec scenarios.

- [ ] **4.3** Apply theme typography and semantic colors to AccountCard
  Update AccountCard text styles to use `Theme.of(context).textTheme.headlineSmall` for account name (Merriweather font), `bodyMedium` for account type, and monospace font with large size for balance amount. Apply semantic colors: success green for positive balances, error red for negative balances. This implements "Custom Typography System" and "Semantic Colors for Financial Data" spec requirements.

## Phase 5: Transaction List Redesign

- [ ] **5.1** Build manual 3-column table layout
  Replace the existing `app/lib/catalog/transaction_list.dart` with a `Column` containing a header `Row` and data `Row` widgets. Use `Expanded` widgets with flex ratios (Date 25%, Description 50%, Amount 25%) to create fixed-width columns. Add 8px vertical + 12px horizontal padding to each cell. This implements the "Transaction Table Layout" spec scenario.

- [ ] **5.2** Style transaction table header
  Create the header row with primary green background (`Theme.of(context).colorScheme.primary`), white text color, bold font weight, and column labels "Date", "Description", "Amount". This implements the "Transaction Table Header Styling" spec scenario.

- [ ] **5.3** Implement alternating row backgrounds
  In the data rows loop, apply white background (`#FFFFFF`) to even-indexed rows and light gray background (`#F9F9F9`) to odd-indexed rows using conditional `BoxDecoration`. This implements the "Transaction Row Alternating Backgrounds" spec scenario.

- [ ] **5.4** Format and color-code transaction amounts
  For the Amount column, use monospace font (JetBrains Mono or system monospace via `TextStyle(fontFamily: 'monospace')`), right-align text, and apply success green color (`#1B8A3A`) for positive amounts and error red color (`#D32F2F`) for negative amounts. Include currency symbol. This implements the "Transaction Amount Formatting and Color" spec scenario.

- [ ] **5.5** Add scroll container with max height constraint
  Wrap the transaction table `Column` in a `ConstrainedBox` with `maxHeight: 400`, then wrap in `SingleChildScrollView` with `scrollDirection: Axis.vertical`. Add `ClipRRect` with 16px border radius to clip edges. This implements the "Transaction Table Scroll Container" spec scenario.

## Phase 6: Account Overview Horizontal Scroll

- [ ] **6.1** Convert AccountOverview to horizontal ListView
  Update `app/lib/catalog/account_overview.dart` to wrap the account cards in a `SizedBox` with height 140 pixels containing a `ListView.builder` with `scrollDirection: Axis.horizontal`. Add 12px horizontal padding between cards using `itemBuilder` padding. Keep the total net worth display at the top in a vertical layout above the horizontal card list. This implements the "Multiple Account Cards in Horizontal Scroll" and "Horizontal Account Card Scroll" spec scenarios.

## Phase 7: Chat Screen Integration

- [ ] **7.1** Initialize catalog callback in ChatScreen
  In `app/lib/screens/chat_screen.dart`, add `initState()` method that sets `CatalogCallbacks.onAccountTap = _sendMessage` (or a wrapper that calls `_sendMessage` with the formatted string "Show transactions for $accountName"`). Add cleanup in `dispose()` to set callback to null. This implements the "AccountCard Tap Triggers Agent Query" spec scenario and completes the tap-to-message data flow.

- [ ] **7.2** Add ClipRRect to GenUI surface rendering
  In ChatScreen's GenUI surface rendering code, wrap `TransactionList` surfaces with `ClipRRect(borderRadius: BorderRadius.circular(16))` to clip table edges. Ensure `AccountOverview` horizontal scroll container is wrapped in appropriate height constraint (SizedBox with height 140). This implements the "ChatScreen Renders Constrained Transaction Table" and "ChatScreen Renders Horizontal Account Card Container" spec scenarios.

- [ ] **7.3** Style message bubbles with theme colors
  Update the message bubble rendering in ChatScreen to apply subtle background tints: user messages with a light tint (e.g., `#F0F8F5` light green tint), AI messages with a different tint (e.g., `#FFF5F5` light coral tint or neutral gray). Add 16px border radius to message containers. This implements the "ChatScreen Message Bubble Styling" spec scenario.

- [ ] **7.4** Add Swift Fox logo to AppBar
  In ChatScreen's AppBar, add the `BrandLogo` widget (with default 40px size) to the `leading` or `title` section. Ensure logo colors (green body, coral accents) are visible against the green AppBar background by adjusting logo rendering if needed. This implements the "Swift Fox Logo Renders in App Bar" spec scenario.

## Phase 8: Remaining Catalog Widgets Styling

- [ ] **8.1** Update CreditCardSummary with new theme
  Update `app/lib/catalog/credit_card_summary.dart` to apply gradient background using `BankTheme.cardGradient()`, 24px border radius, elevation 2dp, coral-colored (`#FF6B6B`) progress bar for credit utilization, Inter font for body text, and monospace font for currency amounts. This implements the "CreditCardSummary with New Theme" spec scenario.

- [ ] **8.2** Update SavingsSummary with new theme
  Update `app/lib/catalog/savings_summary.dart` to apply lighter green tint background, 16px border radius, coral pill badge for interest rate (coral background `#FF6B6B`, white text, 16px border radius), and monospace font for currency amounts. This implements the "SavingsSummary with New Theme" spec scenario.

- [ ] **8.3** Update MortgageDetail with new theme
  Update `app/lib/catalog/mortgage_detail.dart` to present data in a structured table layout with alternating row backgrounds (matching TransactionList style), header row with theme styling, monospace font for currency amounts, and 16px border radius on card container. This implements the "MortgageDetail with New Theme" spec scenario.

## Phase 9: Testing & Verification

- [ ] **9.1** Write unit tests for theme and design tokens
  Create tests in `app/test/theme/bank_theme_test.dart` to verify:
  - ColorScheme contains correct hex values (#006B3D primary, #FF6B6B accent, etc.) per "Modern Theme Color Palette" spec
  - Design token constants have correct values (cardRadius=24, panelRadius=16, etc.) per "Design Token System" spec
  - `BankTheme.cardGradient()` returns LinearGradient with correct color stops per "Account Card Gradient Background" spec

- [ ] **9.2** Write widget tests for AccountCard
  Create tests in `app/test/catalog/account_card_test.dart` to verify:
  - Card renders with 180×120 dimensions per "Account Card Dimensions and Layout" spec
  - Card displays gradient background with correct colors per "Account Card Gradient Background" spec
  - Tapping card invokes callback with correct account name per "Account Card Sends Agent Message on Tap" spec
  - InkWell ripple respects 24px border radius per "Account Card Tap Ripple Effect" spec
  - Positive/negative balances render with correct semantic colors per "Semantic Colors for Financial Data" spec

- [ ] **9.3** Write widget tests for TransactionList
  Create tests in `app/test/catalog/transaction_list_test.dart` to verify:
  - Table has 3 columns with 25/50/25% flex ratios per "Transaction Table Layout" spec
  - Header row has green background and white text per "Transaction Table Header Styling" spec
  - Data rows alternate white/gray backgrounds per "Transaction Row Alternating Backgrounds" spec
  - Amounts are right-aligned, monospace, and color-coded per "Transaction Amount Formatting and Color" spec
  - Table is constrained to 400px max height with scroll per "Transaction Table Scroll Container" spec
  - Empty transaction list shows "No transactions found" message per edge case handling

- [ ] **9.4** Write widget tests for AccountOverview
  Create tests in `app/test/catalog/account_overview_test.dart` to verify:
  - Multiple cards render in horizontal ListView per "Multiple Account Cards in Horizontal Scroll" spec
  - Container height is 140px per "Horizontal Account Card Scroll" spec
  - Horizontal scroll is enabled and functional per spec requirements

- [ ] **9.5** Write widget tests for BrandLogo
  Create tests in `app/test/widgets/brand_logo_test.dart` to verify:
  - Logo widget renders without errors per "Swift Fox Logo Widget Component" spec
  - Logo size parameter is configurable with 40×40 default per spec
  - CustomPainter is invoked (verify paint calls if possible) per implementation design

- [ ] **9.6** Write integration tests for tap-to-message flow
  Create tests in `app/test/integration/account_tap_flow_test.dart` to verify:
  - Tapping AccountCard sends formatted message to agent per "Account Card Tap Triggers Agent Query" spec
  - Message appears in chat conversation per "AccountCard Tap Triggers Agent Query" spec
  - Agent responds with TransactionList surface per spec requirements
  - Full flow: AccountOverview tap → message sent → TransactionList rendered inline per integration point requirements

- [ ] **9.7** Write accessibility tests
  Create tests in `app/test/accessibility/theme_accessibility_test.dart` to verify:
  - Text-background color contrast ratios meet WCAG AA standards (4.5:1 for body, 3:1 for large text) per accessibility requirements
  - AccountCard has semantic label describing account and tap action per "Accessibility – Screen Reader on AccountCard" spec
  - Interactive elements meet 48×48 minimum touch target per accessibility requirements

- [ ] **9.8** Manual verification checklist
  Perform manual testing to verify:
  1. Launch app and confirm Swift Fox logo appears in app bar with correct colors per "Swift Fox Logo Renders in App Bar" spec
  2. Navigate through chat and verify all text uses Merriweather (headers) and Inter (body) fonts per "Custom Typography System" spec
  3. Request account overview and verify horizontal scroll of gradient cards per "Account Overview Component Layout" spec
  4. Tap an account card and verify message "Show transactions for [account name]" appears and agent responds per "AccountCard Tap Triggers Agent Query" spec
  5. Verify transaction table renders with correct layout, colors, and scrolls if >400px height per "Transaction List" spec scenarios
  6. Test on narrow screen (320px width) and verify layouts don't overflow per edge case requirements
  7. Verify smooth scrolling performance (60fps) on both horizontal account cards and vertical transaction table per performance requirements
  8. Check color consistency across all widgets: green (#006B3D) in app bar/cards, coral (#FF6B6B) in accents per "Modern Theme Color Palette" spec
  9. Verify message bubbles have subtle backgrounds and 16px radius per "ChatScreen Message Bubble Styling" spec
  10. Test with airplane mode to verify Google Fonts fallback to Georgia/system sans-serif per edge case requirements

## Phase 10: Documentation & Cleanup

- [ ] **10.1** Update code comments and documentation
  Add inline code comments to `BankTheme` explaining design token usage, comments in `AccountCard` and `TransactionList` explaining layout choices, and update any existing documentation to reference the new theme system and interaction patterns.

- [ ] **10.2** Verify no regressions in existing functionality
  Run full test suite and manually test all existing GenUI catalog surfaces (CreditCardSummary, SavingsSummary, MortgageDetail) to ensure they render correctly with new theme and no functional regressions per success criteria requirement "No Regressions: Existing GenUI functionality remains intact".
