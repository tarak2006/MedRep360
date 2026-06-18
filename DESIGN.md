---
version: alpha
name: MedRep360-AI-Native-Design
description: "A premium, high-precision visual spec for an AI-native medical representative workspace. Obsidian canvas (#030408), clinical emerald accent (#0df295) for regulatory and brand compliance, and cyber cyan (#00e5ff) for data streams. High text contrast using pure white/gray and technical monospace typography (Fira Code) for status logs and agent outputs. Components sit on elevated panels with hairline boundaries, resisting heavy shadow and rounded shapes."

colors:
  primary: "#0df295" # Electric Clinical Emerald
  secondary: "#00e5ff" # Cyber Cyan
  primary-hover: "#43fbb1"
  primary-glow: "rgba(13, 242, 149, 0.15)"
  canvas: "#030408" # Deep obsidian backdrop
  surface-1: "#0b0c10" # Standard elevated charcoal
  surface-2: "#12141c" # Surface level 2
  surface-3: "#1a1c27" # Elevated widgets
  hairline: "rgba(255, 255, 255, 0.08)" # Precision grid line
  hairline-strong: "rgba(13, 242, 149, 0.25)" # Accent grid line
  text-main: "#ffffff" # High-contrast reading
  text-muted: "#98a2b3" # Explanatory type
  text-subtle: "#667085" # Secondary identifiers

typography:
  display-lg:
    fontFamily: Inter, sans-serif
    fontSize: 54px
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: -1.5px
  display-md:
    fontFamily: Inter, sans-serif
    fontSize: 38px
    fontWeight: 700
    lineHeight: 1.20
    letterSpacing: -1.0px
  headline:
    fontFamily: Inter, sans-serif
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.30
    letterSpacing: -0.5px
  body:
    fontFamily: Inter, sans-serif
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.60
    letterSpacing: -0.1px
  mono-label:
    fontFamily: Fira Code, monospace
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.40
    letterSpacing: 0.5px
  mono-code:
    fontFamily: Fira Code, monospace
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.50
    letterSpacing: 0

rounded:
  xs: 2px
  sm: 4px
  md: 6px
  lg: 8px
  pill: 9999px

components:
  agent-console:
    backgroundColor: "{colors.surface-1}"
    border: "1px solid {colors.hairline}"
    rounded: "{rounded.lg}"
  status-chip:
    backgroundColor: "rgba(13, 242, 149, 0.06)"
    border: "1px solid rgba(13, 242, 149, 0.2)"
    textColor: "{colors.primary}"
    typography: "{typography.mono-label}"
    rounded: "{rounded.xs}"
  card-precision:
    backgroundColor: "{colors.surface-1}"
    border: "1px solid {colors.hairline}"
    rounded: "{rounded.lg}"
    padding: 24px
  cta-button:
    backgroundColor: "{colors.primary}"
    textColor: "#000000"
    typography: "{typography.mono-label}"
    rounded: "{rounded.sm}"
---
