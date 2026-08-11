// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Build-time custom skin: eagerly bundle (for their side effects) every .css file
// dropped in this folder. main.ts imports this right after the app's own styles,
// so the rules stay unlayered and override Tailwind's @layer utilities without
// !important. See ./README.md.
import.meta.glob('./**/*.css', { eager: true })
