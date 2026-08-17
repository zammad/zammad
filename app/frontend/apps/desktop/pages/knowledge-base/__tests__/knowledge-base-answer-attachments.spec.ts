// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { imageViewerOptions } from '#shared/composables/useImageViewer.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import type { KnowledgeBaseAnswerQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import {
  mockKnowledgeBaseAnswerQuery,
  waitForKnowledgeBaseAnswerQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'

const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 5)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CONTENT_ID = convertToGraphQLId('KnowledgeBase::Answer::Translation::Content', 5)

const ANSWER_PATH: `/${string}` = `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(ANSWER_ID)}`

type Answer = NonNullable<KnowledgeBaseAnswerQuery['knowledgeBaseAnswer']>

const attachment = (internalId: number, name: string, type: string) => ({
  __typename: 'StoredFile' as const,
  id: convertToGraphQLId('Store', internalId),
  internalId,
  name,
  type,
  size: 248_000,
  preferences: { 'Content-Type': type },
})

const mockAnswer = (attachments: Answer['attachments']) =>
  mockKnowledgeBaseAnswerQuery({
    knowledgeBaseAnswer: {
      id: ANSWER_ID,
      title: 'Some Knowledge Base Answer',
      content: {
        __typename: 'KnowledgeBaseAnswerTranslationContent',
        id: CONTENT_ID,
        bodyWithUrls: '<p>Some answer body.</p>',
      },
      visibility: EnumKnowledgeBaseVisibility.Published,
      translationMissing: false,
      internalAt: null,
      publishedAt: '2026-08-01T10:00:00Z',
      archivedAt: null,
      editedAt: null,
      editedBy: null,
      navigation: null,
      attachments,
      category: {
        id: CATEGORY_ID,
        breadcrumb: [
          {
            id: CATEGORY_ID,
            title: 'Root Category',
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
          },
        ],
      },
    },
  } as KnowledgeBaseAnswerQuery)

describe('knowledge base answer attachments', () => {
  beforeEach(() => {
    mockApplicationConfig({
      api_path: '/api/v1',
      kb_active_publicly: true,
      'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'],
    })
    mockPermissions(['knowledge_base.reader'])

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

  it('lists the attachments of the answer below its body', async () => {
    mockAnswer([
      attachment(1, 'IMG_1234.png', 'image/png'),
      attachment(2, 'SomeMeetingFile.ics', 'text/calendar'),
      attachment(3, 'SomeTableFile.csv', 'text/csv'),
    ])

    const view = await visitView(ANSWER_PATH)

    const list = await view.findByRole('list', { name: 'Attachments' })

    expect(list.querySelectorAll('li')).toHaveLength(3)
    expect(view.getByText('IMG_1234')).toBeInTheDocument()
    expect(view.getByText('SomeMeetingFile')).toBeInTheDocument()
    expect(view.getByText('SomeTableFile')).toBeInTheDocument()

    // The body comes first, the attachments after it.
    expect(
      list.compareDocumentPosition(view.getByText('Some answer body.')) &
        Node.DOCUMENT_POSITION_PRECEDING,
    ).toBeTruthy()
  })

  it('builds the download URL from the internal id', async () => {
    mockAnswer([attachment(3, 'SomeTableFile.csv', 'text/csv')])

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByRole('link', { name: 'Download SomeTableFile.csv' })).toHaveAttribute(
      'href',
      '/api/v1/attachments/3?disposition=attachment',
    )
  })

  it('renders nothing when the answer has no attachments', async () => {
    mockAnswer([])

    const view = await visitView(ANSWER_PATH)

    await waitForKnowledgeBaseAnswerQueryCalls()

    await waitFor(() => {
      expect(view.queryByRole('list', { name: 'Attachments' })).not.toBeInTheDocument()
    })
  })

  it('opens an image attachment in the image viewer', async () => {
    mockAnswer([attachment(1, 'IMG_1234.png', 'image/png')])

    const view = await visitView(ANSWER_PATH)

    await view.events.click(await view.findByRole('button', { name: 'Preview IMG_1234.png' }))

    await waitFor(() => {
      expect(imageViewerOptions.value.visible).toBe(true)
    })

    expect(imageViewerOptions.value.images.at(0)).toEqual(
      expect.objectContaining({ title: 'IMG_1234.png' }),
    )
  })
})
