// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  EnumKnowledgeBaseVisibility,
  EnumLinkType,
  EnumTicketStateColorCode,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockLinkListQuery,
  waitForLinkListQueryCalls,
} from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'

import KnowledgeBaseAnswerLinkedTickets from '../KnowledgeBaseAnswerLinkedTickets.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../../types.ts'

const translationId = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)

const answer = {
  __typename: 'KnowledgeBaseAnswer',
  id: convertToGraphQLId('KnowledgeBase::Answer', 1),
  title: 'Some Answer',
  visibility: EnumKnowledgeBaseVisibility.Published,
  translationId,
  translationMissing: false,
  internalAt: null,
  publishedAt: null,
  archivedAt: null,
  editedAt: null,
  editedBy: null,
  navigation: null,
  content: {
    __typename: 'KnowledgeBaseAnswerTranslationContent',
    bodyWithUrls: 'Et non omnis. Iste rerum ut. Reiciendis officia cumque.',
    id: convertToGraphQLId('KnowledgeBase::AnswerTranslationContent', 1),
  },
  category: {
    __typename: 'KnowledgeBaseCategory',
    id: convertToGraphQLId('KnowledgeBase::Category', 1),
    breadcrumb: [],
  },
  tags: [],
  attachments: [],
} as KnowledgeBaseAnswerHeader

const linkedTicket = (
  internalId: number,
  title: string,
  stateColorCode: EnumTicketStateColorCode,
) => ({
  item: {
    __typename: 'Ticket' as const,
    id: convertToGraphQLId('Ticket', internalId),
    internalId,
    title,
    stateColorCode,
  },
  type: EnumLinkType.Normal,
})

const renderLinkedTickets = (props: { answer: KnowledgeBaseAnswerHeader } = { answer }) =>
  renderComponent(KnowledgeBaseAnswerLinkedTickets, {
    props,
    store: true,
    router: true,
  })

describe('KnowledgeBaseAnswerLinkedTickets', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockLinkListQuery({
      linkList: [
        linkedTicket(
          1,
          'Printer on the second floor jams every other page',
          EnumTicketStateColorCode.Open,
        ),
        linkedTicket(
          2,
          'VPN disconnects after roughly ten minutes',
          EnumTicketStateColorCode.Pending,
        ),
      ],
    })
  })

  it('labels the section as related tickets', async () => {
    const view = renderLinkedTickets()

    expect(await view.findByText('Related tickets')).toBeInTheDocument()
  })

  // The links belong to the translation of the browsed locale, not to the answer.
  it('looks the links up by the answer translation', async () => {
    renderLinkedTickets()

    const calls = await waitForLinkListQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({ objectId: translationId, targetType: 'Ticket' })
  })

  it('renders a row per linked ticket, linking to it', async () => {
    const view = renderLinkedTickets()

    const links = await view.findAllByRole('link')

    expect(links).toHaveLength(2)

    expect(links[0]).toHaveAccessibleName('Printer on the second floor jams every other page')
    expect(links[0]).toHaveAttribute('href', '/tickets/1')

    expect(links[1]).toHaveAccessibleName('VPN disconnects after roughly ten minutes')
    expect(links[1]).toHaveAttribute('href', '/tickets/2')
  })

  it('shows the state of every linked ticket', async () => {
    const view = renderLinkedTickets()

    await view.findAllByRole('link')

    const states = view.getAllByRole('status')

    expect(states[0]).toHaveAttribute('aria-roledescription', '(ticket status: open)')
    expect(states[1]).toHaveAttribute('aria-roledescription', '(ticket status: pending)')
  })

  it('states that the answer has no links yet', async () => {
    mockLinkListQuery({ linkList: [] })

    const view = renderLinkedTickets()

    expect(await view.findByText('No links added yet.')).toBeInTheDocument()
  })

  // An answer without any translation has nothing links could hang off, so the
  //   lookup never runs and the section stays empty.
  it('lists no ticket for an answer without a translation', async () => {
    const view = renderLinkedTickets({
      answer: { ...answer, translationId: null } as KnowledgeBaseAnswerHeader,
    })

    expect(await view.findByText('No links added yet.')).toBeInTheDocument()

    await waitFor(() => {
      expect(view.queryAllByRole('link')).toHaveLength(0)
    })
  })
})
