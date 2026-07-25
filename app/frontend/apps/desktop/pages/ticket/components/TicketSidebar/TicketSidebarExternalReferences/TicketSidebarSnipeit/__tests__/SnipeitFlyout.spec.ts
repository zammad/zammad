// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import SnipeitFlyout from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/SnipeitFlyout.vue'
import { mockTicketExternalReferencesSnipeitAssetSearchQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesSnipeitAssetSearch.mocks.ts'

describe('SnipeitFlyout', () => {
  it('renders flyout Ui correctly', async () => {
    mockTicketExternalReferencesSnipeitAssetSearchQuery({
      ticketExternalReferencesSnipeitAssetSearch: [
        {
          snipeitAssetId: 26,
          link: 'http://localhost:9001/hardware/26',
          name: 'Test',
          assetTag: 'TEST001',
          status: 'Ready to Deploy',
          model: 'MacBook Pro',
          category: 'Laptops',
        },
        {
          snipeitAssetId: 27,
          link: 'http://localhost:9001/hardware/27',
          name: 'LG Power',
          assetTag: 'MON001',
          status: 'Deployed',
          model: 'UltraSharp',
          category: 'Monitors',
        },
      ],
    })

    const mockSubmit = vi.fn()

    const wrapper = renderComponent(SnipeitFlyout, {
      props: {
        name: 'flyout-snipeit',
        assetIds: [26, 27],
        onSubmit: mockSubmit,
        icon: 'snipeit-logo-light',
      },
      form: true,
      router: true,
      flyout: true,
    })

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent('Snipe-IT: Link assets')

    expect(wrapper.getByIconName('snipeit-logo-light')).toBeInTheDocument()

    expect(wrapper.getByLabelText('Category')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Model')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Filter')).toBeInTheDocument()

    expect(await wrapper.findByText('LG Power')).toBeInTheDocument()
  })
})
