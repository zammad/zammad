// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { EnumAppearanceTheme } from '#shared/graphql/types.ts'

export const addEventListener = vi.fn()

export const mockMediaTheme = (theme: EnumAppearanceTheme) => {
  window.matchMedia = (rule) =>
    ({
      matches: rule === '(prefers-color-scheme: dark)' && theme === 'dark',
      addEventListener,
    }) as any

  window.matchMedia = (rule) =>
    ({
      matches: rule === '(prefers-color-scheme: light)' && theme === 'light',
      addEventListener,
    }) as any
}
