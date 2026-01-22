extends Node
## Centralized design token system for consistent UI theming across False Witness.
##
## Access via DesignTokens singleton. Contains color palettes, spacing values,
## font sizes, animation timings, and border styles.
##
## Usage: DesignTokens.COLORS.text_primary, DesignTokens.SPACING.md, etc.

# --- Color Tokens ---

## Core color palette for all UI elements.
## Organized by purpose: backgrounds, text, accents, horror-specific, game-specific.
const COLORS: Dictionary = {
	# Background colors - dark horror aesthetic
	"bg_primary": Color(0.05, 0.05, 0.08),  # Near-black, matches default clear color
	"bg_secondary": Color(0.1, 0.1, 0.12),  # Slightly lighter for contrast
	"bg_surface": Color(0.15, 0.15, 0.18),  # Panel/card backgrounds
	"bg_overlay": Color(0.0, 0.0, 0.0, 0.8),  # Semi-transparent overlays

	# Text colors
	"text_primary": Color(0.9, 0.9, 0.9),  # Main text, high contrast
	"text_secondary": Color(0.7, 0.7, 0.7),  # Secondary/muted text
	"text_muted": Color(0.5, 0.5, 0.5),  # Disabled/placeholder text
	"text_danger": Color(1.0, 0.3, 0.3),  # Error/danger text

	# Accent colors
	"accent_primary": Color(0.3, 0.6, 0.9),  # Primary interactive elements
	"accent_secondary": Color(0.5, 0.3, 0.8),  # Secondary highlights (purple)
	"accent_warning": Color(1.0, 0.7, 0.3),  # Warnings, caution
	"accent_success": Color(0.3, 1.0, 0.3),  # Success, confirmation

	# Horror-specific colors
	"horror_blood": Color(0.8, 0.1, 0.1),  # Deep blood red
	"horror_ethereal": Color(0.3, 0.8, 0.9),  # Ghostly cyan/teal
	"horror_corruption": Color(0.6, 0.2, 0.6),  # Corrupted purple

	# Trust level colors (evidence reliability indicators)
	"trust_unfalsifiable": Color.GOLD,  # Cannot be fabricated - behavioral ground truth
	"trust_high": Color.GREEN,  # Equipment-verified, difficult to fake
	"trust_variable": Color.YELLOW,  # Requires cooperation, verify with second reading
	"trust_low": Color.ORANGE,  # Easy to misreport, cross-reference recommended
	"trust_sabotage": Color.RED,  # Cultist can directly contaminate

	# Evidence category colors (for icons/visual distinction)
	"evidence_equipment": Color.CORNFLOWER_BLUE,  # Equipment-derived readings
	"evidence_apparent": Color.LIGHT_GREEN,  # Readily apparent phenomena
	"evidence_triggered": Color.GOLD,  # Triggered test results
	"evidence_behavior": Color.INDIAN_RED,  # Behavior-based observations
}

## Player attribution colors for evidence collector indicators.
## Indexed by peer_id % 8 to cycle through colors.
const PLAYER_COLORS: Array[Color] = [
	Color.CYAN,
	Color.MAGENTA,
	Color.LIME,
	Color.YELLOW,
	Color.CORAL,
	Color.DEEP_SKY_BLUE,
	Color.HOT_PINK,
	Color.SPRING_GREEN,
]

# --- Spacing Tokens ---

## Consistent spacing values for margins, padding, and gaps.
## All values are integers representing pixels.
const SPACING: Dictionary = {
	"xs": 4,  # Extra small - tight spacing
	"sm": 8,  # Small - compact elements
	"md": 16,  # Medium - standard spacing (default)
	"lg": 24,  # Large - section separation
	"xl": 32,  # Extra large - major sections
	"xxl": 48,  # Double extra large - page margins
}

# --- Typography Tokens ---

## Font size values for consistent text hierarchy.
## All values are integers representing pixels.
const FONT_SIZES: Dictionary = {
	"xs": 12,  # Extra small - fine print, timestamps
	"sm": 14,  # Small - secondary text, captions
	"md": 16,  # Medium - body text (default)
	"lg": 20,  # Large - subheadings
	"xl": 24,  # Extra large - section headings
	"xxl": 32,  # Double extra large - page titles
	"display": 48,  # Display - hero text, win/loss announcements
}
