// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TicketArticleTranslation } from '#shared/entities/ticket-article/stores/types.ts'

// A tab's translation state as the bubbles see it: nothing translated, nothing stored.
export const createArticleTranslationMock = (
  overrides: Partial<TicketArticleTranslation> = {},
): TicketArticleTranslation => ({
  translationFor: vi.fn(() => undefined),
  isTranslationActive: vi.fn(() => false),
  hasDirectTranslationAction: vi.fn(() => false),
  showTranslation: vi.fn(() => Promise.resolve()),
  showOriginal: vi.fn(),
  ...overrides,
})
