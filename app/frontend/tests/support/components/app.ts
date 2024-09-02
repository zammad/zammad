// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AppName } from '#shared/types/app.ts'

// internal Vitest variable, ideally should check expect.getState().testPath, but it's not populated in 0.34.6 (a bug)
const { filepath } = (globalThis as any).__vitest_worker__ as any

const isDesktop = filepath.includes('apps/desktop')

export const getTestAppName = (): AppName => {
  return isDesktop ? 'desktop' : 'mobile'
}
