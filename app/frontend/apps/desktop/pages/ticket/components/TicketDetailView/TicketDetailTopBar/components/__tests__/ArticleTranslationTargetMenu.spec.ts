// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { createArticleTranslationMock } from '#shared/entities/ticket-article/__tests__/mocks/articleTranslation.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { mockTicketArticleTranslationTargetLocalesQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import { mockUserCurrentContentTranslationTargetLocaleMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationTargetLocale.mocks.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import ArticleTranslationTargetMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/ArticleTranslationTargetMenu.vue'

const ticket = createDummyTicket()

const renderMenu = () => {
  mockApplicationConfig({
    content_translation_service: true,
    content_translation_ticket_article: true,
    locale_default: 'en-us',
  })

  mockTicketArticleTranslationTargetLocalesQuery({
    ticketArticleTranslationTargetLocales: [
      { locale: 'de-de', alias: 'de', name: 'Deutsch - German', dir: EnumTextDirection.Ltr },
      { locale: 'en-us', alias: 'en', name: 'English (United States)', dir: EnumTextDirection.Ltr },
      { locale: 'fr-fr', alias: 'fr', name: 'Français - French', dir: EnumTextDirection.Ltr },
    ],
  })

  // The picked language is saved as a preference of the current user.
  mockUserCurrent({ preferences: { locale: 'en-us' } })

  mockUserCurrentContentTranslationTargetLocaleMutation({
    userCurrentContentTranslationTargetLocale: { success: true, errors: null },
  })

  const store = useArticleTranslationStore()
  // What the ticket tab does on creation.
  store.loadTargetLocales()

  const articleTranslation = createArticleTranslationMock()

  const wrapper = renderComponent(
    {
      components: { ArticleTranslationTargetMenu },
      setup() {
        provideTicketInformationMocks(ticket, { articleTranslation })
      },
      template: '<ArticleTranslationTargetMenu />',
    },
    { router: true, store: true, form: true },
  )

  return { wrapper, store, articleTranslation }
}

const openMenu = async (wrapper: ReturnType<typeof renderMenu>['wrapper']) => {
  await wrapper.events.click(
    await wrapper.findByRole('button', { name: 'Translation to English (United States)' }),
  )
}

describe('ArticleTranslationTargetMenu', () => {
  it('shows the code of the current target language', async () => {
    const { wrapper } = renderMenu()

    expect(
      await wrapper.findByRole('button', { name: 'Translation to English (United States)' }),
    ).toHaveTextContent('EN-US')
  })

  it('lists the supported languages with the current one marked', async () => {
    const { wrapper } = renderMenu()

    await openMenu(wrapper)

    expect(wrapper.getByRole('option', { name: 'Deutsch - German' })).toHaveAttribute(
      'aria-selected',
      'false',
    )
    expect(wrapper.getByRole('option', { name: 'English (United States)' })).toHaveAttribute(
      'aria-selected',
      'true',
    )
  })

  it('narrows the list down to the searched language', async () => {
    const { wrapper } = renderMenu()

    await openMenu(wrapper)
    await wrapper.events.type(wrapper.getByRole('searchbox'), 'fr')

    expect(wrapper.getByRole('option', { name: 'Fran\u00e7ais - French' })).toBeInTheDocument()
    expect(wrapper.queryByRole('option', { name: 'Deutsch - German' })).not.toBeInTheDocument()
  })

  it('says when no language matches the search', async () => {
    const { wrapper } = renderMenu()

    await openMenu(wrapper)
    await wrapper.events.type(wrapper.getByRole('searchbox'), 'klingon')

    expect(wrapper.getByText('No results found')).toBeInTheDocument()
  })

  it('changes the target for the ticket', async () => {
    const { wrapper, store } = renderMenu()
    const setTargetLocale = vi.spyOn(store, 'setTargetLocale')

    await openMenu(wrapper)
    await wrapper.events.click(wrapper.getByRole('option', { name: 'Deutsch - German' }))

    expect(setTargetLocale).toHaveBeenCalledWith('de-de')
    expect(
      await wrapper.findByRole('button', { name: 'Translation to Deutsch - German' }),
    ).toHaveTextContent('DE-DE')
  })

  // Kept for the follow-up that translates the articles of a whole ticket automatically.
})
