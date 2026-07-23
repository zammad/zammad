// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'
import { defineComponent, toRef } from 'vue'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { errorOptions } from '#shared/router/error.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockKnowledgeBaseCategorySubcategoriesQuery,
  mockKnowledgeBaseCategorySubcategoriesQueryError,
  waitForKnowledgeBaseCategorySubcategoriesQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseCategorySubcategories.mocks.ts'
import { getKnowledgeBaseContentUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseContentUpdates.mocks.ts'

import { useKnowledgeBaseStore } from '../../../../entities/knowledge-base/stores/knowledgeBase.ts'
import { useKnowledgeBaseCategorySubcategories } from '../useKnowledgeBaseCategorySubcategories.ts'

const KB_ID = convertToGraphQLId('KnowledgeBase', 1)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)
const UNRELATED_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 99)

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
  { name: 'ErrorTab', path: '/error', component: { template: '<div />' } },
]

let api: ReturnType<typeof useKnowledgeBaseCategorySubcategories>

const TestComponent = defineComponent({
  props: {
    categoryId: { type: String, default: undefined },
    locale: { type: String, default: undefined },
  },
  setup(props) {
    api = useKnowledgeBaseCategorySubcategories({
      categoryId: toRef(props, 'categoryId'),
      locale: toRef(props, 'locale'),
    })
    return () => null
  },
})

const mountComposable = (props: { categoryId?: string; locale?: string } = {}) =>
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

describe('useKnowledgeBaseCategorySubcategories', () => {
  beforeEach(() => {
    mockKnowledgeBaseCategorySubcategoriesQuery({
      knowledgeBaseCategorySubcategories: {
        category: {
          id: CATEGORY_ID,
          breadcrumb: [{ id: CATEGORY_ID, title: 'Support', categoryIcon: 'folder' }],
        },
        subcategories: [
          {
            id: CHILD_CATEGORY_ID,
            title: 'Billing',
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
            answerCount: 0,
            subcategoryCount: 0,
            position: 0,
          },
        ],
      },
    })
  })

  it('exposes the breadcrumb and subcategories from the query result', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    expect(api.breadcrumb.value.map((item) => item.title)).toEqual(['Support'])
    expect(api.subcategories.value.map((category) => category.title)).toEqual(['Billing'])
  })

  it('refetches when a content update affects a shown category', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })

    await flushPromises()

    await triggerContentUpdate([CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()).toHaveLength(2)
    })
  })

  // A new sub-category deep under the viewed one: its ping carries the full
  //   ancestor chain, so the viewed category's own id is in it and it refetches.
  it('refetches for a new nested category whose ping carries the viewed category as an ancestor', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })

    await flushPromises()

    const NEW_NESTED_ID = convertToGraphQLId('KnowledgeBase::Category', 50)
    await triggerContentUpdate([NEW_NESTED_ID, CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()).toHaveLength(2)
    })
  })

  it('refetches when a content update affects a displayed child category', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })

    await flushPromises()

    await triggerContentUpdate([CHILD_CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()).toHaveLength(2)
    })
  })

  it('refetches on a knowledge-base-wide content update', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()).toHaveLength(2)
    })
  })

  it('routes to the not-found page with a link back to the knowledge base when forbidden', async () => {
    mockKnowledgeBaseCategorySubcategoriesQueryError('Forbidden', {
      type: GraphQLErrorTypes.Forbidden,
    })

    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    expect(getTestRouter().currentRoute.value.name).toBe('ErrorTab')
    // Locale-less target: the section entry guard resolves the user's preferred
    //   locale, rather than the forbidden category's locale.
    expect(errorOptions.value.backLink).toEqual({
      label: 'Go to knowledge base',
      link: { name: 'KnowledgeBaseBrowse', params: {} },
    })
  })

  it('forgets the forbidden path so the section entry does not loop back to it', async () => {
    mockKnowledgeBaseCategorySubcategoriesQueryError('Forbidden', {
      type: GraphQLErrorTypes.Forbidden,
    })

    const store = useKnowledgeBaseStore()
    store.rememberPath('/knowledge-base/locale/en-us/category/1')

    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    expect(store.previousPath).toBe('')
  })

  it('does not refetch for a content update outside the shown categories', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([UNRELATED_CATEGORY_ID])
    await flushPromises()

    expect(await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()).toHaveLength(1)
  })

  // A newly created or newly visible top-level category is not yet in the
  //   displayed set, and its ping carries only its own id — so the root must
  //   refetch on any content update, unlike a category view (see the case above).
  it('refetches at the root for a top-level category not currently shown', async () => {
    mountComposable({ categoryId: undefined, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([UNRELATED_CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseCategorySubcategoriesQueryCalls()).toHaveLength(2)
    })
  })
})
