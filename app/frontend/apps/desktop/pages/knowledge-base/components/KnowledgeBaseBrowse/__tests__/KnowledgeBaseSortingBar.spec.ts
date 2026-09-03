// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { EnumKnowledgeBaseSortingMode } from '#shared/graphql/types.ts'

import KnowledgeBaseSortingBar from '../KnowledgeBaseSortingBar.vue'

import type { KnowledgeBaseSortingMode } from '../../../types.ts'

const { Manual, Alphabetical, LastUpdate } = EnumKnowledgeBaseSortingMode

const renderSortingBar = (
  props: { modelValue?: KnowledgeBaseSortingMode; dirty?: boolean; saving?: boolean } = {},
) =>
  renderComponent(KnowledgeBaseSortingBar, {
    props: {
      modelValue: Manual,
      ...props,
    },
  })

describe('KnowledgeBaseSortingBar', () => {
  // Asserted as an order rather than as three separate lookups: the manual mode belongs between
  //   the two automatic ones, and the legacy interface offers the same three in the same order
  //   (spec/system/knowledge_base/sorting_spec.rb), so neither side can drift unnoticed.
  it('offers all three sorting modes, the manual one between the automatic ones', () => {
    const view = renderSortingBar()

    expect(view.getAllByRole('tab').map((tab) => tab.getAttribute('aria-label'))).toEqual([
      'Sort alphabetically',
      'Sort by drag & drop',
      'Sort by latest updates',
    ])
  })

  it('marks the mode the browsed node is stored with', () => {
    const view = renderSortingBar({ modelValue: LastUpdate })

    expect(view.getByRole('tab', { name: 'Sort by latest updates' })).toHaveAttribute(
      'aria-selected',
      'true',
    )
    expect(view.getByRole('tab', { name: 'Sort by drag & drop' })).toHaveAttribute(
      'aria-selected',
      'false',
    )
  })

  it('reports the picked mode', async () => {
    const view = renderSortingBar()

    await view.events.click(view.getByRole('tab', { name: 'Sort alphabetically' }))

    expect(view.emitted()['update:modelValue']).toEqual([[Alphabetical]])
  })

  // Nothing to save is not an error to report - the button simply has nothing to do.
  it('cannot be saved while nothing was changed', () => {
    const view = renderSortingBar()

    expect(view.getByRole('button', { name: 'Save' })).toBeDisabled()
    expect(view.getByRole('button', { name: 'Cancel' })).toBeEnabled()
  })

  it('saves once something was changed', async () => {
    const view = renderSortingBar({ dirty: true })

    await view.events.click(view.getByRole('button', { name: 'Save' }))

    expect(view.emitted().save).toHaveLength(1)
  })

  // Both are locked while the mutations are in flight, so a second click cannot send the order
  //   twice or drop it mid-save.
  it('locks both actions while saving', () => {
    const view = renderSortingBar({ dirty: true, saving: true })

    expect(view.getByRole('button', { name: 'Save' })).toBeDisabled()
    expect(view.getByRole('button', { name: 'Cancel' })).toBeDisabled()
  })

  it('cancels', async () => {
    const view = renderSortingBar({ dirty: true })

    await view.events.click(view.getByRole('button', { name: 'Cancel' }))

    expect(view.emitted().cancel).toHaveLength(1)
  })
})
