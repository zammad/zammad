// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockKnowledgeBaseQuery,
  mockKnowledgeBaseQueryError,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import {
  mockKnowledgeBaseAnswersQuery,
  waitForKnowledgeBaseAnswersQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import {
  mockKnowledgeBaseCategorySubcategoriesQuery,
  waitForKnowledgeBaseCategorySubcategoriesQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

const ROOT_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

// The view scrolls its content container through scrollIntoView; mock it so the calls can be
//   asserted without a real scroller.
const scrollIntoViewMock = vi.hoisted(() => vi.fn())

vi.mock('#shared/utils/dom.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/utils/dom.ts')>()),
  scrollIntoView: scrollIntoViewMock,
}))

const category = (
  id: string,
  title: string,
  counts: { answerCount?: number; subcategoryCount?: number } = {},
) => ({
  id,
  translation: { title },
  categoryIcon: 'f115',
  iconSet: 'FontAwesome',
  visibility: EnumKnowledgeBaseVisibility.Published,
  answerCount: counts.answerCount ?? 0,
  subcategoryCount: counts.subcategoryCount ?? 0,
  position: 0,
})

const answer = (id: string, title: string) => ({
  id,
  visibility: EnumKnowledgeBaseVisibility.Published,
  position: 0,
  translation: { id: `${id}-translation`, title },
})

describe('knowledge base category navigation', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        translation: { title: 'My Knowledge Base' },
        iconset: 'default',
        isPubliclyAvailable: true,
        isVisiblePublicly: true,
        policy: { update: true },
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
          id: 'gid://zammad/KnowledgeBase::Locale/1',
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })

    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
      // Opening the root category shows its breadcrumb (itself) and its children.
      if (categoryId === ROOT_CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            category: {
              id: ROOT_CATEGORY_ID,
              breadcrumb: [{ id: ROOT_CATEGORY_ID, translation: { title: 'Root Category' } }],
            },
            subcategories: [category(CHILD_CATEGORY_ID, 'Child Category')],
          },
        }
      }

      // Knowledge base root: only top-level categories, no breadcrumb.
      return {
        knowledgeBaseCategorySubcategories: {
          category: null,
          subcategories: [category(ROOT_CATEGORY_ID, 'Root Category', { subcategoryCount: 7 })],
        },
      }
    })

    // Answers only exist below a category; the query stays disabled at the root.
    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 1,
        edges: [{ node: answer('gid://zammad/KnowledgeBase::Answer/1', 'Getting Started') }],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })
  })

  it('normalizes the bare entry to the localized root', async () => {
    const view = await visitView('/knowledge-base')

    await waitFor(() => {
      expect(view, 'redirected to the localized root').toHaveCurrentUrl(
        '/knowledge-base/locale/en-us',
      )
    })

    expect(await view.findByText('Root Category')).toBeInTheDocument()
  })

  it('shows the subtree subcategory count on the category card', async () => {
    const view = await visitView('/knowledge-base')

    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
    })

    expect(await view.findByText('7')).toBeInTheDocument()
  })

  it('links the public knowledge base button to the browsed node preview endpoint', async () => {
    mockPermissions(['knowledge_base.reader'])

    const view = await visitView('/knowledge-base')

    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
    })

    const links = await view.findAllByRole('link', { name: 'View public knowledge base' })

    expect(links.length).toBeGreaterThan(0)
    links.forEach((link) => {
      expect(link).toHaveAttribute('href', '/api/v1/knowledge_bases/preview/KnowledgeBase/1/en-us')
    })
  })

  it('hides the public knowledge base button for a public visitor without permission', async () => {
    mockPermissions([])

    const view = await visitView('/knowledge-base')

    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
    })

    // Content is visible (root loaded), so the button is hidden by permission,
    //   not by an empty page.
    expect(await view.findByText('Root Category')).toBeInTheDocument()
    expect(view.queryByRole('link', { name: 'View public knowledge base' })).not.toBeInTheDocument()
  })

  it('marks the sidebar entry active while browsing a nested knowledge base route', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
    )

    // The sidebar entry maps to the top-level layout route, whereas the current
    //   route resolves to a child record — the active state must still apply.
    const navigation = view.getByRole('navigation', { name: 'Navigation' })
    const sidebarEntry = await within(navigation).findByRole('link', { name: 'Knowledge Base' })

    expect(sidebarEntry).toHaveClass('bg-blue-800!')
  })

  it('renders the categories again after navigating back to the root via the breadcrumb', async () => {
    const view = await visitView('/knowledge-base')

    await view.events.click(await view.findByText('Root Category'))

    await waitFor(() => {
      expect(view, 'entered the category').toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
      )
    })

    // The child category is only listed inside the opened category.
    expect(await view.findByText('Child Category')).toBeInTheDocument()

    const breadcrumb = view
      .getAllByRole('navigation', { name: 'Knowledge base navigation' })
      .at(-1)!
    const rootBreadcrumbLink = await within(breadcrumb).findByRole('link', {
      name: 'Knowledge Base Home',
    })

    await view.events.click(rootBreadcrumbLink)

    await waitFor(() => {
      expect(view, 'back at the knowledge base root').toHaveCurrentUrl(
        '/knowledge-base/locale/en-us',
      )
    })

    // Regression: the parent <RouterView> must resolve the empty-path child and
    //   render the root categories instead of an empty section.
    expect(await view.findByText('Root Category')).toBeInTheDocument()

    await waitFor(() => {
      expect(view.queryByText('Child Category'), 'left the category').not.toBeInTheDocument()
    })
  })

  it('starts the opened category at the top of the page', async () => {
    const view = await visitView('/knowledge-base')

    await view.events.click(await view.findByText('Root Category'))

    await waitFor(() => {
      expect(
        scrollIntoViewMock,
        'scrolled the content container back to the top',
      ).toHaveBeenCalledWith(expect.anything(), 'start', { behavior: 'instant' })
    })
  })

  // Only the knowledge base root stretches its (empty) grid to fill the page, for its empty state.
  //   In a category with nothing in the grid — no subcategories, and no add card for a reader or a
  //   public visitor — stretching would push the answers below the fold.
  it('keeps the empty category grid from stretching above the answers', async () => {
    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: {
        category: {
          id: CHILD_CATEGORY_ID,
          breadcrumb: [{ id: CHILD_CATEGORY_ID, translation: { title: 'Child Category' } }],
          policy: { update: false, destroy: false, createSubcategory: false },
        },
        subcategories: [],
      },
    })

    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CHILD_CATEGORY_ID)}`,
    )

    const answers = await view.findByText('Getting Started')

    expect(view.container.querySelector('ol.grid'), 'no grid above them').toBeNull()
    expect(answers.closest('section'), 'section does not grow').not.toHaveClass('grow')
  })

  // The counterpart of the above: the root does stretch, because that is what centers its empty
  //   state on the page.
  it('shows the empty state at the root when there is nothing to list', async () => {
    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        translation: { title: 'My Knowledge Base' },
        iconset: 'default',
        // No add card for a visitor who may not create a top level category.
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

    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: { category: null, subcategories: [] },
    })

    const view = await visitView('/knowledge-base')

    expect(await view.findByText('No knowledge base content is available yet.')).toBeInTheDocument()
  })

  it('can navigate away from the knowledge base without being redirected back', async () => {
    const view = await visitView('/knowledge-base')

    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
    })

    await getTestRouter().push('/dashboard')

    // The locale sync must not bounce navigation back into the knowledge base.
    await waitFor(() => {
      expect(view, 'stayed on the target route').toHaveCurrentUrl('/dashboard')
    })
  })

  it('returns to the last browsed page when the locale-less entry is re-entered', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
    )

    await waitFor(() => {
      expect(view).toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
      )
    })

    // Re-clicking the sidebar entry navigates to the locale-less URL while the
    //   section is already open; it must return to the last browsed page (the
    //   open category), like the personal settings section.
    await getTestRouter().push('/knowledge-base')

    await waitFor(() => {
      expect(view, 'returned to the last browsed page').toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
      )
    })
  })

  it('keeps the locale selector in sync with the route when switching language', async () => {
    const view = await visitView('/knowledge-base')

    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
    })

    // The trigger shows the active locale code, resolved from the route.
    expect(await view.findAllByText('EN-US')).not.toHaveLength(0)

    // Both the full and the (scrolled) compact header carry a language selector;
    //   at the top only the full header is active, so target the last one.
    const languageButtons = view.getAllByRole('button', { name: 'Change language' })
    await view.events.click(languageButtons.at(-1) as HTMLElement)

    await view.events.click(await view.findByText('Deutsch'))

    // Switching language must update the URL so selector and route stay aligned.
    await waitFor(() => {
      expect(view, 'navigated to the selected locale').toHaveCurrentUrl(
        '/knowledge-base/locale/de-de',
      )
    })

    expect(await view.findAllByText('DE-DE')).not.toHaveLength(0)
  })

  it('keeps the open category when switching language inside it', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
    )

    await waitFor(() => {
      expect(view).toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
      )
    })

    const languageButtons = view.getAllByRole('button', { name: 'Change language' })
    await view.events.click(languageButtons.at(-1) as HTMLElement)

    await view.events.click(await view.findByText('Deutsch'))

    await waitFor(() => {
      expect(view, 'stayed in the category on the selected locale').toHaveCurrentUrl(
        `/knowledge-base/locale/de-de/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
      )
    })
  })

  it('drives the content query with the locale from the URL', async () => {
    await visitView(`/knowledge-base/locale/de-de/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`)

    const calls = await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()

    expect(calls.at(-1)?.variables).toEqual({
      categoryId: ROOT_CATEGORY_ID,
      locale: 'de-de',
    })
  })

  it('lists the answers of the opened category', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
    )

    expect(await view.findByText('Getting Started')).toBeInTheDocument()
  })

  it('does not query answers at the knowledge base root', async () => {
    const view = await visitView('/knowledge-base')

    await waitFor(() => {
      expect(view).toHaveCurrentUrl('/knowledge-base/locale/en-us')
    })

    // The root lists categories only; the answers query must stay disabled
    //   because there is no category to fetch answers for.
    expect(view.queryByText('Getting Started')).not.toBeInTheDocument()
  })

  it('drives the answers query with the category and locale from the URL', async () => {
    await visitView(`/knowledge-base/locale/de-de/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`)

    const calls = await waitForKnowledgeBaseAnswersQueryCalls()

    expect(calls.at(-1)?.variables).toMatchObject({
      categoryId: ROOT_CATEGORY_ID,
      locale: 'de-de',
    })
  })

  it('warns when the opened category has no translation in the browsed locale', async () => {
    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
      if (categoryId === ROOT_CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            // No translation of its own in the browsed locale: the title comes from the
            //   primary one, which is what its `kbLocale` says.
            category: {
              id: ROOT_CATEGORY_ID,
              translation: {
                title: 'Root Category',
                kbLocale: {
                  __typename: 'KnowledgeBaseLocale' as const,
                  // Its own id, or the mocked locale of the browsed page (one record for every
                  //   KnowledgeBaseLocale) would answer this one too.
                  id: convertToGraphQLId('KnowledgeBase::Locale', 2),
                  systemLocale: { __typename: 'Locale' as const, locale: 'de-de' },
                },
              },
              breadcrumb: [{ id: ROOT_CATEGORY_ID, translation: { title: 'Root Category' } }],
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

    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
    )

    // The alert is docked below both the full and the compact header.
    expect(await view.findAllByText('No translation available for this locale')).not.toHaveLength(0)
  })

  it('shows no translation warning when the opened category is translated', async () => {
    mockKnowledgeBaseCategorySubcategoriesQuery(({ categoryId }) => {
      if (categoryId === ROOT_CATEGORY_ID) {
        return {
          knowledgeBaseCategorySubcategories: {
            category: {
              id: ROOT_CATEGORY_ID,
              breadcrumb: [{ id: ROOT_CATEGORY_ID, translation: { title: 'Root Category' } }],
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

    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
    )

    await waitFor(() => {
      expect(view).toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(ROOT_CATEGORY_ID)}`,
      )
    })

    expect(view.queryAllByText('No translation available for this locale')).toHaveLength(0)
  })

  it('shows a not-found error for a locale the knowledge base does not offer', async () => {
    // The mocked knowledge base only offers en-us and de-de.
    const view = await visitView('/knowledge-base/locale/fr-fr')

    expect(
      await view.findByText('This knowledge base is not available in the selected language.'),
    ).toBeInTheDocument()
  })

  it('shows a generic error when the base query fails to load', async () => {
    // A load failure is not a language problem — it must not be masked as one.
    mockKnowledgeBaseQueryError('boom', { type: GraphQLErrorTypes.UnknownError })

    const view = await visitView('/knowledge-base/locale/en-us')

    expect(await view.findByText('The knowledge base could not be loaded.')).toBeInTheDocument()
  })
})
