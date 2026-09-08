// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  EnumKnowledgeBaseVisibility,
  EnumSearchableModels,
  EnumTicketStateColorCode,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockDetailSearchQuery } from '#desktop/components/Search/graphql/queries/detailSearch.mocks.ts'
import { mockSearchCountsQuery } from '#desktop/components/Search/graphql/queries/searchCounts.mocks.ts'

describe('search view', () => {
  it('has no accessibility violations in main content', async () => {
    mockPermissions(['ticket.agent'])

    mockSearchCountsQuery({
      searchCounts: [
        {
          model: EnumSearchableModels.User,
          totalCount: 111,
        },
        {
          model: EnumSearchableModels.Organization,
          totalCount: 222,
        },
      ],
    })

    mockDetailSearchQuery({
      search: {
        totalCount: 1,
        items: [
          {
            title: 'Ticket 1',
            id: convertToGraphQLId('Ticket', 1),
            internalId: 1,
            customer: {
              id: convertToGraphQLId('User', 2),
              fullname: 'Nicole Braun User',
            },
            group: {
              id: convertToGraphQLId('Group', 6),
              name: 'Group 1',
            },
            state: {
              id: convertToGraphQLId('State', 2),
              name: 'open',
            },
            stateColorCode: EnumTicketStateColorCode.Open,
            priority: {
              id: convertToGraphQLId('TicketPriority', 2),
              name: '2 normal',
              uiColor: null,
            },
            createdAt: '2025-02-20T10:21:14Z',
            __typename: 'Ticket',
          },
        ],
      },
    })

    const view = await visitView('/search/Nicole')

    await expect(view.container).toBeAccessible()
  })

  // The knowledge base answer tab renders a table whose columns are declared locally rather than
  //   resolved from the object manager, and whose visibility cell is a custom slot — so it is swept
  //   separately from the ticket table above.
  it('has no accessibility violations on the knowledge base answer tab', async () => {
    mockPermissions(['ticket.agent', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })

    mockSearchCountsQuery({
      searchCounts: [
        {
          model: EnumSearchableModels.KnowledgeBaseAnswerTranslation,
          totalCount: 1,
        },
      ],
    })

    mockDetailSearchQuery({
      search: {
        totalCount: 1,
        items: [
          {
            __typename: 'KnowledgeBaseAnswerTranslation',
            id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 7),
            title: 'Ocarina tuning guide',
            updatedAt: '2025-02-20T10:21:14Z',
            visibility: EnumKnowledgeBaseVisibility.Published,
            answer: {
              __typename: 'KnowledgeBaseAnswer',
              id: convertToGraphQLId('KnowledgeBase::Answer', 42),
              category: {
                __typename: 'KnowledgeBaseCategory',
                id: convertToGraphQLId('KnowledgeBase::Category', 3),
              },
            },
            kbLocale: {
              __typename: 'KnowledgeBaseLocale',
              systemLocale: { __typename: 'Locale', locale: 'en-us' },
            },
          },
        ],
      },
    })

    const view = await visitView(
      `/search/Ocarina?entity=${EnumSearchableModels.KnowledgeBaseAnswerTranslation}`,
    )

    expect(await view.findByRole('tab', { name: /Knowledge base answer/ })).toBeInTheDocument()

    await expect(view.container).toBeAccessible()
  })
})
