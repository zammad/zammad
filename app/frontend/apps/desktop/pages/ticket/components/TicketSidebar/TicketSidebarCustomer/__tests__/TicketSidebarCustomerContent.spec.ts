// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { TicketSidebarScreenType } from '../../../../types/sidebar.ts'
import customerSidebarPlugin from '../../plugins/customer.ts'
import TicketSidebarCustomerContent from '../TicketSidebarCustomerContent.vue'

const secondaryOrganizations = {
  array: [
    {
      __typename: 'Organization',
      id: convertToGraphQLId('Organization', 2),
      name: 'Zammad Org',
      internalId: 2,
      active: true,
    },
    {
      __typename: 'Organization',
      id: convertToGraphQLId('Organization', 3),
      name: 'Zammad Inc',
      internalId: 3,
      active: true,
    },
    {
      __typename: 'Organization',
      id: convertToGraphQLId('Organization', 4),
      name: 'Zammad Ltd',
      internalId: 4,
      active: true,
    },
  ],
  totalCount: 5,
}

const mockedUser = {
  __typename: 'User',
  id: convertToGraphQLId('User', 2),
  internalId: 2,
  firstname: 'Nicole',
  lastname: 'Braun',
  fullname: 'Nicole Braun',
  email: 'nicole.braun@zammad.org',
  organization: {
    __typename: 'Organization',
    id: convertToGraphQLId('Organization', 1),
    internalId: 1,
    name: 'Zammad Foundation',
    ticketsCount: null,
    active: true,
  },
  vip: false,
  ticketsCount: {
    open: 42,
    closed: 10,
  },
  policy: {
    update: true,
  },
}

const renderTicketSidebarCustomerContent = async (options: any = {}) => {
  const result = renderComponent(TicketSidebarCustomerContent, {
    props: {
      sidebarPlugin: customerSidebarPlugin,
      customer: mockedUser,
      secondaryOrganizations,
      objectAttributes: [
        {
          __typename: 'ObjectManagerFrontendAttribute',
          name: 'email',
          display: 'Email',
          dataType: 'input',
          dataOption: {
            type: 'email',
            maxlength: 150,
            null: true,
            item_class: 'formGroup--halfSize',
          },
          isInternal: true,
        },
      ],
      context: {
        screenType: TicketSidebarScreenType.TicketCreate,
      },
    },
    router: true,
    ...options,
  })

  return result
}

describe('TicketSidebarCustomerContent.vue', () => {
  it('renders customer info', async () => {
    const wrapper = await renderTicketSidebarCustomerContent()

    await waitForNextTick()

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
