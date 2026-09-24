// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink } from '@apollo/client/core'
import { asyncMap } from '@apollo/client/utilities'
import { waitFor } from '@testing-library/vue'
import { defineComponent, h, nextTick, ref } from 'vue'

import { getGraphQLMockCalls, mockedApolloClient } from '#tests/graphql/builders/mocks.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import {
  mockTicketArticleTranslateMutation,
  mockTicketArticleTranslateMutationError,
  waitForTicketArticleTranslateMutationCalls,
} from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslate.mocks.ts'
import { TicketArticleTranslateManyDocument } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslateMany.api.ts'
import {
  mockTicketArticleTranslateManyMutation,
  waitForTicketArticleTranslateManyMutationCalls,
  mockTicketArticleTranslateManyMutationError,
} from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslateMany.mocks.ts'
import { mockTicketArticleTranslationTargetLocalesQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { getTicketArticleTranslationUpdatesSubscriptionHandler } from '#shared/entities/ticket-article/graphql/subscriptions/ticketArticleTranslationUpdates.mocks.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import type { TicketArticleTranslation } from '#shared/entities/ticket-article/stores/types.ts'
import { mockUserCurrentContentTranslationAutoMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationAuto.mocks.ts'
import { mockUserCurrentContentTranslationTargetLocaleMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationTargetLocale.mocks.ts'
import {
  EnumTextDirection,
  type TicketArticlesQueryVariables,
  type TicketArticleTranslateManyMutation,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import type { ConfigList } from '#shared/types/store.ts'
import emitter from '#shared/utils/emitter.ts'

import { useTicketArticleTranslation } from '../useTicketArticleTranslation.ts'

const ticketId = convertToGraphQLId('Ticket', 1)
const articleId = convertToGraphQLId('Ticket::Article', 1)
const otherArticleId = convertToGraphQLId('Ticket::Article', 2)
const analyticsRunId = convertToGraphQLId('AIAnalyticsRun', 1)

const mockTargetLocales = (locales = ['de-de', 'en-us', 'fr-fr']) =>
  mockTicketArticleTranslationTargetLocalesQuery({
    ticketArticleTranslationTargetLocales: locales.map((locale) => ({
      locale,
      alias: locale.split('-')[0],
      name: `Name ${locale}`,
      dir: EnumTextDirection.Ltr,
    })),
  })

// Which articles the server has a stored translation for, per target language.
const mockAvailability = (availableIn: (locale: string) => string[]) =>
  mockTicketArticleTranslateManyMutation((variables) => ({
    ticketArticleTranslateMany: {
      results: [articleId, otherArticleId].map((id) => ({
        article: { id, translationAvailable: availableIn(variables.targetLocale).includes(id) },
        translated: null,
      })),
      pendingArticleIds: variables.generateMissing ? [articleId, otherArticleId] : [],
    },
  }))

const loadedArticleSelections = ref<TicketArticlesQueryVariables[]>([])

const selection = (pageSize = 2): TicketArticlesQueryVariables => ({
  ticketId,
  pageSize,
  firstArticlesCount: 5,
  loadFirstArticles: true,
})

let translation: TicketArticleTranslation

// A ticket tab: kept alive while hidden, like the taskbar does it.
const Tab = defineComponent({
  setup() {
    translation = useTicketArticleTranslation(ref(ticketId), {
      loadedArticleSelections,
    })

    return () => {
      const result = translation.translationFor(articleId)
      return h('div', result?.status === 'done' ? (result.content ?? '') : 'tab')
    }
  },
})

// `auto` is the agent's personal setting: whole tickets in the target language.
const setup = (config: Partial<ConfigList> = {}, locales?: string[], auto = false) => {
  mockApplicationConfig({
    content_translation_service: true,
    content_translation_ticket_article: true,
    content_translation_ticket_article_auto: true,
    locale_default: 'en-us',
    ...config,
  })
  mockUserCurrent({
    preferences: { locale: 'de-de', content_translation_auto: auto },
    hasContentTranslationAutoAvailable: true,
  })
  mockUserCurrentContentTranslationTargetLocaleMutation({
    userCurrentContentTranslationTargetLocale: { success: true, errors: null },
  })
  mockUserCurrentContentTranslationAutoMutation({
    userCurrentContentTranslationAuto: { success: true, errors: null },
  })
  mockTargetLocales(locales)
  mockAvailability(() => [])

  loadedArticleSelections.value = [selection()]

  const shown = ref(true)

  const wrapper = renderComponent(
    {
      components: { Tab },
      setup: () => ({ shown }),
      template: '<KeepAlive><Tab v-if="shown" /></KeepAlive>',
    },
    { store: true, router: true },
  )

  return { translation, shown, wrapper, store: useArticleTranslationStore() }
}

// The backend answers a subscription with an empty first event; a request waits for it. A tab
// shown again opens a new subscription, so the one still open is the one to answer.
const openSubscription = async () => {
  // The subscription is (re)created by a watcher, and a stopped one closes a tick later.
  await waitForNextTick(true)

  const subscription = await waitFor(() => {
    const handler = getTicketArticleTranslationUpdatesSubscriptionHandler()
    expect(handler.closed()).toBe(false)

    return handler
  })

  await subscription.trigger({
    ticketArticleTranslationUpdates: { article: null, translation: null, error: null },
  })

  return subscription
}

// The ticket-wide mutation: nothing stored, so every article is on its way through the
// subscription.
const deferredAll = () =>
  mockTicketArticleTranslateManyMutation({
    ticketArticleTranslateMany: {
      results: [],
      pendingArticleIds: [articleId, otherArticleId],
    },
  })

const deferred = () =>
  mockTicketArticleTranslateMutation({
    ticketArticleTranslate: { article: { id: articleId, translation: null }, translation: null },
  })

const immediate = (content = '<p>Hallo</p>') =>
  mockTicketArticleTranslateMutation({
    ticketArticleTranslate: {
      article: { id: articleId, translation: { content, backend: 'ai', translated: true } },
      translation: { translated: true },
    },
  })

const holdBatchResponse = (generateMissing = true) => {
  let resolve!: (result: TicketArticleTranslateManyMutation) => void
  const promise = new Promise<TicketArticleTranslateManyMutation>((done) => {
    resolve = done
  })
  const { send } = MutationHandler.prototype
  vi.spyOn(MutationHandler.prototype, 'send').mockImplementation(function (
    this: MutationHandler,
    variables,
    options,
  ) {
    if (
      variables &&
      'generateMissing' in variables &&
      variables.generateMissing === generateMissing
    )
      return promise
    return send.call(this, variables, options)
  })
  return { resolve }
}

describe('useTicketArticleTranslation', () => {
  afterEach(() => {
    if (vi.isMockFunction(MutationHandler.prototype.send))
      vi.mocked(MutationHandler.prototype.send).mockRestore()
  })
  describe('translating', () => {
    it('does not let Apollo overwrite a subscription result with a late pending response', async () => {
      const originalLink = mockedApolloClient.link
      let release: (() => void) | undefined
      mockedApolloClient.setLink(
        new ApolloLink((operation, forward) => {
          if (operation.operationName !== 'ticketArticleTranslate') return forward(operation)
          return asyncMap(forward(operation), async (result) => {
            await new Promise<void>((resolve) => {
              release = resolve
            })
            return result
          })
        }).concat(originalLink),
      )

      try {
        const { translation } = setup()
        deferred()
        const translating = translation.showTranslation(articleId)
        const subscription = await openSubscription()
        await waitFor(() => expect(release).toBeDefined())
        await subscription.trigger({
          ticketArticleTranslationUpdates: {
            article: {
              id: articleId,
              translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
            },
            translation: { translated: true },
            error: null,
          },
        })
        release!()
        await translating

        expect(translation.translationFor(articleId)).toMatchObject({
          status: 'done',
          content: '<p>Hallo</p>',
        })
      } finally {
        mockedApolloClient.setLink(originalLink)
      }
    })

    it('validates content again after a view is reopened instead of trusting its old cache entry', async () => {
      const first = setup()
      immediate()
      const translating = first.translation.showTranslation(articleId)
      await openSubscription()
      await translating
      first.wrapper.unmount()

      const second = setup()
      deferred()
      const pending = second.translation.showTranslation(articleId)
      await openSubscription()
      await pending

      expect(second.translation.translationFor(articleId)).toEqual({ status: 'pending' })
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(2)
    })

    it('waits for subscription readiness and receives the deferred translation', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      await waitForNextTick(true)

      expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })
      expect(getTicketArticleTranslationUpdatesSubscriptionHandler()).toBeDefined()
      expect(translation.hasDirectTranslationAction(articleId)).toBe(true)
      expect(translation.hasDirectTranslationAction(otherArticleId)).toBe(false)

      const subscription = await openSubscription()
      await translating

      const calls = await waitForTicketArticleTranslateMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ articleId, targetLocale: 'de-de', force: true })
      expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })
      expect(translation.hasDirectTranslationAction(articleId)).toBe(true)

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          error: null,
        },
      })

      expect(translation.translationFor(articleId)).toMatchObject({
        status: 'done',
        content: '<p>Hallo</p>',
        backend: 'ai',
      })
    })

    it('keeps the articles apart', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: {
            id: otherArticleId,
            translation: { content: '<p>Andere</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          error: null,
        },
      })

      expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })
      // Not asked for, so not shown - but known once it is.
      expect(translation.translationFor(otherArticleId)).toBeUndefined()
      expect(translation.hasDirectTranslationAction(otherArticleId)).toBe(true)
    })

    it.each([
      { error: { message: 'Provider down', exception: 'StandardError' }, message: 'Provider down' },
      { error: null, message: 'The translation returned no usable content.' },
    ])('records a background failure: $message', async ({ error, message }) => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: { id: articleId, translation: null },
          translation: null,
          error,
        },
      })

      expect(translation.translationFor(articleId)).toEqual({ status: 'error', error: message })
      expect(translation.isTranslationActive(articleId)).toBe(false)
      expect(translation.hasDirectTranslationAction(articleId)).toBe(false)
    })

    it('is not showing a translation of an article already in the target language', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutation({
        ticketArticleTranslate: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'ai', translated: false },
          },
          translation: { translated: false },
        },
      })

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      // The article keeps its original content, so the toggle is off and the button goes away.
      expect(translation.isTranslationActive(articleId)).toBe(false)
      expect(translation.hasDirectTranslationAction(articleId)).toBe(false)
    })

    it('asks again for what was on its way when the target changed and changes back', async () => {
      const { translation, store } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      store.setTargetLocale('fr-fr')
      await openSubscription()
      await waitFor(async () =>
        expect(
          (await waitForTicketArticleTranslateMutationCalls()).at(-1)?.variables,
        ).toMatchObject({ targetLocale: 'fr-fr' }),
      )

      // The subscription of the former target is gone with it, so its result would be lost ...
      store.setTargetLocale('de-de')
      await openSubscription()

      // ... and is requested again; the server answers from its store once the job finished.
      await waitFor(async () =>
        expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(3),
      )
      expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })
    })

    it('records a refused request without a notification', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutationError('AI provider is not configured.', {
        type: GraphQLErrorTypes.UnknownError,
      })

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      expect(translation.translationFor(articleId)).toMatchObject({ status: 'error' })
    })

    it('reports when no supported target language is available', async () => {
      const { translation } = setup({}, ['es-es'])

      await translation.showTranslation(articleId)

      expect(translation.translationFor(articleId)).toEqual({
        status: 'error',
        error: 'No supported target language is available.',
      })
    })

    it('reuses cached content and requests it again after cache collection', async () => {
      const { translation } = setup()
      immediate()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      translation.showOriginal(articleId)
      expect(translation.translationFor(articleId)).toBeUndefined()

      await translation.showTranslation(articleId)

      expect(translation.translationFor(articleId)).toMatchObject({ content: '<p>Hallo</p>' })
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(1)

      mockedApolloClient.cache.gc()
      expect(translation.translationFor(articleId)).toBeUndefined()
      await translation.showTranslation(articleId)
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(2)
      expect(translation.translationFor(articleId)).toMatchObject({ content: '<p>Hallo</p>' })
    })

    it('translates shown articles into a new target, and reuses the old result on the way back', async () => {
      const { translation, store } = setup()
      immediate()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      store.setTargetLocale('fr-fr')
      await openSubscription()

      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({ status: 'done' }),
      )

      const calls = await waitForTicketArticleTranslateMutationCalls()
      expect(calls).toHaveLength(2)
      expect(calls.at(-1)?.variables).toMatchObject({ targetLocale: 'fr-fr' })

      store.setTargetLocale('de-de')
      await nextTick()

      expect(translation.translationFor(articleId)).toMatchObject({ content: '<p>Hallo</p>' })
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(2)
    })

    it('hides translations when the feature is switched off', async () => {
      const { translation } = setup()
      immediate()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      mockApplicationConfig({ content_translation_ticket_article: false })

      await waitFor(() => expect(translation.translationFor(articleId)).toBeUndefined())
      expect(translation.hasDirectTranslationAction(articleId)).toBe(false)
    })
  })

  // What a rating attaches to: without it the article offers no feedback control at all.
  describe('analytics metadata', () => {
    const analytics = {
      run: { id: analyticsRunId },
      usage: { userHasProvidedFeedback: false },
    }

    it('carries the run of a translation that came back at once', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutation({
        ticketArticleTranslate: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          analytics,
        },
      })

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      expect(translation.translationFor(articleId)).toMatchObject({ status: 'done', analytics })
    })

    // The AI service always defers, so this is the path a rateable translation normally takes.
    it('carries the run of a deferred translation', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          error: null,
          analytics,
        },
      })

      expect(translation.translationFor(articleId)).toMatchObject({ status: 'done', analytics })
    })

    it('shows a translation the service recorded no run for', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'libretranslate', translated: true },
          },
          translation: { translated: true },
          error: null,
          analytics: null,
        },
      })

      expect(translation.translationFor(articleId)).toEqual({
        status: 'done',
        content: '<p>Hallo</p>',
        backend: 'libretranslate',
        translated: true,
        analytics: null,
        regenerating: false,
      })
    })

    it('keeps a rating on the translation it was given for', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutation({
        ticketArticleTranslate: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          analytics,
        },
      })

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      translation.markTranslationRated(articleId)

      expect(translation.translationFor(articleId)).toMatchObject({
        analytics: { usage: { userHasProvidedFeedback: true } },
      })

      translation.showOriginal(articleId)
      await translation.showTranslation(articleId)

      expect(translation.translationFor(articleId)).toMatchObject({
        analytics: { usage: { userHasProvidedFeedback: true } },
      })
    })

    it('records no rating for a translation the service recorded no run for', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutation({
        ticketArticleTranslate: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'libretranslate', translated: true },
          },
          translation: { translated: true },
          analytics: null,
        },
      })

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      translation.markTranslationRated(articleId)

      expect(translation.translationFor(articleId)).toMatchObject({ analytics: null })
    })
  })

  describe('regenerating', () => {
    const analytics = {
      run: { id: analyticsRunId },
      usage: { userHasProvidedFeedback: false },
    }

    const translateWithRun = async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutation({
        ticketArticleTranslate: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          analytics,
        },
      })

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      return { translation, subscription }
    }

    const current = { status: 'done', content: '<p>Hallo</p>', analytics }

    it('asks for another translation of the run and keeps the current one until it arrives', async () => {
      const { translation, subscription } = await translateWithRun()

      deferred()
      await translation.regenerateTranslation(articleId)

      const calls = await waitForTicketArticleTranslateMutationCalls()
      expect(calls.at(-1)?.variables).toEqual({
        articleId,
        targetLocale: 'de-de',
        force: true,
        regenerationOfId: analyticsRunId,
      })
      expect(translation.translationFor(articleId)).toMatchObject({
        ...current,
        regenerating: true,
      })

      // Asking again while one is on its way requests nothing more.
      await translation.regenerateTranslation(articleId)
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(2)

      const regeneratedAnalytics = {
        run: { id: convertToGraphQLId('AIAnalyticsRun', 2) },
        usage: { userHasProvidedFeedback: false },
      }

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: {
            id: articleId,
            translation: { content: '<p>Guten Tag</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          error: null,
          analytics: regeneratedAnalytics,
        },
      })

      expect(translation.translationFor(articleId)).toMatchObject({
        status: 'done',
        content: '<p>Guten Tag</p>',
        analytics: regeneratedAnalytics,
        regenerating: false,
      })
    })

    it('does not let a ticket-wide result end a regeneration on its way', async () => {
      const { translation, subscription } = await translateWithRun()
      const response = holdBatchResponse()

      deferred()
      await translation.regenerateTranslation(articleId)

      useArticleTranslationStore().setAutoEnabled(true)
      await waitFor(() =>
        expect(
          vi
            .mocked(MutationHandler.prototype.send)
            .mock.calls.some(
              ([variables]) =>
                variables && 'generateMissing' in variables && variables.generateMissing,
            ),
        ).toBe(true),
      )

      response.resolve({
        ticketArticleTranslateMany: {
          __typename: 'TicketArticleTranslateManyPayload',
          results: [
            {
              __typename: 'TicketArticleTranslationResult',
              article: {
                __typename: 'TicketArticle',
                id: articleId,
                translationAvailable: true,
                translation: {
                  __typename: 'ContentTranslation',
                  content: '<p>Hallo</p>',
                  backend: 'ai',
                  translated: true,
                },
              },
              translated: true,
              analytics: {
                __typename: 'AIAnalyticsMetadata',
                run: { __typename: 'AIAnalyticsRun', id: analyticsRunId },
                usage: { __typename: 'AIAnalyticsUsage', userHasProvidedFeedback: false },
              },
            },
          ],
          pendingArticleIds: [],
        },
      })
      await waitForNextTick(true)

      expect(translation.translationFor(articleId)).toMatchObject({
        ...current,
        regenerating: true,
      })

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: {
            id: articleId,
            translation: { content: '<p>Guten Tag</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          error: null,
        },
      })

      expect(translation.translationFor(articleId)).toMatchObject({
        status: 'done',
        content: '<p>Guten Tag</p>',
        regenerating: false,
      })
    })

    it('keeps the current translation when the regeneration is rejected', async () => {
      const { translation } = await translateWithRun()

      mockTicketArticleTranslateMutationError('AI provider is not configured.', {
        type: GraphQLErrorTypes.UnknownError,
      })
      await translation.regenerateTranslation(articleId)

      expect(translation.translationFor(articleId)).toMatchObject({
        ...current,
        regenerating: false,
      })
    })

    it('keeps the current translation when the regeneration fails in the background', async () => {
      const { translation, subscription } = await translateWithRun()

      deferred()
      await translation.regenerateTranslation(articleId)

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: { id: articleId, translation: null },
          translation: null,
          error: { message: 'AI provider is not configured.' },
        },
      })

      expect(translation.translationFor(articleId)).toMatchObject({
        ...current,
        regenerating: false,
      })
    })

    it('does not regenerate a translation the service recorded no run for', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutation({
        ticketArticleTranslate: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'libretranslate', translated: true },
          },
          translation: { translated: true },
          analytics: null,
        },
      })

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      await translation.regenerateTranslation(articleId)

      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(1)
      expect(translation.translationFor(articleId)).toMatchObject({ status: 'done' })
    })
  })

  describe('per tab', () => {
    it('keeps listening while hidden, so a deferred result still arrives', async () => {
      const { translation, shown } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      shown.value = false
      await nextTick()

      expect(subscription.closed()).toBe(false)

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          error: null,
        },
      })

      expect(translation.translationFor(articleId)).toMatchObject({ content: '<p>Hallo</p>' })
    })

    it('lets a hidden tab follow a new target only once it is shown again', async () => {
      const { translation, store, shown } = setup()
      immediate()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      shown.value = false
      await nextTick()

      store.setTargetLocale('fr-fr')
      await waitForNextTick(true)

      // Nothing was requested for the hidden tab ...
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(1)

      // ... it asks for the new target when shown again.
      shown.value = true
      await openSubscription()

      await waitFor(async () =>
        expect(
          (await waitForTicketArticleTranslateMutationCalls()).at(-1)?.variables,
        ).toMatchObject({ targetLocale: 'fr-fr' }),
      )
    })

    it.each([false, true])('retries after reconnecting with hidden=%s', async (hidden) => {
      const { translation, shown } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      shown.value = !hidden
      await nextTick()
      immediate()
      emitter.emit('reconnected')
      await waitForNextTick(true)

      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(1)

      shown.value = true
      await openSubscription()

      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({ content: '<p>Hallo</p>' }),
      )
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(2)
    })
  })

  const waitForGenerationCalls = () =>
    waitFor(async () => {
      const calls = (await waitForTicketArticleTranslateManyMutationCalls()).filter(
        ({ variables }) => variables.generateMissing,
      )
      expect(calls.length).toBeGreaterThan(0)
      return calls
    })

  describe('the whole ticket', () => {
    // Enabling the mode and letting the subscription answer, as a tab does on its own.
    const enable = async () => {
      useArticleTranslationStore().setAutoEnabled(true)
      const subscription = await openSubscription()
      await waitForNextTick(true)

      return subscription
    }

    // The setting is the agent's, not the tab's: a ticket opened while it is on needs no action.
    it('translates a ticket opened with the setting already on', async () => {
      const { translation } = setup({}, undefined, true)
      deferredAll()

      await openSubscription()
      await waitForNextTick(true)

      const calls = await waitForGenerationCalls()

      expect(calls).toHaveLength(1)
      expect(getGraphQLMockCalls(TicketArticleTranslateManyDocument)).toHaveLength(1)
      expect(calls[0].variables).toEqual({
        ...selection(),
        targetLocale: 'de-de',
        generateMissing: true,
      })
      expect(useArticleTranslationStore().isAutoEnabled).toBe(true)
      expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })
    })

    // Every open tab follows the one setting, so a ticket in another tab returns to its originals.
    it('returns to the originals when the setting is switched off elsewhere', async () => {
      const { translation, store } = setup({}, undefined, true)
      deferredAll()

      await openSubscription()
      await waitForNextTick(true)

      store.setAutoEnabled(false)
      await waitForNextTick(true)

      expect(useArticleTranslationStore().isAutoEnabled).toBe(false)
      expect(translation.translationFor(articleId)).toBeUndefined()
      expect(translation.translationFor(otherArticleId)).toBeUndefined()
    })

    it('shows what the server has stored right away', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateManyMutation({
        ticketArticleTranslateMany: {
          pendingArticleIds: [otherArticleId],
          results: [
            {
              article: {
                id: articleId,
                translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
              },
              translated: true,
            },
          ],
        },
      })

      await enable()

      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({
          status: 'done',
          content: '<p>Hallo</p>',
        }),
      )
      // Still on its way, so the original stays on screen without a direct answer.
      expect(translation.translationFor(otherArticleId)).toEqual({ status: 'pending' })
    })

    it('carries the run of a stored translation, so it can be rated', async () => {
      const { translation } = setup()
      const analytics = {
        run: { id: analyticsRunId },
        usage: { userHasProvidedFeedback: false },
      }
      mockTicketArticleTranslateManyMutation({
        ticketArticleTranslateMany: {
          pendingArticleIds: [],
          results: [
            {
              article: {
                id: articleId,
                translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
              },
              translated: true,
              analytics,
            },
          ],
        },
      })

      await enable()

      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({ status: 'done', analytics }),
      )
    })

    it.each(['done', 'error'] as const)(
      'keeps a subscription %s result that arrives before the pending acknowledgement',
      async (status) => {
        const { translation } = setup()
        const response = holdBatchResponse()
        const subscription = await enable()

        expect(translation.isTranslating.value).toBe(true)
        expect(translation.translationFor(articleId)).toBeUndefined()

        await subscription.trigger({
          ticketArticleTranslationUpdates: {
            article: {
              id: articleId,
              translation:
                status === 'done' ? { content: 'Hallo', translated: true, backend: 'ai' } : null,
            },
            translation: status === 'done' ? { translated: true } : null,
            error:
              status === 'error'
                ? { message: 'Provider unavailable', exception: 'StandardError' }
                : null,
          },
        })
        response.resolve({
          ticketArticleTranslateMany: {
            __typename: 'TicketArticleTranslateManyPayload',
            results: [],
            pendingArticleIds: [articleId],
          },
        })

        await waitFor(() => expect(translation.isTranslating.value).toBe(false))
        expect(translation.translationFor(articleId)?.status).toBe(status)
      },
    )

    it('ignores a response from a former subscription generation', async () => {
      const { translation, store } = setup()
      const response = holdBatchResponse()
      await enable()

      store.setTargetLocale('fr-fr')
      await waitForNextTick(true)
      response.resolve({
        ticketArticleTranslateMany: {
          __typename: 'TicketArticleTranslateManyPayload',
          results: [],
          pendingArticleIds: [articleId],
        },
      })
      await waitForNextTick(true)
      store.setAutoEnabled(false)
      store.setTargetLocale('de-de')
      await waitForNextTick(true)
      store.setAutoEnabled(true)
      await waitForNextTick(true)

      expect(translation.translationFor(articleId)).toBeUndefined()
    })

    it('requests a refreshed page while an equal-sized selection is still in flight', async () => {
      const { translation } = setup()
      const response = holdBatchResponse()
      await enable()
      const send = vi.mocked(MutationHandler.prototype.send)
      const batchCalls = () =>
        send.mock.calls.filter(
          ([variables]) => variables && 'generateMissing' in variables && variables.generateMissing,
        )
      expect(batchCalls()).toHaveLength(1)

      loadedArticleSelections.value = [selection()]
      await waitFor(() => expect(batchCalls()).toHaveLength(2))

      response.resolve({
        ticketArticleTranslateMany: {
          __typename: 'TicketArticleTranslateManyPayload',
          results: [],
          pendingArticleIds: [otherArticleId],
        },
      })
      await waitFor(() => expect(translation.isTranslating.value).toBe(false))
      expect(translation.translationFor(otherArticleId)).toEqual({ status: 'pending' })
    })

    it('covers every retained page on a target change', async () => {
      const { store } = setup()
      deferredAll()
      loadedArticleSelections.value = [
        { ...selection(2000), beforeCursor: 'older-page' },
        { ...selection(100), loadFirstArticles: false },
      ]
      await enable()
      expect(await waitForGenerationCalls()).toHaveLength(2)

      store.setTargetLocale('fr-fr')
      await openSubscription()
      await waitFor(async () => {
        const calls = await waitForGenerationCalls()
        expect(calls).toHaveLength(4)
        expect(calls.slice(-2).map(({ variables }) => variables)).toEqual(
          loadedArticleSelections.value.map((page) => ({
            ...page,
            targetLocale: 'fr-fr',
            generateMissing: true,
          })),
        )
      })
    })

    it.each([false, true])(
      'handles a failed batch with generateMissing=%s',
      async (generateMissing) => {
        const { notifications, clearAllNotifications } = useNotifications()
        clearAllNotifications()
        const send = vi.spyOn(MutationHandler.prototype, 'send')
        const { translation, shown } = setup({}, undefined, generateMissing)
        mockTicketArticleTranslateManyMutationError('Provider unavailable', {
          type: GraphQLErrorTypes.UnknownError,
        })
        await openSubscription()
        await waitForNextTick(true)
        expect(notifications.value).toHaveLength(generateMissing ? 1 : 0)

        await waitFor(() => expect(translation.isTranslating.value).toBe(false))
        expect(translation.translationFor(articleId)).toBeUndefined()

        shown.value = false
        await nextTick()
        shown.value = true
        await waitFor(() => expect(send).toHaveBeenCalledTimes(2))
      },
    )

    // The ticket-wide request is unforced, so the server answers an article already in the target
    // language with its original. Asking for that one article is forced, and must go through.
    it('still translates an article the ticket-wide request skipped', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateManyMutation({
        ticketArticleTranslateMany: {
          pendingArticleIds: [otherArticleId],
          results: [
            {
              article: {
                id: articleId,
                translation: null,
              },
              translated: false,
            },
          ],
        },
      })

      await enable()

      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({ translated: false }),
      )

      immediate()
      await translation.showTranslation(articleId)

      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({
          content: '<p>Hallo</p>',
          translated: true,
        }),
      )

      loadedArticleSelections.value = [selection(3)]
      await waitFor(async () => expect(await waitForGenerationCalls()).toHaveLength(2))
      expect(translation.translationFor(articleId)).toMatchObject({
        content: '<p>Hallo</p>',
        translated: true,
      })
    })

    it.each(['target change', 'reconnect'])(
      'keeps an article on its original across a %s',
      async (trigger) => {
        const { translation, store } = setup()
        deferredAll()
        await enable()
        translation.showOriginal(articleId)

        expect(translation.translationFor(articleId)).toBeUndefined()
        expect(translation.translationFor(otherArticleId)).toEqual({ status: 'pending' })

        if (trigger === 'target change') store.setTargetLocale('fr-fr')
        else emitter.emit('reconnected')
        await openSubscription()

        await waitFor(async () => {
          const calls = await waitForGenerationCalls()
          expect(calls).toHaveLength(2)
          expect(calls[1].variables).toEqual({
            ...selection(),
            targetLocale: trigger === 'target change' ? 'fr-fr' : 'de-de',
            generateMissing: true,
          })
        })
        expect(translation.translationFor(articleId)).toBeUndefined()
      },
    )

    // The article is on its way from the ticket-wide request, so showing it again waits for that
    // result rather than asking for the same translation a second time.
    it('shows the translation of that article again on request', async () => {
      const { translation } = setup()
      deferredAll()

      const subscription = await enable()

      translation.showOriginal(articleId)
      await translation.showTranslation(articleId)

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: {
            id: articleId,
            translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
          },
          translation: { translated: true },
          error: null,
        },
      })

      expect(translation.translationFor(articleId)).toMatchObject({ content: '<p>Hallo</p>' })
    })

    it.each(['disabled', 'hidden'])(
      'abandons an unsent request while %s and catches up afterward',
      async (condition) => {
        const { translation, shown } = setup()
        deferredAll()
        useArticleTranslationStore().setAutoEnabled(true)
        await waitForNextTick(true)

        if (condition === 'disabled') useArticleTranslationStore().setAutoEnabled(false)
        else shown.value = false
        await nextTick()
        await openSubscription()

        expect(
          getGraphQLMockCalls(TicketArticleTranslateManyDocument).filter(
            ({ variables }) => variables.generateMissing,
          ),
        ).toHaveLength(0)
        expect(translation.isTranslating.value).toBe(false)

        if (condition === 'disabled') useArticleTranslationStore().setAutoEnabled(true)
        else shown.value = true
        await openSubscription()

        await waitFor(async () => {
          const calls = await waitForGenerationCalls()
          expect(calls).toHaveLength(1)
          expect(calls[0].variables).toEqual({
            ...selection(),
            targetLocale: 'de-de',
            generateMissing: true,
          })
        })
        expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })
      },
    )

    it('translates nothing while the tab is hidden, and catches up when it is shown', async () => {
      const { shown } = setup()
      deferredAll()

      shown.value = false
      await nextTick()

      useArticleTranslationStore().setAutoEnabled(true)
      await waitForNextTick(true)

      // Nothing was requested for the hidden tab.
      expect(
        getGraphQLMockCalls(TicketArticleTranslateManyDocument).filter(
          ({ variables }) => variables.generateMissing,
        ),
      ).toHaveLength(0)

      shown.value = true
      await openSubscription()

      await waitFor(async () =>
        expect((await waitForGenerationCalls()).at(-1)?.variables).toMatchObject(selection()),
      )
    })

    describe('an article arriving in the open ticket', () => {
      const arrive = async () => {
        loadedArticleSelections.value = [selection(3)]
        await waitForNextTick(true)
      }

      it('is translated while the mode is on', async () => {
        setup()
        deferredAll()

        await enable()
        await waitForGenerationCalls()

        await arrive()

        await waitFor(async () =>
          expect((await waitForGenerationCalls()).at(-1)?.variables).toMatchObject({ pageSize: 3 }),
        )
      })

      it('is left alone while the mode is off', async () => {
        setup()
        deferredAll()

        await openSubscription()
        await arrive()

        expect(
          getGraphQLMockCalls(TicketArticleTranslateManyDocument).filter(
            ({ variables }) => variables.generateMissing,
          ),
        ).toHaveLength(0)
      })

      it('is left alone while the tab is hidden, and translated when it is shown', async () => {
        const { shown } = setup()
        deferredAll()

        await enable()
        await waitForGenerationCalls()

        shown.value = false
        await nextTick()

        await arrive()

        expect(
          getGraphQLMockCalls(TicketArticleTranslateManyDocument).filter(
            ({ variables }) => variables.generateMissing,
          ),
        ).toHaveLength(1)

        shown.value = true
        await openSubscription()

        await waitFor(async () =>
          expect((await waitForGenerationCalls()).at(-1)?.variables).toMatchObject({ pageSize: 3 }),
        )
      })
    })
  })

  describe('stored translations', () => {
    it('asks which of the loaded articles have one, without their bodies', async () => {
      const { translation } = setup()
      mockAvailability(() => [articleId])
      await waitFor(() => expect(translation.hasDirectTranslationAction(articleId)).toBe(true))
      expect(translation.hasDirectTranslationAction(otherArticleId)).toBe(false)

      const calls = await waitForTicketArticleTranslateManyMutationCalls()
      expect(calls).toHaveLength(1)
      expect(translation.isTranslating.value).toBe(false)

      expect(calls.at(-1)?.variables).toMatchObject({
        ticketId,
        pageSize: 2,
        firstArticlesCount: 5,
        targetLocale: 'de-de',
        generateMissing: false,
      })
    })

    it('ignores an old lookup response after switching to generation', async () => {
      const { store, translation } = setup()
      const lookup = holdBatchResponse(false)
      await waitFor(() =>
        expect(MutationHandler.prototype.send).toHaveBeenCalledWith(
          expect.objectContaining({ generateMissing: false }),
        ),
      )

      mockTicketArticleTranslateManyMutation({
        ticketArticleTranslateMany: {
          results: [
            {
              article: {
                id: articleId,
                translationAvailable: true,
                translation: { content: 'Hallo', backend: 'ai', translated: true },
              },
              translated: true,
            },
          ],
          pendingArticleIds: [],
        },
      })
      store.setAutoEnabled(true)
      await openSubscription()
      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({ content: 'Hallo' }),
      )

      lookup.resolve({
        ticketArticleTranslateMany: {
          __typename: 'TicketArticleTranslateManyPayload',
          results: [
            {
              __typename: 'TicketArticleTranslationResult',
              article: { __typename: 'TicketArticle', id: articleId, translationAvailable: false },
            },
          ],
        },
      })
      await waitForNextTick(true)

      expect(translation.translationFor(articleId)).toMatchObject({ content: 'Hallo' })
      expect(translation.hasDirectTranslationAction(articleId)).toBe(true)
    })

    it.each([2, 3])(
      'refreshes availability after loading a page of %s articles',
      async (pageSize) => {
        const { translation } = setup()
        await waitForNextTick(true)
        expect(translation.hasDirectTranslationAction(articleId)).toBe(false)
        mockAvailability(() => [articleId])

        loadedArticleSelections.value = [selection(pageSize)]

        await waitFor(() => expect(translation.hasDirectTranslationAction(articleId)).toBe(true))
        const calls = await waitForTicketArticleTranslateManyMutationCalls()
        expect(calls).toHaveLength(2)
        expect(calls.at(-1)?.variables).toMatchObject({ pageSize })
      },
    )

    it('looks up only the added page when completed pages are retained', async () => {
      setup()
      loadedArticleSelections.value = [selection(2000)]
      await waitForNextTick(true)
      const olderPage = { ...selection(100), loadFirstArticles: false, beforeCursor: 'older-page' }

      loadedArticleSelections.value = [...loadedArticleSelections.value, olderPage]

      await waitForNextTick(true)
      const calls = await waitForTicketArticleTranslateManyMutationCalls()
      expect(calls).toHaveLength(2)
      expect(calls.at(-1)?.variables).toMatchObject(olderPage)
    })

    it.each([false, true])(
      'reuses only completed lookups across tab switches with generateMissing=%s',
      async (generateMissing) => {
        const { shown } = setup({}, undefined, generateMissing)
        await openSubscription()
        await waitForNextTick(true)
        expect(await waitForTicketArticleTranslateManyMutationCalls()).toHaveLength(1)

        shown.value = false
        await nextTick()
        shown.value = true
        await waitForNextTick(true)
        const expectedCalls = generateMissing ? 2 : 1
        expect(await waitForTicketArticleTranslateManyMutationCalls()).toHaveLength(expectedCalls)

        emitter.emit('reconnected')
        await openSubscription()
        await waitFor(() =>
          expect(getGraphQLMockCalls(TicketArticleTranslateManyDocument)).toHaveLength(
            expectedCalls + 1,
          ),
        )
      },
    )

    it('does not follow a change while hidden, and catches up when shown again', async () => {
      const { store, shown } = setup()
      const before = (await waitForTicketArticleTranslateManyMutationCalls()).length

      shown.value = false
      await nextTick()

      store.setTargetLocale('fr-fr')
      await waitForNextTick(true)

      expect((await waitForTicketArticleTranslateManyMutationCalls()).length).toBe(before)

      shown.value = true

      await waitFor(async () => {
        const calls = await waitForTicketArticleTranslateManyMutationCalls()
        expect(calls.length).toBe(before + 1)
        expect(calls.at(-1)?.variables).toMatchObject({
          targetLocale: 'fr-fr',
          generateMissing: false,
        })
      })
    })
  })

  describe('direct action', () => {
    it('follows the target language', async () => {
      const { translation, store } = setup()
      mockAvailability((locale) => (locale === 'fr-fr' ? [articleId] : []))

      await waitForTicketArticleTranslateManyMutationCalls()
      expect(translation.hasDirectTranslationAction(articleId)).toBe(false)

      store.setTargetLocale('fr-fr')

      await waitFor(() => expect(translation.hasDirectTranslationAction(articleId)).toBe(true))
      expect(
        (await waitForTicketArticleTranslateManyMutationCalls()).at(-1)?.variables,
      ).toMatchObject({ targetLocale: 'fr-fr', generateMissing: false })
    })

    it('belongs to nobody while the service cannot translate', async () => {
      const { translation } = setup({ content_translation_ticket_article: false })
      mockAvailability(() => [articleId])
      await waitForNextTick(true)

      expect(translation.hasDirectTranslationAction(articleId)).toBe(false)
    })
  })
})
