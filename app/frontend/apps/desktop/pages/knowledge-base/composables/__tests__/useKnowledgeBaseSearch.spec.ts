// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'
import { defineComponent, toRef } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { KnowledgeBaseSearchDocument } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseSearch.api.ts'
import {
  mockKnowledgeBaseSearchQuery,
  waitForKnowledgeBaseSearchQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseSearch.mocks.ts'
import { getKnowledgeBaseContentUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseContentUpdates.mocks.ts'

import { useKnowledgeBaseSearch } from '../useKnowledgeBaseSearch.ts'

const KB_ID = convertToGraphQLId('KnowledgeBase', 1)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)
const SIBLING_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 3)

const routerRoutes = [
  { name: 'Dashboard', path: '/', component: { template: '<div />' } },
  {
    name: 'KnowledgeBaseBrowse',
    path: '/knowledge-base/locale/:localeCode?',
    component: { template: '<div />' },
  },
  {
    name: 'KnowledgeBaseCategory',
    path: '/knowledge-base/locale/:localeCode/category/:categoryInternalId(\\d+)',
    component: { template: '<div />' },
  },
]

const searchResult = (id: number, title: string) => ({
  node: {
    item: {
      __typename: 'KnowledgeBaseAnswer' as const,
      id: convertToGraphQLId('KnowledgeBase::Answer', id),
      title,
      visibility: EnumKnowledgeBaseVisibility.Published,
      translationMissing: false,
    },
    titlePreview: [{ text: title, highlight: true }],
    bodyPreview: [{ text: 'Some body text', highlight: false }],
    categoryPath: [{ id: CATEGORY_ID, title: 'Category One' }],
  },
})

let api: ReturnType<typeof useKnowledgeBaseSearch>

const TestComponent = defineComponent({
  props: {
    query: { type: String, default: '' },
    categoryId: { type: String, default: undefined },
    locale: { type: String, default: undefined },
  },
  setup(props) {
    api = useKnowledgeBaseSearch({
      query: toRef(props, 'query'),
      categoryId: toRef(props, 'categoryId'),
      locale: toRef(props, 'locale'),
    })
    return () => null
  },
})

const mountComposable = (props: { query?: string; categoryId?: string; locale?: string } = {}) =>
  renderComponent(TestComponent, { props, router: true, routerRoutes })

// The content-updates subscription is only active while a locale is browsed, so
//   put the router on a localized knowledge base route before emitting a ping.
const triggerContentUpdate = async (affectedCategoryIds: string[]) => {
  await getTestRouter().push('/knowledge-base/locale/en-us/category/1')
  await flushPromises()

  const handler = await waitFor(() => {
    const subscription = getKnowledgeBaseContentUpdatesSubscriptionHandler()
    expect(subscription).toBeTruthy()
    return subscription
  })

  await handler.trigger({
    knowledgeBaseContentUpdates: {
      knowledgeBase: { id: KB_ID },
      affectedCategoryIds,
    },
  })
}

describe('useKnowledgeBaseSearch', () => {
  beforeEach(() => {
    mockKnowledgeBaseSearchQuery({
      knowledgeBaseSearch: {
        totalCount: 2,
        edges: [searchResult(1, 'Result One'), searchResult(2, 'Result Two')],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })
  })

  it('stays idle while the search term is blank', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    expect(getGraphQLMockCalls(KnowledgeBaseSearchDocument)).toHaveLength(0)
    expect(api.results.value).toEqual([])
  })

  it('searches with the term, scope, locale and page size, and exposes the results', async () => {
    mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    const calls = await waitForKnowledgeBaseSearchQueryCalls()
    expect(calls).toHaveLength(1)
    expect(calls.at(-1)?.variables).toEqual({
      query: 'printer',
      categoryId: CATEGORY_ID,
      locale: 'en-us',
      pageSize: 30,
    })

    expect(
      api.results.value.map((result) =>
        result.item.__typename === 'KnowledgeBaseAnswer' ? result.item.title : undefined,
      ),
    ).toEqual(['Result One', 'Result Two'])
    expect(api.totalCount.value).toBe(2)
  })

  it('searches the whole knowledge base when no scope is given', async () => {
    mountComposable({ query: 'printer', locale: 'en-us' })
    await flushPromises()

    const calls = await waitForKnowledgeBaseSearchQueryCalls()
    expect(calls.at(-1)?.variables).toEqual({
      query: 'printer',
      locale: 'en-us',
      pageSize: 30,
    })

    // Without a scope, a change anywhere in the knowledge base is relevant.
    await triggerContentUpdate([SIBLING_CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(2)
    })
  })

  it('starts a fresh query when the searched scope switches', async () => {
    const view = mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await view.rerender({ categoryId: CHILD_CATEGORY_ID })

    await waitFor(async () => {
      const calls = await waitForKnowledgeBaseSearchQueryCalls()
      expect(calls).toHaveLength(2)
      expect(calls.at(-1)?.variables).toEqual({
        query: 'printer',
        categoryId: CHILD_CATEGORY_ID,
        locale: 'en-us',
        pageSize: 30,
      })
    })
  })

  it('refetches when a change happened anywhere in the searched subtree', async () => {
    mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    // The scope appearing only as an ancestor still matters here: unlike the
    //   answer list, a search covers the whole subtree.
    await triggerContentUpdate([CHILD_CATEGORY_ID, CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(2)
    })
  })

  it('refetches on a knowledge-base-wide change', async () => {
    mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(2)
    })
  })

  it('does not refetch when the change happened outside the searched subtree', async () => {
    mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([SIBLING_CATEGORY_ID])
    await flushPromises()

    expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(1)
  })
})
