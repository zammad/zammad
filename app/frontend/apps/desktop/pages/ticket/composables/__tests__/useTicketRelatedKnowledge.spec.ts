// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { computed, defineComponent } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumKnowledgeBaseVisibility, EnumLinkType } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { LinkListDocument } from '#desktop/entities/link/graphql/queries/linkList.api.ts'
import { mockLinkListQuery } from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'
import { getLinkUpdatesSubscriptionHandler } from '#desktop/entities/link/graphql/subscriptions/linkUpdates.mocks.ts'
import { TicketAiRelatedKnowledgeBaseAnswersDocument } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.api.ts'
import {
  mockTicketAiRelatedKnowledgeBaseAnswersQuery,
  mockTicketAiRelatedKnowledgeBaseAnswersQueryError,
  waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls,
} from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.mocks.ts'

import { useTicketRelatedKnowledge } from '../useTicketRelatedKnowledge.ts'

const translationId = (id: number) => convertToGraphQLId('KnowledgeBase::Answer::Translation', id)

const translation = (
  id: number,
  title: string,
  {
    answerId = id,
    visibility = EnumKnowledgeBaseVisibility.Published,
    maybeLocale = null as string | null,
  } = {},
) => ({
  __typename: 'KnowledgeBaseAnswerTranslation' as const,
  id: translationId(id),
  title,
  maybeLocale,
  visibility,
  categoryTreeTranslation: [
    {
      __typename: 'KnowledgeBaseCategoryTranslation' as const,
      id: convertToGraphQLId('KnowledgeBase::Category::Translation', 1),
      title: 'Network',
    },
  ],
  answer: {
    __typename: 'KnowledgeBaseAnswer' as const,
    id: convertToGraphQLId('KnowledgeBase::Answer', answerId),
    category: { id: convertToGraphQLId('KnowledgeBase::Category', 1) },
  },
})

const linkedAnswer = (...args: Parameters<typeof translation>) => ({
  item: translation(...args),
  type: EnumLinkType.Normal,
})

const suggestedAnswer = (score: number, ...args: Parameters<typeof translation>) => ({
  score,
  translation: translation(...args),
})

const enableKnowledgeBase = ({ suggestions = true } = {}) => {
  mockApplicationConfig({
    kb_active: true,
    vectordb_enabled: true,
    ai_provider: true,
    ai_assistance_kb_answer_suggestions: suggestions,
  })
}

let api: ReturnType<typeof useTicketRelatedKnowledge>

const mountComposable = (ticket: TicketById = createDummyTicket()) =>
  renderComponent(
    defineComponent({
      setup() {
        api = useTicketRelatedKnowledge(
          computed(() => ticket),
          computed(() => ticket.id),
        )
        return () => null
      },
    }),
  )

describe('useTicketRelatedKnowledge', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
  })

  it('hands the linked answers first and the suggested ones second to the editor', async () => {
    enableKnowledgeBase()
    mockLinkListQuery({
      linkList: [
        linkedAnswer(1, 'VPN setup on company notebooks (Windows)', { maybeLocale: 'EN-US' }),
      ],
    })
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [
          suggestedAnswer(0.912, 2, 'VPN setup on company notebooks (macOS)', {
            maybeLocale: 'DE-DE',
          }),
        ],
      },
    })

    mountComposable()

    await waitFor(() => expect(api.editorRelatedAnswers().suggested).toHaveLength(1))
    await waitFor(() => expect(api.editorRelatedAnswers().linked).toHaveLength(1))

    expect(api.editorRelatedAnswers()).toEqual({
      linked: [
        expect.objectContaining({
          id: translationId(1),
          title: 'VPN setup on company notebooks (Windows)',
          maybeLocale: 'EN-US',
          categoryTreeTranslation: [expect.objectContaining({ title: 'Network' })],
        }),
      ],
      suggested: [
        expect.objectContaining({
          id: translationId(2),
          title: 'VPN setup on company notebooks (macOS)',
          maybeLocale: 'DE-DE',
          categoryTreeTranslation: [expect.objectContaining({ title: 'Network' })],
        }),
      ],
    })
  })

  it('searches with the variables of the sidebar, so both share one search', async () => {
    enableKnowledgeBase()
    mockLinkListQuery({ linkList: [] })
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    const ticket = createDummyTicket()

    mountComposable(ticket)

    const calls = await waitForTicketAiRelatedKnowledgeBaseAnswersQueryCalls()

    expect(calls).toHaveLength(1)
    expect(calls[0].variables).toEqual({
      ticketId: ticket.id,
      includeDraftsAndArchived: false,
      includeLinkedAnswers: false,
    })
  })

  it('never hands a linked answer to the editor as a suggestion, in any locale', async () => {
    enableKnowledgeBase()
    mockLinkListQuery({ linkList: [linkedAnswer(1, 'Reset your password')] })
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [
          suggestedAnswer(0.95, 1, 'Reset your password'),
          suggestedAnswer(0.9, 2, 'Passwort zurücksetzen', { answerId: 1 }),
          suggestedAnswer(0.8, 3, 'Set up 2FA'),
        ],
      },
    })

    mountComposable()

    await waitFor(() => expect(api.editorRelatedAnswers().linked).toHaveLength(1))
    await waitFor(() =>
      expect(api.editorRelatedAnswers().suggested).toEqual([
        expect.objectContaining({ id: translationId(3), title: 'Set up 2FA' }),
      ]),
    )
  })

  it('hands over the linked answers only when suggestions are switched off', async () => {
    enableKnowledgeBase({ suggestions: false })
    mockLinkListQuery({ linkList: [linkedAnswer(1, 'Reset your password')] })

    mountComposable()

    await waitFor(() => expect(api.editorRelatedAnswers().linked).toHaveLength(1))

    expect(api.editorRelatedAnswers().suggested).toEqual([])
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(0)
  })

  it('hands over no suggestions until the first result arrives', async () => {
    enableKnowledgeBase()
    mockLinkListQuery({ linkList: [] })
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [suggestedAnswer(0.8, 1, 'Set up 2FA')],
      },
    })

    mountComposable()

    expect(api.isAiSuggestedAnswersLoading.value).toBe(true)
    expect(api.editorRelatedAnswers().suggested).toEqual([])

    await waitFor(() => expect(api.editorRelatedAnswers().suggested).toHaveLength(1))
  })

  it('hands over no suggestions while the embedding is still being generated', async () => {
    enableKnowledgeBase()
    mockLinkListQuery({ linkList: [] })
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: true, answers: null },
    })

    mountComposable()

    await waitFor(() => expect(api.isAiSuggestedAnswersPending.value).toBe(true))
    expect(api.editorRelatedAnswers().suggested).toEqual([])
  })

  it('hands over the linked answers only when the search fails', async () => {
    enableKnowledgeBase()
    mockLinkListQuery({ linkList: [linkedAnswer(1, 'Reset your password')] })
    mockTicketAiRelatedKnowledgeBaseAnswersQueryError('boom', {
      type: GraphQLErrorTypes.UnknownError,
    })

    mountComposable()

    await waitFor(() => expect(api.hasAiSuggestedAnswersError.value).toBe(true))
    await waitFor(() => expect(api.editorRelatedAnswers().linked).toHaveLength(1))
    expect(api.editorRelatedAnswers().suggested).toEqual([])
  })

  it('keeps the editor up to date when the linked answers change', async () => {
    enableKnowledgeBase({ suggestions: false })
    mockLinkListQuery({ linkList: [linkedAnswer(1, 'Reset your password')] })

    mountComposable()

    const linkedTitles = computed(() =>
      api.editorRelatedAnswers().linked.map((answer) => answer.title),
    )

    await waitFor(() => expect(linkedTitles.value).toEqual(['Reset your password']))

    await getLinkUpdatesSubscriptionHandler().trigger({
      linkUpdates: {
        links: [linkedAnswer(1, 'Reset your password'), linkedAnswer(2, 'Set up 2FA')],
      },
    })

    await waitFor(() => expect(linkedTitles.value).toEqual(['Reset your password', 'Set up 2FA']))
  })

  it('requests nothing for an agent who only has customer access to the ticket', async () => {
    enableKnowledgeBase()
    mockLinkListQuery({ linkList: [] })
    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: { pending: false, answers: [] },
    })

    mountComposable(createDummyTicket({ defaultPolicy: { update: true, agentReadAccess: false } }))

    await flushPromises()

    expect(api.isKbActive.value).toBe(false)
    expect(api.editorRelatedAnswers()).toEqual({
      linked: [],
      suggested: [],
    })
    expect(getGraphQLMockCalls(LinkListDocument)).toHaveLength(0)
    expect(getGraphQLMockCalls(TicketAiRelatedKnowledgeBaseAnswersDocument)).toHaveLength(0)
  })
})
