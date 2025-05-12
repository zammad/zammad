// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { TicketSidebarScreenType } from '../../../../types/sidebar.ts'
import organizationSidebarPlugin from '../../plugins/organization.ts'
import TicketSidebarOrganizationContent from '../TicketSidebarOrganizationContent.vue'

mockRouterHooks()

const renderTicketSidebarOrganizationContent = async (options: any = {}) => {
  const result = renderComponent(TicketSidebarOrganizationContent, {
    props: {
      sidebarPlugin: organizationSidebarPlugin,
      organization: {
        name: 'Zammad Foundation',
        domain: 'zammad.org',
        active: true,
        policy: {
          update: true,
        },
      },
      modelValue: {},
      organizationMembers: {
        array: [
          {
            __typename: 'User',
            id: convertToGraphQLId('User', 2),
            internalId: 2,
            firstname: 'Nicole',
            lastname: 'Braun',
            fullname: 'Nicole Braun',
          },
        ],
        totalCount: 2,
      },
      objectAttributes: [
        {
          name: 'domain',
          display: 'Domain',
          dataType: 'input',
          dataOption: {
            type: 'text',
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

describe('TicketSidebarOrganizationContent.vue', () => {
  it('renders organization info', async () => {
    mockPermissions(['ticket.agent'])

    const wrapper = await renderTicketSidebarOrganizationContent()

    expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent(
      'Organization',
    )

    expect(
      wrapper.getByRole('img', { name: 'Avatar (Zammad Foundation)' }),
    ).toBeInTheDocument()

    expect(wrapper.getByText('Zammad Foundation')).toBeInTheDocument()
    expect(wrapper.getByText('Domain')).toBeInTheDocument()
    expect(wrapper.getByText('zammad.org')).toBeInTheDocument()

    expect(wrapper.getByText('Members')).toBeInTheDocument()

    expect(
      await wrapper.findByRole('link', {
        name: 'Avatar (Nicole Braun) Nicole Braun',
      }),
    ).toHaveAttribute('href', '/user/profile/2')

    expect(
      wrapper.getByRole('button', { name: 'Show 1 more' }),
    ).toBeInTheDocument()
  })
})
