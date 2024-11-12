// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import IdoitObjectList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarIdoit/IdoitFlyout/IdoitObjectList.vue'

describe('IdoitObjectList', () => {
  it('renders table correctly', () => {
    const wrapper = renderComponent(IdoitObjectList, {
      props: {
        items: [
          {
            id: 26,
            idoitObjectId: 26,
            title: {
              link: 'http://localhost:9001/?objID=26',
              label: 'Main Building',
              openInNewTab: true,
              external: true,
            },
            type: 'Building',
            status: 'in operation',
          },
        ],
      },
      router: true,
      form: true,
    })

    const container = wrapper.getByRole('table')

    const link = within(container).getByRole('link')

    expect(link).toHaveTextContent('Main Building')
    expect(link).toHaveAttribute('href', 'http://localhost:9001/?objID=26')
    expect(link).toHaveAttribute('target', '_blank')

    expect(container).toHaveTextContent('ID')
    expect(container).toHaveTextContent('26')

    expect(container).toHaveTextContent('Status')
    expect(container).toHaveTextContent('in operation')

    expect(
      wrapper.getByRole('checkbox', { name: 'Select this entry' }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('checkbox', { name: 'Select all entries' }),
    ).toBeInTheDocument()
  })

  it('shows empty state message', () => {
    const wrapper = renderComponent(IdoitObjectList, {
      props: {
        items: [],
      },
    })

    expect(wrapper.getByText('No results found')).toBeInTheDocument()
  })
})
