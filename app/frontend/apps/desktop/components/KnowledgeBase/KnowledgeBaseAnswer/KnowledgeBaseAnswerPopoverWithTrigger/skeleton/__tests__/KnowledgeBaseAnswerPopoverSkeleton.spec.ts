// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import KnowledgeBaseAnswerPopoverSkeleton from '../KnowledgeBaseAnswerPopoverSkeleton.vue'

describe('KnowledgeBaseAnswerPopoverSkeleton', () => {
  it('renders a placeholder per row while loading', () => {
    const wrapper = renderComponent(KnowledgeBaseAnswerPopoverSkeleton, {
      props: { loading: true },
    })

    expect(wrapper.getAllByRole('progressbar')).toHaveLength(8)
  })

  it('renders its content once loading is done', () => {
    const wrapper = renderComponent(KnowledgeBaseAnswerPopoverSkeleton, {
      props: { loading: false },
      slots: { default: 'Ocarina tuning' },
    })

    expect(wrapper.queryAllByRole('progressbar')).toHaveLength(0)
    expect(wrapper.getByText('Ocarina tuning')).toBeInTheDocument()
  })
})
