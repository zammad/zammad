// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'
import { defineComponent, toRef } from 'vue'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import {
  mockKnowledgeBaseAnswersQuery,
  waitForKnowledgeBaseAnswersQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswers.mocks.ts'
import { getKnowledgeBaseContentUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseContentUpdates.mocks.ts'

import { useKnowledgeBaseAnswers } from '../useKnowledgeBaseAnswers.ts'

const KB_ID = convertToGraphQLId('KnowledgeBase', 1)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

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

const answer = (id: number, title: string) => ({
  node: {
    id: convertToGraphQLId('KnowledgeBase::Answer', id),
    title,
    visibility: EnumKnowledgeBaseVisibility.Published,
    position: id,
  },
})

let api: ReturnType<typeof useKnowledgeBaseAnswers>

const TestComponent = defineComponent({
  props: {
    categoryId: { type: String, default: undefined },
    locale: { type: String, default: undefined },
  },
  setup(props) {
    api = useKnowledgeBaseAnswers({
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

describe('useKnowledgeBaseAnswers', () => {
  beforeEach(() => {
    mockKnowledgeBaseAnswersQuery({
      knowledgeBaseAnswers: {
        totalCount: 2,
        edges: [answer(1, 'Answer One'), answer(2, 'Answer Two')],
        pageInfo: { endCursor: null, hasNextPage: false },
      },
    })
  })

  it('exposes the answers and total count of the open category', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    expect(api.answers.value.map((entry) => entry.title)).toEqual(['Answer One', 'Answer Two'])
    expect(api.totalAnswerCount.value).toBe(2)
  })

  it('refetches when the change happened directly in the open category', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseAnswersQueryCalls()).toHaveLength(2)
    })
  })

  it('refetches on a knowledge-base-wide change', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseAnswersQueryCalls()).toHaveLength(2)
    })
  })

  it('does not refetch when the open category is only an ancestor of the change', async () => {
    mountComposable({ categoryId: CATEGORY_ID, locale: 'en-us' })
    await flushPromises()

    // The payload lists the changed record's category first, then its ancestors;
    //   the open category appearing only as an ancestor must not refetch.
    await triggerContentUpdate([CHILD_CATEGORY_ID, CATEGORY_ID])
    await flushPromises()

    expect(await waitForKnowledgeBaseAnswersQueryCalls()).toHaveLength(1)
  })
})
