// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { mockTicketArticleTranslationTargetLocalesQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { mockLocalesQuery } from '#shared/graphql/queries/locales.mocks.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'

describe('testing locale a11y view', () => {
  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/locale')
    await expect(view.container).toBeAccessible()
  })

  it('has no accessibility violations with the content translation section', async () => {
    mockApplicationConfig({
      content_translation_service: true,
      content_translation_ticket_article: true,
      content_translation_ticket_article_auto: true,
      language_detection_article: 'cld',
    })
    mockTicketArticleTranslationTargetLocalesQuery({
      ticketArticleTranslationTargetLocales: [
        { locale: 'de-de', alias: 'de', name: 'Deutsch - German', dir: EnumTextDirection.Ltr },
      ],
    })
    // A selected language shows the clear control, which needs an accessible name.
    mockUserCurrent({
      preferences: { locale: 'en-us', content_translation_excluded_languages: ['en'] },
      hasContentTranslationAutoAvailable: true,
    })
    mockLocalesQuery({
      locales: [
        ['en-us', 'en'],
        ['de-de', 'de'],
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

    await view.findByLabelText('Languages you understand')
    await expect(view.container).toBeAccessible()
  })
})
