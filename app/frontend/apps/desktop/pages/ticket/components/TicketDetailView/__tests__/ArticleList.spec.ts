// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import ArticleList from '#desktop/pages/ticket/components/TicketDetailView/ArticleList.vue'

// TODO: can be removed?
describe.todo('ArticleList', () => {
  it('outputs a list of articles', () => {
    const wrapper = renderComponent(ArticleList)

    expect(wrapper.queryByText('See more')).toBeInTheDocument()
  })
})
