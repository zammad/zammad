// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import TicketKnowledgeBaseActions from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketRelatedKnowledge/TicketKnowledgeBaseActions.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation } from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceEnqueueKnowledgeBaseAnswer.mocks.ts'
import { mockTicketAiRelatedKnowledgeBaseAnswersQuery } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.mocks.ts'

const ticketId = convertToGraphQLId('Ticket', 1)

// The flyout fetches the suggestions itself, so they are mocked on the wire (score as a ratio)
//   instead of being handed to the actions component.
const mockSuggestedAnswers = (titles: string[]) =>
  mockTicketAiRelatedKnowledgeBaseAnswersQuery({
    ticketAIRelatedKnowledgeBaseAnswers: {
      pending: false,
      answers: titles.map((title, index) => ({
        score: 0.9,
        translation: {
          id: convertToGraphQLId('KnowledgeBase::Answer::Translation', index + 1),
          title,
          visibility: EnumKnowledgeBaseVisibility.Published,
          content: { bodyExcerpt: null },
          answer: {
            id: convertToGraphQLId('KnowledgeBase::Answer', index + 1),
            archivedAt: null,
            publishedAt: null,
            category: {
              id: convertToGraphQLId('KnowledgeBase::Category', 1),
              title: 'Account',
              knowledgeBase: { id: convertToGraphQLId('KnowledgeBase', 1) },
            },
          },
          kbLocale: { systemLocale: { locale: 'en-us', name: 'English' } },
        },
      })),
    },
  })

const renderActions = (
  props: Partial<{
    showDraft: boolean
    isTicketEditable: boolean
    newKnowledgeBaseAnswer: boolean
  }> = {},
) =>
  renderComponent(TicketKnowledgeBaseActions, {
    props: {
      showDraft: true,
      isTicketEditable: true,
      newKnowledgeBaseAnswer: false,
      isLinkListLoading: false,
      ...props,
    },
    provide: [
      [
        TICKET_KEY,
        {
          ticket: computed(() => ({ id: ticketId, policy: { agentReadAccess: true } })),
          ticketId: computed(() => ticketId),
          ticketInternalId: computed(() => 1),
        },
      ],
    ],
    router: true,
    routerRoutes: [
      { path: '/', name: 'Root', component: { template: '<div />' } },
      {
        path: '/knowledge-base/:localeCode/category/:categoryInternalId',
        name: 'KnowledgeBaseCategory',
        component: { template: '<div />' },
      },
      // Tags link into the detailed search.
      { path: '/search/:searchTerm?', name: 'Search', component: { template: '<div />' } },
    ],
    store: true,
    flyout: true,
  })

describe('TicketKnowledgeBaseActions', () => {
  describe('AI draft', () => {
    const notifications = useNotifications()

    vi.spyOn(notifications, 'notify')

    beforeEach(() => {
      vi.clearAllMocks()
      mockPermissions(['ticket.agent', 'knowledge_base.editor'])
      mockApplicationConfig({
        ai_provider: true,
        ai_assistance_kb_answer_suggestions: true,
      })
    })

    it('opens the AI draft flyout with the suggested answers on click', async () => {
      mockSuggestedAnswers(['Reset your password'])

      const wrapper = renderActions()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Add AI draft' }))

      const flyout = await wrapper.findByRole('complementary', {
        name: 'Generate knowledge base answer from this ticket',
      })

      // The flyout runs the search itself, so the title arrives asynchronously.
      expect(await within(flyout).findByText('Reset your password')).toBeInTheDocument()

      expect(notifications.notify).not.toHaveBeenCalled()
    })

    it('opens the flyout instead of requesting a draft directly when there are no suggested answers', async () => {
      mockSuggestedAnswers([])

      const wrapper = renderActions()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Add AI draft' }))

      // Generating is confirmed from inside the flyout now, never straight from this button.
      expect(
        await wrapper.findByRole('complementary', {
          name: 'Generate knowledge base answer from this ticket',
        }),
      ).toBeInTheDocument()

      expect(notifications.notify).not.toHaveBeenCalled()
    })

    it('closes the flyout once the generation was requested', async () => {
      mockSuggestedAnswers([])

      mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation({
        ticketAIAssistanceEnqueueKnowledgeBaseAnswer: { success: true },
      })

      const wrapper = renderActions()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Add AI draft' }))

      const flyout = await wrapper.findByRole('complementary', {
        name: 'Generate knowledge base answer from this ticket',
      })

      await wrapper.events.click(within(flyout).getByRole('button', { name: 'Generate' }))

      await waitFor(() =>
        expect(
          wrapper.queryByRole('complementary', {
            name: 'Generate knowledge base answer from this ticket',
          }),
        ).not.toBeInTheDocument(),
      )

      expect(notifications.notify).toHaveBeenCalledWith(expect.objectContaining({ type: 'info' }))
    })

    it('hides the AI draft button when drafting is not available', () => {
      const wrapper = renderActions({ showDraft: false })

      expect(wrapper.queryByRole('button', { name: 'Add AI draft' })).not.toBeInTheDocument()
    })
  })

  describe('link action', () => {
    it('activates the answer picker on click', async () => {
      const wrapper = renderActions()

      await wrapper.events.click(
        wrapper.getByRole('button', { name: 'Link knowledge base answer' }),
      )

      expect(wrapper.emitted('update:newKnowledgeBaseAnswer')).toEqual([[true]])
    })

    it('hides the link button when the ticket is not editable', () => {
      const wrapper = renderActions({ isTicketEditable: false })

      expect(
        wrapper.queryByRole('button', { name: 'Link knowledge base answer' }),
      ).not.toBeInTheDocument()
    })

    it('hides the link button while the answer picker is already active', () => {
      const wrapper = renderActions({ newKnowledgeBaseAnswer: true })

      expect(
        wrapper.queryByRole('button', { name: 'Link knowledge base answer' }),
      ).not.toBeInTheDocument()
    })
  })
})
