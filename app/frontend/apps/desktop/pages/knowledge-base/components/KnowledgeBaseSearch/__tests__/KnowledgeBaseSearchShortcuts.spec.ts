// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent, type ExtendedRenderResult } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import type { ConfigList } from '#shared/types/store.ts'

import KnowledgeBaseSearchShortcuts from '../KnowledgeBaseSearchShortcuts.vue'

// The mocked config is shared by the whole file, so both settings the menu reads are always
//   set: a test states its own preconditions instead of inheriting the previous one's.
const renderShortcuts = (config: Partial<ConfigList> = {}) => {
  mockApplicationConfig({
    es_enabled: true,
    ai_assistance_kb_answer_from_ticket_generation: false,
    ...config,
  })

  return renderComponent(KnowledgeBaseSearchShortcuts, { router: true })
}

const openMenu = (view: ExtendedRenderResult) =>
  view.events.click(view.getByLabelText('Suggested searches'))

const shortcutLabels = (view: ExtendedRenderResult) =>
  view.getAllByRole('menuitem').map((item) => item.textContent?.trim())

describe('KnowledgeBaseSearchShortcuts', () => {
  it('suggests searches in the right order', async () => {
    const view = renderShortcuts()

    await openMenu(view)

    expect(shortcutLabels(view)).toEqual([
      'User documentation',
      'Created within last 14 days',
      'Updated within last 3 days',
      'Drafts only',
    ])
  })

  it('suggests the AI generated tag third when answers can be AI generated', async () => {
    const view = renderShortcuts({ ai_assistance_kb_answer_from_ticket_generation: true })

    await openMenu(view)

    expect(shortcutLabels(view)).toEqual([
      'User documentation',
      'Created within last 14 days',
      'Updated within last 3 days',
      'Tagged ai-generated',
      'Drafts only',
    ])
  })

  it.each([
    ['Created within last 14 days', 'created_at:>now-14d'],
    ['Updated within last 3 days', 'edited_at:>now-3d'],
    ['Tagged ai-generated', 'tags:ai-generated'],
    ['Drafts only', 'publication_state:draft'],
  ])('searches for %s', async (label, query) => {
    const view = renderShortcuts({ ai_assistance_kb_answer_from_ticket_generation: true })

    await openMenu(view)
    await view.events.click(view.getByText(label))

    expect(view.emitted('search')).toEqual([[query]])
  })

  it('links to the documentation in a new tab', async () => {
    const view = renderShortcuts()

    await openMenu(view)

    const link = view.getByRole('link', { name: /User documentation/ })

    expect(link).toHaveAttribute(
      'href',
      'https://next.zammad.org/documentation/use/guides/knowledge-base.html#Search',
    )
    expect(link).toHaveAttribute('target', '_blank')
  })

  it.each([false, true])(
    'suggests only the documentation without a search index, with AI generation %s',
    async (aiGenerationEnabled) => {
      const view = renderShortcuts({
        es_enabled: false,
        ai_assistance_kb_answer_from_ticket_generation: aiGenerationEnabled,
      })

      await openMenu(view)

      expect(shortcutLabels(view)).toEqual(['User documentation'])
    },
  )
})
