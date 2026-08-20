// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import type { KnowledgeBaseAnswerQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswerQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'

const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 5)
const PREVIOUS_ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 4)
const NEXT_ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 6)
const ROOT_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

const ANSWER_PATH = `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(ANSWER_ID)}`

type Answer = NonNullable<KnowledgeBaseAnswerQuery['knowledgeBaseAnswer']>

const mockAnswer = (overrides: Partial<Answer> = {}) =>
  mockKnowledgeBaseAnswerQuery({
    knowledgeBaseAnswer: {
      id: ANSWER_ID,
      title: 'Some Knowledge Base Answer',
      visibility: EnumKnowledgeBaseVisibility.Published,
      translationMissing: false,
      internalAt: null,
      publishedAt: '2026-08-01T10:00:00Z',
      archivedAt: null,
      editedAt: '2026-08-03T10:00:00Z',
      editedBy: {
        id: convertToGraphQLId('User', 3),
        firstname: 'Erika',
        lastname: 'Mustermann',
        fullname: 'Erika Mustermann',
        organization: null,
      },
      navigation: {
        __typename: 'KnowledgeBaseAnswerNavigation',
        index: 2,
        totalCount: 3,
        previousAnswer: {
          __typename: 'KnowledgeBaseAnswer',
          id: PREVIOUS_ANSWER_ID,
          title: 'Previous Knowledge Base Answer',
        },
        nextAnswer: {
          __typename: 'KnowledgeBaseAnswer',
          id: NEXT_ANSWER_ID,
          title: 'Next Knowledge Base Answer',
        },
      },
      category: {
        id: CHILD_CATEGORY_ID,
        breadcrumb: [
          {
            id: ROOT_CATEGORY_ID,
            title: 'Root Category',
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
          },
          {
            id: CHILD_CATEGORY_ID,
            title: 'Child Category',
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
          },
        ],
      },
      ...overrides,
    },
  } as KnowledgeBaseAnswerQuery)

describe('knowledge base answer header', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })
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
          {
            id: convertToGraphQLId('KnowledgeBase::Locale', 2),
            primary: false,
            systemLocale: { id: '2', locale: 'de-de', name: 'Deutsch' },
          },
        ],
        currentLocale: {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })

    mockAnswer()
  })

  it('shows the full category path and the answer as the opened node', async () => {
    const view = await visitView(ANSWER_PATH)

    const breadcrumb = (
      await view.findAllByRole('navigation', { name: 'Knowledge base navigation' })
    ).at(-1)!

    // Each link carries its category icon, which contributes to the accessible name.
    expect(within(breadcrumb).getByRole('link', { name: /Root Category/ })).toBeInTheDocument()
    expect(within(breadcrumb).getByRole('link', { name: /Child Category/ })).toBeInTheDocument()
    expect(
      within(breadcrumb).getByRole('heading', { name: 'Some Knowledge Base Answer' }),
      'the opened answer is the page heading',
    ).toBeInTheDocument()
  })

  it('shows the answer title, its publication state and its edit metadata', async () => {
    const view = await visitView(ANSWER_PATH)

    expect(await view.findAllByText('Published')).not.toHaveLength(0)
    expect(view.getByText(/edited .* by Erika Mustermann/)).toBeInTheDocument()
  })

  it('links the public knowledge base button to the answer preview endpoint', async () => {
    const view = await visitView(ANSWER_PATH)

    const links = await view.findAllByRole('link', { name: 'View public knowledge base' })

    expect(links.length).toBeGreaterThan(0)
    links.forEach((link) => {
      expect(link).toHaveAttribute(
        'href',
        `/api/v1/knowledge_bases/preview/KnowledgeBaseAnswer/${getIdFromGraphQLId(ANSWER_ID)}/en-us`,
      )
    })
  })

  it('hides the public knowledge base button for an unpublished answer without editor permission', async () => {
    mockAnswer({
      visibility: EnumKnowledgeBaseVisibility.Internal,
      publishedAt: null,
      internalAt: '2026-08-01T10:00:00Z',
    })

    const view = await visitView(ANSWER_PATH)

    // The header rendered, so the button is hidden by visibility, not by an empty page.
    expect(await view.findAllByText('Internal')).not.toHaveLength(0)
    expect(view.queryByRole('link', { name: 'View public knowledge base' })).not.toBeInTheDocument()
  })

  it('stays on the answer when switching language', async () => {
    const view = await visitView(ANSWER_PATH)

    // Both the full and the (scrolled) compact header carry a language selector;
    //   at the top only the full header is active, so target the last one.
    const languageButtons = await view.findAllByRole('button', { name: 'Change language' })
    await view.events.click(languageButtons.at(-1) as HTMLElement)

    await view.events.click(await view.findByText('Deutsch'))

    await waitFor(() => {
      expect(view, 'stayed on the answer in the selected locale').toHaveCurrentUrl(
        `/knowledge-base/locale/de-de/answer/${getIdFromGraphQLId(ANSWER_ID)}`,
      )
    })
  })

  it('navigates to the next answer in the route locale', async () => {
    const view = await visitView(ANSWER_PATH)

    const nextLinks = await view.findAllByRole('link', {
      name: 'Next answer: Next Knowledge Base Answer',
    })
    await view.events.click(nextLinks.at(-1) as HTMLElement)

    await waitFor(() => {
      expect(view).toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(NEXT_ANSWER_ID)}`,
      )
    })
  })

  it('warns when the answer has no translation in the browsed locale', async () => {
    mockAnswer({ translationMissing: true })

    const view = await visitView(ANSWER_PATH)

    // One alert per header, so the warning survives the scroll swap.
    await waitFor(() => {
      expect(view.getAllByText('No translation for this locale available')).toHaveLength(2)
    })
  })

  it('does not warn about a missing translation for a translated answer', async () => {
    const view = await visitView(ANSWER_PATH)

    // Both headers are mounted, so the answer title appears more than once.
    expect(await view.findAllByText('Some Knowledge Base Answer')).not.toHaveLength(0)
    expect(view.queryAllByText('No translation for this locale available')).toHaveLength(0)
  })
})
