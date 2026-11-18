// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { waitFor, within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { waitForTicketUpdateMutationCalls } from '#shared/entities/ticket/graphql/mutations/update.mocks.ts'
import { mockTicketArticlesQuery } from '#shared/entities/ticket/graphql/queries/ticket/articles.mocks.ts'
import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { mockTicketArticleTranslateMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslate.mocks.ts'
import { mockTicketArticleTranslateManyMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleTranslateMany.mocks.ts'
import { mockTicketArticleTranslationTargetLocalesQuery } from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { getTicketArticleTranslationUpdatesSubscriptionHandler } from '#shared/entities/ticket-article/graphql/subscriptions/ticketArticleTranslationUpdates.mocks.ts'
import { EnumTextDirection, EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockLinkListQuery } from '#desktop/entities/link/graphql/queries/linkList.mocks.ts'

const NOTICE = 'The original message was written in another language.'
const NOTICE_WITH_LANGUAGE = 'The original message was written in %s.'

const articleId = convertToGraphQLId('TicketArticle', 1)

type View = Awaited<ReturnType<typeof visitView>>

describe('Ticket detail view - reply to a translated article', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      content_translation_service: true,
      content_translation_ticket_article: true,
      locale_default: 'en-us',
      ui_ticket_zoom_article_note_new_internal: true,
    })

    mockLinkListQuery({ linkList: [] })
  })

  const visitTicket = async (detectedLanguage?: string) => {
    mockTicketQuery({
      ticket: createDummyTicket({
        group: {
          id: convertToGraphQLId('Group', 1),
          emailAddress: { name: 'Zammad Helpdesk', emailAddress: 'zammad@localhost' },
        },
        articleType: 'email',
        defaultPolicy: { update: true, agentReadAccess: true },
      }),
    })

    mockTicketArticlesQuery({
      articles: {
        totalCount: 1,
        edges: [
          {
            node: createDummyArticle({
              articleType: 'email',
              internal: false,
              senderName: EnumTicketArticleSenderName.Customer,
              bodyWithUrls: 'Guten Tag',
              detectedLanguage,
            }),
          },
        ],
      },
    })

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: { options: [{ value: 1, label: 'Users' }] },
          owner_id: { options: [{ value: 3, label: 'Test Admin Agent' }] },
          state_id: { options: [{ value: 2, label: 'open' }] },
          pending_time: { show: false },
          priority_id: { options: [{ value: 2, label: '2 normal' }] },
        },
        flags: { newArticlePresent: false },
      },
    })

    mockTicketArticleTranslationTargetLocalesQuery({
      ticketArticleTranslationTargetLocales: [
        { locale: 'en-us', alias: 'en', name: 'English', dir: EnumTextDirection.Ltr },
      ],
    })

    mockTicketArticleTranslateManyMutation({
      ticketArticleTranslateMany: { results: [], pendingArticleIds: [], pendingBackend: null },
    })

    mockTicketArticleTranslateMutation({
      ticketArticleTranslate: {
        article: {
          id: articleId,
          translation: { content: 'Good day', backend: 'ai', translated: true },
        },
        translation: { translated: true },
      },
    })

    const view = await visitView('/tickets/1')

    const [article] = await view.findAllByRole('article')

    return { view, article }
  }

  const translate = async (view: View, article: HTMLElement) => {
    await view.events.click(
      await within(article).findByRole('button', { name: 'Translate article' }),
    )

    // The request waits for the first answer of the tab's subscription.
    const subscription = await waitFor(() => {
      const handler = getTicketArticleTranslationUpdatesSubscriptionHandler()
      expect(handler.closed()).toBe(false)

      return handler
    })

    await subscription.trigger({
      ticketArticleTranslationUpdates: { article: null, translation: null, error: null },
    })

    expect(await within(article).findByText('Good day')).toBeVisible()
  }

  const reply = async (view: View, article: HTMLElement) => {
    await view.events.click(await within(article).findByRole('button', { name: 'Reply' }))

    const complementary = await view.findByRole('complementary', { name: 'Reply' })
    await getNode('form-ticket-edit-1')?.settled

    return complementary
  }

  // The test setup replaces the editor by a plain text area, so the hint is read where the editor
  //   takes it from. How the editor shows it is covered by the specs of its action bar.
  const editorNotice = () => getNode('form-ticket-edit-1')?.find('body', 'name')?.context?.notice

  it('hands the hint to the editor while the answered article is displayed translated', async () => {
    const { view, article } = await visitTicket()

    await translate(view, article)
    await reply(view, article)

    await waitFor(() => expect(editorNotice()).toEqual({ key: articleId, text: NOTICE }))
  })

  it('names the detected language of the answered article in the hint', async () => {
    const { view, article } = await visitTicket('de')

    await translate(view, article)
    await reply(view, article)

    await waitFor(() =>
      expect(editorNotice()).toEqual({
        key: articleId,
        text: NOTICE_WITH_LANGUAGE,
        textPlaceholder: ['German'],
      }),
    )
  })

  it('names no language in the hint for a detected language without a name', async () => {
    const { view, article } = await visitTicket('xx')

    await translate(view, article)
    await reply(view, article)

    await waitFor(() => expect(editorNotice()).toEqual({ key: articleId, text: NOTICE }))
  })

  it('hands the hint to the editor when forwarding the article', async () => {
    const { view, article } = await visitTicket()

    await translate(view, article)

    await view.events.click(
      await within(article).findByRole('button', { name: 'Action menu button' }),
    )
    await view.events.click(await view.findByRole('button', { name: 'Forward' }))

    await view.findByRole('complementary', { name: 'Reply' })

    await waitFor(() => expect(editorNotice()).toMatchObject({ text: NOTICE }))
  })

  it('removes the hint once the article shows its original again', async () => {
    const { view, article } = await visitTicket()

    await translate(view, article)
    await reply(view, article)

    await waitFor(() => expect(editorNotice()).toMatchObject({ text: NOTICE }))

    await view.events.click(within(article).getByRole('button', { name: 'Show original' }))

    await waitFor(() => expect(editorNotice()).toBeUndefined())
  })

  it('hands no hint to the editor for an article in its original language', async () => {
    const { view, article } = await visitTicket()

    await reply(view, article)

    expect(getNode('form-ticket-edit-1')?.find('answeredArticleId', 'name')?.value).toBe(articleId)
    expect(editorNotice()).toBeUndefined()
  })

  it('hands no hint to the editor for a note that answers no article, also after a discarded reply to a translated one', async () => {
    const { view, article } = await visitTicket()

    await translate(view, article)

    const complementary = await reply(view, article)

    await waitFor(() => expect(editorNotice()).toMatchObject({ text: NOTICE }))

    await view.events.click(
      within(complementary).getByRole('button', { name: 'Discard unsaved reply' }),
    )
    await view.events.click(
      within(await view.findByRole('dialog')).getByRole('button', { name: 'Discard changes' }),
    )

    await view.events.click(
      await within(view.getByRole('toolbar', { name: 'Ticket actions' })).findByRole('button', {
        name: 'Add internal note',
      }),
    )

    await view.findByRole('complementary', { name: 'Reply' })
    await getNode('form-ticket-edit-1')?.settled

    expect(getNode('form-ticket-edit-1')?.find('answeredArticleId', 'name')?.value).toBeFalsy()
    expect(editorNotice()).toBeUndefined()
  })

  it('forgets an answered article the form still knows when a note is added below the articles', async () => {
    const { view } = await visitTicket()

    await getNode('form-ticket-edit-1')?.settled

    // As after a reply that was closed without its values being reset.
    const answeredArticle = () => getNode('form-ticket-edit-1')?.find('answeredArticleId', 'name')
    await answeredArticle()?.input(articleId, false)

    await view.events.click(
      await within(view.getByRole('toolbar', { name: 'Ticket actions' })).findByRole('button', {
        name: 'Add internal note',
      }),
    )

    await view.findByRole('complementary', { name: 'Reply' })
    await getNode('form-ticket-edit-1')?.settled

    expect(answeredArticle()?.value).toBeNull()
  })

  it('submits nothing about the answered article', async () => {
    const { view, article } = await visitTicket()

    await translate(view, article)
    await reply(view, article)

    await waitFor(() => expect(editorNotice()).toMatchObject({ text: NOTICE }))

    await view.events.type(await view.findByRole('textbox', { name: 'Text' }), 'Foo email')
    await getNode('form-ticket-edit-1')?.settled

    await view.events.click(view.getByRole('button', { name: 'Update' }))

    const calls = await waitForTicketUpdateMutationCalls()
    const { article: submittedArticle } = calls.at(-1)?.variables.input ?? {}

    expect(submittedArticle).toMatchObject({ body: 'Foo email' })
    expect(submittedArticle).not.toHaveProperty('answeredArticleId')
  })
})
