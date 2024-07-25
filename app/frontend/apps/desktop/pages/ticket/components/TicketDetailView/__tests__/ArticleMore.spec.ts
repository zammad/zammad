// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import ArticleMore from '#desktop/pages/ticket/components/TicketDetailView/ArticleMore.vue'

const renderWrapper = (disabled: boolean) => {
  return renderComponent(ArticleMore, { router: true, props: { disabled } })
}

describe('ArticleMore', () => {
  it('creates the component with enabled button', () => {
    const wrapper = renderWrapper(false)

    expect(wrapper.queryByText('See more')).toBeInTheDocument()
    expect(wrapper.getByRole('button')).not.toBeDisabled()
  })

  it('creates the component with disabled button', () => {
    const wrapper = renderWrapper(true)

    expect(wrapper.queryByText('See more')).toBeInTheDocument()
    expect(wrapper.getByRole('button')).toBeDisabled()
  })
})
