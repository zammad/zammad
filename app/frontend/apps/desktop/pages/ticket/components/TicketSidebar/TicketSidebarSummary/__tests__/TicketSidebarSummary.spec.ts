// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
import { waitFor } from '@testing-library/vue'
import { ref, computed, effectScope } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTicketSummaryGeneration } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { pluginFiles } from '#desktop/pages/ticket/components/TicketSidebar/plugins/index.ts'
import plugin from '#desktop/pages/ticket/components/TicketSidebar/plugins/ticket-summary.ts'
import TicketSidebarSummary from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarSummary/TicketSidebarSummary.vue'
import { ARTICLES_INFORMATION_KEY } from '#desktop/pages/ticket/composables/useArticleContext.ts'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { TICKET_SIDEBAR_SYMBOL } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'
import {
  mockTicketAiAssistanceSummarizeMutation,
  waitForTicketAiAssistanceSummarizeMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/ticketAIAssistanceSummarize.mocks.ts'

const defaultTicket = createDummyTicket()
const testArticle = createDummyArticle({
  bodyWithUrls: 'foobar',
})

mockRouterHooks()

const onActivatedMock = vi.hoisted(() => (callback?: () => void) => {
  const scope = effectScope()
  scope.run(() => {
    callback?.()
  })
})

vi.mock('vue', async () => {
  const mod = await vi.importActual<typeof import('vue')>('vue')

  return {
    ...mod,
    onActivated: onActivatedMock,
  }
})

const renderRenderTicketSidebarSummary = (ticket: Partial<TicketById> = defaultTicket) => {
  const wrapper = renderComponent(TicketSidebarSummary, {
    props: {
      sidebar: 'ticket-summary',
      sidebarPlugin: plugin,
      selected: true,
      context: {},
    },
    provide: [
      [
        TICKET_KEY,
        {
          ticket: ref(ticket),
          ticketId: ref(ticket.id),
          ticketInternalId: ref(ticket.internalId),
        },
      ],
      [
        ARTICLES_INFORMATION_KEY,
        {
          articles: computed(() => ({
            totalCount: 1,
            edges: [{ node: testArticle }],
            firstArticles: {
              edges: [{ node: testArticle }],
            },
          })),
          articlesQuery: { watchOnResult: vi.fn() },
        },
      ],
      [
        TICKET_SIDEBAR_SYMBOL,
        {
          switchSidebar: vi.fn(),
          shownSidebars: ref({ 'ticket-summary': true }),
          activeSidebar: ref('ticket-summary'),
          sidebarPlugins: pluginFiles,
          hasSidebar: vi.fn(),
          showSidebar: vi.fn(),
          hideSidebar: vi.fn(),
        },
      ],
    ],
    global: {
      stubs: {
        teleport: true,
      },
    },
    router: true,
    form: true,
    store: true,
  })

  // call  manually onActivated without wrapping component in keep-alive
  onActivatedMock()

  return wrapper
}
const ticketAIAssistanceSummarizeMock = {
  summary: {
    customerRequest: 'Order not received after payment',
    conversationSummary:
      'The customer paid for an order but claims to have not received it. They provided the order number and requested assistance with tracking.',
    openQuestions: ['What was the payment method used?'],
    upcomingEvents: [
      'Check the order status in the system',
      'Verify if the shipping address is correct',
      'Contact the shipping carrier for updates',
    ],
    customerMood: 'Frustrated',
    customerEmotion: '🤬',
  },
}

describe('TicketSidebarSummary', () => {
  it('displays correctly', async () => {
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
      ticketAIAssistanceSummarize: ticketAIAssistanceSummarizeMock,
    })

    const wrapper = renderRenderTicketSidebarSummary()

    expect(wrapper.getAllByIconName(plugin.icon).length).toBe(2)

    expect(wrapper.getByRole('button', { name: plugin.title })).toBeInTheDocument()

    expect(
      await wrapper.findByRole('heading', {
        name: 'Customer Intent',
        level: 3,
      }),
    ).toBeInTheDocument()

    const headings = [
      'Customer Intent',
      'Conversation Summary',
      'Open Questions',
      'Upcoming Events',
      'Customer Sentiment',
    ]

    headings.forEach((heading) => {
      expect(
        wrapper.getByRole('heading', {
          name: heading,
          level: 3,
        }),
      ).toBeInTheDocument()
    })

    const content = [
      ticketAIAssistanceSummarizeMock.summary.customerRequest,
      ticketAIAssistanceSummarizeMock.summary.conversationSummary,
      ...ticketAIAssistanceSummarizeMock.summary.openQuestions,
      ...ticketAIAssistanceSummarizeMock.summary.upcomingEvents,
      `${ticketAIAssistanceSummarizeMock.summary.customerEmotion} ${ticketAIAssistanceSummarizeMock.summary.customerMood}`,
    ]

    content.forEach((text) => {
      expect(wrapper.getByText(text)).toBeInTheDocument()
    })
  })

  it('does not display headings which are disabled,', async () => {
    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        open_questions: false,
        upcoming_events: true,
        customer_sentiment: false,
      },
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: ticketAIAssistanceSummarizeMock,
    })

    const wrapper = renderRenderTicketSidebarSummary()

    expect(wrapper.getAllByIconName(plugin.icon).length).toBe(2)

    expect(wrapper.getByRole('button', { name: plugin.title })).toBeInTheDocument()

    expect(
      await wrapper.findByRole('heading', {
        name: 'Customer Intent',
        level: 3,
      }),
    ).toBeInTheDocument()

    const enabledHeadings = ['Customer Intent', 'Conversation Summary', 'Upcoming Events']

    const disabledHeadings = ['Open Questions', 'Customer Sentiment']

    enabledHeadings.forEach((heading) => {
      expect(
        wrapper.getByRole('heading', {
          name: heading,
          level: 3,
        }),
      ).toBeInTheDocument()
    })

    disabledHeadings.forEach((heading) => {
      expect(
        wrapper.queryByRole('heading', {
          name: heading,
          level: 3,
        }),
      ).not.toBeInTheDocument()
    })
  })

  it('hides sidebar when ticket got merged', async () => {
    const wrapper = renderRenderTicketSidebarSummary({
      state: {
        name: 'merged',
        id: convertToGraphQLId('State', 5),
        stateType: {
          id: convertToGraphQLId('StateType', 6),
          name: 'merged',
        },
      },
    })

    await waitFor(() => expect(wrapper.emitted('hide')).toBeTruthy())
  })

  it('displays content hint', async () => {
    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        ...ticketAIAssistanceSummarizeMock,
        analytics: {
          run: {
            id: convertToGraphQLId('AIAnalyticsRun', 12345),
          },
          usage: {
            userHasProvidedFeedback: false,
          },
        },
      },
    })

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
      ai_assistance_ticket_summary_config: {
        open_questions: true,
        suggestions: true,
      },
    })

    const wrapper = renderRenderTicketSidebarSummary()

    expect(await wrapper.findByText('Any feedback on this result?')).toBeInTheDocument()
  })

  it('shows info that summary is too short to be generated', async () => {
    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        summary: {
          customerRequest: null,
          conversationSummary: null,
          openQuestions: null,
          upcomingEvents: null,
          customerMood: null,
          customerEmotion: null,
        },
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

    const wrapper = renderRenderTicketSidebarSummary()

    expect(
      await wrapper.findByText('There is not enough content yet to summarize this ticket.'),
    ).toBeInTheDocument()
  })

  it('shows skeleton loader when summary is not ready', async () => {
    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        summary: null,
      },
    })

    const wrapper = renderRenderTicketSidebarSummary()

    expect(wrapper.getByText('Summary is being generated…')).toBeInTheDocument()
    expect(wrapper.getAllByLabelText('Placeholder for AI generated heading')).toHaveLength(4)

    expect(wrapper.getAllByLabelText('Placeholder for AI generated text')).toHaveLength(16)
  })

  it('shows message that user has provided already feedback', async () => {
    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        ...ticketAIAssistanceSummarizeMock,
        analytics: {
          run: {
            id: convertToGraphQLId('AIAnalyticsRun', 12345),
          },
          usage: {
            userHasProvidedFeedback: true,
          },
        },
      },
    })

    const wrapper = renderRenderTicketSidebarSummary()

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    expect(
      await wrapper.findByText('You have already provided feedback, thank you.'),
    ).toBeInTheDocument()
  })

  it('allows to regenerate AI summary', async () => {
    const runId = convertToGraphQLId('AIAnalyticsRun', 12345)

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        ...ticketAIAssistanceSummarizeMock,
        analytics: {
          run: {
            id: runId,
          },
          usage: {
            userHasProvidedFeedback: false,
          },
        },
      },
    })

    const wrapper = renderRenderTicketSidebarSummary()

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'Regenerate' }))

    const calls = await waitForTicketAiAssistanceSummarizeMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({
      ticketId: defaultTicket.id,
      regenerationOfId: runId,
    })
  })

  it('removes ask for feedback message on positive feedback', async () => {
    const runId = convertToGraphQLId('AIAnalyticsRun', 12345)

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        ...ticketAIAssistanceSummarizeMock,
        analytics: {
          run: {
            id: runId,
          },
          usage: {
            userHasProvidedFeedback: false,
          },
        },
      },
    })

    const wrapper = renderRenderTicketSidebarSummary()

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'Positive Feedback' }))

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    expect(wrapper.queryByText('Any feedback on this result?')).not.toBeInTheDocument()
  })

  it('removes ask for feedback message on negative feedback', async () => {
    const runId = convertToGraphQLId('AIAnalyticsRun', 12345)

    mockApplicationConfig({
      ai_provider: true,
      ai_assistance_ticket_summary: true,
    })

    mockTicketAiAssistanceSummarizeMutation({
      ticketAIAssistanceSummarize: {
        ...ticketAIAssistanceSummarizeMock,
        analytics: {
          run: {
            id: runId,
          },
          usage: {
            userHasProvidedFeedback: false,
          },
        },
      },
    })

    const wrapper = renderRenderTicketSidebarSummary()

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    await wrapper.events.click(await wrapper.findByRole('button', { name: 'Negative Feedback' }))

    await waitForTicketAiAssistanceSummarizeMutationCalls()

    expect(wrapper.queryByText('Any feedback on this result?')).not.toBeInTheDocument()
  })
})
