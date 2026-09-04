// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { imageViewerOptions } from '#shared/composables/useImageViewer.ts'
import { OnlineNotificationSeenDocument } from '#shared/entities/online-notification/graphql/mutations/seen.api.ts'
import { waitForOnlineNotificationSeenMutationCalls } from '#shared/entities/online-notification/graphql/mutations/seen.mocks.ts'
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
const TRANSLATION_ID = convertToGraphQLId('KnowledgeBase::Answer::Translation', 7)

const ANSWER_PATH: `/${string}` = `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(ANSWER_ID)}`

type Answer = NonNullable<KnowledgeBaseAnswerQuery['knowledgeBaseAnswer']>
type AnswerContent = NonNullable<Answer['translation']>['content']

const mockAnswer = (content: AnswerContent) =>
  mockKnowledgeBaseAnswerQuery({
    knowledgeBaseAnswer: {
      id: ANSWER_ID,
      visibility: EnumKnowledgeBaseVisibility.Published,
      internalAt: null,
      publishedAt: '2026-08-01T10:00:00Z',
      archivedAt: null,
      translation: {
        id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
        title: 'Some Knowledge Base Answer',
        content,
        editedAt: null,
        editedBy: null,
        navigation: null,
      },
      category: {
        id: CATEGORY_ID,
        breadcrumb: [
          {
            id: CATEGORY_ID,
            translation: { title: 'Root Category' },
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
          },
        ],
      },
    },
  } as KnowledgeBaseAnswerQuery)

const mockBody = (bodyWithUrls: string) =>
  mockAnswer({
    __typename: 'KnowledgeBaseAnswerTranslationContent',
    id: CONTENT_ID,
    bodyWithUrls,
  } as AnswerContent)

describe('knowledge base answer content', () => {
  beforeEach(() => {
    mockApplicationConfig({
      kb_active_publicly: true,
      // Decides which inline images the image viewer considers previewable.
      'active_storage.content_types_allowed_inline': ['image/png', 'image/jpeg'],
    })
    mockPermissions(['knowledge_base.reader'])

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        translation: { title: 'My Knowledge Base' },
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

  it('renders the body of the answer', async () => {
    mockBody('<h1>Introduction</h1><p>The following describes our workflow.</p>')

    const view = await visitView(ANSWER_PATH)

    expect(await view.findByRole('heading', { name: 'Introduction' })).toBeInTheDocument()
    expect(view.getByText('The following describes our workflow.')).toBeInTheDocument()
  })

  it('renders the body with the article content styling hooks', async () => {
    mockBody('<h1>Introduction</h1><p>Some <strong>answer</strong> body.</p>')

    const view = await visitView(ANSWER_PATH)

    await view.findByRole('heading', { name: 'Introduction' })

    const body = view.container.querySelector('.Content .inner-article-body')

    expect(body).toBeInTheDocument()
    expect(body).not.toHaveAttribute('dir')
    expect(body?.children[0]).toHaveAttribute('dir', 'auto')
    expect(body?.children[1]).toHaveAttribute('dir', 'auto')
    expect(body?.querySelector('strong')).toHaveAttribute('dir', 'auto')
  })

  it('renders no body when the answer has no content', async () => {
    mockAnswer(null as unknown as AnswerContent)

    const view = await visitView(ANSWER_PATH)

    await waitForKnowledgeBaseAnswerQueryCalls()

    // Anchor on the rendered answer, so the absence check runs after the view rendered. Both
    //   the full and compact headers are mounted, so the title appears more than once.
    expect(await view.findAllByText('Some Knowledge Base Answer')).not.toHaveLength(0)
    expect(view.container.querySelector('.inner-article-body')).not.toBeInTheDocument()
  })

  // The server resolves a link to another answer into this app's own answer route (see
  //   KnowledgeBase::Answer::Translation#desktop_url), so following one stays inside the app
  //   instead of leaving for the public help page.
  it('navigates in-app when a link to another answer is followed', async () => {
    mockBody(
      '<p>See <a href="/desktop/knowledge-base/locale/en-us/answer/9" data-target-type="knowledge-base-answer" data-target-id="12">the other answer</a>.</p>',
    )

    const view = await visitView(ANSWER_PATH)

    await view.events.click(await view.findByRole('link', { name: 'the other answer' }))

    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us/answer/9')
    })
  })

  // The legacy stack addresses an answer as
  //   `#knowledge_base/<kb id>/locale/<locale>/answer/<answer id>`; links in that shape still
  //   arrive here (online notifications build it), so the route redirects them.
  it('opens the answer from a legacy knowledge base URL', async () => {
    mockBody('<h1>Introduction</h1>')

    const view = await visitView(
      `/knowledge_base/1/locale/en-us/answer/${getIdFromGraphQLId(ANSWER_ID)}`,
    )

    expect(await view.findByRole('heading', { name: 'Introduction' })).toBeInTheDocument()
    expect(view).toHaveCurrentUrl(ANSWER_PATH)
  })

  it('opens an inline image of the body in the image viewer', async () => {
    mockBody('<p>Some answer body.</p><img src="/api/v1/attachments/1" alt="inline.png">')

    const view = await visitView(ANSWER_PATH)

    await view.findByText('Some answer body.')

    const image = view.container.querySelector<HTMLImageElement>('.inner-article-body img')

    expect(image).toBeInTheDocument()

    await view.events.click(image as HTMLImageElement)

    await waitFor(() => {
      expect(imageViewerOptions.value.visible).toBe(true)
    })

    expect(imageViewerOptions.value.images.at(0)).toEqual(
      expect.objectContaining({ title: 'inline.png' }),
    )
  })

  // Opening a translation is what marks a notification about it as read, and it has to happen in
  //   this view rather than in the notification list: the mobile app has no answer view, so its
  //   list links in here - a full page load that drops a mutation the list itself started.
  it('marks a notification about the opened translation as seen', async () => {
    mockKnowledgeBaseAnswerQuery({
      knowledgeBaseAnswer: { translation: { id: TRANSLATION_ID } },
    })

    await visitView(ANSWER_PATH)

    const calls = await waitForOnlineNotificationSeenMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({ objectId: TRANSLATION_ID })
  })

  it('marks nothing as seen when the answer has no translation in this locale', async () => {
    mockKnowledgeBaseAnswerQuery({ knowledgeBaseAnswer: { translation: null } })

    await visitView(ANSWER_PATH)

    await waitForKnowledgeBaseAnswerQueryCalls()

    expect(getGraphQLMockCalls(OnlineNotificationSeenDocument)).toHaveLength(0)
  })
})
