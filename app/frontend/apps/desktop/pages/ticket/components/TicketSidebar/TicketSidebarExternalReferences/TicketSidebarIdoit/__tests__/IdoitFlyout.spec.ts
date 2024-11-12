// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import IdoitFlyout from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/IdoitFlyout.vue'
import { mockTicketExternalReferencesIdoitObjectSearchQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIdoitObjectSearch.mocks.ts'

describe('IdoitFlyout', () => {
  it('renders flyout Ui correctly', async () => {
    mockTicketExternalReferencesIdoitObjectSearchQuery({
      ticketExternalReferencesIdoitObjectSearch: [
        {
          idoitObjectId: 26,
          link: 'http://localhost:9001/?objID=26',
          title: 'Test',
          type: 'Building',
          status: 'in operation',
        },
        {
          idoitObjectId: 27,
          link: 'http://localhost:9001/?objID=27',
          title: 'LG Power',
          type: 'Monitor',
          status: 'assembled',
        },
      ],
    })

    const mockSubmit = vi.fn()

    const wrapper = renderComponent(IdoitFlyout, {
      props: {
        name: 'flyout-idoit',
        objectIds: [26, 27],
        onSubmit: mockSubmit,
        icon: 'i-doit-logo-light',
      },
      form: true,
      router: true,
      flyout: true,
    })

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent(
      'i-doit: Link objects',
    )

    expect(wrapper.getByIconName('i-doit-logo-light')).toBeInTheDocument()

    expect(wrapper.getByLabelText('Type')).toBeInTheDocument()

    expect(wrapper.getByLabelText('Filter')).toBeInTheDocument()

    expect(await wrapper.findByText('LG Power')).toBeInTheDocument()
  })
})
