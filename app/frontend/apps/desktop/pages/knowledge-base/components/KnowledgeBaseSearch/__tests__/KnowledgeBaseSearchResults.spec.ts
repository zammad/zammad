// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
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

const renderResults = async (props = {}) => {
  const view = renderComponent(KnowledgeBaseSearchResults, {
    router: true,
    routerRoutes,
    props: { query: 'printer', locale: 'en-us', ...props },
  })

  await getTestRouter().push('/knowledge-base/locale/en-us')
  await flushPromises()

  return view
}

describe('KnowledgeBaseSearchResults', () => {
  it('lists the hits of the searched term', async () => {
    mockKnowledgeBaseSearchQuery({
      knowledgeBaseSearch: {
        totalCount: 2,
        edges: [answerHit(1, 'Printer setup'), answerHit(2, 'Printer drivers')],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })

    const view = await renderResults()

    expect(await view.findByText('Printer setup')).toBeInTheDocument()
    expect(view.getByText('Printer drivers')).toBeInTheDocument()
    expect(view.queryByText('No search results for this query.')).not.toBeInTheDocument()
  })

  describe('without hits', () => {
    beforeEach(() => {
      mockKnowledgeBaseSearchQuery({
        knowledgeBaseSearch: {
          totalCount: 0,
          edges: [],
          pageInfo: { endCursor: null, hasNextPage: false },
        },
      })
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
  })
})
