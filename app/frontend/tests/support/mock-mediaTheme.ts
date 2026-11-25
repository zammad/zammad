// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { EnumAppearanceTheme } from '#shared/graphql/types.ts'

const addEventListener = vi.fn()
const removeEventListener = vi.fn()

export const mockMediaTheme = (theme: EnumAppearanceTheme) => {
  window.matchMedia = (rule) =>
    ({
      matches: rule === `(prefers-color-scheme: ${theme})`,
      addEventListener,
      removeEventListener,
    }) as any
}
