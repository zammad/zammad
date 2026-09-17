// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { mockTicketArticleTranslationTargetLocalesQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import { testOptionsTopBar } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/__tests__/support/testOptions.ts'
import TopBarHeaderCompact from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/TopBarHeaderCompact.vue'

const renderTopBarHeaderCompact = ({
  ticket = testOptionsTopBar,
}: {
  ticket?: typeof testOptionsTopBar
} = {}) => {
  return renderComponent(
    {
      components: { TopBarHeaderCompact },
      setup() {
        provideTicketInformationMocks(ticket)
      },
      template: '<TopBarHeaderCompact />',
    },
    { form: true, router: true },
  )
}

const TICKET_HOOK = 'Ticket#'

describe('TopBarHeaderCompact', () => {
  beforeEach(() => {
    mockApplicationConfig({
      fqdn: 'zammad.example.com',
      http_type: 'http',
      ticket_hook: TICKET_HOOK,
    })
  })

  it('shows last part of breadcrumb and copy button', () => {
    const view = renderTopBarHeaderCompact()

    expect(
      view.getByRole('heading', { name: `${TICKET_HOOK}${testOptionsTopBar.number}` }),
    ).toBeInTheDocument()
    expect(view.getByRole('button', { name: 'Copy ticket number' })).toBeInTheDocument()
  })

  it('shows highlight actions for editable agent tickets', () => {
    const view = renderTopBarHeaderCompact()

    expect(view.getByRole('button', { name: 'Highlight options' })).toBeInTheDocument()
  })

  it('hides highlight actions for readonly tickets', () => {
    const view = renderTopBarHeaderCompact({
      ticket: {
        ...testOptionsTopBar,
        policy: { ...testOptionsTopBar.policy, update: false },
      },
    })

    expect(view.queryByRole('button', { name: 'Highlight options' })).not.toBeInTheDocument()
  })

  it('shows the translation language menu for agents when the service can translate', async () => {
    mockApplicationConfig({
      content_translation_service: true,
      content_translation_ticket_article: true,
    })
    mockTicketArticleTranslationTargetLocalesQuery({
      ticketArticleTranslationTargetLocales: [
        { locale: 'en-us', alias: 'en', name: 'English', dir: EnumTextDirection.Ltr },
      ],
    })
    // What the ticket tab does on creation.
    useArticleTranslationStore().loadTargetLocales()

    const view = renderTopBarHeaderCompact({
      ticket: {
        ...testOptionsTopBar,
        policy: { ...testOptionsTopBar.policy, update: false },
      },
    })

    expect(await view.findByTestId('article-translation-target-menu')).toBeInTheDocument()
  })

  it('hides the translation language menu while article translation is off', () => {
    mockApplicationConfig({ content_translation_service: false })

    const view = renderTopBarHeaderCompact()

    expect(view.queryByTestId('article-translation-target-menu')).not.toBeInTheDocument()
  })
})
