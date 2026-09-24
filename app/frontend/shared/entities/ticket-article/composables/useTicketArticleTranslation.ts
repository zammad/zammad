// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onActivated, onDeactivated, ref, shallowReactive, watch, type Ref } from 'vue'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import { useTicketArticleTranslateMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslate.api.ts'
import { useTicketArticleTranslateManyMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslateMany.api.ts'
import { useTicketArticleTranslationUpdatesSubscription } from '#shared/entities/ticket-article/graphql/subscriptions/ticketArticleTranslationUpdates.api.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import type {
  ArticleTranslation,
  ArticleTranslationResult,
  TicketArticleTranslation,
} from '#shared/entities/ticket-article/stores/types.ts'
import type {
  AiAnalyticsMetadata,
  TicketArticlesQueryVariables,
  TicketArticleTranslationFragment,
} from '#shared/graphql/types.ts'
import { MutationHandler, SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import { useArticleTranslationCache } from './useArticleTranslationCache.ts'

export const NO_TARGET_LOCALE_ERROR = __('No supported target language is available.')
export const NO_RESULT_ERROR = __('The translation returned no usable content.')

type TranslationState =
  | { status: 'pending' }
  | { status: 'done'; translated: boolean; analytics?: Maybe<DeepPartial<AiAnalyticsMetadata>> }
  | { status: 'error'; error: string }

const translationKey = (articleId: string, locale: string) => `${articleId}:${locale}`

// The server delivers deferred results only to subscribers of the ticket and target, so a request
// waits until the subscription for the current target has answered once. A new target or a new
// connection means a new subscription, which has to answer again first.
const useSubscriptionReadiness = () => {
  let readyLocale: string | undefined
  let waiting: Array<() => void> = []

  const answered = (locale?: string) => {
    readyLocale = locale
    waiting.forEach((resolve) => resolve())
    waiting = []
  }

  const reset = () => {
    readyLocale = undefined
  }

  const until = (locale: string) =>
    readyLocale === locale
      ? Promise.resolve()
      : new Promise<void>((resolve) => waiting.push(resolve))

  return { answered, reset, until }
}

// The translations of one ticket tab's articles. Created once by the ticket view, which the tab
// keeps alive, so the state lives exactly as long as the tab; the view provides it to the bubbles.
export const useTicketArticleTranslation = (
  ticketId: Ref<string>,
  options: {
    loadedArticleSelections: Ref<TicketArticlesQueryVariables[]>
  },
): TicketArticleTranslation => {
  const store = useArticleTranslationStore()

  // Whether the service can translate is the server's answer, asked once per session.
  if (store.isEnabled) store.loadTargetLocales()

  // Keyed by article and locale, so a result for a former target never shows up as the current one.
  const translations = ref(new Map<string, TranslationState>())
  // Regenerations on their way, by the same key: the translation they replace stays until one
  // succeeds, and is kept when it fails.
  const regenerations = shallowReactive(new Map<string, object>())
  const translationCache = useArticleTranslationCache()
  // Articles whose translation is displayed instead of the original.
  const shown = ref(new Set<string>())

  // Whether whole tickets are read in the target language is the agent's personal setting; what
  // this tab does with it stays here, so a ticket nobody is looking at still translates nothing.
  const allArticlesEnabled = computed(() => store.isAutoEnabled)
  // Articles the agent put back to their original while the setting is on.
  const original = ref(new Set<string>())

  // A hidden tab keeps listening, but acts only when shown again.
  const isActive = ref(true)

  const targetLocale = computed(() => store.targetLocale)

  // Subscription

  // One for the tab, following the target; it starts once the service and a target are known.
  //   Started only, never paused: a vue-apollo subscription enabled again under the same variables
  //   delivers nothing anymore.
  const started = ref(false)

  watch(
    () => store.isAvailable && !!targetLocale.value,
    (ready) => {
      if (ready) started.value = true
    },
    { immediate: true },
  )

  const subscription = new SubscriptionHandler(
    useTicketArticleTranslationUpdatesSubscription(
      () => ({ ticketId: ticketId.value, targetLocale: targetLocale.value ?? '' }),
      () => ({ enabled: started.value, fetchPolicy: 'no-cache' }),
    ),
    { errorShowNotification: false },
  )

  const readiness = useSubscriptionReadiness()

  const applyUpdate = (
    articleId: string,
    locale: string,
    update: {
      article?: Maybe<Partial<TicketArticleTranslationFragment>>
      translation?: Maybe<Pick<ArticleTranslationResult, 'translated'>>
      error?: Maybe<{ message: string }>
      // A sibling of the translation in both payloads, not a part of it.
      analytics?: Maybe<DeepPartial<AiAnalyticsMetadata>>
    },
  ) => {
    const key = translationKey(articleId, locale)
    const regenerating = regenerations.delete(key)

    const fail = (error: string) => {
      if (!regenerating) translations.value.set(key, { status: 'error', error })
    }

    if (update.error) {
      fail(update.error.message)
      return
    }

    const translation =
      update.translation?.translated === false
        ? { translated: false }
        : update.translation && update.article?.translation

    // The job publishes an empty event when the service produced nothing usable.
    if (!translation) {
      fail(NO_RESULT_ERROR)
      return
    }

    const translated = translation.translated !== false
    if (translated) translationCache.write(articleId, locale, translation)
    translations.value.set(key, { status: 'done', translated, analytics: update.analytics })
  }

  subscription.onResult(({ data }) => {
    const locale = targetLocale.value
    readiness.answered(locale)

    const update = data?.ticketArticleTranslationUpdates
    if (!update?.article || !locale) return

    applyUpdate(update.article.id, locale, update)
  })

  // A failing subscription is not the end: the mutation still answers, and reports its own error.
  subscription.onError(() => readiness.answered())

  // Translating

  const translateMutation = new MutationHandler(
    useTicketArticleTranslateMutation({ fetchPolicy: 'no-cache' }),
    {
      errorShowNotification: false,
    },
  )

  // Results that cannot arrive anymore are forgotten, so that the next request asks the server again.
  const forgetPending = () => {
    translations.value.forEach((translation, key) => {
      if (translation.status === 'pending') translations.value.delete(key)
    })
    regenerations.clear()
  }

  const requestTranslation = async (
    articleId: string,
    locale: string,
    regenerationOfId?: string,
  ) => {
    const key = translationKey(articleId, locale)
    const request = {}

    if (regenerationOfId) regenerations.set(key, request)
    else translations.value.set(key, { status: 'pending' })
    const pending = translations.value.get(key)

    // Answered already, or forgotten, e.g. because the target changed.
    const isCurrent = () =>
      regenerationOfId
        ? regenerations.get(key) === request
        : translations.value.get(key) === pending

    await readiness.until(locale)

    if (!isCurrent()) return

    try {
      // Forced: the agent asked for this one article, whatever language it was detected in. A
      // stored translation is still served first, unless it is the one to regenerate.
      const result = await translateMutation.send({
        articleId,
        targetLocale: locale,
        force: true,
        regenerationOfId,
      })

      if (!isCurrent()) return
      const payload = result?.ticketArticleTranslate

      // No translation yet means it is generated in the background; the subscription delivers it.
      if (payload?.translation) applyUpdate(articleId, locale, payload)
    } catch (error) {
      if (!isCurrent()) return
      applyUpdate(articleId, locale, {
        error: { message: error instanceof Error ? error.message : String(error) },
      })
    }
  }

  const translate = async (articleId: string) => {
    shown.value.add(articleId)
    original.value.delete(articleId)

    await store.loadTargetLocales()

    const locale = targetLocale.value

    if (!locale) {
      // Without a locale there is no key; the article shows the error under a pseudo key.
      translations.value.set(translationKey(articleId, ''), {
        status: 'error',
        error: NO_TARGET_LOCALE_ERROR,
      })
      return
    }

    const key = translationKey(articleId, locale)
    const existing = translations.value.get(key)

    // A known result is reused; a failed one is asked for again, and so is one the ticket-wide
    // request left untranslated - this one is forced, which is what the agent asks for here.
    if (existing?.status === 'pending') return
    if (
      existing?.status === 'done' &&
      existing.translated &&
      translationCache.read(articleId, locale)
    )
      return

    await requestTranslation(articleId, locale)
  }

  // Only a translation that came from an analytics run can be regenerated: the run is what the
  // server asks another translation for.
  const regenerateTranslation = async (articleId: string) => {
    const locale = targetLocale.value
    if (!locale) return

    const key = translationKey(articleId, locale)
    const translation = translations.value.get(key)
    if (translation?.status !== 'done' || !translation.analytics?.run?.id) return
    if (regenerations.has(key)) return

    await requestTranslation(articleId, locale, translation.analytics.run.id)
  }

  const translateShown = () => shown.value.forEach((articleId) => translate(articleId))

  // Lookup errors stay silent even if a generating request starts before they arrive.
  const lookupMutation = new MutationHandler(
    useTicketArticleTranslateManyMutation({ fetchPolicy: 'no-cache' }),
    { errorShowNotification: false },
  )
  const translateManyMutation = new MutationHandler(
    useTicketArticleTranslateManyMutation({ fetchPolicy: 'no-cache' }),
  )
  const requests = ref(new Map<string, boolean>())
  // Selection objects change on article-list refresh, even when pagination stays identical.
  let completedLookups = new WeakSet<TicketArticlesQueryVariables>()
  let generation = 0

  const cancelRequests = () => {
    generation += 1
    requests.value.clear()
  }

  const requestSelection = async (selection: TicketArticlesQueryVariables) => {
    const locale = targetLocale.value
    if (!locale || !store.isAvailable || !isActive.value) return

    const generateMissing = allArticlesEnabled.value

    const requestGeneration = generation
    const requestKey = JSON.stringify([requestGeneration, locale, generateMissing, selection])
    if (requests.value.has(requestKey) || (!generateMissing && completedLookups.has(selection)))
      return

    requests.value.set(requestKey, generateMissing)

    try {
      if (generateMissing) await readiness.until(locale)

      if (requestGeneration !== generation || !isActive.value) return

      const previous = new Map(translations.value)
      const mutation = generateMissing ? translateManyMutation : lookupMutation
      const result = await mutation.send({
        ...selection,
        targetLocale: locale,
        generateMissing,
      })
      if (requestGeneration !== generation) return

      const payload = result?.ticketArticleTranslateMany
      translationCache.batch(() => {
        payload?.results.forEach((entry) => {
          const { article, translated, analytics } = entry
          const key = translationKey(article.id, locale)
          const current = translations.value.get(key)
          if (current !== previous.get(key) || regenerations.has(key)) return
          translationCache.writeAvailability(article.id, locale, article.translationAvailable)

          if (!generateMissing || translated == null) return
          // An unforced batch must not replace a translation the agent explicitly requested.
          if (!translated && current?.status === 'done' && current.translated) return

          applyUpdate(article.id, locale, { article, translation: { translated }, analytics })
        })
      })
      if (payload && !generateMissing) completedLookups.add(selection)
      payload?.pendingArticleIds?.forEach((articleId) => {
        const key = translationKey(articleId, locale)
        const current = translations.value.get(key)
        // A background result can arrive before the mutation acknowledges the queued job.
        if (
          current === previous.get(key) &&
          (current?.status !== 'done' ||
            (current.translated && !translationCache.read(articleId, locale)))
        ) {
          translations.value.set(key, { status: 'pending' })
        }
      })
    } catch {
      // Generating requests report failures; metadata lookups retry on the next change.
    } finally {
      requests.value.delete(requestKey)
    }
  }

  const requestSelections = () => options.loadedArticleSelections.value.forEach(requestSelection)

  watch(
    [
      ticketId,
      targetLocale,
      () => store.isAvailable,
      allArticlesEnabled,
      options.loadedArticleSelections,
      isActive,
    ],
    (
      [ticket, locale, serviceAvailable, enabled],
      [previousTicket, previousLocale, previousServiceAvailable, previousEnabled],
    ) => {
      cancelRequests()
      if (
        ticket !== previousTicket ||
        locale !== previousLocale ||
        serviceAvailable !== previousServiceAvailable ||
        enabled !== previousEnabled
      )
        completedLookups = new WeakSet()
      if (ticket !== previousTicket || locale !== previousLocale) {
        readiness.reset()
        forgetPending()
      }
      if (enabled !== previousEnabled) {
        original.value.clear()
        if (!enabled) shown.value.clear()
      }
      if (!isActive.value) return

      translateShown()
      requestSelections()
    },
    { immediate: true },
  )

  // A result published while disconnected is lost; generating again waits for the subscription.
  useOnEmitter('reconnected', () => {
    cancelRequests()
    completedLookups = new WeakSet()
    readiness.reset()
    forgetPending()
    if (!isActive.value) return

    translateShown()
    requestSelections()
  })

  onActivated(() => {
    isActive.value = true
  })
  onDeactivated(() => {
    isActive.value = false
  })

  // Reading

  // What an article displays right now: nothing while the original is shown or the feature is off.
  // Shown by the agent's own request, or by the mode that translates the whole ticket.
  const isShown = (articleId: string) =>
    shown.value.has(articleId) || (allArticlesEnabled.value && !original.value.has(articleId))

  const translationFor = (articleId: string) => {
    if (!store.isAvailable || !isShown(articleId)) return undefined

    const locale = targetLocale.value ?? ''
    const key = translationKey(articleId, locale)
    const state =
      translations.value.get(key) ?? translations.value.get(translationKey(articleId, ''))
    if (state?.status !== 'done' || !state.translated) return state

    const cached = translationCache.read(articleId, locale)
    if (!cached) return undefined

    return {
      ...state,
      content: cached.content,
      backend: cached.backend,
      regenerating: regenerations.has(key),
    }
  }

  // A failed one leaves the original on screen, and so does a result for an article already in the
  // target language: neither is a translation the article could show.
  const isTranslation = (translation?: ArticleTranslation) => {
    if (!translation || translation.status === 'error') return false

    return translation.status === 'pending' || translation.translated !== false
  }

  // Requested and not failed: shown when done, awaited while pending. The toggle is on for both
  // and turns the original back on; for a failed one it is off and asks again.
  const isTranslationActive = (articleId: string) => isTranslation(translationFor(articleId))

  // Whether the article carries the direct translate button: a translation is stored for it, or
  // one is on its way or shown. Everything else, a failed request included, translates from the
  // article menu.
  const hasDirectTranslationAction = (articleId: string) => {
    const locale = targetLocale.value
    if (!store.isAvailable || !locale) return false

    const known = translations.value.get(translationKey(articleId, locale))

    return (
      !!translationCache.readAvailability(articleId, locale) ||
      (known?.status === 'done' && isTranslation(known)) ||
      isTranslationActive(articleId)
    )
  }

  const showOriginal = (articleId: string) => {
    shown.value.delete(articleId)
    // The mode shows every article, so putting one back has to be remembered next to it.
    if (allArticlesEnabled.value) original.value.add(articleId)
  }

  // The rating belongs to the translation, not to whatever displays it: showing the original and
  // back reuses this entry, so a rating kept elsewhere would be forgotten with the control.
  const markTranslationRated = (articleId: string) => {
    const key = translationKey(articleId, targetLocale.value ?? '')
    const translation = translations.value.get(key)

    if (translation?.status !== 'done' || !translation.analytics) return

    translations.value.set(key, {
      ...translation,
      analytics: {
        ...translation.analytics,
        usage: { ...translation.analytics.usage, userHasProvidedFeedback: true },
      },
    })
  }

  return {
    translationFor,
    isTranslationActive,
    hasDirectTranslationAction,
    showTranslation: translate,
    showOriginal,
    isTranslating: computed(() => [...requests.value.values()].some(Boolean)),
    markTranslationRated,
    regenerateTranslation,
  }
}
