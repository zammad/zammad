// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import TicketKnowledgeBaseActions from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketRelatedKnowledge/TicketKnowledgeBaseActions.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation,
  mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationError,
  waitForTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceEnqueueKnowledgeBaseAnswer.mocks.ts'

const ticketId = convertToGraphQLId('Ticket', 1)

const renderActions = (
  props: { showDraft?: boolean; isTicketEditable?: boolean; newKnowledgeBaseAnswer?: boolean } = {},
) =>
  renderComponent(TicketKnowledgeBaseActions, {
    props: {
      showDraft: true,
      isTicketEditable: true,
      newKnowledgeBaseAnswer: false,
      ...props,
    },
    provide: [
      [
        TICKET_KEY,
        {
          ticket: computed(() => ({ id: ticketId })),
          ticketId: computed(() => ticketId),
          ticketInternalId: computed(() => 1),
        },
      ],
    ],
    router: true,
    store: true,
  })

describe('TicketKnowledgeBaseActions', () => {
  const notifications = useNotifications()

  vi.spyOn(notifications, 'notify')

  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('AI draft', () => {
    it('triggers the generation mutation and shows an info notification on click', async () => {
      mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation({
        ticketAIAssistanceEnqueueKnowledgeBaseAnswer: {
          success: true,
        },
      })

      const wrapper = renderActions()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Add AI draft' }))

      expect(notifications.notify).toHaveBeenCalledWith({
        id: 'ticket-ai-knowledge-base-answers-notification',
        message:
          'A related knowledge base answer is being generated. You will be notified once the draft is ready.',
        type: 'info',
        durationMS: 8000,
      })

      const calls = await waitForTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCalls()
      expect(calls.at(-1)?.variables).toEqual({ ticketId })
    })

    it('shows an error notification when the generation request fails', async () => {
      mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationError('Generation failed', {
        type: GraphQLErrorTypes.UnknownError,
      })

      const wrapper = renderActions()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Add AI draft' }))

      expect(notifications.notify).toHaveBeenCalledWith({
        id: 'ticket-ai-knowledge-base-answers-notification',
        message: 'Generation failed',
        type: 'error',
      })
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
