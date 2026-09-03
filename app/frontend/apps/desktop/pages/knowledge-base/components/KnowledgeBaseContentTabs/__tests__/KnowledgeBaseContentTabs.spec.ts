// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { KnowledgeBaseSortingScope } from '#desktop/pages/knowledge-base/types.ts'

import KnowledgeBaseContentTabs, { type Props } from '../KnowledgeBaseContentTabs.vue'

const renderContentTabs = (
  props: Partial<Props> & { modelValue?: KnowledgeBaseSortingScope } = {},
) =>
  renderComponent(KnowledgeBaseContentTabs, {
    props: {
      categoryCount: 3,
      answerCount: 3,
      ...props,
    },
    // Through the model rather than as a plain prop: the group echoes its resolved selection back
    //   on mount, and a prop the parent never updates would leave the two out of step.
    vModel: { modelValue: props.modelValue ?? 'categories' },
  })

describe('KnowledgeBaseContentTabs', () => {
  it('offers both kinds of content with their counts', () => {
    const view = renderContentTabs()

    expect(view.getByRole('tab', { name: 'Categories' })).toHaveTextContent('3')
    expect(view.getByRole('tab', { name: 'Answers' })).toHaveTextContent('3')
  })

  // The entry is what tells the user that content of that kind belongs here, so an empty one is
  //   rendered rather than dropped - and its badge says as much.
  it('keeps an entry that holds nothing', () => {
    const view = renderContentTabs({ answerCount: 0 })

    expect(view.getByRole('tab', { name: 'Answers' })).toHaveTextContent('0')
  })

  it('marks the picked kind', () => {
    const view = renderContentTabs({ modelValue: 'answers' })

    expect(view.getByRole('tab', { name: 'Answers' })).toHaveAttribute('aria-selected', 'true')
    expect(view.getByRole('tab', { name: 'Categories' })).toHaveAttribute('aria-selected', 'false')
  })

  it('reports the picked kind', async () => {
    const view = renderContentTabs()

    await view.events.click(view.getByRole('tab', { name: 'Answers' }))

    expect(view.emitted()['update:modelValue']).toEqual([['answers']])
  })

  it('follows the counts as they change', async () => {
    const view = renderContentTabs()

    await view.rerender({ categoryCount: 5, answerCount: 0 })

    expect(view.getByRole('tab', { name: 'Categories' })).toHaveTextContent('5')
    expect(view.getByRole('tab', { name: 'Answers' })).toHaveTextContent('0')
  })

  // For a listing that leads with the answers, so the entries read in the same order as the
  //   content below them.
  it('leads with the answers when asked to reverse the order', () => {
    const view = renderContentTabs({ reverseOrder: true })

    const tabs = view.getAllByRole('tab')

    expect(tabs[0]).toHaveAccessibleName('Answers')
    expect(tabs[1]).toHaveAccessibleName('Categories')
  })
})
