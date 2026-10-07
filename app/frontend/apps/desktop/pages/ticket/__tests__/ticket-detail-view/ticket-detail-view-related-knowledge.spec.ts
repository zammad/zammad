// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumKnowledgeBaseVisibility, EnumLinkType } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockLinkListQuery } from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'
import { getLinkUpdatesSubscriptionHandler } from '#desktop/entities/link/graphql/subscriptions/linkUpdates.mocks.ts'
import { mockTicketAiRelatedKnowledgeBaseAnswersQuery } from '#desktop/pages/ticket/graphql/queries/ticketAIRelatedKnowledgeBaseAnswers.mocks.ts'

const KB_TARGET_TYPE = 'KnowledgeBase::Answer::Translation'

const translation = (id: number, title: string) => ({
  __typename: 'KnowledgeBaseAnswerTranslation' as const,
  id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
  title,
  visibility: EnumKnowledgeBaseVisibility.Internal,
  answer: {
    __typename: 'KnowledgeBaseAnswer' as const,
    id: convertToGraphQLId('KnowledgeBase::Answer', id),
    category: { id: convertToGraphQLId('KnowledgeBase::Category', 1) },
  },
})

const linkedAnswer = (id: number, title: string) => ({
  item: translation(id, title),
  type: EnumLinkType.Normal,
})

const getRelatedAnswers = () => {
  const body = getNode('form-ticket-edit-1')?.find('body')
  const { meta } = body!.context as unknown as FieldEditorProps

  return meta!.mentionKnowledgeBase!.relatedAnswers!()
}

describe('Ticket detail view related knowledge', () => {
  it('hands linked and suggested answers to the reply editor while another sidebar is open', async () => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({
      kb_active: true,
      vectordb_enabled: true,
      ai_provider: true,
      ai_assistance_kb_answer_suggestions: true,
    })

    mockTicketQuery({ ticket: createDummyTicket() })

    mockLinkListQuery(({ targetType }) => ({
      linkList:
        targetType === KB_TARGET_TYPE
          ? [linkedAnswer(1, 'VPN setup on company notebooks (Windows)')]
          : [],
    }))

    mockTicketAiRelatedKnowledgeBaseAnswersQuery({
      ticketAIRelatedKnowledgeBaseAnswers: {
        pending: false,
        answers: [{ score: 0.9, translation: translation(2, 'VPN troubleshooting') }],
      },
    })

    const view = await visitView('/tickets/1')

    await view.events.click(await view.findByRole('button', { name: 'Customer' }))

    expect(view.queryByRole('heading', { name: 'Related knowledge' })).not.toBeInTheDocument()

    await view.events.click(await view.findByRole('button', { name: 'Add internal note' }))

    await getNode('form-ticket-edit-1')?.settled

    await waitFor(() =>
      expect(getRelatedAnswers()).toEqual({
        linked: [expect.objectContaining({ title: 'VPN setup on company notebooks (Windows)' })],
        suggested: [expect.objectContaining({ title: 'VPN troubleshooting' })],
      }),
    )

    // The linked answers stay live without the information sidebar.
    await getLinkUpdatesSubscriptionHandler().trigger({
      linkUpdates: {
        links: [
          linkedAnswer(1, 'VPN setup on company notebooks (Windows)'),
          linkedAnswer(3, 'VPN setup on company notebooks (macOS)'),
        ],
      },
    })

    await waitFor(() =>
      expect(getRelatedAnswers().linked.map((answer) => answer.title)).toEqual([
        'VPN setup on company notebooks (Windows)',
        'VPN setup on company notebooks (macOS)',
      ]),
    )
  })
})
