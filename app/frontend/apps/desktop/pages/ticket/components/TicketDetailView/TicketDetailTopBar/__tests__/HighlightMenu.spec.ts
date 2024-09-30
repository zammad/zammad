// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import HighlightMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader/HighlightMenu.vue'

describe('CommonHighlightMenu', () => {
  it('renders component correctly', () => {
    const wrapper = renderComponent(HighlightMenu, {})
    expect(wrapper.getByText('Highlight')).toBeInTheDocument()
    expect(wrapper.getByIconName('highlighter')).toBeInTheDocument()
    expect(wrapper.getByIconName('chevron-down')).toBeInTheDocument()
  })
  // :TODO add more tests
})
