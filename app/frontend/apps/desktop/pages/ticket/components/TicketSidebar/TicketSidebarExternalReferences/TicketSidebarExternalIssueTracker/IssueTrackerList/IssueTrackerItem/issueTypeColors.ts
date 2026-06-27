// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export interface IssueTypeColorSet {
  bg: string
  text: string
}

// All background colors are chosen so white text always meets WCAG AA (≥ 4.5:1).
// Light: GitHub's standard issue-type palette (dark colors).
// Dark: slightly more vibrant variants that remain dark enough for white text.
const ISSUE_TYPE_BG_MAP: Record<string, { light: string; dark: string }> = {
  BLUE: { light: '#0075CA', dark: '#1A6FE0' },
  GRAY: { light: '#57606A', dark: '#6B7782' },
  GREEN: { light: '#1A7F37', dark: '#238636' },
  ORANGE: { light: '#BC4C00', dark: '#B45309' },
  PINK: { light: '#BF4B8A', dark: '#BF4B8A' },
  PURPLE: { light: '#8250DF', dark: '#8250DF' },
  RED: { light: '#CF222E', dark: '#DA3633' },
  TEAL: { light: '#1B7C83', dark: '#0E7490' },
  YELLOW: { light: '#9A6700', dark: '#8A6500' },
}

export const resolveIssueTypeColors = (
  colorKey: string | null | undefined,
  isDark: boolean,
): IssueTypeColorSet => {
  const entry = ISSUE_TYPE_BG_MAP[colorKey ?? ''] ?? ISSUE_TYPE_BG_MAP.GRAY
  return { bg: isDark ? entry.dark : entry.light, text: '#FFFFFF' }
}
