// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { beforeEach } from 'vitest'
import { computed, ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'

import plugin from '#desktop/pages/ticket/components/TicketSidebar/plugins/information.ts'
import TicketSidebarInformationContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { mockLinkListQuery } from '#desktop/pages/ticket/graphql/queries/linkList.mocks.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

const defaultTicket = createDummyTicket()

mockRouterHooks()

const renderInformationSidebar = (ticket = defaultTicket) =>
  renderComponent(TicketSidebarInformationContent, {
    props: {
      context: {
        screenType: TicketSidebarScreenType.TicketDetailView,
      },
      sidebarPlugin: plugin,
      modelValue: {},
    },
    form: true,
    router: true,
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
  })

describe('TicketSidebarInformationContent', () => {
  beforeEach(() => {
    mockLinkListQuery({
      linkList: [],
    })
  })

  describe('actions', () => {
    it('displays basic sidebar content', () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar()

      expect(
        wrapper.getByRole('heading', { name: 'Ticket', level: 2 }),
      ).toBeInTheDocument()

      expect(wrapper.getByIconName('chat-left-text'))
    })

    it('contains teleport target element for ticket edit attribute form', () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar()

      expect(
        wrapper.getByRole('heading', { name: 'Attributes', level: 3 }),
      ).toBeInTheDocument()

      expect(wrapper.getByTestId('ticket-edit-attribute-form')).toHaveAttribute(
        'id',
        'ticketEditAttributeForm',
      )
    })

    it('displays tags and heading', () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar({
        ...defaultTicket,
        tags: ['tag1', 'tag2'],
      })

      expect(
        wrapper.getByRole('heading', { name: 'Tags', level: 3 }),
      ).toBeInTheDocument()

      expect(wrapper.getByRole('link', { name: 'tag1' })).toBeInTheDocument()

      // TODO: adjust link as soon as we have correct value for search
      expect(wrapper.getByRole('link', { name: 'tag2' })).toHaveAttribute(
        'href',
        '#',
      )
    })

    it.each(['Change customer'])(
      'shows button for `%s` action',
      async (buttonLabel) => {
        mockPermissions(['ticket.agent'])

        const wrapper = renderInformationSidebar()

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

    it('does not show customer change action if agent has no update permission', async () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar({
        ...defaultTicket,
        policy: {
          update: false,
          agentReadAccess: true,
        },
      })

      const actionMenuButton = wrapper.getByRole('button', {
        name: 'Action menu button',
      })

      await wrapper.events.click(actionMenuButton)

      expect(
        wrapper.queryByRole('button', { name: 'Change customer' }),
      ).not.toBeInTheDocument()
    })

    it('does not show `Customer change` action if user is customer', () => {
      mockPermissions(['ticket.customer'])

      const wrapper = renderInformationSidebar({
        ...defaultTicket,
        policy: {
          update: true,
          agentReadAccess: false,
        },
      })

      expect(
        wrapper.queryByRole('button', { name: 'Action menu button' }),
      ).not.toBeInTheDocument()
    })

    it('does not display accounted time if user is customer', () => {
      mockPermissions(['ticket.customer'])

      const wrapper = renderInformationSidebar()

      expect(
        wrapper.queryByRole('heading', { name: 'Accounted time', level: 3 }),
      ).not.toBeInTheDocument()
    })

    it('does not display accounted time if there are no records', () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar({
        ...defaultTicket,
        timeUnit: null,
        timeUnitsPerType: [],
      })

      expect(
        wrapper.queryByRole('heading', { name: 'Accounted Time', level: 3 }),
      ).not.toBeInTheDocument()
    })

    it('displays accounted time.', () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar({
        ...defaultTicket,
        timeUnit: 1,
        timeUnitsPerType: [
          {
            __typename: 'TicketTimeAccountingTypeSum',
            name: 'None',
            timeUnit: 1,
          },
        ],
      })

      expect(
        wrapper.getByRole('heading', { name: 'Accounted Time', level: 3 }),
      ).toBeInTheDocument()
    })

    it('hides tags, links, accounted time if user has readonly permission and no entries are present', () => {
      mockPermissions(['ticket.agent'])

      mockLinkListQuery({
        linkList: [],
      })

      const ticket = createDummyTicket({
        tags: [],
        timeUnit: null,
        defaultPolicy: {
          update: false,
          agentReadAccess: true,
        },
      })

      const wrapper = renderInformationSidebar(ticket)

      expect(
        wrapper.queryByRole('heading', { name: 'Tags', level: 3 }),
      ).not.toBeInTheDocument()

      expect(
        wrapper.queryByRole('heading', { name: 'Links', level: 3 }),
      ).not.toBeInTheDocument()

      expect(
        wrapper.queryByRole('heading', { name: 'Accounted Time', level: 3 }),
      ).not.toBeInTheDocument()
    })
  })
})
