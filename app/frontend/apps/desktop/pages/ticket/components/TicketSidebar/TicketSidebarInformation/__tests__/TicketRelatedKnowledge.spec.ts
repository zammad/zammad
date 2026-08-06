// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref } from 'vue'

import '#tests/graphql/builders/mocks.ts'
import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseAnswerTranslationFragment,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { TICKET_SIDEBAR_SYMBOL } from '#desktop/pages/ticket/composables/useTicketSidebar.ts'
import {
  mockLinkRemoveMutation,
  waitForLinkRemoveMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/linkRemove.mocks.ts'

import TicketRelatedKnowledge, {
  type Props,
} from '../TicketSidebarInformationContent/TicketRelatedKnowledge.vue'

// The detailed behavior of the pieces this component wires together (AI draft generation, AI
//   suggestions, the answer picker, linked answers) is covered by the co-located sub-component
//   specs under TicketRelatedKnowledge/__tests__. Here we only assert the parent delegates to the
//   right piece for a given permission/config/link state. The already-linked answers are fetched
//   by the parent sidebar component and handed in via props.

const ticket = createDummyTicket()

const TARGET_TYPE = 'KnowledgeBase::Answer::Translation'

const enableKnowledgeBaseAi = () => {
  mockApplicationConfig({
    kb_active: true,
    ai_provider: true,
    ai_assistance_kb_answer_suggestions: true,
    ai_assistance_kb_answer_from_ticket_generation: true,
  })
}

// `answerId` defaults to the translation's own id; pass it to build a second locale of one answer.
const buildLinkedAnswer = (
  id: number,
  title: string,
  answerId = id,
): KnowledgeBaseAnswerTranslationFragment => ({
  __typename: 'KnowledgeBaseAnswerTranslation',
  id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
  title,
  visibility: EnumKnowledgeBaseVisibility.Published,
  categoryTreeTranslation: [
    {
      __typename: 'KnowledgeBaseCategoryTranslation',
      id: convertToGraphQLId('KnowledgeBase::Category::Translation', id),
      title: 'Account',
    },
  ],
  content: {
    __typename: 'KnowledgeBaseAnswerTranslationContent',
    bodyExcerpt: `Excerpt for ${title}`,
  },
  answer: {
    __typename: 'KnowledgeBaseAnswer',
    id: convertToGraphQLId('KnowledgeBase::Answer', answerId),
    archivedAt: null,
    publishedAt: null,
    internalAt: null,
    tags: null,
    category: {
      __typename: 'KnowledgeBaseCategory',
      id: convertToGraphQLId('KnowledgeBase::Category', id),
      title: 'Account',
      knowledgeBase: { __typename: 'KnowledgeBase', id: convertToGraphQLId('KnowledgeBase', 1) },
    },
  },
  kbLocale: {
    __typename: 'KnowledgeBaseLocale',
    systemLocale: { __typename: 'Locale', locale: 'en-us', name: 'English' },
  },
})

const renderRelatedKnowledge = (
  props: Partial<Props> & {
    isTicketEditable?: boolean
  } = {},
) => {
  const { isTicketEditable = true, ...componentProps } = props

  return renderComponent(TicketRelatedKnowledge, {
    props: {
      linkedAnswers: [],
      linkedAnswerIds: [],
      targetType: TARGET_TYPE,
      showAiSuggestedAnswers: false,
      showRelevanceScore: false,
      aiSuggestedAnswers: [],
      isAiSuggestedAnswersLoading: false,
      isAiSuggestedAnswersPending: false,
      hasAiSuggestedAnswersError: false,
      aiSuggestedAnswersErrorDetail: null,
      ...componentProps,
    },
    form: true,
    router: true,
    provide: [
      [
        TICKET_KEY,
        {
          ticketId: computed(() => ticket.id),
          ticket: computed(() => ticket),
          ticketInternalId: computed(() => ticket.internalId),
          isTicketEditable: computed(() => isTicketEditable),
        },
      ],
      // The AI draft action hands the active sidebar to the flyout it opens.
      [TICKET_SIDEBAR_SYMBOL, { activeSidebar: ref('information') }],
    ],
  })
}

describe('TicketRelatedKnowledge', () => {
  it('shows the AI draft action and the AI suggestions when the agent may use them', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.editor'])
    enableKnowledgeBaseAi()

    const wrapper = renderRelatedKnowledge({ showAiSuggestedAnswers: true })

    expect(await wrapper.findByText('Suggested by AI')).toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Add AI draft' })).toBeInTheDocument()
  })

  it('shows the AI suggestions but not the AI draft action for an agent without editor permission', async () => {
    // A reader can see AI-suggested answers (knowledge_base.*), but drafting a new answer
    //   additionally requires knowledge_base.editor.
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    enableKnowledgeBaseAi()

    const wrapper = renderRelatedKnowledge({ showAiSuggestedAnswers: true })

    expect(await wrapper.findByText('Suggested by AI')).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Add AI draft' })).not.toBeInTheDocument()
  })

  it('renders the ticket’s already-linked answers', async () => {
    mockPermissions(['ticket.agent'])

    const wrapper = renderRelatedKnowledge({
      linkedAnswers: [buildLinkedAnswer(1, 'Reset your password')],
      linkedAnswerIds: [convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)],
    })

    expect(await wrapper.findByText('Linked')).toBeInTheDocument()
    expect(await wrapper.findByText('Reset your password')).toBeInTheDocument()
  })

  it('unlinks an answer and re-runs the AI suggestions search, so it can be suggested again', async () => {
    mockPermissions(['ticket.agent'])
    enableKnowledgeBaseAi()
    mockLinkRemoveMutation({ linkRemove: { success: true } })

    const wrapper = renderRelatedKnowledge({
      linkedAnswers: [buildLinkedAnswer(1, 'Reset your password')],
      linkedAnswerIds: [convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)],
      showAiSuggestedAnswers: true,
    })

    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'Unlink knowledge base answer' }),
    )

    const calls = await waitForLinkRemoveMutationCalls()
    expect(calls.at(-1)?.variables).toEqual({
      input: {
        sourceId: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
        targetId: ticket.id,
        type: 'normal',
      },
    })

    // The search runs on the server and excluded the answer while it was linked, so the
    //   unlinked answer can only reappear under "Suggested by AI" by re-running it.
    expect(wrapper.emitted('refresh-ai-suggested-answers')).toHaveLength(1)
  })

  it('never lists an already-linked answer as an AI suggestion', async () => {
    mockPermissions(['ticket.agent'])
    enableKnowledgeBaseAi()

    const translation = buildLinkedAnswer(1, 'Duplicate charge on latest invoice')

    // A suggestions response that was still in flight while the answer got linked carries it
    //   along; it must not show up under both "Linked" and "Suggested by AI".
    const wrapper = renderRelatedKnowledge({
      linkedAnswers: [translation],
      linkedAnswerIds: [translation.id],
      showAiSuggestedAnswers: true,
      aiSuggestedAnswers: [
        {
          __typename: 'TicketAIRelatedKnowledgeBaseAnswer',
          score: 95,
          translation,
        },
      ],
    })

    expect(await wrapper.findByText('Suggested by AI')).toBeInTheDocument()

    // Listed once, under "Linked" — the suggestions fall back to their empty state.
    expect(await wrapper.findAllByText('Duplicate charge on latest invoice')).toHaveLength(1)
    expect(wrapper.getByText('No suggestions.')).toBeInTheDocument()
  })

  it('does not suggest another locale of an already-linked answer', async () => {
    mockPermissions(['ticket.agent'])
    enableKnowledgeBaseAi()

    const ANSWER_ID = 7
    const linkedTranslation = buildLinkedAnswer(1, 'Doppelte Abbuchung', ANSWER_ID)
    const otherLocaleTranslation = buildLinkedAnswer(2, 'Duplicate charge', ANSWER_ID)

    // The server excludes a linked answer in every locale, so a sibling translation is no
    //   suggestion either — matching on the translation alone would let it slip through.
    const wrapper = renderRelatedKnowledge({
      linkedAnswers: [linkedTranslation],
      linkedAnswerIds: [linkedTranslation.id],
      showAiSuggestedAnswers: true,
      aiSuggestedAnswers: [
        {
          __typename: 'TicketAIRelatedKnowledgeBaseAnswer',
          score: 95,
          translation: otherLocaleTranslation,
        },
      ],
    })

    expect(await wrapper.findByText('Suggested by AI')).toBeInTheDocument()
    expect(await wrapper.findByText('Doppelte Abbuchung')).toBeInTheDocument()
    expect(wrapper.queryByText('Duplicate charge')).not.toBeInTheDocument()
    expect(wrapper.getByText('No suggestions.')).toBeInTheDocument()
  })

  it('hides the link action when the ticket is not editable', () => {
    mockPermissions(['ticket.agent'])

    const wrapper = renderRelatedKnowledge({ isTicketEditable: false })

    expect(
      wrapper.queryByRole('button', { name: 'Link knowledge base answer' }),
    ).not.toBeInTheDocument()
  })

  it('shows neither the AI draft action nor the AI suggestions without knowledge base AI access', () => {
    mockPermissions(['ticket.agent'])

    const wrapper = renderRelatedKnowledge()

    expect(wrapper.queryByText('Suggested by AI')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Add AI draft' })).not.toBeInTheDocument()
  })
})
