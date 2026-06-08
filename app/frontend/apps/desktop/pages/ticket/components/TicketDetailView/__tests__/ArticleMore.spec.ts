// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import ArticleMore, {
  type Props,
} from '#desktop/pages/ticket/components/TicketDetailView/ArticleMore.vue'

const renderWrapper = (props: Props = { nextFetchCount: 5 }) => {
  return renderComponent(ArticleMore, { router: true, props })
}

describe('ArticleMore', () => {
  it('displays component with count', () => {
    const wrapper = renderWrapper({ disabled: false, nextFetchCount: 5 })

    expect(wrapper.queryByText('Load 5 more')).toBeInTheDocument()
    expect(wrapper.getByRole('button')).not.toBeDisabled()
  })

  it('creates the component with disabled button', () => {
    const wrapper = renderWrapper({ disabled: true, nextFetchCount: 5 })

    expect(wrapper.queryByText('Load 5 more')).toBeInTheDocument()

    expect(wrapper.getByRole('button')).toBeDisabled()
  })

  it('emits load-more event on click', async () => {
    const wrapper = renderWrapper({ disabled: false, nextFetchCount: 5 })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Load 5 more' }))

    expect(wrapper.emitted('load-more')).toBeTruthy()
  })
})
