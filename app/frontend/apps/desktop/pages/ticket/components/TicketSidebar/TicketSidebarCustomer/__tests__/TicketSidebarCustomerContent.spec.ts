// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

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
const defaultTicket = createDummyTicket()

const renderTicketSidebarCustomerContent = async (
  screen: TicketSidebarScreenType = TicketSidebarScreenType.TicketCreate,
  ticket = defaultTicket,
  options: any = {},
) =>
  renderComponent(TicketSidebarCustomerContent, {
    props: {
      sidebarPlugin: customerSidebarPlugin,
      customer: mockedUser,
      secondaryOrganizations,
      objectAttributes: [
        {
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
        screenType: screen,
      },
    },
    provide: [
      [
        TICKET_KEY,
        {
          ticketId: computed(() => ticket.id),
          ticket: computed(() => ticket),
          form: ref(),
          showTicketArticleReplyForm: () => {},
          isTicketEditable: computed(() => true),
          newTicketArticlePresent: ref(false),
          ticketInternalId: computed(() => ticket.internalId),
        },
      ],
    ],
    router: true,
    ...options,
  })

describe('TicketSidebarCustomerContent.vue', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  describe('ticket-create-screen', () => {
    it('renders customer info', async () => {
      const wrapper = await renderTicketSidebarCustomerContent()

      await waitForNextTick()

      expect(wrapper.getByRole('heading', { level: 2 })).toHaveTextContent(
        'Customer',
      )

      // :TODO currently we don't have an available actions
      // For example customer change is logically not available in ticket create
      expect(
        wrapper.queryByRole('button', { name: 'Action menu button' }),
      ).not.toBeInTheDocument()

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

  describe('ticket-detail-screen', () => {
    it.each(['Change customer'])(
      'shows button for `%s` action',
      async (buttonLabel) => {
        const wrapper = await renderTicketSidebarCustomerContent(
          TicketSidebarScreenType.TicketDetailView,
        )

        await wrapper.events.click(
          wrapper.getByRole('button', {
            name: 'Action menu button',
          }),
        )

        expect(
          await wrapper.findByRole('button', { name: buttonLabel }),
        ).toBeInTheDocument()
      },
    )

    it('does not show `Change customer` action if user is agent and has no update permission', async () => {
      mockPermissions(['ticket.agent'])

      const wrapper = await renderTicketSidebarCustomerContent(
        TicketSidebarScreenType.TicketDetailView,
        {
          ...defaultTicket,
          policy: {
            update: false,
            agentReadAccess: true,
          },
        },
      )

      expect(
        wrapper.queryByRole('button', { name: 'Action menu button' }),
      ).not.toBeInTheDocument()
    })
  })
})
