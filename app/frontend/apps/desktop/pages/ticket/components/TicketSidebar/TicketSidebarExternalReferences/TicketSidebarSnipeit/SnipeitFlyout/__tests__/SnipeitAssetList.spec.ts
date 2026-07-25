// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import SnipeitAssetList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarSnipeit/SnipeitFlyout/SnipeitAssetList.vue'

describe('SnipeitAssetList', () => {
  it('renders table correctly', () => {
    const wrapper = renderComponent(SnipeitAssetList, {
      props: {
        items: [
          {
            id: 26,
            snipeitAssetId: 26,
            name: {
              link: 'http://localhost:9001/hardware/26',
              label: 'Laptop-001',
              openInNewTab: true,
              external: true,
            },
            assetTag: 'LAP001',
            status: 'Ready to Deploy',
          },
        ],
      },
      router: true,
      form: true,
    })

    const container = wrapper.getByRole('table')

    const link = within(container).getByRole('link')

    expect(link).toHaveTextContent('Laptop-001')
    expect(link).toHaveAttribute('href', 'http://localhost:9001/hardware/26')
    expect(link).toHaveAttribute('target', '_blank')

    expect(container).toHaveTextContent('ID')
    expect(container).toHaveTextContent('26')

    expect(container).toHaveTextContent('Asset Tag')
    expect(container).toHaveTextContent('LAP001')

    expect(container).toHaveTextContent('Status')
    expect(container).toHaveTextContent('Ready to Deploy')

    expect(wrapper.getByRole('cell', { name: '26' })).toBeInTheDocument()
  })

  it('shows empty state message', () => {
    const wrapper = renderComponent(SnipeitAssetList, {
      props: {
        items: [],
      },
    })

    expect(wrapper.getByText('No results found')).toBeInTheDocument()
  })
})
