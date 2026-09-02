// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumKnowledgeBaseSchedulableVisibility } from '#shared/graphql/types.ts'

import KnowledgeBaseAnswerScheduledVisibilityItem from '../KnowledgeBaseAnswerScheduledVisibilityItem.vue'

const hour = 60 * 60 * 1000

// The extra hour keeps the date clear of the boundary the relative formatter floors at - exactly two
//   days from now comes out as "in 1 day" by the time the assertion runs.
const inDays = (days: number) => new Date(Date.now() + days * 24 * hour + hour).toISOString()

const renderItem = (
  visibility: EnumKnowledgeBaseSchedulableVisibility,
  slots?: Record<string, string>,
) =>
  renderComponent(KnowledgeBaseAnswerScheduledVisibilityItem, {
    props: { visibility, scheduledAt: inDays(2) },
    slots,
    store: true,
    router: true,
  })

describe('KnowledgeBaseAnswerScheduledVisibilityItem', () => {
  it('names the state and when it happens', () => {
    const view = renderItem(EnumKnowledgeBaseSchedulableVisibility.Internal)

    expect(view.getByText('Internal')).toBeInTheDocument()
    expect(view.getByText('in 2 days')).toBeInTheDocument()
  })

  // A list row wherever it is used, so both surfaces get the list semantics without repeating them.
  it('renders as a list item', () => {
    const view = renderItem(EnumKnowledgeBaseSchedulableVisibility.Internal)

    // By tag rather than by role: an `li` only carries the `listitem` role inside a list, and the
    //   list is the caller's - the sidebar section and the header popover each bring their own.
    expect(view.container.querySelector('li')).toBeInTheDocument()
  })

  // One clock for every state, rather than the state icons the answer list shows.
  it.each([
    EnumKnowledgeBaseSchedulableVisibility.Internal,
    EnumKnowledgeBaseSchedulableVisibility.Published,
    EnumKnowledgeBaseSchedulableVisibility.Archived,
  ])('carries a clock for a scheduled %s', (visibility) => {
    const view = renderItem(visibility)

    expect(view.container.querySelector('.icon-clock')).toBeInTheDocument()
  })

  // The state's own colour is what makes the rows scannable, as it does in the answer list.
  it.each([
    [EnumKnowledgeBaseSchedulableVisibility.Internal, 'Internal', 'text-blue-800!'],
    [EnumKnowledgeBaseSchedulableVisibility.Published, 'Published', 'text-green-400!'],
  ])('tints a scheduled %s', (visibility, label, tint) => {
    const view = renderItem(visibility)

    expect(view.getByText(label)).toHaveClass(tint)
  })

  // What the sidebar puts its remove button into, and the read-only popover leaves empty.
  it('renders what the caller appends to the row', () => {
    const view = renderItem(EnumKnowledgeBaseSchedulableVisibility.Internal, {
      default: '<button type="button">Remove</button>',
    })

    expect(view.getByRole('button', { name: 'Remove' })).toBeInTheDocument()
  })

  it('appends nothing of its own', () => {
    const view = renderItem(EnumKnowledgeBaseSchedulableVisibility.Internal)

    expect(view.queryByRole('button')).not.toBeInTheDocument()
  })
})
