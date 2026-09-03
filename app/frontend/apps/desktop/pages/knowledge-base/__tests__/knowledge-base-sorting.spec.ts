// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseSortingMode, EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForKnowledgeBaseReorderAnswersMutationCalls } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseReorderAnswers.mocks.ts'
import { waitForKnowledgeBaseReorderCategoriesMutationCalls } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseReorderCategories.mocks.ts'
import { waitForKnowledgeBaseReorderRootCategoriesMutationCalls } from '#desktop/entities/knowledge-base/graphql/mutations/knowledgeBaseReorderRootCategories.mocks.ts'
import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { KnowledgeBaseAnswersDocument } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.api.ts'
import { mockKnowledgeBaseAnswersQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { KnowledgeBaseCategorySubcategoriesDocument } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.api.ts'
import { mockKnowledgeBaseCategorySubcategoriesQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'

import {
  armKnowledgeBaseSorting,
  resetKnowledgeBaseSorting,
  useKnowledgeBaseSorting,
} from '../composables/useKnowledgeBaseSorting.ts'

const { Manual, Alphabetical, LastUpdate } = EnumKnowledgeBaseSortingMode

const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)

const category = (id: number, title: string) => ({
  id: convertToGraphQLId('KnowledgeBase::Category', id),
  title,
  categoryIcon: 'folder',
  iconSet: 'FontAwesome',
  visibility: EnumKnowledgeBaseVisibility.Published,
  translationMissing: false,
  answerCount: 0,
  subcategoryCount: 0,
  position: id,
  isDeletable: true,
  policy: { update: true, destroy: true, createSubcategory: true, createAnswer: true },
})

const answer = (id: number, title: string) => ({
  node: {
    id: convertToGraphQLId('KnowledgeBase::Answer', id),
    title,
    visibility: EnumKnowledgeBaseVisibility.Published,
    translationMissing: false,
    position: id,
  },
})

// The category the examples browse, so both lists are on the page: a category has subcategories
//   and answers, the knowledge base root only categories.
const visitCategory = () => visitView('/knowledge-base/locale/en-us/category/1')

// What the browsed category holds. The counts are stated rather than left to the auto-mocker:
//   whether there is anything to sort is decided by them.
const mockCategoryContent = ({
  subcategories = [category(2, 'Hardware'), category(3, 'Software')],
  answers = [answer(1, 'First answer'), answer(2, 'Second answer')],
  editor = true,
  categorySortingMode = Manual,
  answerSortingMode = Manual,
} = {}) => {
  mockKnowledgeBaseCategorySubcategoriesQuery({
    knowledgeBaseCategorySubcategories: {
      category: {
        ...category(1, 'Category'),
        categorySortingMode,
        answerSortingMode,
        policy: {
          update: editor,
          destroy: editor,
          createSubcategory: editor,
          createAnswer: editor,
        },
        directSubcategoryCount: subcategories.length,
        directAnswerCount: answers.length,
        breadcrumb: [{ id: CATEGORY_ID, title: 'Category', categoryIcon: 'folder' }],
      },
      subcategories,
    },
  })

  mockKnowledgeBaseAnswersQuery({
    knowledgeBaseAnswers: {
      totalCount: answers.length,
      edges: answers,
      pageInfo: { endCursor: null, hasNextPage: false },
    },
  })
}

// The knowledge base root, which lists top level categories and holds no answers of its own -
//   the other of the two nodes the sorting bar is offered on.
const visitRoot = async () => {
  mockKnowledgeBaseCategorySubcategoriesQuery({
    knowledgeBaseCategorySubcategories: {
      category: null,
      subcategories: [category(2, 'Hardware'), category(3, 'Software')],
    },
  })

  return visitView('/knowledge-base')
}

const save = async (view: Awaited<ReturnType<typeof visitCategory>>) =>
  view.events.click(await view.findByRole('button', { name: 'Save' }))

// The mode tabs of the bar, told apart from the scope tabs by their names.
const pickMode = async (
  view: Awaited<ReturnType<typeof visitCategory>>,
  mode: 'Sort by drag & drop' | 'Sort alphabetically' | 'Sort by latest updates',
) => view.events.click(await view.findByRole('tab', { name: mode }))

// The arguments a listing query was last sent with, which is what says in whose order the
//   listing on screen was fetched. No `sortingMode` there is the node's own stored mode.
const subcategoriesCalls = () => getGraphQLMockCalls(KnowledgeBaseCategorySubcategoriesDocument)

const answersCalls = () => getGraphQLMockCalls(KnowledgeBaseAnswersDocument)

const lastCallVariables = (calls: () => { variables: Record<string, unknown> }[]) =>
  calls().at(-1)?.variables

// The entry lives behind the header's action menu.
const openHeaderMenu = async (view: Awaited<ReturnType<typeof visitCategory>>) => {
  const menuButtons = await view.findAllByRole('button', { name: 'Additional actions' })

  await view.events.click(menuButtons[0])
}

// Which of the two lists is arranged. The scope tabs and the mode tabs are both tab groups, so
//   the names are what tells them apart.
const switchScope = async (
  view: Awaited<ReturnType<typeof visitCategory>>,
  scope: 'Answers' | 'Categories',
) => view.events.click(await view.findByRole('tab', { name: scope }))

describe('knowledge base sorting', () => {
  beforeEach(() => {
    resetKnowledgeBaseSorting()

    mockApplicationConfig({ kb_active_publicly: true })
    mockPermissions(['knowledge_base.editor'])

    mockKnowledgeBaseQuery({
      knowledgeBase: {
        id: convertToGraphQLId('KnowledgeBase', 1),
        title: 'My Knowledge Base',
        iconset: 'default',
        isPubliclyAvailable: true,
        isVisiblePublicly: true,
        policy: { update: true },
        // Stated, not left to the auto-mocker: it is what puts the RSS entry in the header menu,
        //   so without it the menu button itself comes and goes between runs.
        showFeedIcon: true,
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

    mockCategoryContent()
  })

  it('offers sorting the content to an editor', async () => {
    const view = await visitCategory()

    await openHeaderMenu(view)

    expect(await view.findByText('Sort content')).toBeInTheDocument()
  })

  // The picker changes what everyone browsing sees, so it follows the same per-record gate the
  //   other editing actions do rather than the global editor permission.
  it('does not offer sorting to someone who may not edit the category', async () => {
    mockCategoryContent({ editor: false })

    const view = await visitCategory()

    await openHeaderMenu(view)

    expect(view.queryByText('Sort content')).not.toBeInTheDocument()
  })

  // The mode is stored on the category and applies to everything that arrives under it later, so
  //   it is worth picking before there is any content to see it on - nothing about what the
  //   category holds right now gates the entry.
  it('offers sorting an empty category', async () => {
    mockCategoryContent({ subcategories: [], answers: [] })

    const view = await visitCategory()

    await openHeaderMenu(view)

    expect(await view.findByText('Sort content')).toBeInTheDocument()
  })

  // The add cards step aside while sorting, so without one of these the scope would be a blank
  //   page. Visibility rather than presence: the scope not in view stays rendered but hidden.
  it('says so when the scope being arranged holds nothing', async () => {
    mockCategoryContent({ subcategories: [], answers: [] })

    const view = await visitCategory()

    armKnowledgeBaseSorting()

    expect(await view.findByText('There are no categories to arrange yet.')).toBeVisible()
    expect(view.getByText('There are no answers to arrange yet.')).not.toBeVisible()

    await switchScope(view, 'Answers')

    await waitFor(() => {
      expect(view.getByText('There are no answers to arrange yet.')).toBeVisible()
    })

    expect(view.getByText('There are no categories to arrange yet.')).not.toBeVisible()
  })

  // With nothing on screen to drag, the empty state has to say what picking a mode is still good
  //   for - the mode is stored on the category and places whatever arrives under it later.
  it('says what the mode it is picked with will apply to', async () => {
    mockCategoryContent({ subcategories: [], answers: [] })

    const view = await visitCategory()

    armKnowledgeBaseSorting()

    expect(
      await view.findByText('The sorting mode you save here will apply to categories added later.'),
    ).toBeVisible()

    await switchScope(view, 'Answers')

    await waitFor(() => {
      expect(
        view.getByText('The sorting mode you save here will apply to answers added later.'),
      ).toBeVisible()
    })
  })

  it('arms the rearrange state from the menu', async () => {
    const view = await visitCategory()

    await openHeaderMenu(view)
    await view.events.click(await view.findByText('Sort content'))

    expect(await view.findByRole('tab', { name: 'Sort by drag & drop' })).toBeInTheDocument()
  })

  // The bar opens on what the browsed node is actually stored with, not on a default - otherwise
  //   it would show a mode the content is not in, and Save would look like a no-op.
  it('starts each list from the mode it is stored with', async () => {
    mockCategoryContent({
      categorySortingMode: Alphabetical,
      answerSortingMode: LastUpdate,
    })

    const view = await visitCategory()

    await openHeaderMenu(view)
    await view.events.click(await view.findByText('Sort content'))

    await waitFor(() => {
      expect(view.getByRole('tab', { name: 'Sort alphabetically' })).toHaveAttribute(
        'aria-selected',
        'true',
      )
    })

    // Nothing was picked yet, so there is nothing to save.
    expect(view.getByRole('button', { name: 'Save' })).toBeDisabled()

    await switchScope(view, 'Answers')

    expect(view.getByRole('tab', { name: 'Sort by latest updates' })).toHaveAttribute(
      'aria-selected',
      'true',
    )
  })

  // The layout's own bottom bar, which spans the content area and shortens it. It must not be
  //   reserved while nothing is being sorted, which is why the slot itself is conditional.
  it('puts the bar in the layout bottom bar, and only while sorting', async () => {
    const view = await visitCategory()

    expect(view.queryByRole('contentinfo')).not.toBeInTheDocument()
    expect(await view.findByRole('toolbar', { name: 'Knowledge base actions' })).toBeInTheDocument()

    armKnowledgeBaseSorting()

    const bottomBar = await view.findByRole('contentinfo')

    expect(within(bottomBar).getByRole('tab', { name: 'Sort by drag & drop' })).toBeInTheDocument()
    expect(within(bottomBar).getByRole('button', { name: 'Save' })).toBeInTheDocument()
    expect(within(bottomBar).getByRole('button', { name: 'Cancel' })).toBeInTheDocument()

    // The floating add shortcuts step aside for it.
    expect(view.queryByRole('toolbar', { name: 'Knowledge base actions' })).not.toBeInTheDocument()
  })

  it('offers a scope to arrange, counting what each one holds', async () => {
    const view = await visitCategory()

    expect(view.queryByRole('tablist', { name: 'Content type' })).not.toBeInTheDocument()

    armKnowledgeBaseSorting()

    const scopes = await view.findByRole('tablist', { name: 'Content type' })

    expect(within(scopes).getByRole('tab', { name: 'Categories' })).toHaveTextContent('2')
    expect(within(scopes).getByRole('tab', { name: 'Answers' })).toHaveTextContent('2')
  })

  // An empty entry is what tells an editor that content of that kind belongs here, and where the
  //   next one will land - so it is offered rather than dropped.
  it('offers the answers entry when the category holds none', async () => {
    mockCategoryContent({ answers: [] })

    const view = await visitCategory()

    armKnowledgeBaseSorting()

    expect(await view.findByRole('tab', { name: 'Answers' })).toHaveTextContent('0')
  })

  it('starts on the categories scope', async () => {
    const view = await visitCategory()

    armKnowledgeBaseSorting()

    expect(await view.findByRole('tab', { name: 'Categories' })).toHaveAttribute(
      'aria-selected',
      'true',
    )
  })

  // Otherwise the only list there is to arrange sits behind a tab switch, below an empty one.
  it('starts on the answers scope when the category holds only answers', async () => {
    mockCategoryContent({ subcategories: [] })

    const view = await visitCategory()

    armKnowledgeBaseSorting()

    await waitFor(() => {
      expect(view.getByRole('tab', { name: 'Answers' })).toHaveAttribute('aria-selected', 'true')
    })

    expect(view.getByRole('tab', { name: 'Categories' })).toHaveAttribute('aria-selected', 'false')
  })

  // Nothing to prefer when neither list holds anything: the categories are where the page starts.
  it('starts on the categories scope when the category is empty', async () => {
    mockCategoryContent({ subcategories: [], answers: [] })

    const view = await visitCategory()

    armKnowledgeBaseSorting()

    expect(await view.findByRole('tab', { name: 'Categories' })).toHaveAttribute(
      'aria-selected',
      'true',
    )
  })

  // The root holds no answers and never will, so a zero there would promise something that cannot
  //   arrive - and a single entry is nothing to pick between.
  it('offers no scope picker at the knowledge base root', async () => {
    const view = await visitView('/knowledge-base/locale/en-us')

    armKnowledgeBaseSorting()

    expect(await view.findByRole('tab', { name: 'Sort by drag & drop' })).toBeInTheDocument()
    expect(view.queryByRole('tablist', { name: 'Content type' })).not.toBeInTheDocument()
  })

  // One Save at the bottom for the whole state: both lists can be arranged before it is pressed,
  //   so switching between them must carry what was already done along.
  it('keeps an order staged in the scope left behind', async () => {
    const view = await visitCategory()
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()

    const categoryList = await view.findByRole('list', { name: 'Category order list' })
    categoryList.focus()
    await view.events.keyboard('{Space}{ArrowDown}{Space}')

    await switchScope(view, 'Answers')

    const answerList = await view.findByRole('list', { name: 'Answer order list' })
    answerList.focus()
    await view.events.keyboard('{Space}{ArrowDown}{Space}')

    expect(sorting.pendingChanges.value).toEqual([
      {
        scope: 'categories',
        sortingMode: Manual,
        orderedIds: [
          convertToGraphQLId('KnowledgeBase::Category', 3),
          convertToGraphQLId('KnowledgeBase::Category', 2),
        ],
      },
      {
        scope: 'answers',
        sortingMode: Manual,
        orderedIds: [
          convertToGraphQLId('KnowledgeBase::Answer', 2),
          convertToGraphQLId('KnowledgeBase::Answer', 1),
        ],
      },
    ])
  })

  it('shows the sorting bar in place of the search bar', async () => {
    const view = await visitCategory()

    // By its placeholder: the main sidebar carries a search box of its own.
    expect(await view.findByPlaceholderText('Search within Category…')).toBeInTheDocument()

    armKnowledgeBaseSorting()

    expect(await view.findByRole('tab', { name: 'Sort by drag & drop' })).toBeInTheDocument()
    expect(view.queryByPlaceholderText('Search within Category…')).not.toBeInTheDocument()
  })

  // Acceptance criterion: while the mode is armed, entering a category or an answer must not be
  //   possible - it would abandon an order the editor has not saved yet.
  it('cannot be navigated while rearranging, in either scope', async () => {
    const view = await visitCategory()

    // Asked of the card's own heading rather than of a link role: both cards keep rendering
    //   everything they have, and it is only their surrounding <a> that goes.
    const categoryTile = await view.findByRole('heading', { name: 'Hardware' })
    const answerRow = await view.findByRole('heading', { name: 'First answer' })

    expect(categoryTile.closest('a')).not.toBeNull()
    expect(answerRow.closest('a')).not.toBeNull()

    armKnowledgeBaseSorting()

    await waitFor(() => {
      expect(view.getByRole('heading', { name: 'Hardware' }).closest('a')).toBeNull()
    })

    await switchScope(view, 'Answers')

    await waitFor(() => {
      expect(view.getByRole('heading', { name: 'First answer' }).closest('a')).toBeNull()
    })
  })

  // Only one list is arranged at a time, so only one is on screen. The other stays rendered but
  //   hidden, which is what lets an order staged in it survive the switch.
  it('shows one scope at a time', async () => {
    const view = await visitCategory()

    armKnowledgeBaseSorting()

    await waitFor(() => {
      expect(view.queryByRole('heading', { name: 'First answer' })).not.toBeInTheDocument()
    })

    expect(view.getByRole('heading', { name: 'Hardware' })).toBeInTheDocument()

    await switchScope(view, 'Answers')

    await waitFor(() => {
      expect(view.queryByRole('heading', { name: 'Hardware' })).not.toBeInTheDocument()
    })

    expect(view.getByRole('heading', { name: 'First answer' })).toBeInTheDocument()
  })

  it('moves the drag handles to the scope being arranged', async () => {
    const view = await visitCategory()

    expect(view.queryAllByIconName('grip-vertical')).toHaveLength(0)

    armKnowledgeBaseSorting()

    // The two categories, and nothing on the answers - they are not the list being arranged.
    await waitFor(() => {
      expect(view.getAllByIconName('grip-vertical')).toHaveLength(2)
    })

    expect(view.getByRole('list', { name: 'Category order list' })).toBeInTheDocument()

    await switchScope(view, 'Answers')

    await waitFor(() => {
      expect(view.getByRole('list', { name: 'Answer order list' })).toBeInTheDocument()
    })

    expect(view.getAllByIconName('grip-vertical')).toHaveLength(2)
  })

  // Neither is a category or an answer, so neither may take part in an order that is sent as the
  //   complete set of its scope.
  it('drops the add cards and the row filler from the draggable lists', async () => {
    const view = await visitCategory()

    expect(await view.findByText('Add category')).toBeInTheDocument()
    expect(view.getByText('Add answer')).toBeInTheDocument()

    armKnowledgeBaseSorting()

    await waitFor(() => {
      expect(view.queryByText('Add category')).not.toBeInTheDocument()
    })

    expect(
      within(view.getByRole('list', { name: 'Category order list' })).getAllByRole('listitem'),
    ).toHaveLength(2)

    await switchScope(view, 'Answers')

    await waitFor(() => {
      expect(view.queryByText('Add answer')).not.toBeInTheDocument()
    })

    expect(
      within(view.getByRole('list', { name: 'Answer order list' })).getAllByRole('listitem'),
    ).toHaveLength(2)
  })

  // The keyboard path is the one JSDOM can drive - a pointer drag needs client rectangles it does
  //   not provide. It swaps two items and is what the pointer drag ends up doing as well.
  it('stages a category order made by keyboard', async () => {
    const view = await visitCategory()
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()

    const categoryList = await view.findByRole('list', { name: 'Category order list' })
    categoryList.focus()

    await view.events.keyboard('{Space}')
    await view.events.keyboard('{ArrowDown}')
    await view.events.keyboard('{Space}')

    expect(sorting.isDirty.value).toBe(true)
    expect(sorting.pendingChanges.value).toEqual([
      {
        scope: 'categories',
        sortingMode: Manual,
        orderedIds: [
          convertToGraphQLId('KnowledgeBase::Category', 3),
          convertToGraphQLId('KnowledgeBase::Category', 2),
        ],
      },
    ])
  })

  // Sideways as much as up and down: the tiles are a grid, and the arrow key that points along a
  //   row has to move along it. Which row a tile sits in is the grid's own, so JSDOM - which lays
  //   nothing out - sees the single column every arrow steps by one item in (see the composable's
  //   own spec for the grid geometry).
  it('stages a category order made sideways by keyboard', async () => {
    const view = await visitCategory()
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()

    const categoryList = await view.findByRole('list', { name: 'Category order list' })
    categoryList.focus()

    await view.events.keyboard('{Space}')
    await view.events.keyboard('{ArrowRight}')
    await view.events.keyboard('{Space}')

    expect(sorting.pendingChanges.value).toEqual([
      {
        scope: 'categories',
        sortingMode: Manual,
        orderedIds: [
          convertToGraphQLId('KnowledgeBase::Category', 3),
          convertToGraphQLId('KnowledgeBase::Category', 2),
        ],
      },
    ])
  })

  // The outline is the only thing that says where the keyboard is, and it is drawn by a variant
  //   that reads the list's focus - so it only ever appears while the list is marked as the group
  //   the tiles look up to.
  it('outlines the tile the keyboard is on', async () => {
    const view = await visitCategory()

    armKnowledgeBaseSorting()

    const categoryList = await view.findByRole('list', { name: 'Category order list' })
    expect(categoryList).toHaveClass('group')

    categoryList.focus()

    // The outline classes style the tile itself - the rounded, backed card a category card
    //   renders inside its `<li>` - not the plain list item wrapping it.
    await waitFor(() => {
      expect(within(categoryList).getAllByRole('listitem')[0].firstElementChild).toHaveClass(
        'group-focus-visible:outline',
      )
    })

    await view.events.keyboard('{Space}')

    expect(within(categoryList).getAllByRole('listitem')[0].firstElementChild).toHaveClass(
      'outline',
    )
  })

  it('stages an answer order made by keyboard', async () => {
    const view = await visitCategory()
    const sorting = useKnowledgeBaseSorting()

    armKnowledgeBaseSorting()
    await switchScope(view, 'Answers')

    const answerList = await view.findByRole('list', { name: 'Answer order list' })
    answerList.focus()

    await view.events.keyboard('{Space}')
    await view.events.keyboard('{ArrowDown}')
    await view.events.keyboard('{Space}')

    expect(sorting.pendingChanges.value).toEqual([
      {
        scope: 'answers',
        sortingMode: Manual,
        orderedIds: [
          convertToGraphQLId('KnowledgeBase::Answer', 2),
          convertToGraphQLId('KnowledgeBase::Answer', 1),
        ],
      },
    ])
  })

  // An automatic mode is the server's to apply, so there is nothing to drag and nothing staged.
  it('stops rearranging when an automatic mode is picked', async () => {
    const view = await visitCategory()

    armKnowledgeBaseSorting()

    await waitFor(() => {
      expect(view.getAllByIconName('grip-vertical')).toHaveLength(2)
    })

    await pickMode(view, 'Sort alphabetically')

    await waitFor(() => {
      expect(view.queryAllByIconName('grip-vertical')).toHaveLength(0)
    })

    expect(view.queryByRole('list', { name: 'Category order list' })).not.toBeInTheDocument()
  })

  // The bar is up in every one of its modes, and every card action leads away from a mode the
  //   editor has not saved yet - an automatic one just as much as a hand-made order.
  it('keeps the cards out of reach in an automatic mode too', async () => {
    const view = await visitCategory()

    armKnowledgeBaseSorting()

    await pickMode(view, 'Sort alphabetically')

    await waitFor(() => {
      expect(view.getByRole('heading', { name: 'Hardware' }).closest('a')).toBeNull()
    })

    expect(view.queryByRole('button', { name: 'Category actions' })).not.toBeInTheDocument()

    await switchScope(view, 'Answers')

    await pickMode(view, 'Sort by latest updates')

    await waitFor(() => {
      expect(view.getByRole('heading', { name: 'First answer' }).closest('a')).toBeNull()
    })

    expect(view.queryByRole('button', { name: 'Answer actions' })).not.toBeInTheDocument()
  })

  // What a category holds says nothing about where it belongs in the order.
  it('hides the category counts while the bar is up', async () => {
    mockCategoryContent({
      subcategories: [
        { ...category(2, 'Hardware'), subcategoryCount: 7, answerCount: 9 },
        category(3, 'Software'),
      ],
    })

    const view = await visitCategory()

    expect(await view.findByLabelText('Category count: 7')).toBeInTheDocument()
    expect(view.getByLabelText('Answer count: 9')).toBeInTheDocument()

    armKnowledgeBaseSorting()

    await waitFor(() => {
      expect(view.queryByLabelText('Category count: 7')).not.toBeInTheDocument()
    })

    expect(view.queryByLabelText('Answer count: 9')).not.toBeInTheDocument()
  })

  // The preview is the listing itself, fetched in the picked mode: KnowledgeBase::Category /
  //   KnowledgeBase::Answer.sorted_by_mode is the one place the order of a listing is decided, for
  //   the desktop view and the public help site alike, so it decides the preview as well.
  describe('previewing a mode', () => {
    it('lists the categories in the picked mode', async () => {
      const view = await visitCategory()

      armKnowledgeBaseSorting()

      await pickMode(view, 'Sort alphabetically')

      await waitFor(() => {
        expect(lastCallVariables(subcategoriesCalls)).toMatchObject({
          categoryId: CATEGORY_ID,
          sortingMode: Alphabetical,
        })
      })
    })

    it('lists the answers in the picked mode', async () => {
      const view = await visitCategory()

      armKnowledgeBaseSorting()

      await switchScope(view, 'Answers')
      await view.findByRole('list', { name: 'Answer order list' })

      await pickMode(view, 'Sort by latest updates')

      await waitFor(() => {
        expect(lastCallVariables(answersCalls)).toMatchObject({
          categoryId: CATEGORY_ID,
          sortingMode: LastUpdate,
        })
      })
    })

    // The round-trip would deliver the very order already on screen, and it would land after the
    //   editor started dragging - throwing away the order they had just made.
    it('does not refetch a list for the mode it is already stored in', async () => {
      const view = await visitCategory()

      await waitFor(() => expect(subcategoriesCalls().length).toBeGreaterThan(0))

      const callsBeforeArming = subcategoriesCalls().length

      armKnowledgeBaseSorting({ categories: Manual, answers: Manual })

      await view.findByRole('list', { name: 'Category order list' })

      expect(subcategoriesCalls()).toHaveLength(callsBeforeArming)
    })
  })
  describe('saving', () => {
    // A category arranges the list below it, so the mutation names it as the parent - and a
    //   `manual` order always names every record of the scope, which is what the backend
    //   requires to number them.
    it('sends a rearranged category order to the category mutation', async () => {
      const view = await visitCategory()

      armKnowledgeBaseSorting()

      const categoryList = await view.findByRole('list', { name: 'Category order list' })
      categoryList.focus()
      await view.events.keyboard('{Space}{ArrowDown}{Space}')

      await save(view)

      const calls = await waitForKnowledgeBaseReorderCategoriesMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        parentCategoryId: CATEGORY_ID,
        sortingMode: Manual,
        categoryIds: [
          convertToGraphQLId('KnowledgeBase::Category', 3),
          convertToGraphQLId('KnowledgeBase::Category', 2),
        ],
      })
    })

    it('sends a rearranged answer order to the answer mutation', async () => {
      const view = await visitCategory()

      armKnowledgeBaseSorting()
      await switchScope(view, 'Answers')

      const answerList = await view.findByRole('list', { name: 'Answer order list' })
      answerList.focus()
      await view.events.keyboard('{Space}{ArrowDown}{Space}')

      await save(view)

      const calls = await waitForKnowledgeBaseReorderAnswersMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        categoryId: CATEGORY_ID,
        sortingMode: Manual,
        answerIds: [
          convertToGraphQLId('KnowledgeBase::Answer', 2),
          convertToGraphQLId('KnowledgeBase::Answer', 1),
        ],
      })
    })

    // The top level has no parent category to name, so it goes to a mutation of its own.
    it('sends the top level order to the root mutation', async () => {
      const view = await visitRoot()

      armKnowledgeBaseSorting()

      const categoryList = await view.findByRole('list', { name: 'Category order list' })
      categoryList.focus()
      await view.events.keyboard('{Space}{ArrowDown}{Space}')

      await save(view)

      const calls = await waitForKnowledgeBaseReorderRootCategoriesMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        sortingMode: Manual,
        categoryIds: [
          convertToGraphQLId('KnowledgeBase::Category', 3),
          convertToGraphQLId('KnowledgeBase::Category', 2),
        ],
      })
    })

    // An automatic mode is the server's to apply and the backend refuses a list sent alongside
    //   one, so the mode travels alone.
    it('sends an automatic mode without an order', async () => {
      const view = await visitCategory()

      armKnowledgeBaseSorting()

      await view.events.click(await view.findByRole('tab', { name: 'Sort alphabetically' }))
      await save(view)

      const calls = await waitForKnowledgeBaseReorderCategoriesMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        parentCategoryId: CATEGORY_ID,
        sortingMode: Alphabetical,
        categoryIds: undefined,
      })
    })

    // One Save for the whole state: each list goes to the mutation of its own scope.
    it('saves both lists in one go', async () => {
      const view = await visitCategory()

      armKnowledgeBaseSorting()

      const categoryList = await view.findByRole('list', { name: 'Category order list' })
      categoryList.focus()
      await view.events.keyboard('{Space}{ArrowDown}{Space}')

      await switchScope(view, 'Answers')

      const answerList = await view.findByRole('list', { name: 'Answer order list' })
      answerList.focus()
      await view.events.keyboard('{Space}{ArrowDown}{Space}')

      await save(view)

      expect((await waitForKnowledgeBaseReorderCategoriesMutationCalls()).at(-1)).toBeDefined()
      expect((await waitForKnowledgeBaseReorderAnswersMutationCalls()).at(-1)).toBeDefined()
    })

    it('leaves the rearrange state once everything went through', async () => {
      const view = await visitCategory()
      const sorting = useKnowledgeBaseSorting()

      armKnowledgeBaseSorting()

      const categoryList = await view.findByRole('list', { name: 'Category order list' })
      categoryList.focus()
      await view.events.keyboard('{Space}{ArrowDown}{Space}')

      await save(view)
      await waitForKnowledgeBaseReorderCategoriesMutationCalls()

      await waitFor(() => {
        expect(sorting.isArmed.value).toBe(false)
      })

      expect(view.queryByRole('button', { name: 'Save' })).not.toBeInTheDocument()
    })

    // Nothing moved is nothing to send - Save just leaves the state.
    it('sends nothing when nothing was changed', async () => {
      const view = await visitCategory()

      armKnowledgeBaseSorting()

      await waitFor(() => {
        expect(view.getByRole('button', { name: 'Save' })).toBeDisabled()
      })
    })
  })
})
