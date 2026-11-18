// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import IdoitUpFlyout from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoitUp/IdoitUpFlyout.vue'
import { mockTicketExternalReferencesIdoitUpObjectSearchQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitUpObjectSearch.mocks.ts'

describe('IdoitUpFlyout', () => {
  it('renders flyout Ui correctly', async () => {
    mockTicketExternalReferencesIdoitUpObjectSearchQuery({
      ticketExternalReferencesIdoitUpObjectSearch: [
        {
          idoitUpObjectId: '00000000Test0026',
          link: 'http://localhost:9001/object/00000000Test0026',
          title: 'Test',
          type: 'Building',
          status: 'in operation',
        },
        {
          idoitUpObjectId: '00000000Test0027',
          link: 'http://localhost:9001/object/00000000Test0027',
          title: 'LG Power',
          type: 'Monitor',
          status: 'assembled',
        },
      ],
    })

    const mockSubmit = vi.fn()

    const wrapper = renderComponent(IdoitUpFlyout, {
      props: {
        name: 'flyout-idoit_up',
        objectIds: ['00000000Test0026', '00000000Test0027'],
        onSubmit: mockSubmit,
        icon: 'i-doit-up-logo-light',
      },
      form: true,
      router: true,
      flyout: true,
    })

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent('i-doit up: Link objects')

    expect(wrapper.getByIconName('i-doit-up-logo-light')).toBeInTheDocument()

    expect(wrapper.getByLabelText('Type')).toBeInTheDocument()

    expect(wrapper.getByLabelText('Filter')).toBeInTheDocument()

    expect(await wrapper.findByText('LG Power')).toBeInTheDocument()
  })
})
