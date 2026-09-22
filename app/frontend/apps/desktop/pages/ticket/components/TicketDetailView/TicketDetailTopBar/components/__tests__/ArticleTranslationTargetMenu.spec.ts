// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { createArticleTranslationMock } from '#shared/entities/ticket-article/__tests__/mocks/articleTranslation.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { mockTicketArticleTranslationTargetLocalesQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import {
  mockUserCurrentContentTranslationAutoMutation,
  waitForUserCurrentContentTranslationAutoMutationCalls,
} from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationAuto.mocks.ts'
import { mockUserCurrentContentTranslationTargetLocaleMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentContentTranslationTargetLocale.mocks.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import ArticleTranslationTargetMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/ArticleTranslationTargetMenu.vue'

const ticket = createDummyTicket()

// `auto` is the server capability; `allArticles` is the saved preference.
const renderMenu = ({ auto = false, allArticles = false } = {}) => {
  mockApplicationConfig({
    content_translation_service: true,
    content_translation_ticket_article: true,
    content_translation_ticket_article_auto: true,
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
  mockUserCurrent({
    preferences: { locale: 'en-us', content_translation_auto: allArticles },
    hasContentTranslationAutoAvailable: auto,
  })

  mockUserCurrentContentTranslationAutoMutation({
    userCurrentContentTranslationAuto: { success: true, errors: null },
  })

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

  return { wrapper, store }
}

const openMenu = async (
  wrapper: ReturnType<typeof renderMenu>['wrapper'],
  name = 'Translation to English (United States)',
) => {
  await wrapper.events.click(await wrapper.findByRole('button', { name }))
}

const ALL_ARTICLES_TRIGGER = 'All articles translated to English (United States)'

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

  describe('the switch for the whole ticket', () => {
    it('is missing for an agent the configured roles do not allow', async () => {
      const { wrapper } = renderMenu()

      await openMenu(wrapper)

      expect(wrapper.queryByRole('switch')).not.toBeInTheDocument()
      // The target language stays theirs to pick.
      expect(wrapper.getByRole('option', { name: 'Deutsch - German' })).toBeInTheDocument()
    })

    it('switches the whole ticket on', async () => {
      const { wrapper } = renderMenu({ auto: true })

      await openMenu(wrapper)

      const toggle = wrapper.getByRole('switch', { name: 'Translate all articles' })
      expect(toggle).toHaveAttribute('aria-checked', 'false')

      await wrapper.events.click(toggle)

      expect(
        (await waitForUserCurrentContentTranslationAutoMutationCalls()).at(-1)?.variables,
      ).toEqual({ enabled: true })
    })

    it('shows the mode of the ticket when the popover is opened again', async () => {
      const { wrapper } = renderMenu({ auto: true, allArticles: true })

      await openMenu(wrapper, ALL_ARTICLES_TRIGGER)

      expect(wrapper.getByRole('switch', { name: 'Translate all articles' })).toHaveAttribute(
        'aria-checked',
        'true',
      )
    })

    it('switches the whole ticket off again', async () => {
      const { wrapper } = renderMenu({ auto: true, allArticles: true })

      await openMenu(wrapper, ALL_ARTICLES_TRIGGER)
      await wrapper.events.click(wrapper.getByRole('switch', { name: 'Translate all articles' }))

      expect(
        (await waitForUserCurrentContentTranslationAutoMutationCalls()).at(-1)?.variables,
      ).toEqual({ enabled: false })
    })

    // The mode is otherwise only visible on the articles themselves.
    it('is announced by the trigger button while it is on', async () => {
      const { wrapper } = renderMenu({ auto: true, allArticles: true })

      expect(await wrapper.findByRole('button', { name: ALL_ARTICLES_TRIGGER })).toBeInTheDocument()
    })
  })
})
