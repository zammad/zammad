// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation,
  mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationError,
  waitForTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceEnqueueKnowledgeBaseAnswer.mocks.ts'

import TicketAIKnowledgeBaseAnswers from '../TicketSidebarInformationContent/TicketAIKnowledgeBaseAnswers.vue'

const ticketId = 'gid://zammad/Ticket/123'

vi.mock('#desktop/pages/ticket/composables/useTicketInformation.ts', () => ({
  useTicketInformation: () => ({
    ticketId: computed(() => ticketId),
  }),
}))

const renderKBAnswers = () =>
  renderComponent(TicketAIKnowledgeBaseAnswers, {
    router: true,
  })

describe('TicketAIKnowledgeBaseAnswers', () => {
  const notifications = useNotifications()

  vi.spyOn(notifications, 'notify')

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('triggers generation mutation on button click and shows info notification', async () => {
    mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutation({
      ticketAIAssistanceEnqueueKnowledgeBaseAnswer: {
        success: true,
      },
    })

    const wrapper = renderKBAnswers()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Generate Related AI Answer' }))

    expect(notifications.notify).toHaveBeenCalledWith({
      id: 'ticket-ai-knowledge-base-answers-notification',
      message: 'Generating knowledge base answer from related ticket…',
      type: 'info',
    })

    const calls = await waitForTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationCalls()
    expect(calls.at(-1)?.variables).toEqual({ ticketId })
  })

  it('shows error notification when generation request fails', async () => {
    mockTicketAiAssistanceEnqueueKnowledgeBaseAnswerMutationError('Generation failed', {
      type: GraphQLErrorTypes.UnknownError,
    })

    const wrapper = renderKBAnswers()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Generate Related AI Answer' }))

    expect(notifications.notify).toHaveBeenCalledWith({
      id: 'ticket-ai-knowledge-base-answers-notification',
      message: 'Generation failed',
      type: 'error',
    })
  })
})
