// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createTestingPinia } from '@pinia/testing'
import { waitFor } from '@testing-library/vue'
import { setActivePinia } from 'pinia'

import {
  mockTicketArticleTranslationTargetLocalesQuery,
  mockTicketArticleTranslationTargetLocalesQueryError,
  waitForTicketArticleTranslationTargetLocalesQueryCalls,
} from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import {
  mockUserCurrentContentTranslationTargetLocaleMutation,
  waitForUserCurrentContentTranslationTargetLocaleMutationCalls,
} from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationTargetLocale.mocks.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'
import type { ConfigList, UserData } from '#shared/types/store.ts'

import { useArticleTranslationStore } from '../articleTranslation.ts'

const mockTargetLocales = (locales = ['de-de', 'en-us', 'fr-fr']) =>
  mockTicketArticleTranslationTargetLocalesQuery({
    ticketArticleTranslationTargetLocales: locales.map((locale) => ({
      locale,
      alias: locale.split('-')[0],
      name: `Name ${locale}`,
      dir: EnumTextDirection.Ltr,
    })),
  })

// A pinia of its own per example: the locales of the last one would otherwise carry over.
const setup = (config: Partial<ConfigList> = {}) => {
  setActivePinia(createTestingPinia({ createSpy: vi.fn, stubActions: false }))

  useApplicationStore().config = {
    content_translation_service: true,
    content_translation_ticket_article: true,
    locale_default: 'en-us',
    ...config,
  } as ConfigList

  useSessionStore().user = {
    id: 'gid://zammad/User/2',
    preferences: { locale: 'de-de' },
  } as UserData

  mockUserCurrentContentTranslationTargetLocaleMutation({
    userCurrentContentTranslationTargetLocale: { success: true, errors: null },
  })

  return useArticleTranslationStore()
}

describe('useArticleTranslationStore', () => {
  describe('availability', () => {
    it('is not available before the server answered', () => {
      const store = setup()

      expect(store.isEnabled).toBe(true)
      expect(store.isAvailable).toBe(false)
    })

    it('is available once the server offers target locales', async () => {
      const store = setup()

      mockTargetLocales()
      await store.loadTargetLocales()

      expect(store.isAvailable).toBe(true)
    })

    it('is not available when the service cannot translate', async () => {
      const store = setup()

      mockTicketArticleTranslationTargetLocalesQueryError('AI provider is not configured.', {
        type: GraphQLErrorTypes.UnknownError,
      })
      await store.loadTargetLocales()

      expect(store.isAvailable).toBe(false)
    })

    it('is not available without any target locale', async () => {
      const store = setup()

      mockTargetLocales([])
      await store.loadTargetLocales()

      expect(store.isAvailable).toBe(false)
    })

    it('is not available while the settings are off', async () => {
      const store = setup({ content_translation_ticket_article: false })

      mockTargetLocales()
      await store.loadTargetLocales()

      expect(store.isAvailable).toBe(false)
    })

    it('asks the server again when the AI provider setting changes', async () => {
      const store = setup()

      mockTargetLocales()
      await store.loadTargetLocales()
      expect(await waitForTicketArticleTranslationTargetLocalesQueryCalls()).toHaveLength(1)

      useApplicationStore().config.ai_provider = true

      await waitFor(async () =>
        expect(await waitForTicketArticleTranslationTargetLocalesQueryCalls()).toHaveLength(2),
      )
      await waitFor(() => expect(store.isAvailable).toBe(true))
    })
  })

  describe('target locale', () => {
    it('falls back to the user locale, then the system default, then English', async () => {
      const store = setup()

      expect(store.targetLocale).toBe('de-de')

      mockTargetLocales(['en-us', 'fr-fr'])
      await store.loadTargetLocales()

      expect(store.targetLocale).toBe('en-us')
    })

    it('uses English when neither the user locale nor the system default are supported', async () => {
      const store = setup({ locale_default: 'fr-fr' })

      mockTargetLocales(['en-us'])
      await store.loadTargetLocales()

      expect(store.targetLocale).toBe('en-us')
    })

    it('has no target when none of the fallbacks is supported', async () => {
      const store = setup()

      mockTargetLocales(['es-es'])
      await store.loadTargetLocales()

      expect(store.targetLocale).toBeUndefined()
    })

    it('prefers the saved preference over the user locale', async () => {
      const store = setup()
      useSessionStore().user!.preferences!.content_translation_target_locale = 'fr-fr'

      mockTargetLocales()
      await store.loadTargetLocales()

      expect(store.targetLocale).toBe('fr-fr')
      expect(store.targetLocaleName).toBe('Name fr-fr')
    })

    it('saves a picked target as the preference of the agent', async () => {
      const store = setup()

      mockTargetLocales()
      await store.loadTargetLocales()
      mockUserCurrentContentTranslationTargetLocaleMutation({
        userCurrentContentTranslationTargetLocale: { success: true, errors: null },
      })

      store.setTargetLocale('fr-fr')

      expect(store.targetLocale).toBe('fr-fr')
      expect(useSessionStore().user?.preferences?.content_translation_target_locale).toBe('fr-fr')

      const calls = await waitForUserCurrentContentTranslationTargetLocaleMutationCalls()
      expect(calls.at(-1)?.variables).toEqual({ targetLocale: 'fr-fr' })
    })
  })
})
