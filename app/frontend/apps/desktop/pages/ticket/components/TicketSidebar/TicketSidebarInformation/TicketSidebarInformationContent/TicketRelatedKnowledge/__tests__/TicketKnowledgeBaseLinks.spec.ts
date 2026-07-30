// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseAnswerTranslationFragment,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import TicketKnowledgeBaseLinks from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketRelatedKnowledge/TicketKnowledgeBaseLinks.vue'
import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import {
  mockLinkRemoveMutation,
  waitForLinkRemoveMutationCalls,
} from '#desktop/pages/ticket/graphql/mutations/linkRemove.mocks.ts'
import { mockLinkListQuery } from '#desktop/pages/ticket/graphql/queries/linkList.mocks.ts'

const ticketId = convertToGraphQLId('Ticket', 1)

const KNOWLEDGE_BASE_ID = convertToGraphQLId('KnowledgeBase', 1)
const KNOWLEDGE_BASE_LOCALE = 'en-us'

const TARGET_TYPE = 'KnowledgeBase::Answer::Translation'

// The popover the trigger wraps reads the full translation, so give it a complete
//   shape even though these tests only assert the trigger's link and icon.
const linkedAnswer = (
  id: number,
  title: string,
  visibility = EnumKnowledgeBaseVisibility.Published,
): KnowledgeBaseAnswerTranslationFragment => ({
  __typename: 'KnowledgeBaseAnswerTranslation',
  id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
  title,
  visibility,
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
    id: convertToGraphQLId('KnowledgeBase::Answer', id),
    archivedAt: null,
    publishedAt: null,
    internalAt: null,
    tags: null,
    category: {
      __typename: 'KnowledgeBaseCategory',
      id: convertToGraphQLId('KnowledgeBase::Category', id),
      title: 'Account',
      knowledgeBase: { __typename: 'KnowledgeBase', id: KNOWLEDGE_BASE_ID },
    },
  },
  kbLocale: {
    __typename: 'KnowledgeBaseLocale',
    systemLocale: { __typename: 'Locale', locale: KNOWLEDGE_BASE_LOCALE, name: 'English' },
  },
})

const renderLinks = (
  linkedAnswers = [linkedAnswer(1, 'Reset your password')],
  isTicketEditable = true,
) =>
  renderComponent(TicketKnowledgeBaseLinks, {
    props: {
      linkedAnswers,
      targetType: TARGET_TYPE,
      isTicketEditable,
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

describe('TicketKnowledgeBaseLinks', () => {
  beforeEach(() => {
    mockLinkListQuery({ linkList: [] })

    // The links are built from the browsed knowledge base (its internal id and
    //   current locale), which the store loads via this query.
    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: KNOWLEDGE_BASE_ID,
        currentLocale: { systemLocale: { locale: KNOWLEDGE_BASE_LOCALE } },
      },
    })
  })

  it('renders every linked answer as a link with its visibility icon', async () => {
    const wrapper = renderLinks([
      linkedAnswer(1, 'Reset your password', EnumKnowledgeBaseVisibility.Published),
      linkedAnswer(2, 'Internal runbook', EnumKnowledgeBaseVisibility.Internal),
    ])

    expect(wrapper.getByText('Linked')).toBeInTheDocument()

    const first = await wrapper.findByText('Reset your password')
    expect(first).toBeInTheDocument()
    expect(first.closest('a')).toHaveAttribute(
      'href',
      expect.stringContaining(
        `#knowledge_base/${getIdFromGraphQLId(KNOWLEDGE_BASE_ID)}/locale/${KNOWLEDGE_BASE_LOCALE}/answer/${getIdFromGraphQLId(linkedAnswer(1, '').id)}`,
      ),
    )

    expect(wrapper.getByIconName('kb-published')).toBeInTheDocument()
    expect(wrapper.getByIconName('kb-internal')).toBeInTheDocument()
  })

  it('unlinks an answer when its unlink action is clicked', async () => {
    mockLinkRemoveMutation({ linkRemove: { success: true } })

    const wrapper = renderLinks([linkedAnswer(1, 'Reset your password')])

    await wrapper.events.click(
      await wrapper.findByRole('button', { name: 'Unlink knowledge base answer' }),
    )

    const calls = await waitForLinkRemoveMutationCalls()
    expect(calls.at(-1)?.variables).toEqual({
      input: {
        sourceId: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
        targetId: ticketId,
        type: 'normal',
      },
    })
  })
})
