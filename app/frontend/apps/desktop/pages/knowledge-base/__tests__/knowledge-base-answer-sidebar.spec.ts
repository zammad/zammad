// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumLinkType } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswerQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'
import {
  mockLinkListQuery,
  waitForLinkListQueryCalls,
} from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'

const ANSWER_PATH = '/knowledge-base/locale/en-us/answer/1'

const ANSWER_TRANSLATION_ID = convertToGraphQLId('KnowledgeBase::Answer::Translation', 1)

describe('knowledge base answer sidebar', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        title: 'My Knowledge Base',
        iconset: 'default',
        isPubliclyAvailable: true,
        isVisiblePublicly: true,
        kbLocales: [
          {
            id: convertToGraphQLId('KnowledgeBase::Locale', 1),
            primary: true,
            systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
          },
        ],
        currentLocale: {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })
  })

  it('renders the content sidebar', async () => {
    const view = await visitView(ANSWER_PATH)

    expect(await view.findByRole('complementary', { name: 'Content sidebar' })).toBeInTheDocument()
  })

  it('lists the tags of the answer', async () => {
    mockKnowledgeBaseAnswerQuery({ knowledgeBaseAnswer: { tags: ['vip', 'billing'] } })

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByRole('link', { name: 'vip' })).toHaveAttribute(
      'href',
      `/desktop/search/${encodeURI('tags:"vip"')}?entity=Ticket`,
    )
    expect(view.getByRole('link', { name: 'billing' })).toBeInTheDocument()
  })

  it('states that the answer has no tags yet', async () => {
    mockKnowledgeBaseAnswerQuery({ knowledgeBaseAnswer: { tags: [] } })

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByText('No tags added yet.')).toBeInTheDocument()
  })

  it('lists the tickets linked to the answer translation', async () => {
    mockKnowledgeBaseAnswerQuery({
      knowledgeBaseAnswer: { translationId: ANSWER_TRANSLATION_ID },
    })

    mockLinkListQuery({
      linkList: [
        {
          item: {
            __typename: 'Ticket',
            id: convertToGraphQLId('Ticket', 1),
            internalId: 1,
            title: 'Printer on the second floor jams every other page',
          },
          type: EnumLinkType.Normal,
        },
      ],
    })

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByText('Related tickets')).toBeInTheDocument()
    expect(
      await view.findByRole('link', { name: 'Printer on the second floor jams every other page' }),
    ).toHaveAttribute('href', '/desktop/tickets/1')

    const calls = await waitForLinkListQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      objectId: ANSWER_TRANSLATION_ID,
      targetType: 'Ticket',
    })
  })

  it('states that the answer has no linked tickets yet', async () => {
    mockLinkListQuery({ linkList: [] })

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByText('No links added yet.')).toBeInTheDocument()
  })
})
