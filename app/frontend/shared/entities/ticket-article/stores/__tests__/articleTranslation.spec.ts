// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createTestingPinia } from '@pinia/testing'
import { waitFor } from '@testing-library/vue'
import { setActivePinia } from 'pinia'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'

import {
  mockTicketArticleTranslationTargetLocalesQuery,
  mockTicketArticleTranslationTargetLocalesQueryError,
  waitForTicketArticleTranslationTargetLocalesQueryCalls,
} from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { UserCurrentContentTranslationAutoDocument } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationAuto.api.ts'
import {
  mockUserCurrentContentTranslationAutoMutation,
  waitForUserCurrentContentTranslationAutoMutationCalls,
} from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationAuto.mocks.ts'
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
const setup = (config: Partial<ConfigList> = {}, user: Partial<UserData> = {}) => {
  setActivePinia(createTestingPinia({ createSpy: vi.fn, stubActions: false }))

  useApplicationStore().config = {
    content_translation_service: true,
    content_translation_ticket_article: true,
    content_translation_ticket_article_auto: true,
    locale_default: 'en-us',
    ...config,
  } as ConfigList

  useSessionStore().user = {
    id: 'gid://zammad/User/2',
    preferences: { locale: 'de-de' },
    ...user,
  } as UserData

  mockUserCurrentContentTranslationTargetLocaleMutation({
    userCurrentContentTranslationTargetLocale: { success: true, errors: null },
  })
  mockUserCurrentContentTranslationAutoMutation({
    userCurrentContentTranslationAuto: { success: true, errors: null },
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

  describe('whole ticket', () => {
    // The capability the server answers for this agent; without it the setting has no effect.
    const withCapability = (preferences: Record<string, unknown> = {}) => ({
      hasContentTranslationAutoAvailable: true,
      preferences: { locale: 'de-de', ...preferences },
    })

    const available = async (store: ReturnType<typeof setup>) => {
      store.loadTargetLocales()
      await waitFor(() => expect(store.isAvailable).toBe(true))
    }

    it('is off without a stored preference', async () => {
      const store = setup({}, withCapability() as Partial<UserData>)
      mockTargetLocales()
      await available(store)

      expect(store.isAutoEnabled).toBe(false)
    })

    it('follows the stored preference', async () => {
      const store = setup(
        {},
        withCapability({ content_translation_auto: true }) as Partial<UserData>,
      )
      mockTargetLocales()
      await available(store)

      expect(store.isAutoEnabled).toBe(true)
    })

    it('stays off for an agent the configured roles do not allow', async () => {
      const store = setup({}, {
        preferences: { locale: 'de-de', content_translation_auto: true },
      } as Partial<UserData>)
      mockTargetLocales()
      await available(store)

      expect(store.isAutoEnabled).toBe(false)
    })

    it('turns off when the admin disables automatic translation in an open session', async () => {
      const store = setup(
        {},
        withCapability({ content_translation_auto: true }) as Partial<UserData>,
      )
      mockTargetLocales()
      await available(store)

      expect(store.isAutoEnabled).toBe(true)

      useApplicationStore().config.content_translation_ticket_article_auto = false

      expect(store.isAutoAvailable).toBe(false)
      expect(store.isAutoEnabled).toBe(false)
      expect(store.isAvailable).toBe(true)
    })

    it('saves a change as a personal preference', async () => {
      const store = setup({}, withCapability() as Partial<UserData>)
      mockTargetLocales()
      await available(store)

      store.setAutoEnabled(true)

      expect(store.isAutoEnabled).toBe(true)

      const calls = await waitForUserCurrentContentTranslationAutoMutationCalls()
      expect(calls.at(-1)?.variables).toEqual({ enabled: true })
    })

    it('saves nothing when it is set to what it already is', async () => {
      const store = setup({}, withCapability() as Partial<UserData>)
      mockTargetLocales()
      await available(store)

      store.setAutoEnabled(false)

      expect(getGraphQLMockCalls(UserCurrentContentTranslationAutoDocument)).toHaveLength(0)
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
