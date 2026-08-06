// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { beforeEach } from 'vitest'
import { computed, ref } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

// The plugin registry globs all plugin modules eagerly, and the sidebar content below reaches
//   `useTicketSidebar` (which imports the registry) again. Pull the registry in first, so the glob
//   cannot run while `information.ts` is still initializing.
import '#desktop/pages/ticket/components/TicketSidebar/plugins/index.ts'
import plugin from '#desktop/pages/ticket/components/TicketSidebar/plugins/information.ts'
import TicketSidebarInformationContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { TICKET_SIDEBAR_SYMBOL } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'
import { LinkListDocument } from '#desktop/pages/ticket/graphql/queries/linkList.api.ts'
import { mockLinkListQuery } from '#desktop/pages/ticket/graphql/queries/linkList.mocks.ts'
import { TicketAiRelatedKnowledgeBaseAnswersDocument } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.api.ts'
import { mockTicketAiRelatedKnowledgeBaseAnswersQuery } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.mocks.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

const defaultTicket = createDummyTicket()

mockRouterHooks()

const renderInformationSidebar = (
  ticket = defaultTicket,
  { isTicketEditable = true }: { isTicketEditable?: boolean } = {},
) =>
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
          isTicketEditable: computed(() => isTicketEditable),
          newTicketArticlePresent: ref(false),
          ticketInternalId: computed(() => ticket.internalId),
        },
      ],
      // The AI draft action hands the active sidebar to the flyout it opens.
      [TICKET_SIDEBAR_SYMBOL, { activeSidebar: ref('information') }],
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

      expect(wrapper.getByRole('heading', { name: 'Ticket', level: 2 })).toBeInTheDocument()

      expect(wrapper.getByIconName('chat-left-text'))
    })

    it('contains teleport target element for ticket edit attribute form', () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar()

      expect(wrapper.getByRole('heading', { name: 'Attributes', level: 3 })).toBeInTheDocument()

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

      expect(wrapper.getByRole('heading', { name: 'Tags', level: 3 })).toBeInTheDocument()

      expect(wrapper.getByRole('link', { name: 'tag1' })).toHaveAttribute(
        'href',
        `/desktop/search/${encodeURI('tags:"tag1"')}?entity=Ticket`,
      )

      expect(wrapper.getByRole('link', { name: 'tag2' })).toHaveAttribute(
        'href',
        `/desktop/search/${encodeURI('tags:"tag2"')}?entity=Ticket`,
      )
    })

    it.each(['Change customer'])('shows button for `%s` action', async (buttonLabel) => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar()

      await wrapper.events.click(
        wrapper.getByRole('button', {
          name: 'Action menu button',
        }),
      )

      expect(await wrapper.findByRole('button', { name: buttonLabel })).toBeInTheDocument()
    })

    it('does not show customer change action if agent has no update permission', async () => {
      mockPermissions(['ticket.agent'])

      const wrapper = renderInformationSidebar({
        ...defaultTicket,
        policy: {
          __typename: 'PolicyTicket',
          update: false,
          agentReadAccess: true,
        },
      })

      const actionMenuButton = wrapper.getByRole('button', {
        name: 'Action menu button',
      })

      await wrapper.events.click(actionMenuButton)

      expect(wrapper.queryByRole('button', { name: 'Change customer' })).not.toBeInTheDocument()
    })

    it('does not show `Customer change` action if user is customer', () => {
      mockPermissions(['ticket.customer'])

      const wrapper = renderInformationSidebar({
        ...defaultTicket,
        policy: {
          __typename: 'PolicyTicket',
          update: true,
          agentReadAccess: false,
        },
      })

      expect(wrapper.queryByRole('button', { name: 'Action menu button' })).not.toBeInTheDocument()
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
        wrapper.queryByRole('heading', { name: 'Accounted time', level: 3 }),
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

      expect(wrapper.getByRole('heading', { name: 'Accounted time', level: 3 })).toBeInTheDocument()
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

      expect(wrapper.queryByRole('heading', { name: 'Tags', level: 3 })).not.toBeInTheDocument()

      expect(wrapper.queryByRole('heading', { name: 'Links', level: 3 })).not.toBeInTheDocument()

      expect(
        wrapper.queryByRole('heading', { name: 'Accounted time', level: 3 }),
      ).not.toBeInTheDocument()
    })
  })

  describe('related knowledge', () => {
    // Order matters: `mockApplicationConfig` merges into the shared application store, which
    //   isn't reset between tests in this file, so the "hides" case (asserting the section's
    //   absence with the default/unmocked kb config) must run before any test enables it.
    it('hides the section on a non-editable ticket with no linked or suggested answers', () => {
      mockPermissions(['ticket.agent'])
      mockLinkListQuery({ linkList: [] })

      const wrapper = renderInformationSidebar(defaultTicket, { isTicketEditable: false })

      expect(
        wrapper.queryByRole('heading', { name: 'Related knowledge', level: 3 }),
      ).not.toBeInTheDocument()
    })

    it('shows AI-suggested answers on a non-editable ticket with no linked answers', async () => {
      mockPermissions(['ticket.agent', 'knowledge_base.reader'])
      mockApplicationConfig({
        kb_active: true,
        ai_provider: true,
        ai_assistance_kb_answer_suggestions: true,
      })
      mockLinkListQuery({ linkList: [] })
      mockTicketAiRelatedKnowledgeBaseAnswersQuery({
        ticketAIRelatedKnowledgeBaseAnswers: {
          pending: false,
          answers: [
            {
              score: 0.9,
              translation: {
                id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
                title: 'Reset your password',
                answer: {
                  id: convertToGraphQLId('KnowledgeBase::Answer', 1),
                  category: { knowledgeBase: { id: convertToGraphQLId('KnowledgeBase', 1) } },
                },
              },
            },
          ],
        },
      })

      const wrapper = renderInformationSidebar(defaultTicket, { isTicketEditable: false })

      expect(
        await wrapper.findByRole('heading', { name: 'Related knowledge', level: 3 }),
      ).toBeInTheDocument()
      expect(await wrapper.findByText('Reset your password')).toBeInTheDocument()
    })

    // An agent can be the customer of a ticket in a group they have no access to. They see it in
    //   the customer view, where the server denies both the link list and the suggestions search -
    //   so neither may be requested.
    it('requests nothing for an agent who only has customer access to the ticket', async () => {
      mockPermissions(['ticket.agent', 'knowledge_base.reader'])
      mockApplicationConfig({
        kb_active: true,
        ai_provider: true,
        ai_assistance_kb_answer_suggestions: true,
      })
      mockLinkListQuery({ linkList: [] })
      mockTicketAiRelatedKnowledgeBaseAnswersQuery({
        ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
      })

      const ticket = createDummyTicket({
        defaultPolicy: { update: true, agentReadAccess: false },
      })

      const wrapper = renderInformationSidebar(ticket)

      await flushPromises()

      expect(
        wrapper.queryByRole('heading', { name: 'Related knowledge', level: 3 }),
      ).not.toBeInTheDocument()

      expect(getGraphQLMockCalls(LinkListDocument)).toHaveLength(0)
      expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(0)
    })
  })
})
