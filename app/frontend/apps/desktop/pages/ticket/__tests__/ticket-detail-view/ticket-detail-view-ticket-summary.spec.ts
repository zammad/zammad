// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { getTicketArticleUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketArticlesUpdates.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumTicketArticleSenderName,
  EnumTicketSummaryGeneration,
  type TicketAiAssistanceSummaryUpdatesPayload,
  type TicketArticleUpdatesPayload,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockTicketAiAssistanceSummarizeMutation,
  waitForTicketAiAssistanceSummarizeMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceSummarize.mocks.ts'
import { getTicketAiAssistanceSummaryUpdatesSubscriptionHandler } from '#desktop/pages/ticket/graphql/subscriptions/ticketAIAssistanceSummaryUpdates.mocks.ts'

import type { DeepPartial } from '@apollo/client/utilities'

const triggerSummaryUpdate = async (
  data: TicketAiAssistanceSummaryUpdatesPayload,
  withInitialSubscription = true,
) => {
  const mockSubscription = getTicketAiAssistanceSummaryUpdatesSubscriptionHandler()

  if (withInitialSubscription) {
    await mockSubscription.trigger({
      ticketAIAssistanceSummaryUpdates: {
        summary: null,
        error: null,
      },
    })
  }

  await mockSubscription.trigger({
    ticketAIAssistanceSummaryUpdates: data,
  })
}

const triggerArticleUpdate = async (
  data: DeepPartial<TicketArticleUpdatesPayload>,
  withInitialSubscription = true,
) => {
  const mockSubscription = await getTicketArticleUpdatesSubscriptionHandler()

  if (withInitialSubscription) {
    await mockSubscription.trigger({
      ticketArticleUpdates: {
        addArticle: null,
        updateArticle: null,
        removeArticleId: null,
      },
    })
  }

  await waitForNextTick()

  await mockSubscription.trigger({
    ticketArticleUpdates: data,
  })
}

describe('Ticket detail view - Ticket summary', () => {
  it('shows ticket summary to agent', async () => {
    mockPermissions(['ticket.agent'])

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        open_questions: true,
        upcoming_events: true,
        customer_sentiment: true,
      },
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        summary: {
          customerRequest: 'Order not received after payment',
          conversationSummary: [
            'The customer paid for an order but claims to have not received it. They provided the order number and requested assistance with tracking.',
          ],
          openQuestions: ['What was the payment method used?'],
          upcomingEvents: [
            'Check the order status in the system',
            'Verify if the shipping address is correct',
            'Contact the shipping carrier for updates',
          ],
          customerMood: 'Frustrated',
          customerEmotion: '🤬',
        },
      },
    })

    const view = await visitView('/tickets/1')

    const contentSidebar = await view.findByRole('complementary', {
      name: 'Content sidebar',
    })

    expect(within(contentSidebar).getByRole('button', { name: 'AI summary' })).toBeInTheDocument()

    await view.events.click(within(contentSidebar).getByRole('button', { name: 'AI summary' }))

    expect(
      await within(contentSidebar).findByRole('heading', {
        name: 'Customer intent',
        level: 3,
      }),
    ).toBeInTheDocument()
  })

  it('hides ticket summary for customer', async () => {
    mockPermissions(['ticket.customer'])

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    const view = await visitView('/tickets/1')

    const contentSidebar = view.getByRole('complementary', {
      name: 'Content sidebar',
    })

    expect(
      within(contentSidebar).queryByRole('button', { name: 'AI summary' }),
    ).not.toBeInTheDocument()
  })

  it('re-invokes summary update when new article is created', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        open_questions: true,
        upcoming_events: true,
        customer_sentiment: true,
      },
    })

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    const view = await visitView('/tickets/1')

    await view.events.click(view.getByRole('button', { name: 'AI summary' }))

    const calls = await waitForTicketAiAssistanceSummarizeMutationCalls()

    const numberOfCalls = calls.length

    expect(await view.findByRole('heading', { name: 'Customer intent' }))

    await triggerArticleUpdate({
      addArticle: {
        createdAt: new Date().toISOString(),
        sender: {
          name: EnumTicketArticleSenderName.Customer,
        },
        id: convertToGraphQLId('Article', 1),
      },
      updateArticle: null,
      removeArticleId: null,
    })

    expect(calls).toHaveLength(numberOfCalls + 1)
  })

  it('does not re-invoke summary update when article of type system is updated', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        open_questions: true,
        upcoming_events: true,
        customer_sentiment: true,
        generate_on: EnumTicketSummaryGeneration.OnTicketDetailOpening,
      },
    })

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    const view = await visitView('/tickets/1')

    await view.events.click(view.getByRole('button', { name: 'AI summary' }))

    const calls = await waitForTicketAiAssistanceSummarizeMutationCalls()

    const numberOfCalls = calls.length

    expect(await view.findByRole('heading', { name: 'Customer intent' }))

    await triggerArticleUpdate(
      {
        addArticle: {
          sender: {
            name: EnumTicketArticleSenderName.System,
          },
        },
        updateArticle: null,
        removeArticleId: null,
      },
      false,
    )

    expect(calls).toHaveLength(numberOfCalls)
  })

  it('triggers summary update when subscription comes in', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        open_questions: true,
        upcoming_events: true,
        customer_sentiment: true,
        generate_on: EnumTicketSummaryGeneration.OnTicketDetailOpening,
      },
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        summary: {
          customerRequest: 'Order not received after payment',
          conversationSummary: [
            'The customer paid for an order but claims to have not received it. They provided the order number and requested assistance with tracking.',
          ],
          openQuestions: ['What was the payment method used?'],
          upcomingEvents: [
            'Check the order status in the system',
            'Verify if the shipping address is correct',
            'Contact the shipping carrier for updates',
          ],
          customerMood: 'Frustrated',
          customerEmotion: '🤬',
        },
      },
    })

    const ticket = createDummyTicket()

    mockTicketQuery({
      ticket,
    })

    const view = await visitView('/tickets/1')

    await view.events.click(view.getByRole('button', { name: 'AI summary' }))

    await triggerSummaryUpdate({
      summary: {
        customerRequest: '...',
        conversationSummary: ['Summary to see if subscription comes in'],
        openQuestions: ['...'],
        upcomingEvents: ['foo', 'bar'],
        customerMood: '...',
        customerEmotion: '🤬',
      },
      error: null,
    })

    expect(
      await view.findByRole('heading', { level: 3, name: 'Customer intent' }),
    ).toBeInTheDocument()

    expect(await view.findByText('Summary to see if subscription comes in')).toBeInTheDocument()
  })

  it('displays update indicator when new summary comes in', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        generate_on: EnumTicketSummaryGeneration.OnTicketDetailOpening,
      },
    })

    mockTicketQuery({
      ticket: createDummyTicket({
        group: { summaryGeneration: EnumTicketSummaryGeneration.GlobalDefault },
      }),
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        analytics: {
          isUnread: true,
        },
      },
    })

    const view = await visitView('/tickets/1')

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    const contentSidebar = view.getByRole('complementary', { name: 'Content sidebar' })
    expect(
      await within(contentSidebar).findByRole('status', { name: 'Has update' }),
    ).toBeInTheDocument()
  })

  it('hides update indicator when new summary comes updated from current user', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: false,
    })

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        analytics: {
          isUnread: false,
        },
      },
    })

    const view = await visitView('/tickets/1')

    const contentSidebar = view.getByRole('complementary', { name: 'Content sidebar' })

    console.log(within(contentSidebar).queryByRole('status', { name: 'Has update' }))

    expect(
      within(contentSidebar).queryByRole('status', { name: 'Has update' }),
    ).not.toBeInTheDocument()
  })

  it('hides update indicator when ticket summary sidebar is opened', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        generate_on: EnumTicketSummaryGeneration.OnTicketDetailOpening,
      },
    })

    mockTicketQuery({
      ticket: createDummyTicket({
        group: { summaryGeneration: EnumTicketSummaryGeneration.GlobalDefault },
      }),
    })

    const view = await visitView('/tickets/1')

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    await view.events.click(view.getByRole('button', { name: 'AI summary' }))

    const contentSidebar = view.getByRole('complementary', { name: 'Content sidebar' })

    expect(
      within(contentSidebar).queryByRole('status', { name: 'Has update' }),
    ).not.toBeInTheDocument()
  })

  it('hides update indicator when last article was created by current user', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        generate_on: EnumTicketSummaryGeneration.OnTicketDetailOpening,
      },
    })

    mockTicketQuery({
      ticket: createDummyTicket({
        group: { summaryGeneration: EnumTicketSummaryGeneration.GlobalDefault },
      }),
    })

    const view = await visitView('/tickets/1')

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    await triggerSummaryUpdate({
      summary: {
        customerRequest: '...',
        conversationSummary: ['Agent replies something'],
        openQuestions: ['...'],
        upcomingEvents: ['...'],
        customerMood: '...',
        customerEmotion: '🤬',
      },
      analytics: {
        isUnread: false,
        usage: null,
      },
      error: null,
    })

    const contentSidebar = view.getByRole('complementary', { name: 'Content sidebar' })

    expect(
      within(contentSidebar).queryByRole('status', { name: 'Has update' }),
    ).not.toBeInTheDocument()
  })

  describe('errors', () => {
    beforeEach(() => {
      mockPermissions(['ticket.agent'])

      mockTicketQuery({
        ticket: createDummyTicket(),
      })
    })

    it('shows detailed error message to agent if summary generation fails', async () => {
      mockTicketAiAssistanceSummarizeMutation({
        ticketAIAssistanceSummarize: {
          summary: null,
        },
      })
      mockApplicationConfig({
        ai_provider: true,
        ai_assistance_ticket_summary: true,
        ai_assistance_ticket_summary_config: {
          open_questions: true,
          upcoming_events: true,
          customer_sentiment: true,
          generate_on: EnumTicketSummaryGeneration.OnTicketDetailOpening,
        },
      })

      const view = await visitView('/tickets/1')

      await view.events.click(view.getByRole('button', { name: 'AI summary' }))

      await waitForTicketAiAssistanceSummarizeMutationCalls()

      await triggerSummaryUpdate({
        summary: null,
        error: {
          message: 'Authentication problem with provider.',
          exception: 'Error',
        },
      })

      const contentSidebar = await view.findByRole('complementary', {
        name: 'Content sidebar',
      })

      const alert = await within(contentSidebar).findByRole('alert')

      expect(alert).toHaveTextContent(
        'The summary could not be generated. Please try again later or contact your administrator.',
      )

      expect(alert).toHaveTextContent('API server error: Authentication problem with provider.')
    })

    it('shows no ai provider is selected', async () => {
      mockApplicationConfig({
        ai_provider: false,
        ai_assistance_ticket_summary: true,
        ai_assistance_ticket_summary_config: {
          open_questions: true,
          upcoming_events: true,
          customer_sentiment: true,
          generate_on: EnumTicketSummaryGeneration.OnTicketDetailOpening,
        },
      })

      const view = await visitView('/tickets/1')

      await view.events.click(view.getByRole('button', { name: 'AI summary' }))

      expect(
        view.getByText('No AI provider is currently set up. Please contact your administrator.'),
      ).toBeInTheDocument()
    })
  })

  it('hides sidebar when feature is disabled', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: false,
    })

    mockTicketQuery({
      ticket: createDummyTicket(),
    })

    const view = await visitView('/tickets/1')

    expect(view.queryByRole('button', { name: 'AI summary' })).not.toBeInTheDocument()
  })

  describe('ticket summary generation is set to "OnTicketSummarySidebarActivation"', () => {
    it('does not generate summary on ticket detail opening', async () => {
      mockPermissions(['ticket.agent'])

      mockApplicationConfig({
        ai_provider: true,
        ai_assistance_ticket_summary: true,
        ai_assistance_ticket_summary_config: {
          open_questions: true,
          upcoming_events: true,
          customer_sentiment: true,
          generate_on: EnumTicketSummaryGeneration.OnTicketSummarySidebarActivation,
        },
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          group: { summaryGeneration: EnumTicketSummaryGeneration.GlobalDefault },
        }),
      })

      const view = await visitView('/tickets/1')

      await view.events.click(await view.findByRole('button', { name: 'AI summary' }))

      await waitForTicketAiAssistanceSummarizeMutationCalls()
    })

    it('does not generate summary on ticket detail opening when group has value set', async () => {
      mockPermissions(['ticket.agent'])

      mockApplicationConfig({
        ai_provider: true,
        ai_assistance_ticket_summary: true,
        ai_assistance_ticket_summary_config: {
          open_questions: true,
          upcoming_events: true,
          customer_sentiment: true,
          generate_on: EnumTicketSummaryGeneration.OnTicketDetailOpening,
        },
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          group: {
            summaryGeneration: EnumTicketSummaryGeneration.OnTicketSummarySidebarActivation,
          },
        }),
      })

      const view = await visitView('/tickets/1')

      await view.events.click(await view.findByRole('button', { name: 'AI summary' }))

      await waitForTicketAiAssistanceSummarizeMutationCalls()
    })

    it('does generate summary on ticket detail opening when group has value set', async () => {
      mockPermissions(['ticket.agent'])

      mockApplicationConfig({
        ai_provider: true,
        ai_assistance_ticket_summary: true,
        ai_assistance_ticket_summary_config: {
          open_questions: true,
          upcoming_events: true,
          customer_sentiment: true,
          generate_on: EnumTicketSummaryGeneration.OnTicketSummarySidebarActivation,
        },
      })

      mockTicketQuery({
        ticket: createDummyTicket({
          group: {
            summaryGeneration: EnumTicketSummaryGeneration.OnTicketDetailOpening,
          },
        }),
      })

      await visitView('/tickets/1')

      await waitForTicketAiAssistanceSummarizeMutationCalls()
    })
  })

  it('triggers summary generation only on entering sidebar', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        open_questions: true,
        upcoming_events: true,
        customer_sentiment: true,
        generate_on: EnumTicketSummaryGeneration.OnTicketSummarySidebarActivation,
      },
    })

    mockTicketQuery({
      ticket: createDummyTicket({
        group: { summaryGeneration: EnumTicketSummaryGeneration.GlobalDefault },
      }),
    })

    const view = await visitView('/tickets/1')

    await view.events.click(await view.findByRole('button', { name: 'AI summary' }))

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    await view.events.click(await view.findByRole('button', { name: 'Ticket' }))

    expect(await waitForTicketAiAssistanceSummarizeMutationCalls()).toHaveLength(1)
  })
})
