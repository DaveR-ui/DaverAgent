---
name: SafeGuard
version: 1.0.0
author: Antigravity Agent
description: >
  Design identity for Matafuegos Necochea. 
  Focuses on trust, reliability, and precision in safety services.
  Optimized for high-contrast visibility and architectural clarity.
last_updated: 2026-05-09
status: active
tags: [design, tokens, identity]

tokens:
  colors:
    primary:
      base: "#dc2626" # Red-600 (Safety/Urgency)
      dark: "#991b1b"
      light: "#fef2f2"
    secondary:
      base: "#0f172a" # Slate-900 (Professionalism/Trust)
      dark: "#020617"
      light: "#f8fafc"
    accent:
      base: "#f59e0b" # Amber-500 (Alert/Urgency)
    neutral:
      50: "#f8fafc"
      100: "#f1f5f9"
      200: "#e2e8f0"
      300: "#cbd5e1"
      400: "#94a3b8"
      500: "#64748b"
      600: "#475569"
      700: "#334155"
      800: "#1e293b"
      900: "#0f172a"
    success: "#10b981"
    warning: "#f59e0b"
    error: "#ef4444"

  typography:
    fontFamily:
      sans: "'Inter', system-ui, -apple-system, sans-serif"
      display: "'Outfit', sans-serif"
    weights:
      normal: 400
      medium: 500
      bold: 700
    scale:
      display-lg: { size: "3.5rem", weight: 700, leading: "1.1" }
      headline-md: { size: "2rem", weight: 600, leading: "1.2" }
      body-base: { size: "1rem", weight: 400, leading: "1.5" }
      label-sm: { size: "0.875rem", weight: 500, leading: "1.4" }

  spacing:
    xs: "0.25rem"
    sm: "0.5rem"
    md: "1rem"
    lg: "1.5rem"
    xl: "2rem"
    "2xl": "3rem"

  rounded:
    sm: "0.25rem"
    md: "0.5rem"
    lg: "1rem"
    full: "9999px"

  shadows:
    sm: "0 1px 2px 0 rgb(0 0 0 / 0.05)"
    md: "0 4px 6px -1px rgb(0 0 0 / 0.1)"
    lg: "0 10px 15px -3px rgb(0 0 0 / 0.1)"
---

# 🛡️ SafeGuard Design System

## Identity & Philosophy
Matafuegos Necochea provides critical safety infrastructure. The design system must reflect **Trust**, **Reliability**, and **Precision**.

### Architectural Minimalism
Layouts should be structured and predictable. Information hierarchy is paramount—users need to find safety certifications and expiration dates instantly.

### Journalistic Gravitas
Using **Outfit** for headings provides a modern yet authoritative feel. High contrast between text and background ensures accessibility in all lighting conditions (critical for field work).

### Premium Solid Finish
Avoid excessive gradients or transparency. Use solid blocks of color and sharp borders to convey stability.

## Implementation Guidelines
- Use the `@theme` block in `src/styles.css` to map these tokens to Tailwind v4.
- All components must use these tokens exclusively. Ad-hoc hex codes are prohibited.
- Maintain a minimum contrast ratio of 4.5:1 for all text.
