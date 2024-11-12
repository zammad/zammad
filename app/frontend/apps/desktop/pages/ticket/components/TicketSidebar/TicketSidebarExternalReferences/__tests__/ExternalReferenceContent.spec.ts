// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import ExternalReferenceContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceContent.vue'

describe('ExternalReferenceContent', () => {
  it('renders component correctly', () => {
    const wrapper = renderComponent(ExternalReferenceContent, {
      props: {
        label: 'Foo bar',
        values: ['vue', 'ts'],
      },
    })

    expect(wrapper.baseElement).toHaveTextContent('Foo bar')
    expect(wrapper.getByRole('list')).toHaveTextContent('vue')
    expect(wrapper.getByRole('list')).toHaveTextContent('ts')
  })
})
