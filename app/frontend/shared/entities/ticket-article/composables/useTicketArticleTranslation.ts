// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, onActivated, onDeactivated, ref, watch, type Ref } from 'vue'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import { useTicketArticleTranslateMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslate.api.ts'
import { useTicketArticleTranslateManyMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslateMany.api.ts'
import { useTicketArticlesTranslationAvailabilityLazyQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticlesTranslationAvailability.api.ts'
import { useTicketArticleTranslationUpdatesSubscription } from '#shared/entities/ticket-article/graphql/subscriptions/ticketArticleTranslationUpdates.api.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import type {
  ArticleTranslation,
  ArticleTranslationResult,
  TicketArticleTranslation,
} from '#shared/entities/ticket-article/stores/types.ts'
import type { TicketArticlesQueryVariables } from '#shared/graphql/types.ts'
import {
  MutationHandler,
  QueryHandler,
  SubscriptionHandler,
} from '#shared/server/apollo/handler/index.ts'

export const NO_TARGET_LOCALE_ERROR = __('No supported target language is available.')
export const NO_RESULT_ERROR = __('The translation returned no usable content.')

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
    // How many articles the tab has loaded: which of them have a stored translation is asked for
    // separately, page by page like the articles themselves.
    loadedArticlesCount: Ref<number>
    firstArticlesCount: Ref<number>
    loadedArticleSelections: Ref<TicketArticlesQueryVariables[]>
  },
): TicketArticleTranslation => {
  const store = useArticleTranslationStore()

  // Whether the service can translate is the server's answer, asked once per session.
  if (store.isEnabled) store.loadTargetLocales()

  // Keyed by article and locale, so a result for a former target never shows up as the current one.
  const translations = ref(new Map<string, ArticleTranslation>())
  // Articles whose translation is displayed instead of the original.
  const shown = ref(new Set<string>())
  // Articles the server has a stored translation for, per locale.
  const available = ref(new Map<string, Set<string>>())

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
      () => ({ enabled: started.value }),
    ),
    { errorShowNotification: false },
  )

  const readiness = useSubscriptionReadiness()

  const applyUpdate = (
    articleId: string,
    locale: string,
    update: {
      translation?: Maybe<ArticleTranslationResult>
      error?: Maybe<{ message: string }>
    },
  ) => {
    const key = translationKey(articleId, locale)

    if (update.error) {
      translations.value.set(key, { status: 'error', error: update.error.message })
      return
    }

    // The job publishes an empty event when the service produced nothing usable.
    if (!update.translation) {
      translations.value.set(key, { status: 'error', error: NO_RESULT_ERROR })
      return
    }

    const { content, backend, translated } = update.translation

    translations.value.set(key, { status: 'done', content, backend, translated })
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

  // Stored translations

  // Which of the loaded articles have a stored translation in the current target, asked with the
  // pages of the articles query reduced to that one flag: the bodies stay where they are.
  const availabilityQuery = new QueryHandler(useTicketArticlesTranslationAvailabilityLazyQuery(), {
    errorShowNotification: false,
  })

  let fetched: { locale: string; count: number } | undefined

  const fetchAvailability = async () => {
    const locale = targetLocale.value
    const count = options.loadedArticlesCount.value

    if (!store.isAvailable || !locale || !count) return
    if (fetched?.locale === locale && fetched.count === count) return

    fetched = { locale, count }

    const { data } = await availabilityQuery.query({
      variables: {
        ticketId: ticketId.value,
        pageSize: count,
        firstArticlesCount: options.firstArticlesCount.value,
        translationTargetLocale: locale,
      },
      // Not written to the cache: a cache write of the same connection would make the articles
      // query fetch its bodies again.
      fetchPolicy: 'no-cache',
    })

    if (!data) {
      // Not answered: the next change asks again.
      fetched = undefined
      return
    }

    const set = available.value.get(locale) ?? new Set<string>()

    ;[...(data.firstArticles?.edges ?? []), ...data.articles.edges].forEach(({ node }) => {
      if (node.translationAvailable) set.add(node.id)
      else set.delete(node.id)
    })

    available.value.set(locale, set)
  }

  // Only a shown tab asks; a hidden one catches up once when shown again.
  watch(
    () => [targetLocale.value, store.isAvailable, options.loadedArticlesCount.value],
    () => {
      if (isActive.value) fetchAvailability()
    },
    { immediate: true },
  )

  // Translating

  const translateMutation = new MutationHandler(useTicketArticleTranslateMutation(), {
    errorShowNotification: false,
  })

  // Results that cannot arrive anymore are forgotten, so that the next request asks the server again.
  const forgetPending = () => {
    translations.value.forEach((translation, key) => {
      if (translation.status === 'pending') translations.value.delete(key)
    })
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
    if (existing?.status === 'done' && existing.translated !== false) return

    translations.value.set(key, { status: 'pending' })

    await readiness.until(locale)

    // Forgotten while waiting, e.g. because the target changed.
    if (translations.value.get(key)?.status !== 'pending') return

    try {
      // Forced: the agent asked for this one article, whatever language it was detected in. A
      // stored translation is still served first.
      const result = await translateMutation.send({ articleId, targetLocale: locale, force: true })

      const translation = result?.ticketArticleTranslate?.translation

      // No translation yet means it is generated in the background; the subscription delivers it.
      if (translation) applyUpdate(articleId, locale, { translation })
    } catch (error) {
      applyUpdate(articleId, locale, {
        error: { message: error instanceof Error ? error.message : String(error) },
      })
    }
  }

  const translateShown = () => shown.value.forEach((articleId) => translate(articleId))

  const translateManyMutation = new MutationHandler(useTicketArticleTranslateManyMutation())
  const requests = ref(new Set<string>())
  let generation = 0

  const cancelRequests = () => {
    generation += 1
    requests.value.clear()
  }

  const translateSelection = async (selection: TicketArticlesQueryVariables) => {
    const locale = targetLocale.value
    if (!locale || !store.isAvailable || !allArticlesEnabled.value || !isActive.value) return

    const requestGeneration = generation
    const requestKey = JSON.stringify([requestGeneration, locale, selection])
    if (requests.value.has(requestKey)) return

    requests.value.add(requestKey)

    try {
      await readiness.until(locale)

      if (requestGeneration !== generation || !allArticlesEnabled.value || !isActive.value) return

      const previous = new Map(translations.value)
      const result = await translateManyMutation.send({ ...selection, targetLocale: locale })
      if (requestGeneration !== generation) return

      const payload = result?.ticketArticleTranslateMany
      payload?.translations?.forEach(({ article, translation }) => {
        const key = translationKey(article.id, locale)
        const current = translations.value.get(key)
        if (current !== previous.get(key)) return
        // An unforced batch must not replace a translation the agent explicitly requested.
        if (translation.translated === false && current?.status === 'done' && current.translated)
          return

        applyUpdate(article.id, locale, { translation })
      })
      payload?.pendingArticleIds.forEach((articleId) => {
        const key = translationKey(articleId, locale)
        const current = translations.value.get(key)
        // A background result can arrive before the mutation acknowledges the queued job.
        if (current === previous.get(key) && current?.status !== 'done') {
          translations.value.set(key, { status: 'pending' })
        }
      })
    } catch {
      // MutationHandler reports request failures; article failures arrive via the subscription.
    } finally {
      requests.value.delete(requestKey)
    }
  }

  const translateAll = () => options.loadedArticleSelections.value.forEach(translateSelection)

  // Every open tab follows the agent's preference; per-article display overrides remain local.
  watch(
    allArticlesEnabled,
    (enabled) => {
      original.value.clear()

      if (!enabled) {
        cancelRequests()
        shown.value.clear()
        return
      }

      translateAll()
    },
    { immediate: true },
  )

  watch(options.loadedArticleSelections, () => {
    cancelRequests()
    translateAll()
  })

  // What was on its way is lost with the former subscription; the shown articles are asked for
  // again once the new one answered. Known results are reused.
  const restart = () => {
    cancelRequests()
    readiness.reset()
    forgetPending()

    if (isActive.value) translateShown()
    translateAll()
  }

  // Articles showing a translation follow the new target.
  watch([ticketId, targetLocale], restart)

  // A result published while the connection was down is lost, and so would be one asked for
  // before the subscription is registered anew on the server.
  useOnEmitter('reconnected', restart)

  onActivated(() => {
    isActive.value = true
    fetchAvailability()
    translateShown()
    translateAll()
  })

  onDeactivated(() => {
    isActive.value = false
    cancelRequests()
  })

  // Reading

  // What an article displays right now: nothing while the original is shown or the feature is off.
  // Shown by the agent's own request, or by the mode that translates the whole ticket.
  const isShown = (articleId: string) =>
    shown.value.has(articleId) || (allArticlesEnabled.value && !original.value.has(articleId))

  const translationFor = (articleId: string) => {
    if (!store.isAvailable || !isShown(articleId)) return undefined

    return (
      translations.value.get(translationKey(articleId, targetLocale.value ?? '')) ??
      translations.value.get(translationKey(articleId, ''))
    )
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
      !!available.value.get(locale)?.has(articleId) ||
      (known?.status === 'done' && isTranslation(known)) ||
      isTranslationActive(articleId)
    )
  }

  const showOriginal = (articleId: string) => {
    shown.value.delete(articleId)
    // The mode shows every article, so putting one back has to be remembered next to it.
    if (allArticlesEnabled.value) original.value.add(articleId)
  }

  return {
    translationFor,
    isTranslationActive,
    hasDirectTranslationAction,
    showTranslation: translate,
    showOriginal,
    isTranslating: computed(() => requests.value.size > 0),
  }
}
