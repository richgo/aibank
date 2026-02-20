# AIBank UI Redesign Specification Delta

## ADDED Requirements

### Requirement: Swift Fox Brand Logo

The system SHALL display a Swift Fox logo widget as a brand identity element in the application.

#### Scenario: Swift Fox Logo Renders in App Bar

- GIVEN the app is launched
- WHEN the main ChatScreen renders
- THEN a Swift Fox logo widget appears in the app bar
- AND the logo uses forest green (`#006B3D`) for the body
- AND the logo uses coral (`#FF6B6B`) for ear tips, tail tip, and eye highlights
- AND the logo is rendered as a geometric, minimalist design with rounded edges

#### Scenario: Swift Fox Logo Widget Component

- GIVEN a `BrandLogo` widget is instantiated
- WHEN the widget is rendered
- THEN it displays a Swift Fox illustration
- AND the illustration is implemented using CustomPaint or SVG
- AND the widget has configurable size parameter
- AND the default size is approximately 40×40 logical pixels

### Requirement: Modern Theme Color Palette

The system SHALL use a new color palette that blends Lloyds heritage green with Monzo coral accents.

#### Scenario: Primary Green Applied to App Elements

- GIVEN the app renders any screen
- WHEN primary color is referenced by components
- THEN the color `#006B3D` (forest green) is used
- AND this color appears in the app bar, primary buttons, and card gradients

#### Scenario: Accent Coral Applied to CTAs

- GIVEN the app renders interactive elements
- WHEN accent color is referenced
- THEN the color `#FF6B6B` (coral) is used
- AND this color appears in call-to-action buttons, progress bars, and positive accents

#### Scenario: Text and Background Colors

- GIVEN any text content is rendered
- WHEN the text color is applied
- THEN primary text uses `#1A1A1A` (near-black)
- AND screen backgrounds use `#F5F5F5` (light gray)
- AND card surfaces use `#FFFFFF` (pure white)

#### Scenario: Semantic Colors for Financial Data

- GIVEN financial amounts are displayed
- WHEN the amount is positive or a credit
- THEN the text color is `#1B8A3A` (success green)
- AND when the amount is negative or a debit
- THEN the text color is `#D32F2F` (error red)

### Requirement: Custom Typography System

The system SHALL use custom typography loaded via the google_fonts package for brand consistency.

#### Scenario: Header Typography Using Merriweather

- GIVEN any header text is rendered (account names, section titles)
- WHEN the header text style is applied
- THEN the font family is Merriweather (serif)
- AND if Merriweather is unavailable, Georgia is used as fallback
- AND font weights are medium to bold for prominence

#### Scenario: Body Typography Using Inter

- GIVEN any body text is rendered (descriptions, chat text)
- WHEN the body text style is applied
- THEN the font family is Inter (sans-serif)
- AND if Inter is unavailable, system sans-serif (SF Pro/Roboto) is used as fallback
- AND font weights are regular for readability

#### Scenario: Currency Typography Using Monospace

- GIVEN currency amounts are displayed
- WHEN the amount text style is applied
- THEN the font family is JetBrains Mono or system monospace
- AND tabular figures are used for alignment
- AND numbers are scannable and clearly separated

### Requirement: Design Token System

The system SHALL define consistent design tokens for spacing, border radius, and elevation in the theme.

#### Scenario: Border Radius Tokens

- GIVEN any rounded component is rendered
- WHEN border radius is applied to account cards
- THEN the radius is 24 pixels
- AND when applied to panels, the radius is 16 pixels
- AND when applied to buttons, the radius is 8 pixels

#### Scenario: Elevation Tokens

- GIVEN any component with shadow/elevation is rendered
- WHEN the component is in resting state
- THEN elevation is 2dp
- AND when the component is hovered or tapped, elevation is 4dp
- AND when the component is a modal, elevation is 8dp

#### Scenario: Spacing Tokens

- GIVEN any component requires padding
- WHEN standard padding is applied, the value is 16 pixels
- AND when compact padding is applied, the value is 12 pixels
- AND when spacious padding is applied, the value is 24 pixels

### Requirement: Horizontal Thin Account Cards

The system SHALL render AccountCard components as thin horizontal gradient cards optimized for horizontal scrolling.

#### Scenario: Account Card Dimensions and Layout

- GIVEN an AccountCard is rendered
- WHEN the component is displayed
- THEN the card width is approximately 180 logical pixels
- AND the card height is approximately 120 logical pixels
- AND the card displays account type icon (top-left)
- AND the card displays account name below the icon
- AND the card displays balance in large bold text (center)
- AND the card displays account type label at the bottom

#### Scenario: Account Card Gradient Background

- GIVEN an AccountCard is rendered
- WHEN the card background is painted
- THEN a gradient from `#006B3D` (forest green) to `#00A86B` (lighter green) is applied
- AND the gradient flows from top-left to bottom-right
- AND the card has 24 pixel border radius on all corners

#### Scenario: Account Card Tap Ripple Effect

- GIVEN an AccountCard is rendered with InkWell
- WHEN the user taps the card
- THEN a ripple effect respects the 24 pixel border radius
- AND the ripple color is white with 30% opacity
- AND the tap is visually responsive

#### Scenario: Account Card Sends Agent Message on Tap

- GIVEN an AccountCard for "Current Account" is rendered
- WHEN the user taps the card
- THEN an agent message "Show transactions for Current Account" is sent
- AND the message appears in the chat conversation
- AND the agent processes the request and responds with transaction data

#### Scenario: Multiple Account Cards in Horizontal Scroll

- GIVEN multiple AccountCard components are rendered
- WHEN the cards are displayed in AccountOverview
- THEN the cards are laid out horizontally in a ListView
- AND the scrollDirection is Axis.horizontal
- AND the container height is approximately 140 logical pixels
- AND horizontal padding separates each card by 12 pixels

### Requirement: Compact Inline Transaction Table

The system SHALL render TransactionList as a compact table optimized for inline display within chat conversation.

#### Scenario: Transaction Table Layout

- GIVEN a TransactionList is rendered
- WHEN the table is displayed
- THEN the table has three columns: Date, Description, Amount
- AND the Date column occupies 25% of the table width
- AND the Description column occupies 50% of the table width
- AND the Amount column occupies 25% of the table width
- AND the table has a header row with column labels

#### Scenario: Transaction Table Header Styling

- GIVEN a TransactionList table is rendered
- WHEN the header row is displayed
- THEN the background color is primary green (`#006B3D`)
- AND the text color is white
- AND the font weight is bold
- AND the padding is 8 pixels vertical, 12 pixels horizontal

#### Scenario: Transaction Row Alternating Backgrounds

- GIVEN a TransactionList with multiple rows is rendered
- WHEN the rows are displayed
- THEN even rows have white (`#FFFFFF`) background
- AND odd rows have light gray (`#F9F9F9`) background
- AND the alternating pattern improves scannability

#### Scenario: Transaction Amount Formatting and Color

- GIVEN a transaction row is rendered
- WHEN the amount is displayed
- THEN the amount is right-aligned in the Amount column
- AND the font is monospace (JetBrains Mono or system monospace)
- AND positive amounts (credits) are colored success green (`#1B8A3A`)
- AND negative amounts (debits) are colored error red (`#D32F2F`)
- AND the currency symbol is included

#### Scenario: Transaction Table Scroll Container

- GIVEN a TransactionList with many transactions is rendered
- WHEN the table exceeds 400 pixels in height
- THEN the table is wrapped in a ConstrainedBox with maxHeight 400 pixels
- AND the table is wrapped in a SingleChildScrollView
- AND the user can scroll vertically to view all transactions
- AND the header row remains visible during scroll (if using sticky header implementation)

#### Scenario: Transaction Table Inline in Chat

- GIVEN the agent responds with a TransactionList surface
- WHEN the surface renders in the chat conversation
- THEN the table appears inline between chat messages
- AND the table width respects the chat message container width
- AND the table has 16 pixel border radius clipping
- AND the table is visually integrated with the conversation flow

### Requirement: Themed Catalog Widget Updates

The system SHALL apply new theme styling to all existing catalog widgets for visual consistency.

#### Scenario: CreditCardSummary with New Theme

- GIVEN a CreditCardSummary is rendered
- WHEN the component is displayed
- THEN the card has a gradient background using green shades
- AND the card has 24 pixel border radius
- AND the credit utilization progress bar uses coral (`#FF6B6B`) color
- AND card elevation is 2dp at rest
- AND text uses Inter font family for body text
- AND currency amounts use monospace font

#### Scenario: SavingsSummary with New Theme

- GIVEN a SavingsSummary is rendered
- WHEN the component is displayed
- THEN the card has a lighter green tint background
- AND the card has 16 pixel border radius
- AND the interest rate is displayed in a coral pill badge
- AND the pill badge has coral background with white text
- AND the pill badge has 16 pixel border radius
- AND currency amounts use monospace font

#### Scenario: MortgageDetail with New Theme

- GIVEN a MortgageDetail is rendered
- WHEN the component is displayed
- THEN the data is presented in a structured table layout
- AND payment breakdown rows have alternating backgrounds
- AND the table has header styling matching theme
- AND currency amounts use monospace font
- AND the card container has 16 pixel border radius

## MODIFIED Requirements

### Requirement: AccountOverview Component Layout

The system SHALL display AccountCard components in a horizontal scrollable list instead of a vertical list.

(Previously: "each account is rendered as an `AccountCard` in a vertical list")

#### Scenario: Horizontal Account Card Scroll

- GIVEN an AccountOverview with multiple accounts is rendered
- WHEN the component is displayed
- THEN AccountCard components are arranged horizontally
- AND the container uses ListView with scrollDirection Axis.horizontal
- AND the container height is constrained to approximately 140 logical pixels
- AND horizontal scroll indicators guide user discovery
- AND the total net worth figure is still displayed at the top

### Requirement: AccountCard Component Interaction

The system SHALL send an agent message when an AccountCard is tapped, rather than only displaying static information.

(Previously: AccountCard was a display-only component with no tap interaction specified)

#### Scenario: AccountCard Tap Triggers Agent Query

- GIVEN an AccountCard for "Savings Account" is displayed
- WHEN the user taps the card
- THEN the message "Show transactions for Savings Account" is sent to the agent
- AND the message appears in the chat input as if the user typed it
- AND the conversation processes the message through GenUI conversation flow
- AND the agent responds with a TransactionList surface for that account

### Requirement: ChatScreen Layout Container Adjustments

The system SHALL support horizontal scrolling account card lists and constrained transaction table heights within the chat conversation.

(Previously: ChatScreen only supported vertical scrolling for GenUI surfaces)

#### Scenario: ChatScreen Renders Horizontal Account Card Container

- GIVEN the agent sends an AccountOverview surface
- WHEN the surface is rendered in ChatScreen
- THEN the AccountCard horizontal list is wrapped in a SizedBox with height 140 pixels
- AND the horizontal scroll behavior is preserved within the chat flow
- AND the container does not break the vertical chat scroll

#### Scenario: ChatScreen Renders Constrained Transaction Table

- GIVEN the agent sends a TransactionList surface
- WHEN the surface is rendered in ChatScreen
- THEN the table is wrapped in a ConstrainedBox with maxHeight 400 pixels
- AND internal vertical scrolling is enabled if content exceeds 400 pixels
- AND the table is clipped with ClipRRect using 16 pixel border radius
- AND the table integrates visually with chat message bubbles

#### Scenario: ChatScreen Message Bubble Styling

- GIVEN chat messages are displayed
- WHEN user messages are rendered
- THEN user message bubbles have a subtle background tint
- AND AI/agent messages have a different background tint
- AND both message types have 16 pixel border radius
- AND the distinction is clear but not harsh

## REMOVED Requirements

_(No requirements are being removed in this change. All existing functionality is preserved and enhanced.)_

## Design Constraints

### Visual Design Rules

1. **Color Ratio**: 70% green (primary), 20% white/gray (neutral), 10% coral (accent)
2. **Typography Hierarchy**: Serif for headers (heritage), sans-serif for body (clarity), monospace for numbers (precision)
3. **Spacing Consistency**: All spacing values must use theme tokens (8px, 12px, 16px, 24px)
4. **Border Radius Consistency**: 24px for cards, 16px for panels, 8px for small components
5. **Elevation Consistency**: 2dp resting, 4dp interactive, 8dp modal

### Implementation Constraints

1. **Theme as Source of Truth**: All design tokens defined in BankTheme, no inline styling
2. **Google Fonts Integration**: Merriweather and Inter loaded via google_fonts package with fallbacks
3. **GenUI Compatibility**: All catalog components must maintain A2UI data model compatibility
4. **Mobile-First**: Designs optimized for mobile viewport (375px–428px width)
5. **Scrolling Behavior**: Horizontal scroll for account cards, vertical scroll for transaction tables, both integrated into chat vertical scroll

### Accessibility Requirements

1. **Color Contrast**: All text must meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text)
2. **Touch Targets**: All interactive elements minimum 48×48 logical pixels
3. **Semantic Labels**: All interactive components have accessible labels for screen readers
4. **Focus Indicators**: Keyboard/assistive navigation shows clear focus states

### Performance Requirements

1. **Smooth Scrolling**: Horizontal and vertical scrolling must maintain 60 fps
2. **Font Loading**: Google Fonts cached locally, fallback fonts used during load
3. **Gradient Rendering**: Linear gradients optimized for performance, no complex shaders
4. **Logo Rendering**: Brand logo optimized for fast render, no expensive custom paint operations

## Integration Points

### GenUI Framework

- AccountCard tap must integrate with GenUI conversation sendRequest() method
- TransactionList must render from A2UI data model without breaking surface lifecycle
- All catalog components must serialize/deserialize via A2uiMessageProcessor
- Surface dimensions must work within GenUiSurface container constraints

### Agent Backend

- Account card tap message format: "Show transactions for [accountName]"
- Agent must handle transaction query messages and respond with TransactionList surfaces
- No backend changes required, agent uses existing MCP tool calls
- Agent responds with standard A2UI surface messages

### Dependencies

- google_fonts package added to pubspec.yaml for Inter and Merriweather fonts
- No other new dependencies required
- All UI components use flutter/material.dart built-in widgets
- Optional flutter_svg if logo is SVG-based (otherwise use CustomPaint)

## Testing Scenarios

### Visual Regression Testing

#### Scenario: Theme Color Palette Verification

- GIVEN all screens are rendered in test environment
- WHEN a visual snapshot is captured
- THEN primary green `#006B3D` appears in app bar and primary buttons
- AND coral `#FF6B6B` appears in accent elements
- AND no colors from old theme remain

#### Scenario: Typography Consistency

- GIVEN all text elements are rendered
- WHEN font families are inspected
- THEN headers use Merriweather or Georgia
- AND body text uses Inter or system sans-serif
- AND currency amounts use monospace font
- AND all text is legible and properly sized

### Interaction Testing

#### Scenario: Account Card Tap Message Flow

- GIVEN an AccountCard is displayed for "Current Account"
- WHEN the card is tapped
- THEN the message "Show transactions for Current Account" appears in chat
- AND the agent receives the message via GenUI conversation
- AND the agent responds with a TransactionList surface
- AND the transaction table renders inline in the chat

#### Scenario: Horizontal Scroll Discovery

- GIVEN five AccountCard components are rendered horizontally
- WHEN the screen width shows only three cards
- THEN horizontal scroll indicators are visible
- AND the user can swipe to reveal additional cards
- AND the scroll is smooth and responsive

#### Scenario: Transaction Table Vertical Scroll

- GIVEN a TransactionList with 50 transactions is rendered
- WHEN the table exceeds 400 pixel max height
- THEN a vertical scrollbar or scroll indicator appears
- AND the user can scroll through all transactions
- AND the header row remains accessible

### Edge Cases

#### Scenario: Very Long Account Name

- GIVEN an AccountCard with account name exceeding 20 characters
- WHEN the card is rendered at 180 pixels width
- THEN the name truncates with ellipsis
- AND the full name is accessible via tooltip or tap
- AND the card layout does not break

#### Scenario: Narrow Mobile Screen

- GIVEN the app is rendered on a device with 320 pixel width
- WHEN the TransactionList table is displayed
- THEN the Description column truncates text
- AND the Date and Amount columns remain fully visible
- AND the table remains scannable and usable

#### Scenario: Missing Google Fonts

- GIVEN the google_fonts package fails to load fonts
- WHEN the app renders text
- THEN Merriweather falls back to Georgia
- AND Inter falls back to system sans-serif
- AND the app remains visually acceptable

#### Scenario: Accessibility – Screen Reader on AccountCard

- GIVEN a screen reader is active
- WHEN focus moves to an AccountCard
- THEN the screen reader announces: "Current Account, balance £1,234.56, tap to view transactions"
- AND the tap action is clearly described

#### Scenario: Accessibility – High Contrast Mode

- GIVEN the device is in high contrast mode
- WHEN the app renders
- THEN text contrast ratios meet WCAG AA standards
- AND coral/green color combinations are adjusted if necessary
- AND all content remains readable

## Success Criteria

The UI redesign is complete and successful when:

1. **Brand Identity**: Swift Fox logo appears in app bar with correct colors
2. **Theme Applied**: All components use new color palette, typography, and spacing tokens
3. **Account Cards**: Render as 180×120px horizontal gradient cards with tap interaction
4. **Transaction Tables**: Render as compact inline tables with 3-column layout and scrolling
5. **Interaction Flow**: Tapping account card sends agent message and displays transactions
6. **Visual Consistency**: All catalog widgets use new theme styling
7. **Performance**: Smooth scrolling and no visual lag
8. **Accessibility**: WCAG AA compliance and screen reader support
9. **Test Coverage**: All scenarios pass automated and manual testing
10. **No Regressions**: Existing GenUI functionality remains intact
