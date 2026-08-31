// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'
import { defineComponent, toRef } from 'vue'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { errorOptions } from '#shared/router/error.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import {
  mockKnowledgeBaseAnswerQuery,
  mockKnowledgeBaseAnswerQueryError,
  waitForKnowledgeBaseAnswerQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'
import { getKnowledgeBaseAnswerUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseAnswerUpdates.mocks.ts'
import { getKnowledgeBaseContentUpdatesSubscriptionHandler } from '#desktop/entities/knowledge-base/graphql/subscriptions/knowledgeBaseContentUpdates.mocks.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'

import { useKnowledgeBaseAnswer } from '../useKnowledgeBaseAnswer.ts'

const KB_ID = convertToGraphQLId('KnowledgeBase', 1)
const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 5)
const PREVIOUS_ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 4)
const NEXT_ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 6)
const CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const ANCESTOR_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)
const UNRELATED_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 99)

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
  { name: 'ErrorTab', path: '/error', component: { template: '<div />' } },
]

let api: ReturnType<typeof useKnowledgeBaseAnswer>

const TestComponent = defineComponent({
  props: {
    answerId: { type: String, default: undefined },
    locale: { type: String, default: undefined },
    redirectOnAccessError: { type: Boolean, default: undefined },
    withBodyForEditing: { type: Boolean, default: undefined },
    withNavigation: { type: Boolean, default: undefined },
  },
  setup(props) {
    api = useKnowledgeBaseAnswer({
      answerId: toRef(props, 'answerId'),
      locale: toRef(props, 'locale'),
      redirectOnAccessError: props.redirectOnAccessError,
      withBodyForEditing: props.withBodyForEditing,
      withNavigation: props.withNavigation,
    })
    return () => null
  },
})

const mountComposable = (
  props: {
    answerId?: string
    locale?: string
    redirectOnAccessError?: boolean
    withBodyForEditing?: boolean
    withNavigation?: boolean
  } = {},
) => renderComponent(TestComponent, { props, router: true, routerRoutes })

// The content-updates subscription is only active while a locale is browsed, so
//   put the router on a localized knowledge base route before emitting a ping.
const triggerContentUpdate = async (affectedCategoryIds: string[]) => {
  await getTestRouter().push('/knowledge-base/locale/en-us/answer/5')
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

// The default answer factory nulls `navigation` to break the answer -> navigation
//   -> answer cycle, so a fixture has to supply it to exercise the neighbours.
const mockAnswerWithNavigation = (totalCount: number) =>
  mockKnowledgeBaseAnswerQuery({
    knowledgeBaseAnswer: {
      id: ANSWER_ID,
      title: 'Some Answer',
      category: { id: CATEGORY_ID, breadcrumb: [{ id: CATEGORY_ID, title: 'Support' }] },
      navigation: {
        index: 2,
        totalCount,
        previousAnswer: { id: PREVIOUS_ANSWER_ID, title: 'Previous Answer' },
        nextAnswer: { id: NEXT_ANSWER_ID, title: 'Next Answer' },
      },
    },
  })

describe('useKnowledgeBaseAnswer', () => {
  beforeEach(() => {
    mockKnowledgeBaseAnswerQuery({
      knowledgeBaseAnswer: {
        id: ANSWER_ID,
        title: 'Some Answer',
        category: { id: CATEGORY_ID, breadcrumb: [{ id: CATEGORY_ID, title: 'Support' }] },
      },
    })
  })

  it('exposes the answer from the query result', async () => {
    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    expect(api.answer.value?.title).toBe('Some Answer')
  })

  // The baseline useKnowledgeBaseAnswerConcurrentChange measures a foreign change against, so it
  //   must only ever be true for what the server actually said: the app queries
  //   `cache-and-network`, and a cached answer that no round trip has confirmed is exactly what
  //   must not become that baseline.
  describe('answerConfirmed', () => {
    it('is false until the server has answered', () => {
      mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })

      expect(api.answerConfirmed.value).toBe(false)
    })

    it('is true once it has', async () => {
      mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
      await flushPromises()

      expect(api.answerConfirmed.value).toBe(true)
    })

    // A cached answer whose refresh fails: Apollo keeps serving the cache entry and reports
    //   `loading: false`, so settlement alone would confirm an answer nobody has confirmed - and
    //   the next successful refresh would then look like somebody else's change. Reached here by a
    //   failed refetch; a reopened tab whose first refresh fails lands in the very same state.
    it('goes back to false when a refresh of the cached answer fails', async () => {
      mountComposable({ answerId: ANSWER_ID, locale: 'en-us', redirectOnAccessError: false })
      await flushPromises()

      expect(api.answerConfirmed.value, 'confirmed by the first result').toBe(true)

      mockKnowledgeBaseAnswerQueryError('Nope', { type: GraphQLErrorTypes.NetworkError })

      await triggerContentUpdate([CATEGORY_ID])
      await flushPromises()

      expect(api.answer.value?.title, 'still served from the cache').toBe('Some Answer')
      expect(api.knowledgeBaseAnswerQuery.operationError().value?.message).toBe('Nope')
      expect(api.answerConfirmed.value).toBe(false)
    })
  })

  it('does not query without an answer id', async () => {
    mountComposable({ answerId: undefined, locale: 'en-us' })
    await flushPromises()

    expect(api.answer.value).toBeUndefined()
  })

  it('prefetches both neighbours with the query the stepper will navigate to', async () => {
    mockAnswerWithNavigation(17)

    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    const calls = await waitForKnowledgeBaseAnswerQueryCalls()

    // Same operation and same variables the stepper's route change produces —
    //   that identity is what lets the next view render straight from the cache.
    expect(calls.map((call) => call.variables)).toEqual(
      expect.arrayContaining([
        {
          answerId: PREVIOUS_ANSWER_ID,
          locale: 'en-us',
          withBodyForEditing: false,
          withNavigation: true,
        },
        {
          answerId: NEXT_ANSWER_ID,
          locale: 'en-us',
          withBodyForEditing: false,
          withNavigation: true,
        },
      ]),
    )
  })

  // Every variable is inherited, not hardcoded: a prefetch that asked for a different field set
  //   than the view it warms would be a different operation and miss the cache entirely.
  it('prefetches the neighbours with the same field set it was asked for', async () => {
    mockAnswerWithNavigation(17)

    mountComposable({ answerId: ANSWER_ID, locale: 'en-us', withBodyForEditing: true })
    await flushPromises()

    const calls = await waitForKnowledgeBaseAnswerQueryCalls()

    expect(calls.map((call) => call.variables)).toEqual(
      expect.arrayContaining([
        {
          answerId: PREVIOUS_ANSWER_ID,
          locale: 'en-us',
          withBodyForEditing: true,
          withNavigation: true,
        },
        {
          answerId: NEXT_ANSWER_ID,
          locale: 'en-us',
          withBodyForEditing: true,
          withNavigation: true,
        },
      ]),
    )
  })

  // A caller without the navigation has no stepper to warm the neighbours for - and, not having
  //   asked for it, does not even know who they are. That is the edit view.
  it('does not prefetch neighbours without the navigation', async () => {
    mockAnswerWithNavigation(17)

    mountComposable({ answerId: ANSWER_ID, locale: 'en-us', withNavigation: false })
    await flushPromises()

    expect(await waitForKnowledgeBaseAnswerQueryCalls()).toHaveLength(1)
  })

  it('does not prefetch neighbours in a single-answer category', async () => {
    // Navigation wraps both neighbours back to the answer itself here.
    mockAnswerWithNavigation(1)

    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    expect(await waitForKnowledgeBaseAnswerQueryCalls()).toHaveLength(1)
  })

  it('refetches when a content update affects the answer category', async () => {
    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseAnswerQueryCalls()).toHaveLength(2)
    })
  })

  it('refetches when a content update affects an ancestor in the breadcrumb', async () => {
    // Renaming/moving an ancestor doesn't touch the answer's direct category
    //   id, but it does change the breadcrumb rendered for this answer.
    mockKnowledgeBaseAnswerQuery({
      knowledgeBaseAnswer: {
        id: ANSWER_ID,
        title: 'Some Answer',
        category: {
          id: CATEGORY_ID,
          breadcrumb: [
            { id: ANCESTOR_CATEGORY_ID, title: 'Parent' },
            { id: CATEGORY_ID, title: 'Support' },
          ],
        },
      },
    })

    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([ANCESTOR_CATEGORY_ID])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseAnswerQueryCalls()).toHaveLength(2)
    })
  })

  it('refetches on a knowledge-base-wide content update', async () => {
    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([])

    await waitFor(async () => {
      expect(await waitForKnowledgeBaseAnswerQueryCalls()).toHaveLength(2)
    })
  })

  it('does not refetch for a content update in another category', async () => {
    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    await triggerContentUpdate([UNRELATED_CATEGORY_ID])
    await flushPromises()

    expect(await waitForKnowledgeBaseAnswerQueryCalls()).toHaveLength(1)
  })

  it('pushes an answer update straight into the cache without refetching', async () => {
    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    const handler = await waitFor(() => {
      const subscription = getKnowledgeBaseAnswerUpdatesSubscriptionHandler()
      expect(subscription).toBeTruthy()
      return subscription
    })

    await handler.trigger({
      knowledgeBaseAnswerUpdates: {
        answer: { id: ANSWER_ID, title: 'Edited Title' },
      },
    })

    expect(api.answer.value?.title).toBe('Edited Title')
    expect(await waitForKnowledgeBaseAnswerQueryCalls()).toHaveLength(1)
  })

  it('routes to the not-found page with a link back to the knowledge base when forbidden', async () => {
    mockKnowledgeBaseAnswerQueryError('Forbidden', { type: GraphQLErrorTypes.Forbidden })

    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    expect(getTestRouter().currentRoute.value.name).toBe('ErrorTab')
    // Locale-less target: the section entry guard resolves the user's preferred
    //   locale, rather than the forbidden answer's locale.
    expect(errorOptions.value.backLink).toEqual({
      label: 'Go to knowledge base',
      link: { name: 'KnowledgeBaseBrowse', params: {} },
    })
  })

  it('forgets the forbidden path so the section entry does not loop back to it', async () => {
    mockKnowledgeBaseAnswerQueryError('Forbidden', { type: GraphQLErrorTypes.Forbidden })

    const store = useKnowledgeBaseStore()
    store.rememberPath('/knowledge-base/locale/en-us/answer/5')

    mountComposable({ answerId: ANSWER_ID, locale: 'en-us' })
    await flushPromises()

    expect(store.previousPath).toBe('')
  })

  // The edit route is a taskbar tab, whose own entity access already gates whether this
  //   composable's query ever runs with a forbidden/missing answer - there is nothing left for a
  //   race to redirect away from a second time. Checked through the same side effect the example
  //   above checks the opposite of (Pinia stores, unlike the test router, are reset between
  //   examples), rather than the router's own current route: `redirectToError` fires the
  //   navigation without awaiting it, so asserting on `currentRoute` here can observe a previous
  //   example's own (still-settling) redirect instead of this one.
  it('does not clear the remembered path when redirectOnAccessError is false', async () => {
    mockKnowledgeBaseAnswerQueryError('Forbidden', { type: GraphQLErrorTypes.Forbidden })

    const store = useKnowledgeBaseStore()
    store.rememberPath('/knowledge-base/locale/en-us/answer/5')

    mountComposable({ answerId: ANSWER_ID, locale: 'en-us', redirectOnAccessError: false })
    await flushPromises()

    expect(store.previousPath).toBe('/knowledge-base/locale/en-us/answer/5')
  })
})
