// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'
import { defineComponent, toRef, type PropType } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  EnumKnowledgeBaseSearchEntity,
  EnumKnowledgeBaseVisibility,
} from '#shared/graphql/types.ts'
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

const answerHit = (id: number, title: string) => ({
  node: {
    item: {
      __typename: 'KnowledgeBaseAnswer' as const,
      id: convertToGraphQLId('KnowledgeBase::Answer', id),
      visibility: EnumKnowledgeBaseVisibility.Published,
      translation: {
        id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
        title,
      },
    },
    titlePreview: [{ text: title, highlight: true }],
    bodyPreview: [{ text: 'Some body text', highlight: false }],
    categoryPath: [{ id: CATEGORY_ID, title: 'Category One' }],
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

// The two searches share one document, so the mock answers by the kind that was asked for - with
//   a different total each, so an example can tell the two tabs' counts apart.
const mockBothSearches = () =>
  mockKnowledgeBaseSearchQuery(({ entity }) =>
    entity === EnumKnowledgeBaseSearchEntity.Category
      ? {
          knowledgeBaseSearch: {
            totalCount: 5,
            edges: [categoryHit(1, 'Printers')],
            pageInfo: { endCursor: null, hasNextPage: false },
          },
        }
      : {
          knowledgeBaseSearch: {
            totalCount: 2,
            edges: [answerHit(1, 'Result One'), answerHit(2, 'Result Two')],
            pageInfo: { endCursor: null, hasNextPage: false },
          },
        },
  )

let api: ReturnType<typeof useKnowledgeBaseSearch>

const TestComponent = defineComponent({
  props: {
    query: { type: String, default: '' },
    entity: {
      type: String as PropType<EnumKnowledgeBaseSearchEntity>,
      default: EnumKnowledgeBaseSearchEntity.Answer,
    },
    categoryId: { type: String, default: undefined },
    locale: { type: String, default: undefined },
  },
  setup(props) {
    api = useKnowledgeBaseSearch({
      query: toRef(props, 'query'),
      entity: toRef(props, 'entity'),
      categoryId: toRef(props, 'categoryId'),
      locale: toRef(props, 'locale'),
    })
    return () => null
  },
})

const mountComposable = (
  props: {
    query?: string
    entity?: EnumKnowledgeBaseSearchEntity
    categoryId?: string
    locale?: string
  } = {},
) => renderComponent(TestComponent, { props, router: true, routerRoutes })

const variablesFor = (
  calls: Awaited<ReturnType<typeof waitForKnowledgeBaseSearchQueryCalls>>,
  entity: EnumKnowledgeBaseSearchEntity,
) => calls.findLast((call) => call.variables?.entity === entity)?.variables

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
  beforeEach(mockBothSearches)

  it('stays idle while the search term is blank', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    expect(getGraphQLMockCalls(KnowledgeBaseSearchDocument)).toHaveLength(0)
    expect(api.results.value).toEqual([])
  })

  // One search per kind, so each tab has a count of its own - which is the whole reason both run.
  it('searches both kinds with the term, scope, locale and page size', async () => {
    mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    const calls = await waitForKnowledgeBaseSearchQueryCalls()
    expect(calls).toHaveLength(2)

    expect(variablesFor(calls, EnumKnowledgeBaseSearchEntity.Answer)).toEqual({
      query: 'printer',
      entity: EnumKnowledgeBaseSearchEntity.Answer,
      categoryId: CATEGORY_ID,
      locale: 'en-us',
      pageSize: 30,
    })

    expect(variablesFor(calls, EnumKnowledgeBaseSearchEntity.Category)).toEqual({
      query: 'printer',
      entity: EnumKnowledgeBaseSearchEntity.Category,
      categoryId: CATEGORY_ID,
      locale: 'en-us',
      pageSize: 30,
    })
  })

  it('exposes the results of the kind that is listed, and both totals', async () => {
    mountComposable({ query: 'printer', locale: 'en-us' })
    await flushPromises()

    await waitFor(() =>
      expect(api.results.value.map((result) => result.item.translation?.title)).toEqual([
        'Result One',
        'Result Two',
      ]),
    )

    expect(api.totalCount.value).toBe(2)
    expect([api.answerCount.value, api.categoryCount.value]).toEqual([2, 5])
  })

  it('searches the whole knowledge base when no scope is given', async () => {
    mountComposable({ query: 'printer', locale: 'en-us' })
    await flushPromises()

    const calls = await waitForKnowledgeBaseSearchQueryCalls()
    expect(variablesFor(calls, EnumKnowledgeBaseSearchEntity.Answer)).toEqual({
      query: 'printer',
      entity: EnumKnowledgeBaseSearchEntity.Answer,
      locale: 'en-us',
      pageSize: 30,
    })

    // Without a scope, a change anywhere in the knowledge base is relevant.
    await triggerContentUpdate([SIBLING_CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(4)
    })
  })

  it('starts fresh queries when the searched scope switches', async () => {
    const view = mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await view.rerender({ categoryId: CHILD_CATEGORY_ID })

    await waitFor(async () => {
      const calls = await waitForKnowledgeBaseSearchQueryCalls()
      expect(calls).toHaveLength(4)
      expect(variablesFor(calls, EnumKnowledgeBaseSearchEntity.Answer)).toEqual({
        query: 'printer',
        entity: EnumKnowledgeBaseSearchEntity.Answer,
        categoryId: CHILD_CATEGORY_ID,
        locale: 'en-us',
        pageSize: 30,
      })
    })
  })

  // Both searches are already loaded, so the tab only decides which of them is rendered.
  it('shows the other kind without searching again when the listed kind switches', async () => {
    const view = mountComposable({ query: 'printer', locale: 'en-us' })
    await flushPromises()

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(2)
    })

    await view.rerender({ entity: EnumKnowledgeBaseSearchEntity.Category })

    await waitFor(() =>
      expect(api.results.value.map((result) => result.item.translation?.title)).toEqual([
        'Printers',
      ]),
    )

    expect(api.totalCount.value).toBe(5)
    expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(2)
  })

  it('keeps both counts through a kind switch', async () => {
    const view = mountComposable({ query: 'printer', locale: 'en-us' })
    await flushPromises()

    await waitFor(() => expect([api.answerCount.value, api.categoryCount.value]).toEqual([2, 5]))

    await view.rerender({ entity: EnumKnowledgeBaseSearchEntity.Category })

    expect([api.answerCount.value, api.categoryCount.value]).toEqual([2, 5])
  })

  // The two searches answer independently, and vue-apollo holds each one's last result until its
  //   next arrives - so a new term leaves both kinds carrying the previous one's hits and totals.
  //   Neither may be presented as belonging to the term now in the field.
  it('shows neither kind until it has answered the current term', async () => {
    const view = mountComposable({ query: 'printer', locale: 'en-us' })
    await flushPromises()

    await waitFor(() => expect([api.answerCount.value, api.categoryCount.value]).toEqual([2, 5]))

    await view.rerender({ query: 'scanner' })

    expect([api.answerCount.value, api.categoryCount.value]).toEqual([undefined, undefined])
    expect(api.results.value).toEqual([])
    expect(api.loading.value).toBe(true)

    await waitFor(() => expect([api.answerCount.value, api.categoryCount.value]).toEqual([2, 5]))
    expect(api.loading.value).toBe(false)
  })

  // Switching to a kind that has not answered the current term must show its skeleton rather than
  //   the hits it still holds from the term before - the tab would otherwise be a search behind
  //   the one the user is looking at, with nothing to say so.
  it('does not stand the other kind in with its previous hits when switched to mid-search', async () => {
    const view = mountComposable({ query: 'printer', locale: 'en-us' })
    await flushPromises()

    await waitFor(() =>
      expect(api.results.value.map((result) => result.item.translation?.title)).toEqual([
        'Result One',
        'Result Two',
      ]),
    )

    // A new term and a switch to the categories in one update: their 'printer' hits are still in
    //   hand, and must not stand in for 'scanner'.
    await view.rerender({ query: 'scanner', entity: EnumKnowledgeBaseSearchEntity.Category })

    expect(api.results.value).toEqual([])
    expect(api.loading.value).toBe(true)

    await waitFor(() =>
      expect(api.results.value.map((result) => result.item.translation?.title)).toEqual([
        'Printers',
      ]),
    )
  })

  it('refetches when a change happened anywhere in the searched subtree', async () => {
    mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    // The scope appearing only as an ancestor still matters here: unlike the
    //   answer list, a search covers the whole subtree.
    await triggerContentUpdate([CHILD_CATEGORY_ID, CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(4)
    })
  })

  it('refetches on a knowledge-base-wide change', async () => {
    mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(4)
    })
  })

  it('does not refetch when the change happened outside the searched subtree', async () => {
    mountComposable({ query: 'printer', categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([SIBLING_CATEGORY_ID])
    await flushPromises()

    expect(await waitForKnowledgeBaseSearchQueryCalls()).toHaveLength(2)
  })
})
