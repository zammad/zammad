// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'

import {
  EnumKnowledgeBaseSearchEntity,
  EnumKnowledgeBaseVisibility,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseSearchQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseSearch.mocks.ts'

import KnowledgeBaseSearchResults from '../KnowledgeBaseSearchResults.vue'

const routerRoutes = [
  { name: 'Dashboard', path: '/', component: { template: '<div />' } },
  {
    name: 'KnowledgeBaseBrowse',
    path: '/knowledge-base/locale/:localeCode?',
    component: { template: '<div />' },
  },
  {
    name: 'KnowledgeBaseAnswer',
    path: '/knowledge-base/locale/:localeCode/answer/:answerInternalId(\\d+)',
    component: { template: '<div />' },
  },
  // A category result links to the category's browse page, as the browse card does.
  {
    name: 'KnowledgeBaseCategory',
    path: '/knowledge-base/locale/:localeCode/category/:categoryInternalId(\\d+)',
    component: { template: '<div />' },
  },
]

const answerHit = (id: number, title: string) => ({
  node: {
    item: {
      __typename: 'KnowledgeBaseAnswer' as const,
      id: convertToGraphQLId('KnowledgeBase::Answer', id),
      title,
      visibility: EnumKnowledgeBaseVisibility.Published,
      translationMissing: false,
    },
    titlePreview: [{ text: title, highlight: true }],
    bodyPreview: [],
    categoryPath: [],
  },
})

const categoryHit = (id: number, title: string) => ({
  node: {
    item: {
      __typename: 'KnowledgeBaseCategory' as const,
      id: convertToGraphQLId('KnowledgeBase::Category', id),
      translation: {
        id: convertToGraphQLId('KnowledgeBase::Category::Translation', id),
        title,
      },
      categoryIcon: 'f115',
      iconSet: 'FontAwesome' as const,
      visibility: EnumKnowledgeBaseVisibility.Published,
    },
    titlePreview: [{ text: title, highlight: true }],
    bodyPreview: [],
    categoryPath: [],
  },
})

const renderResults = async (
  props = {},
  entity: EnumKnowledgeBaseSearchEntity = EnumKnowledgeBaseSearchEntity.Answer,
) => {
  const view = renderComponent(KnowledgeBaseSearchResults, {
    router: true,
    routerRoutes,
    props: { query: 'printer', locale: 'en-us', ...props },
    // Through the model rather than as a plain prop: the tab group echoes its resolved selection
    //   back on mount, and a prop the parent never updates would leave the two out of step.
    vModel: { entity },
  })

  await getTestRouter().push('/knowledge-base/locale/en-us')
  await flushPromises()

  return view
}

const noMore = { endCursor: null, hasNextPage: false }

const defaultAnswers = {
  totalCount: 2,
  edges: [answerHit(1, 'Printer setup'), answerHit(2, 'Printer drivers')],
}

// Both searches run and share one document, so the mock answers by the kind that was asked for -
//   with a different total each, so an example can tell the two tabs' counts apart.
const mockSearches = (answers = defaultAnswers) =>
  mockKnowledgeBaseSearchQuery(({ entity }) =>
    entity === EnumKnowledgeBaseSearchEntity.Category
      ? {
          knowledgeBaseSearch: {
            totalCount: 4,
            edges: [categoryHit(1, 'Printers'), categoryHit(2, 'Printer drivers')],
            pageInfo: noMore,
          },
        }
      : { knowledgeBaseSearch: { ...answers, pageInfo: noMore } },
  )

describe('KnowledgeBaseSearchResults', () => {
  beforeEach(() => {
    mockSearches()
  })

  it('lists the hits of the searched term', async () => {
    const view = await renderResults()

    expect(await view.findByText('Printer setup')).toBeInTheDocument()
    expect(view.getByText('Printer drivers')).toBeInTheDocument()
    expect(view.queryByText('No search results for this query.')).not.toBeInTheDocument()
  })

  describe('tab control', () => {
    // The answers lead, which is the order the page reads in and the tab the search starts on.
    it('offers both kinds of content, answers first', async () => {
      const view = await renderResults()

      const tabs = view.getAllByRole('tab')

      expect(tabs[0]).toHaveAccessibleName('Answers')
      expect(tabs[1]).toHaveAccessibleName('Categories')
    })

    // Each count comes from that kind's own search, both of which always run - which is what
    //   lets the tab that is not shown carry a number at all.
    it('shows a count on both tabs', async () => {
      const view = await renderResults()

      await expect(view.findByRole('tab', { name: 'Answers' })).resolves.toHaveTextContent('2')
      expect(view.getByRole('tab', { name: 'Categories' })).toHaveTextContent('4')
    })

    // The tabs carry an `aria-controls` in single-tab mode, so the results they swap have to be
    //   the panel it points at - otherwise both tabs reference an id that does not exist.
    it('marks the results as the panel the tabs control', async () => {
      const view = await renderResults()

      const panel = view.getByRole('tabpanel')

      expect(panel).toHaveAttribute('id', 'tab-panel-answers')
      expect(panel).toHaveAccessibleName('Answers')
      expect(view.getByRole('tab', { name: 'Answers' })).toHaveAttribute(
        'aria-controls',
        'tab-panel-answers',
      )
    })

    it('marks the listed kind as the selected tab', async () => {
      const view = await renderResults({}, EnumKnowledgeBaseSearchEntity.Category)

      expect(view.getByRole('tab', { name: 'Categories' })).toHaveAttribute('aria-selected', 'true')
      expect(view.getByRole('tab', { name: 'Answers' })).toHaveAttribute('aria-selected', 'false')
    })

    it('reports the kind the user picked', async () => {
      const view = await renderResults()

      await view.events.click(view.getByRole('tab', { name: 'Categories' }))

      expect(view.emitted()['update:entity'].at(-1)).toEqual([
        EnumKnowledgeBaseSearchEntity.Category,
      ])
    })

    // Each tab is a focusable button, activated with Enter - CommonTabGroup implements no
    //   arrow-key roving tabindex, and the strip puts its own scroll buttons in the tab order,
    //   so this asserts the tab itself rather than a position in that order.
    it('is focusable and switchable by keyboard', async () => {
      const view = await renderResults()

      const categories = view.getByRole('tab', { name: 'Categories' })

      categories.focus()
      expect(categories).toHaveFocus()

      await view.events.keyboard('{Enter}')

      expect(view.emitted()['update:entity'].at(-1)).toEqual([
        EnumKnowledgeBaseSearchEntity.Category,
      ])
    })
  })

  // A category found by searching has to look like the same category found by browsing, so its
  //   hits are laid out in the browse view's card grid while the answers stay a list.
  describe('category hits', () => {
    it('lays the categories out in a grid', async () => {
      const view = await renderResults({}, EnumKnowledgeBaseSearchEntity.Category)

      expect(await view.findByText('Printers')).toBeInTheDocument()
      expect(view.getByRole('list')).toHaveClass('grid')
    })

    it('keeps the answers a list', async () => {
      const view = await renderResults()

      expect(await view.findByText('Printer setup')).toBeInTheDocument()
      expect(view.getByRole('list')).toHaveClass('flex-col')
    })
  })

  describe('without hits', () => {
    // No answers, while the categories still have four - which is what the other tab keeps
    //   showing beside the empty state.
    beforeEach(() => {
      mockSearches({ totalCount: 0, edges: [] })
    })

    it('shows the empty state', async () => {
      const view = await renderResults()

      expect(await view.findByText('No search results for this query.')).toBeInTheDocument()
      expect(view.getByRole('status')).toBeInTheDocument()
    })

    it('offers to clear the search', async () => {
      const view = await renderResults()

      await view.events.click(await view.findByRole('button', { name: 'Clear search' }))

      expect(view.emitted('clear-search')).toHaveLength(1)
    })

    // The empty state belongs to the selected tab alone; the other tab keeps its count, which is
    //   how the user sees there are hits of the other kind.
    it('leaves the other tab its count', async () => {
      const view = await renderResults()

      expect(await view.findByText('No search results for this query.')).toBeInTheDocument()
      expect(view.getByRole('tab', { name: 'Categories' })).toHaveTextContent('4')
    })
  })
})
