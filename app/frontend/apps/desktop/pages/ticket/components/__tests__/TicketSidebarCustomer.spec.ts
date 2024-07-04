// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  mockUserQuery,
  waitForUserQueryCalls,
} from '#shared/entities/user/graphql/queries/user.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import customerSidebarPlugin from '../TicketSidebar/plugins/customer.ts'
import TicketSidebarCustomerButton from '../TicketSidebar/TicketSidebarCustomerButton.vue'
import TicketSidebarCustomerContent from '../TicketSidebar/TicketSidebarCustomerContent.vue'
import { TicketSidebarScreenType } from '../types.ts'

const renderTicketSidebarCustomerButton = async (
  context: {
    formValues: Record<string, unknown>
  },
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarCustomerButton, {
    props: {
      sidebar: 'customer',
      sidebarPlugin: customerSidebarPlugin,
      selected: true,
      context: {
        screenType: TicketSidebarScreenType.TicketCreate,
        ...context,
      },
    },
    ...options,
  })

  if (context.formValues.customer_id) await waitForUserQueryCalls()

  return result
}

const renderTicketSidebarCustomerContent = async (
  context: {
    formValues: Record<string, unknown>
  },
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarCustomerContent, {
    props: {
      context: {
        screenType: TicketSidebarScreenType.TicketCreate,
        ...context,
      },
    },
    router: true,
    ...options,
  })

  await waitForUserQueryCalls()

  return result
}

describe('TicketSidebarCustomerButton.vue', () => {
  it('shows sidebar when customer ID is present', async () => {
    const wrapper = await renderTicketSidebarCustomerButton({
      formValues: {
        customer_id: 2,
      },
    })

    expect(wrapper.emitted('show')).toHaveLength(1)
  })

  it('does not show sidebar when customer ID is absent', async () => {
    const wrapper = await renderTicketSidebarCustomerButton({
      formValues: {
        customer_id: null,
      },
    })

    expect(wrapper.emitted('show')).toBeUndefined()
  })

  it('hides sidebar when customer was not found', async () => {
    mockUserQuery({
      user: null,
    })

    const wrapper = await renderTicketSidebarCustomerButton({
      formValues: {
        customer_id: 999,
      },
    })

    expect(wrapper.emitted('hide')).toHaveLength(1)
  })

  it('displays badge with open ticket count', async () => {
    mockApplicationConfig({
      ui_sidebar_open_ticket_indicator_colored: true,
    })

    mockUserQuery({
      user: {
        ticketsCount: {
          open: 42,
        },
      },
    })

    const wrapper = await renderTicketSidebarCustomerButton({
      formValues: {
        customer_id: 1,
      },
    })

    const badge = wrapper.getByRole('status', { name: 'Open tickets' })

    expect(badge).toHaveTextContent('42')
    expect(badge).toHaveClass('bg-red-500')
  })
})

describe('TicketSidebarCustomerContent.vue', () => {
  it('renders customer info', async () => {
    mockUserQuery({
      user: {
        firstname: 'Nicole',
        lastname: 'Braun',
        fullname: 'Nicole Braun',
        image: null,
        email: 'nicole.braun@zammad.org',
        organization: {
          __typename: 'Organization',
          id: convertToGraphQLId('Organization', 1),
          internalId: 1,
          name: 'Zammad Foundation',
          ticketsCount: null,
          active: true,
        },
        secondaryOrganizations: {
          __typename: 'OrganizationConnection',
          edges: [
            {
              __typename: 'OrganizationEdge',
              node: {
                __typename: 'Organization',
                id: convertToGraphQLId('Organization', 2),
                name: 'Zammad Org',
                internalId: 2,
                active: true,
              },
            },
            {
              __typename: 'OrganizationEdge',
              node: {
                __typename: 'Organization',
                id: convertToGraphQLId('Organization', 3),
                name: 'Zammad Inc',
                internalId: 3,
                active: true,
              },
            },
            {
              __typename: 'OrganizationEdge',
              node: {
                __typename: 'Organization',
                id: convertToGraphQLId('Organization', 4),
                name: 'Zammad Ltd',
                internalId: 4,
                active: true,
              },
            },
          ],
          totalCount: 5,
        },
        vip: false,
        ticketsCount: {
          open: 42,
          closed: 10,
        },
      },
    })

    const wrapper = await renderTicketSidebarCustomerContent({
      formValues: {
        customer_id: 2,
      },
    })

    expect(wrapper.getByRole('heading')).toHaveTextContent('Customer')

    expect(
      wrapper.getByRole('button', { name: 'Action menu button' }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('img', { name: 'Avatar (Nicole Braun)' }),
    ).toHaveTextContent('NB')

    expect(wrapper.getByText('Nicole Braun')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'Zammad Foundation' }),
    ).toHaveAttribute('href', '/organizations/1')

    expect(wrapper.getByText('Email')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'nicole.braun@zammad.org' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('Secondary organizations')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'Avatar (Zammad Org) Zammad Org' }),
    ).toHaveAttribute('href', '/organizations/2')

    expect(
      wrapper.getByRole('link', { name: 'Avatar (Zammad Inc) Zammad Inc' }),
    ).toHaveAttribute('href', '/organizations/3')

    expect(
      wrapper.getByRole('link', { name: 'Avatar (Zammad Ltd) Zammad Ltd' }),
    ).toHaveAttribute('href', '/organizations/4')

    expect(
      wrapper.getByRole('button', { name: 'Show 2 more' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('Tickets')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'open tickets 42' }),
    ).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'closed tickets 10' }),
    ).toBeInTheDocument()
  })
})
