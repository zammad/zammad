// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { TicketArticleTranslationTargetLocalesDocument } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.api.ts'
import { mockTicketArticleTranslationTargetLocalesQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import { UserCurrentContentTranslationExcludedLanguagesDocument } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationExcludedLanguages.api.ts'
import {
  mockUserCurrentContentTranslationExcludedLanguagesMutation,
  waitForUserCurrentContentTranslationExcludedLanguagesMutationCalls,
} from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationExcludedLanguages.mocks.ts'
import { waitForUserCurrentLocaleMutationCalls } from '#shared/entities/user/current/graphql/mutations/userCurrentLocale.mocks.ts'
import { mockLocalesQuery } from '#shared/graphql/queries/locales.mocks.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import { useSessionStore } from '#shared/stores/session.ts'

describe('locale page', () => {
  it('can change language', async () => {
    mockLocalesQuery({
      locales: [
        // Add always the default language 'en-us' to the list of locales.
        {
          locale: 'en-us',
          name: 'English (United States)',
          dir: EnumTextDirection.Ltr,
          alias: 'en',
          active: true,
        },
        {
          locale: 'de-de',
          name: 'Deutsch',
          dir: EnumTextDirection.Ltr,
          alias: 'de',
          active: true,
        },
        {
          locale: 'ar',
          name: 'Arabic',
          dir: EnumTextDirection.Rtl,
          alias: null,
          active: true,
        },
      ],
    })

    const view = await visitView('/personal-setting/locale')
    const localeField = view.getByLabelText('User interface language')

    await view.events.click(localeField)

    const arabicLocale = view.getByText('Arabic')

    await view.events.click(arabicLocale)

    const calls = await waitForUserCurrentLocaleMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({ locale: 'ar' })

    expect(localeField).not.toHaveTextContent('User interface language')
  })

  it('has link to zammad translations', async () => {
    const view = await visitView('/personal-setting/locale')

    expect(view.queryByText('You can help translating Zammad.')).toBeInTheDocument()
  })

  describe('content translation', () => {
    // `auto` is the server capability to use "translate all", `detection` the language detection.
    const visitLocalePage = async ({ auto = true, detection = 'cld' as '' | 'cld' } = {}) => {
      mockApplicationConfig({
        content_translation_service: true,
        content_translation_ticket_article: true,
        content_translation_ticket_article_auto: true,
        language_detection_article: detection,
      })

      mockTicketArticleTranslationTargetLocalesQuery({
        ticketArticleTranslationTargetLocales: [
          { locale: 'de-de', alias: 'de', name: 'Deutsch - German', dir: EnumTextDirection.Ltr },
        ],
      })

      mockUserCurrent({
        preferences: { locale: 'en-us', content_translation_excluded_languages: ['en'] },
        hasContentTranslationAutoAvailable: auto,
      })

      mockLocalesQuery({
        locales: [
          ['en-us', 'en'],
          ['en-gb', 'en'],
          ['de-de', 'de'],
          ['zh-cn', 'zh-Hans'],
          ['zh-tw', 'zh-Hant'],
        ].map(([locale, language]) => ({
          locale,
          language,
          name: locale,
          dir: EnumTextDirection.Ltr,
          alias: null,
          active: true,
        })),
      })

      const view = await visitView('/personal-setting/locale')

      // Only then is a hidden section hidden for the reason under test.
      if (auto) await waitFor(() => expect(useArticleTranslationStore().isAvailable).toBe(true))

      return view
    }

    it('offers each language once and saves the selection', async () => {
      mockUserCurrentContentTranslationExcludedLanguagesMutation({
        userCurrentContentTranslationExcludedLanguages: { success: true, errors: null },
      })

      const view = await visitLocalePage()

      await view.events.click(await view.findByLabelText('Languages you understand'))

      // en-us and en-gb are one language, zh-cn and zh-tw two.
      expect(view.getAllByRole('option').map((option) => option.textContent?.trim())).toEqual([
        'Chinese (Simplified)',
        'Chinese (Traditional)',
        'English',
        'German',
      ])

      expect(view.getByRole('option', { name: 'English' })).toHaveAttribute('aria-selected', 'true')

      await view.events.click(view.getByRole('option', { name: 'German' }))

      const calls = await waitForUserCurrentContentTranslationExcludedLanguagesMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({ languages: ['en', 'de'] })
    })

    it('names the languages in the UI language', async () => {
      const view = await visitLocalePage()

      await useLocaleStore().setLocale('de-de')
      await view.events.click(await view.findByLabelText('Languages you understand'))

      expect(view.getByRole('option', { name: 'Englisch' })).toBeInTheDocument()
      expect(view.getByRole('option', { name: 'Deutsch' })).toBeInTheDocument()
    })

    // The server pushes the saved user back, e.g. from another tab: the field follows it, but
    // saving it again would bounce every change between client and server.
    it('does not save a change that comes from the server', async () => {
      const view = await visitLocalePage()

      await view.findByLabelText('Languages you understand')

      useSessionStore().setUserPreference('content_translation_excluded_languages', ['en', 'de'])

      await waitFor(() => expect(view.getByText('German')).toBeInTheDocument())

      expect(
        getGraphQLMockCalls(UserCurrentContentTranslationExcludedLanguagesDocument),
      ).toHaveLength(0)
    })

    it('is hidden for an agent who cannot use "translate all"', async () => {
      const view = await visitLocalePage({ auto: false })

      expect(view.queryByLabelText('Languages you understand')).not.toBeInTheDocument()
      // Customers see this page too, and the server would refuse them.
      expect(getGraphQLMockCalls(TicketArticleTranslationTargetLocalesDocument)).toHaveLength(0)
    })

    it('is hidden when language detection is off', async () => {
      const view = await visitLocalePage({ detection: '' })

      expect(view.queryByLabelText('Languages you understand')).not.toBeInTheDocument()
    })
  })
})
