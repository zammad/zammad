// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { ref } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { KnowledgeBaseAnswersDocument } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.api.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'
import { getKnowledgeBaseContentUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseContentUpdates.mocks.ts'

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

// The infinite scroll is driven by @vueuse/core; capture its callback so the
//   test can simulate the user reaching the end of the list.
let triggerLoadMore: (() => Promise<void>) | undefined

vi.mock('@vueuse/core', async (importOriginal) => {
  const modules = await importOriginal<typeof import('@vueuse/core')>()

  return {
    ...modules,
    useInfiniteScroll: (_element: unknown, callback: () => Promise<void>) => {
      triggerLoadMore = callback
      return { reset: vi.fn(), isLoading: ref(false) }
    },
  }
})

const answer = (id: number, title: string) => ({
  node: {
    id: convertToGraphQLId('KnowledgeBase::Answer', id),
    visibility: EnumKnowledgeBaseVisibility.Published,
    position: id,
    translation: {
      id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
      title,
    },
  },
})

describe('knowledge base answers infinite scroll', () => {
  beforeEach(() => {
    triggerLoadMore = undefined

    mockApplicationConfig({ kb_active_publicly: true })

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
        // Pin the resolved locale to the same system locale as the primary
        //   kbLocale. Both resolve to Locale id 1, so leaving currentLocale
        //   unmocked lets the auto-mocker generate a random `locale` for that
        //   shared id, which then fails the section's known-locale gate.
        currentLocale: {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          systemLocale: { id: '1', locale: 'en-us' },
        },
      },
    })

    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: {
        category: {
          id: CATEGORY_ID,
          breadcrumb: [{ id: CATEGORY_ID, translation: { title: 'Category' } }],
        },
        subcategories: [],
      },
    })

    // First page: two answers, more to come. Second page (requested with a
    //   cursor): the remaining two answers, no further pages.
    mockKnowledgeBaseAnswersQuery(({ cursor }) =>
      cursor
        ? {
            knowledgeBaseAnswers: {
              totalCount: 4,
              edges: [answer(3, 'Answer Three'), answer(4, 'Answer Four')],
              pageInfo: { endCursor: null, hasNextPage: false },
            },
          }
        : {
            knowledgeBaseAnswers: {
              totalCount: 4,
              edges: [answer(1, 'Answer One'), answer(2, 'Answer Two')],
              pageInfo: { endCursor: 'CURSOR', hasNextPage: true },
            },
          },
    )
  })

  it('appends the next page of answers when the list end is reached', async () => {
    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CATEGORY_ID)}`,
    )

    expect(await view.findByText('Answer One')).toBeInTheDocument()
    expect(view.queryByText('Answer Three')).not.toBeInTheDocument()

    await triggerLoadMore?.()

    // The second page is appended, not replacing the first — relies on the
    //   relay-style pagination cache policy keyed by category + locale.
    expect(await view.findByText('Answer Three')).toBeInTheDocument()
    expect(view.getByText('Answer One')).toBeInTheDocument()
  })

  // A content update refreshes the whole listing. Refetching its first page only would drop
  //   everything scrolled to so far and put the reader back at the top of the category, so the
  //   refetch asks for as many pages as are loaded.
  it('keeps every loaded page when a content update refreshes the listing', async () => {
    // One full page of answers plus a bit — the composable's own page size decides where the
    //   second one starts, so a listing this long is what it takes to have two of them.
    const serverAnswers = Array.from({ length: 35 }, (_, index) =>
      answer(index + 1, `Answer ${index + 1}`),
    )

    // A server that honours both pagination arguments, unlike the fixed pages above: what the
    //   refetch asks for is the whole point here.
    mockKnowledgeBaseAnswersQuery(({ cursor, pageSize }) => {
      // The cursor is simply the offset it points behind.
      const offset = cursor ? Number(cursor) : 0
      const edges = serverAnswers.slice(offset, offset + (pageSize ?? 0))

      return {
        knowledgeBaseAnswers: {
          totalCount: serverAnswers.length,
          edges,
          pageInfo: {
            endCursor: String(offset + edges.length),
            hasNextPage: offset + edges.length < serverAnswers.length,
          },
        },
      }
    })

    const view = await visitView(
      `/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CATEGORY_ID)}`,
    )

    expect(await view.findByText('Answer 1')).toBeInTheDocument()
    expect(view.queryByText('Answer 35')).not.toBeInTheDocument()

    await triggerLoadMore?.()

    expect(await view.findByText('Answer 35')).toBeInTheDocument()

    await getKnowledgeBaseContentUpdatesSubscriptionHandler().trigger({
      knowledgeBaseContentUpdates: {
        knowledgeBase: { id: convertToGraphQLId('KnowledgeBase', 1) },
        affectedCategoryIds: [CATEGORY_ID],
      },
    })

    await waitFor(() => {
      // Both loaded pages in one request from the start of the listing, rather than the first
      //   page alone.
      expect(getGraphQLMockCalls(KnowledgeBaseAnswersDocument).at(-1)?.variables).toEqual({
        categoryId: CATEGORY_ID,
        locale: 'en-us',
        pageSize: 60,
      })
    })

    // Still the whole loaded window, so the list has not moved under the reader.
    expect(view.getByText('Answer 1')).toBeInTheDocument()
    expect(view.getByText('Answer 35')).toBeInTheDocument()
  })
})

// The ways into the create and the edit view from the browse page.
describe('knowledge base add and edit answer entry points', () => {
  const subcategory = {
    id: convertToGraphQLId('KnowledgeBase::Category', 2),
    title: 'Subcategory',
    policy: { update: true, destroy: true, createSubcategory: true, createAnswer: true },
  }

  // Both flags are always stated, never left to the automocker: an auto-generated boolean differs
  //   between an isolated and a whole-file run, which makes a test about them pass by luck.
  const mockCategory = (
    createAnswer: boolean,
    updateAnswer = false,
    subcategories: (typeof subcategory)[] = [],
  ) =>
    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: {
        category: {
          id: CATEGORY_ID,
          breadcrumb: [{ id: CATEGORY_ID, translation: { title: 'Category' } }],
          policy: {
            update: true,
            destroy: true,
            createSubcategory: createAnswer,
            createAnswer,
            updateAnswer,
            // Off throughout: this describe is about the create and edit entry points, and an
            //   auto-generated flag would decide whether a card has an action menu at all.
            destroyAnswer: false,
          },
        },
        subcategories,
      },
    })

  const mockAnswers = (edges: ReturnType<typeof answer>[]) =>
    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: edges.length,
        edges,
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })

  const visitCategory = () =>
    visitView(`/knowledge-base/locale/en-us/category/${getIdFromGraphQLId(CATEGORY_ID)}`)

  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })

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

  it('is offered to an editor of the category', async () => {
    mockCategory(true)
    mockAnswers([answer(1, 'Answer One')])

    const view = await visitCategory()

    expect(await view.findByText('Add answer')).toBeInTheDocument()
  })

  // The only way to create the first answer in a category.
  it('is offered in a category without answers', async () => {
    mockCategory(true)
    mockAnswers([])

    const view = await visitCategory()

    expect(await view.findByText('Add answer')).toBeInTheDocument()
  })

  // Gated per record: granular permissions make someone editor of one subtree and reader
  //   elsewhere, so the global permission would offer a button the mutation refuses.
  it('is hidden without create access to the category', async () => {
    mockCategory(false)
    mockAnswers([answer(1, 'Answer One')])

    const view = await visitCategory()

    await view.findByText('Answer One')

    expect(view.queryByText('Add answer')).not.toBeInTheDocument()
  })

  // An answer always belongs to a category, so the knowledge base root offers nothing.
  it('is hidden at the knowledge base root', async () => {
    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: { category: null, subcategories: [] },
    })
    mockAnswers([])

    const view = await visitView('/knowledge-base/locale/en-us')

    await waitFor(() => {
      expect(view.queryByText('Add answer')).not.toBeInTheDocument()
    })
  })

  // jsdom reports no intersections, so the add card counts as out of view - which is exactly the
  //   state the toolbar shortcut covers.
  it('offers the shortcut in the floating toolbar while the card is out of view', async () => {
    mockCategory(true)
    mockAnswers([answer(1, 'Answer One')])

    const view = await visitCategory()

    const toolbar = within(await view.findByRole('toolbar', { name: 'Knowledge base actions' }))

    await view.events.click(toolbar.getByRole('button', { name: 'Add answer' }))

    const router = getTestRouter()

    await waitFor(() => {
      expect(router.currentRoute.value.name).toBe('KnowledgeBaseAnswerCreate')
    })

    expect(router.currentRoute.value.query.categoryId).toBe(String(getIdFromGraphQLId(CATEGORY_ID)))
  })

  // Gated per record, like the card: the shortcut must not offer what the mutation refuses.
  it('keeps the shortcut out of the toolbar without create access', async () => {
    mockCategory(false)
    mockAnswers([answer(1, 'Answer One')])

    const view = await visitCategory()

    await view.findByText('Answer One')

    expect(
      within(view.getByRole('toolbar', { name: 'Knowledge base actions' })).queryByRole('button', {
        name: 'Add answer',
      }),
    ).not.toBeInTheDocument()
  })

  // The edit entry on the card itself, which is what the browse page offers for an answer that
  //   already exists - the reader's header menu and floating toolbar being the other two.
  it('offers editing an answer on its card', async () => {
    mockCategory(true, true)
    mockAnswers([answer(1, 'Answer One')])

    const view = await visitCategory()

    const card = (await view.findByText('Answer One')).closest('li') as HTMLElement

    await view.events.click(within(card).getByRole('button', { name: 'Answer actions' }))

    // Asserted on the navigation rather than on the view it opens: the edit view brings its own
    //   taskbar tab and answer query, which this browse spec does not mock - it would render into
    //   errors that say nothing about the card.
    const router = getTestRouter()
    router.mockMethods()

    await view.events.click(await view.findByRole('button', { name: 'Edit answer' }))

    // The browsed locale, like every other way into the edit view: its taskbar tab is per answer
    //   *and* locale.
    expect(router.push).toHaveBeenCalledWith({
      name: 'KnowledgeBaseAnswerEdit',
      params: { localeCode: 'en-us', answerInternalId: 1 },
    })

    router.restoreMethods()
  })

  // Asked of the category once, not per answer: KnowledgeBase::AnswerPolicy#update? resolves the
  //   access of the answer's category anyway, so every card here would answer the same.
  it('hides the card edit action without edit access to the category', async () => {
    mockCategory(true, false)
    mockAnswers([answer(1, 'Answer One')])

    const view = await visitCategory()

    const card = (await view.findByText('Answer One')).closest('li') as HTMLElement

    expect(within(card).queryByRole('button', { name: 'Answer actions' })).not.toBeInTheDocument()
  })

  it('opens a fresh draft for the category it was clicked in', async () => {
    mockCategory(true)
    mockAnswers([])

    const view = await visitCategory()

    await view.events.click(await view.findByText('Add answer'))

    const router = getTestRouter()

    await waitFor(() => {
      expect(router.currentRoute.value.name).toBe('KnowledgeBaseAnswerCreate')
    })

    const { params, query } = router.currentRoute.value

    expect(params.localeCode).toBe('en-us')
    // The internal id: it is what the create form's category field works with.
    expect(query.categoryId).toBe(String(getIdFromGraphQLId(CATEGORY_ID)))
    expect(params.tabId, 'a fresh draft every time').toBeTruthy()
  })

  // The open category takes no answers here, so the only "Add answer" left on the page is the
  //   tile's. Where the click leads is asserted in the card's own spec.
  it('is offered on a category card the user may create answers in', async () => {
    mockCategory(false, false, [subcategory])
    mockAnswers([])

    const view = await visitCategory()

    await view.events.click(await view.findByRole('button', { name: 'Category actions' }))

    expect(await view.findByText('Add answer')).toBeInTheDocument()
  })
})
