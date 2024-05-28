// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { vi } from 'vitest'

import { i18n } from '#shared/i18n/index.ts'

export const mockLocale = (sourceString: string, targetString: string) => {
  return vi.spyOn(i18n, 't').mockImplementation((translation) => {
    if (sourceString === translation) return targetString
    return translation || ''
  })
}
