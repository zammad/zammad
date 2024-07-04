// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { mockOrganizationQuery } from '#shared/entities/organization/graphql/queries/organization.mocks.ts'
import {
  mockUserQuery,
  waitForUserQueryCalls,
} from '#shared/entities/user/graphql/queries/user.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import organizationSidebarPlugin from '../TicketSidebar/plugins/organization.ts'
import TicketSidebarOrganizationButton from '../TicketSidebar/TicketSidebarOrganizationButton.vue'
import TicketSidebarOrganizationContent from '../TicketSidebar/TicketSidebarOrganizationContent.vue'
import { TicketSidebarScreenType } from '../types.ts'

const renderTicketSidebarOrganizationButton = async (
  context: {
    formValues: Record<string, unknown>
  },
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarOrganizationButton, {
    props: {
      sidebar: 'organization',
      sidebarPlugin: organizationSidebarPlugin,
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

const renderTicketSidebarOrganizationContent = async (
  context: {
    formValues: Record<string, unknown>
  },
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarOrganizationContent, {
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

describe('TicketSidebarOrganizationButton.vue', () => {
  it('shows sidebar when customer ID is present', async () => {
    const wrapper = await renderTicketSidebarOrganizationButton({
      formValues: {
        customer_id: 2,
      },
    })

    expect(wrapper.emitted('show')).toHaveLength(1)
  })

  it('does not show sidebar when customer ID is absent', async () => {
    const wrapper = await renderTicketSidebarOrganizationButton({
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

    const wrapper = await renderTicketSidebarOrganizationButton({
      formValues: {
        customer_id: 999,
      },
    })

    expect(wrapper.emitted('hide')).toHaveLength(1)
  })
})

describe('TicketSidebarOrganizationContent.vue', () => {
  it('renders organization info', async () => {
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
        vip: false,
        ticketsCount: {
          open: 42,
          closed: 10,
        },
      },
    })

    mockOrganizationQuery({
      organization: {
        name: 'Zammad Foundation',
        domain: 'zammad.org',
        active: true,
      },
    })

    const wrapper = await renderTicketSidebarOrganizationContent({
      formValues: {
        customer_id: 2,
      },
    })

    expect(wrapper.getByRole('heading')).toHaveTextContent('Organization')

    expect(
      wrapper.getByRole('img', { name: 'Avatar (Zammad Foundation)' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('Zammad Foundation')).toBeInTheDocument()
    expect(wrapper.getByText('Domain')).toBeInTheDocument()
    expect(wrapper.getByText('zammad.org')).toBeInTheDocument()

    expect(wrapper.getByText('Members')).toBeInTheDocument()

    expect(
      wrapper.getByRole('link', { name: 'Avatar (Nicole Braun) Nicole Braun' }),
    ).toHaveAttribute('href', '/user/profile/2')

    expect(
      wrapper.getByRole('button', { name: 'Show 1 more' }),
    ).toBeInTheDocument()
  })
})
