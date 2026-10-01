// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEqual } from 'lodash-es'
import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, ref, toRef, watch } from 'vue'

import { useTicketArticleTranslationTargetLocalesLazyQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.api.ts'
import { useUserCurrentContentTranslationAutoMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationAuto.api.ts'
import { useUserCurrentContentTranslationExcludedLanguagesMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationExcludedLanguages.api.ts'
import { useUserCurrentContentTranslationTargetLocaleMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationTargetLocale.api.ts'
import { MutationHandler, QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { ArticleTranslationTargetLocale } from './types.ts'
import type { JsonValue } from 'type-fest'

// What every ticket tab shares: whether the service can translate, which languages it offers, and
// the one target language of the agent - a personal preference, so changing it anywhere changes it
// everywhere. What a single tab knows about its articles lives in useTicketArticleTranslation.
export const useArticleTranslationStore = defineStore('articleTranslation', () => {
  const config = toRef(useApplicationStore(), 'config')
  const session = useSessionStore()

  // The settings say whether translation is meant to be on ...
  const isEnabled = computed(
    () =>
      !!config.value.content_translation_service &&
      !!config.value.content_translation_ticket_article,
  )

  // Applied at once, saved in the background: the preference is the agent's, so it survives the
  //   tab and the session. A failed save puts the previous value back, so the same choice can be
  //   made again; a newer choice made in the meantime stays.
  const savePreference = (name: string, value: JsonValue, save: () => Promise<unknown>) => {
    const previous = session.user?.preferences?.[name] ?? null
    session.setUserPreference(name, value)

    save().catch(() => {
      if (isEqual(session.user?.preferences?.[name], value))
        session.setUserPreference(name, previous)
    })
  }

  // Target locales

  const targetLocalesQuery = new QueryHandler(
    useTicketArticleTranslationTargetLocalesLazyQuery({ fetchPolicy: 'network-only' }),
    { errorShowNotification: false },
  )

  const targetLocales = ref<ArticleTranslationTargetLocale[] | null>(null)

  let loadingTargetLocales: Promise<ArticleTranslationTargetLocale[] | null> | undefined
  let asked = false

  let loadGeneration = 0

  const loadTargetLocales = () => {
    if (targetLocales.value) return Promise.resolve(targetLocales.value)
    if (loadingTargetLocales) return loadingTargetLocales

    const generation = loadGeneration
    asked = true

    loadingTargetLocales = targetLocalesQuery
      .query()
      .then(({ data }) => {
        if (generation !== loadGeneration) return targetLocales.value
        // A failed request is not cached; the next call asks again.
        if (data) targetLocales.value = data.ticketArticleTranslationTargetLocales

        return targetLocales.value
      })
      .finally(() => {
        if (generation === loadGeneration) loadingTargetLocales = undefined
      })

    return loadingTargetLocales
  }

  // ... and the server whether it can translate right now: the target locales come back only from
  // a usable service (the AI backend, for one, needs a configured AI provider). One question, one
  // answer, no second copy of the server's rules in the client.
  const isAvailable = computed(() => isEnabled.value && (targetLocales.value?.length ?? 0) > 0)

  // Whether this agent may switch a whole ticket to the target language: the server answers it
  // with the session, the configured roles never reach the client.
  const isAutoAvailable = computed(
    () =>
      isAvailable.value &&
      !!config.value.content_translation_ticket_article_auto &&
      !!session.user?.hasContentTranslationAutoAvailable,
  )

  // Whole ticket

  // Whether the agent reads whole tickets in the target language. A personal preference like the
  // target language itself, so a ticket opened later is translated without asking again - and
  // switching it in one ticket switches it in every open one.
  const isAutoEnabled = computed(
    () => isAutoAvailable.value && !!session.user?.preferences?.content_translation_auto,
  )

  const autoMutation = new MutationHandler(useUserCurrentContentTranslationAutoMutation(), {
    errorNotificationMessage: __('The translation setting could not be saved.'),
  })

  const setAutoEnabled = (enabled: boolean) => {
    if (isAutoEnabled.value === enabled) return

    savePreference('content_translation_auto', enabled, () => autoMutation.send({ enabled }))
  }

  // "Translate all" skips articles by their detected language, so without detection there is
  // nothing to exclude.
  const isExclusionAvailable = computed(
    () => isAutoAvailable.value && !!config.value.language_detection_article,
  )

  const excludedLanguages = computed(
    () => (session.user?.preferences?.content_translation_excluded_languages as string[]) ?? [],
  )

  const excludedLanguagesMutation = new MutationHandler(
    useUserCurrentContentTranslationExcludedLanguagesMutation(),
    { errorNotificationMessage: __('The translation setting could not be saved.') },
  )

  const setExcludedLanguages = (languages: string[]) => {
    if (isEqual(excludedLanguages.value, languages)) return

    savePreference('content_translation_excluded_languages', languages, () =>
      excludedLanguagesMutation.send({ languages }),
    )
  }

  // The answer can change with the settings: ask again, if anyone asked before.
  watch(
    () => [isEnabled.value, config.value.ai_provider],
    () => {
      loadGeneration += 1
      loadingTargetLocales = undefined
      targetLocales.value = null

      if (isEnabled.value && asked) loadTargetLocales()
    },
  )

  const isSupported = (locale: string) =>
    // Unknown until the query answered: the default is then narrowed down before translating.
    !targetLocales.value || targetLocales.value.some((entry) => entry.locale === locale)

  // The saved preference first, then the user locale, the system default and English - each only
  // if the service supports it.
  const targetLocale = computed(() => {
    const preferences = session.user?.preferences ?? {}
    const candidates = [
      preferences.content_translation_target_locale as string | undefined,
      preferences.locale as string | undefined,
      config.value.locale_default,
      'en-us',
    ]

    return candidates.find((locale) => locale && isSupported(locale))
  })

  const targetLocaleData = computed(() =>
    targetLocales.value?.find((entry) => entry.locale === targetLocale.value),
  )

  const targetLocaleName = computed(() => targetLocaleData.value?.name ?? targetLocale.value ?? '')

  const targetLocaleMutation = new MutationHandler(
    useUserCurrentContentTranslationTargetLocaleMutation(),
    { errorNotificationMessage: __('The translation language could not be saved.') },
  )

  // The open tabs follow the change on their own.
  const setTargetLocale = (locale: string) => {
    if (targetLocale.value === locale) return

    savePreference('content_translation_target_locale', locale, () =>
      targetLocaleMutation.send({ targetLocale: locale }),
    )
  }

  return {
    isEnabled,
    isAvailable,
    isAutoAvailable,
    isAutoEnabled,
    setAutoEnabled,
    isExclusionAvailable,
    excludedLanguages,
    setExcludedLanguages,
    targetLocales,
    loadTargetLocales,
    targetLocale,
    targetLocaleData,
    targetLocaleName,
    setTargetLocale,
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useArticleTranslationStore, import.meta.hot))
}
