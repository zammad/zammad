// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import KnowledgeBaseSearchResultsSkeleton from '../KnowledgeBaseSearchResultsSkeleton.vue'

describe('KnowledgeBaseSearchResultsSkeleton', () => {
  it('renders three placeholder items by default', () => {
    const view = renderComponent(KnowledgeBaseSearchResultsSkeleton)

    expect(view.container.querySelectorAll('li')).toHaveLength(3)
  })

  it('renders as many placeholder items as requested', () => {
    const view = renderComponent(KnowledgeBaseSearchResultsSkeleton, { props: { count: 5 } })

    expect(view.container.querySelectorAll('li')).toHaveLength(5)
  })

  it('is hidden from assistive technology', () => {
    const view = renderComponent(KnowledgeBaseSearchResultsSkeleton)

    expect(view.container.querySelector('ol')).toHaveAttribute('aria-hidden', 'true')
  })
})
