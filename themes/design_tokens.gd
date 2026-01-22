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
}
