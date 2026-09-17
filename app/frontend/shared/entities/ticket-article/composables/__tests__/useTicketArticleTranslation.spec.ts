// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { computed, defineComponent, h, nextTick, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  mockTicketArticleTranslateMutation,
  mockTicketArticleTranslateMutationError,
  waitForTicketArticleTranslateMutationCalls,
} from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslate.mocks.ts'
import {
  mockTicketArticlesTranslationAvailabilityQuery,
  waitForTicketArticlesTranslationAvailabilityQueryCalls,
} from '#shared/entities/ticket-article/graphql/queries/ticketArticlesTranslationAvailability.mocks.ts'
import { mockTicketArticleTranslationTargetLocalesQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { getTicketArticleTranslationUpdatesSubscriptionHandler } from '#shared/entities/ticket-article/graphql/subscriptions/ticketArticleTranslationUpdates.mocks.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import type { TicketArticleTranslation } from '#shared/entities/ticket-article/stores/types.ts'
import { mockUserCurrentContentTranslationTargetLocaleMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationTargetLocale.mocks.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import type { ConfigList } from '#shared/types/store.ts'
import emitter from '#shared/utils/emitter.ts'

import { useTicketArticleTranslation } from '../useTicketArticleTranslation.ts'

const ticketId = 'gid://zammad/Ticket/1'
const articleId = 'gid://zammad/TicketArticle/1'
const otherArticleId = 'gid://zammad/TicketArticle/2'

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
  mockTicketArticlesTranslationAvailabilityQuery((variables) => ({
    firstArticles: { edges: [] },
    articles: {
      edges: [articleId, otherArticleId].map((id) => ({
        node: {
          id,
          translationAvailable: availableIn(variables.translationTargetLocale as string).includes(
            id,
          ),
        },
      })),
    },
  }))

// How many articles the tab has loaded.
const loadedArticlesCount = ref(0)

let translation: TicketArticleTranslation

// A ticket tab: kept alive while hidden, like the taskbar does it.
const Tab = defineComponent({
  setup() {
    translation = useTicketArticleTranslation(ref(ticketId), {
      loadedArticlesCount,
      firstArticlesCount: computed(() => 5),
    })

    return () => h('div', 'tab')
  },
})

const setup = (config: Partial<ConfigList> = {}, locales?: string[]) => {
  mockApplicationConfig({
    content_translation_service: true,
    content_translation_ticket_article: true,
    locale_default: 'en-us',
    ...config,
  })
  mockUserCurrent({ preferences: { locale: 'de-de' } })
  mockUserCurrentContentTranslationTargetLocaleMutation({
    userCurrentContentTranslationTargetLocale: { success: true, errors: null },
  })
  mockTargetLocales(locales)
  mockAvailability(() => [])

  loadedArticlesCount.value = 2

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

const deferred = () =>
  mockTicketArticleTranslateMutation({ ticketArticleTranslate: { translation: null } })

const immediate = (content = '<p>Hallo</p>') =>
  mockTicketArticleTranslateMutation({
    ticketArticleTranslate: { translation: { content, backend: 'ai', translated: true } },
  })

describe('useTicketArticleTranslation', () => {
  describe('translating', () => {
    it('shows an immediate result and records its producer', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutation({
        ticketArticleTranslate: {
          translation: { content: '<p>Hallo</p>', backend: 'deepl', translated: true },
        },
      })

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      expect(translation.translationFor(articleId)).toEqual({
        status: 'done',
        content: '<p>Hallo</p>',
        backend: 'deepl',
        translated: true,
      })
      expect(translation.hasDirectTranslationAction(articleId)).toBe(true)
    })

    it('subscribes to the ticket and target before asking for the translation', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      await waitForNextTick(true)

      expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })
      expect(getTicketArticleTranslationUpdatesSubscriptionHandler()).toBeDefined()

      await openSubscription()
      await translating

      const calls = await waitForTicketArticleTranslateMutationCalls()

      // Forced: the agent's request for one article overrides the language detection.
      expect(calls.at(-1)?.variables).toEqual({ articleId, targetLocale: 'de-de', force: true })
    })

    it('stays pending until the deferred result arrives through the subscription', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: { id: articleId },
          translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
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
          article: { id: otherArticleId },
          translation: { content: '<p>Andere</p>', backend: 'ai', translated: true },
          error: null,
        },
      })

      expect(translation.translationFor(articleId)).toEqual({ status: 'pending' })
      // Not asked for, so not shown - but known once it is.
      expect(translation.translationFor(otherArticleId)).toBeUndefined()
      expect(translation.hasDirectTranslationAction(otherArticleId)).toBe(true)
    })

    it('records a failed background translation', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: { id: articleId },
          translation: null,
          error: { message: 'Provider down', exception: 'StandardError' },
        },
      })

      expect(translation.translationFor(articleId)).toEqual({
        status: 'error',
        error: 'Provider down',
      })
    })

    it('treats an empty event as a failure, so the agent can ask again', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: { id: articleId },
          translation: null,
          error: null,
        },
      })

      expect(translation.translationFor(articleId)).toEqual({
        status: 'error',
        error: 'The translation returned no usable content.',
      })
    })

    it('is not showing a translation after a failure, and offers no direct button', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      const subscription = await openSubscription()
      await translating

      await subscription.trigger({
        ticketArticleTranslationUpdates: {
          article: { id: articleId },
          translation: null,
          error: { message: 'Provider down', exception: 'StandardError' },
        },
      })

      expect(translation.isTranslationActive(articleId)).toBe(false)
      // Nothing is stored for the failed article, so it translates from the menu, like any other.
      expect(translation.hasDirectTranslationAction(articleId)).toBe(false)
    })

    it('is not showing a translation of an article already in the target language', async () => {
      const { translation } = setup()
      mockTicketArticleTranslateMutation({
        ticketArticleTranslate: {
          translation: { content: '<p>Hallo</p>', backend: 'ai', translated: false },
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

    it('reuses a known translation instead of asking again', async () => {
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
          article: { id: articleId },
          translation: { content: '<p>Hallo</p>', backend: 'ai', translated: true },
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

    it('asks again for what was pending when the connection comes back', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      immediate()
      emitter.emit('reconnected')
      await waitForNextTick(true)

      // Not before the new connection subscribed again and answered with its first event: a result
      // published in between would be lost the same way.
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(1)

      await openSubscription()

      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({ content: '<p>Hallo</p>' }),
      )
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(2)
    })

    it('lets a hidden tab ask again for what it lost in a reconnect once it is shown', async () => {
      const { translation, shown } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      shown.value = false
      await nextTick()

      emitter.emit('reconnected')
      await waitForNextTick(true)

      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(1)

      immediate()
      shown.value = true
      await openSubscription()

      await waitFor(() =>
        expect(translation.translationFor(articleId)).toMatchObject({ content: '<p>Hallo</p>' }),
      )
      expect(await waitForTicketArticleTranslateMutationCalls()).toHaveLength(2)
    })
  })

  describe('stored translations', () => {
    it('asks which of the loaded articles have one, without their bodies', async () => {
      const { store } = setup()
      await waitFor(() => expect(store.isAvailable).toBe(true))

      const calls = await waitForTicketArticlesTranslationAvailabilityQueryCalls()

      expect(calls.at(-1)?.variables).toMatchObject({
        ticketId,
        pageSize: 2,
        firstArticlesCount: 5,
        translationTargetLocale: 'de-de',
      })
    })

    it('asks again for a new target language', async () => {
      const { store } = setup()
      await waitForTicketArticlesTranslationAvailabilityQueryCalls()

      store.setTargetLocale('fr-fr')

      await waitFor(async () =>
        expect(
          (await waitForTicketArticlesTranslationAvailabilityQueryCalls()).at(-1)?.variables,
        ).toMatchObject({ translationTargetLocale: 'fr-fr' }),
      )
    })

    it('asks again once more articles are loaded', async () => {
      setup()
      await waitForTicketArticlesTranslationAvailabilityQueryCalls()

      loadedArticlesCount.value = 3

      await waitFor(async () =>
        expect(
          (await waitForTicketArticlesTranslationAvailabilityQueryCalls()).at(-1)?.variables,
        ).toMatchObject({ pageSize: 3 }),
      )
    })

    it('does not follow a change while hidden, and catches up when shown again', async () => {
      const { store, shown } = setup()
      const before = (await waitForTicketArticlesTranslationAvailabilityQueryCalls()).length

      shown.value = false
      await nextTick()

      store.setTargetLocale('fr-fr')
      await waitForNextTick(true)

      expect((await waitForTicketArticlesTranslationAvailabilityQueryCalls()).length).toBe(before)

      shown.value = true

      await waitFor(async () => {
        const calls = await waitForTicketArticlesTranslationAvailabilityQueryCalls()
        expect(calls.length).toBe(before + 1)
        expect(calls.at(-1)?.variables).toMatchObject({ translationTargetLocale: 'fr-fr' })
      })
    })
  })

  describe('direct action', () => {
    it('belongs to an article the server has a stored translation for', async () => {
      const { translation } = setup()
      mockAvailability(() => [articleId])

      await waitFor(() => expect(translation.hasDirectTranslationAction(articleId)).toBe(true))
      expect(translation.hasDirectTranslationAction(otherArticleId)).toBe(false)
    })

    it('follows the target language', async () => {
      const { translation, store } = setup()
      mockAvailability((locale) => (locale === 'fr-fr' ? [articleId] : []))

      await waitForTicketArticlesTranslationAvailabilityQueryCalls()
      expect(translation.hasDirectTranslationAction(articleId)).toBe(false)

      store.setTargetLocale('fr-fr')

      await waitFor(() => expect(translation.hasDirectTranslationAction(articleId)).toBe(true))
    })

    it('belongs to an article while its translation is on its way or shown', async () => {
      const { translation } = setup()
      deferred()

      const translating = translation.showTranslation(articleId)
      await openSubscription()
      await translating

      expect(translation.hasDirectTranslationAction(articleId)).toBe(true)
      expect(translation.hasDirectTranslationAction(otherArticleId)).toBe(false)
    })

    it('belongs to nobody while the service cannot translate', async () => {
      const { translation } = setup({ content_translation_ticket_article: false })
      mockAvailability(() => [articleId])
      await waitForNextTick(true)

      expect(translation.hasDirectTranslationAction(articleId)).toBe(false)
    })
  })
})
