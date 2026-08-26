// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswerQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'
import { mockKnowledgeBaseSearchQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseSearch.mocks.ts'

const ROOT_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const EMPTY_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

const ROOT_PATH = '/knowledge-base/locale/en-us'

// A term without hits, so specs can pick the empty state by what they search for.
const UNKNOWN_TERM = 'nothing-matches'

const searchHit = (id: number, title: string) => ({
  node: {
    item: {
      __typename: 'KnowledgeBaseAnswer' as const,
      id: convertToGraphQLId('KnowledgeBase::Answer', id),
      title,
      visibility: EnumKnowledgeBaseVisibility.Published,
      translationMissing: false,
    },
    titlePreview: [
      { text: 'Printer', highlight: true },
      { text: title.replace('Printer', ''), highlight: false },
    ],
    bodyPreview: [],
    categoryPath: [{ id: ROOT_CATEGORY_ID, title: 'Hardware' }],
  },
})

// The view scrolls its content container through scrollIntoView; there is no real scroller
//   behind it here.
vi.mock('#shared/utils/dom.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/utils/dom.ts')>()),
  scrollIntoView: vi.fn(),
}))

const noPolicy = { update: false, destroy: false, createSubcategory: false }

const category = (id: string, title: string) => ({
  id,
  title,
  categoryIcon: 'f115',
  iconSet: 'FontAwesome',
  visibility: EnumKnowledgeBaseVisibility.Published,
  translationMissing: false,
  answerCount: 0,
  subcategoryCount: 0,
  position: 0,
  isDeletable: false,
  policy: noPolicy,
})

const searchFieldPlaceholder = (title: string) => `Search within ${title}…`

const findSearchField = (view: Awaited<ReturnType<typeof visitView>>, title: string) =>
  view.findByPlaceholderText(searchFieldPlaceholder(title))

describe('knowledge base search', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true, es_enabled: true })

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        title: 'My Knowledge Base',
        iconset: 'default',
        isPubliclyAvailable: true,
        isVisiblePublicly: true,
        policy: { update: false },
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

    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
      // A category with nothing in it: no subcategories, and a reader who is offered no
      //   add card either — so the browse grid renders nothing at all.
      if (categoryId === EMPTY_CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            category: {
              id: EMPTY_CATEGORY_ID,
              isVisiblePublicly: true,
              translationMissing: false,
              isDeletable: false,
              policy: noPolicy,
              breadcrumb: [{ id: EMPTY_CATEGORY_ID, title: 'Empty Category' }],
            },
            subcategories: [],
          },
        }
      }

      if (categoryId === ROOT_CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            category: {
              id: ROOT_CATEGORY_ID,
              isVisiblePublicly: true,
              translationMissing: false,
              isDeletable: false,
              policy: noPolicy,
              breadcrumb: [{ id: ROOT_CATEGORY_ID, title: 'Root Category' }],
            },
            subcategories: [],
          },
        }
      }

      return {
        knowledgeBaseCategorySubcategories: {
          category: null,
          subcategories: [category(ROOT_CATEGORY_ID, 'Root Category')],
        },
      }
    })

    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 0,
        edges: [],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })

    mockKnowledgeBaseSearchQuery(({ query }) => ({
      knowledgeBaseSearch:
        query === UNKNOWN_TERM
          ? { totalCount: 0, edges: [], pageInfo: { endCursor: null, hasNextPage: false } }
          : {
              totalCount: 2,
              edges: [searchHit(1, 'Printer setup'), searchHit(2, 'Printer drivers')],
              pageInfo: { endCursor: null, hasNextPage: false },
            },
    }))
  })

  it('offers to search the knowledge base at its root', async () => {
    const view = await visitView(ROOT_PATH)

    expect(await findSearchField(view, 'My Knowledge Base')).toBeInTheDocument()
  })

  it('offers to search the opened category', async () => {
    const view = await visitView(`${ROOT_PATH}/category/1`)

    expect(await findSearchField(view, 'Root Category')).toBeInTheDocument()
  })

  it('puts the searched term into the URL', async () => {
    const view = await visitView(ROOT_PATH)

    await view.events.type(await findSearchField(view, 'My Knowledge Base'), 'printer')

    // Waits out the real debounce rather than injecting a shorter one — this is the one
    //   place the whole round trip is exercised as the user meets it.
    await waitFor(
      () => expect(getTestRouter().currentRoute.value.fullPath).toBe(`${ROOT_PATH}?query=printer`),
      3000,
    )
  })

  it('searches for a suggested term as soon as it is picked', async () => {
    const view = await visitView(ROOT_PATH)

    await view.events.click(await view.findByLabelText('Suggested searches'))
    await view.events.click(await view.findByText('Drafts only'))

    // No waiting out the typing debounce: picking a suggestion searches right away.
    await waitFor(() =>
      expect(getTestRouter().currentRoute.value.fullPath).toBe(
        `${ROOT_PATH}?query=publication_state:draft`,
      ),
    )

    expect(await findSearchField(view, 'My Knowledge Base')).toHaveValue('publication_state:draft')
  })

  it('takes the term out of the URL again when the search is cleared', async () => {
    const view = await visitView(`${ROOT_PATH}?query=printer`)

    await view.events.click(await view.findByLabelText('Clear search'))

    await waitFor(() => expect(getTestRouter().currentRoute.value.fullPath).toBe(ROOT_PATH))

    expect(await findSearchField(view, 'My Knowledge Base')).toHaveValue('')
  })

  it('replaces the browse content with the highlighted results while a query is active', async () => {
    const view = await visitView(`${ROOT_PATH}?query=printer`)

    // The highlighted runs split the titles over several nodes, so match on the whole content.
    await waitFor(() => expect(view.container).toHaveTextContent('Printer setup'))
    expect(view.container).toHaveTextContent('Printer drivers')
    expect(view.container.querySelectorAll('mark')).toHaveLength(2)

    // The category grid gives way to the results.
    expect(view.queryByText('Root Category')).not.toBeInTheDocument()
  })

  describe('opened result', () => {
    const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 1)
    const ANSWER_PATH = `${ROOT_PATH}/answer/1`

    beforeEach(() => {
      mockKnowledgeBaseAnswerQuery({
        knowledgeBaseAnswer: {
          id: ANSWER_ID,
          title: 'Printer setup',
          visibility: EnumKnowledgeBaseVisibility.Published,
          translationMissing: false,
          navigation: null,
          category: {
            id: ROOT_CATEGORY_ID,
            breadcrumb: [{ id: ROOT_CATEGORY_ID, title: 'Root Category' }],
          },
        },
      })
    })

    it('leads back to the search it was opened from', async () => {
      const view = await visitView(`${ANSWER_PATH}?query=printer`)

      await view.events.click(await view.findByRole('button', { name: 'Back to search results' }))

      await waitFor(() =>
        expect(getTestRouter().currentRoute.value.fullPath).toBe(`${ROOT_PATH}?query=printer`),
      )
    })

    it('leads back into the category the search was scoped to', async () => {
      const view = await visitView(`${ANSWER_PATH}?query=printer&category=1`)

      await view.events.click(await view.findByRole('button', { name: 'Back to search results' }))

      await waitFor(() =>
        expect(getTestRouter().currentRoute.value.fullPath).toBe(
          `${ROOT_PATH}/category/1?query=printer`,
        ),
      )
    })

    it('offers no way back when it was not opened from a search', async () => {
      const view = await visitView(ANSWER_PATH)

      await waitFor(() => expect(view.container).toHaveTextContent('Printer setup'), 3000)
      expect(view.queryByRole('button', { name: 'Back to search results' })).not.toBeInTheDocument()
    })
  })

  it('focuses the search field when arriving with a focus request, then drops it from the URL', async () => {
    const view = await visitView(`${ROOT_PATH}?focus=search`)

    await waitFor(() => expect(findSearchField(view, 'My Knowledge Base')).resolves.toHaveFocus())
    const searchField = await findSearchField(view, 'My Knowledge Base')

    await waitFor(() => expect(searchField).toHaveFocus())
    await waitFor(() => expect(getTestRouter().currentRoute.value.fullPath).toBe(ROOT_PATH))
  })

  it('does not steal focus without a focus request', async () => {
    const view = await visitView(ROOT_PATH)

    expect(await findSearchField(view, 'My Knowledge Base')).not.toHaveFocus()
  })

  it('shows the empty state for a term without hits and clears the search from it', async () => {
    const view = await visitView(`${ROOT_PATH}?query=${UNKNOWN_TERM}`)

    expect(await view.findByText('No search results for this query.')).toBeInTheDocument()

    // The search field's own clear control carries the same name; the empty state's is the last.
    const clearButtons = await view.findAllByRole('button', { name: 'Clear search' })
    await view.events.click(clearButtons.at(-1)!)

    await waitFor(() => expect(getTestRouter().currentRoute.value.fullPath).toBe(ROOT_PATH))

    // The browse content is back.
    expect(await view.findByText('Root Category')).toBeInTheDocument()
    expect(view.queryByText('No search results for this query.')).not.toBeInTheDocument()
  })
})
