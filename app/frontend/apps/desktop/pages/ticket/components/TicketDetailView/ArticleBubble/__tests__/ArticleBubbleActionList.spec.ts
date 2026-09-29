// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { createArticleTranslationMock } from '#shared/entities/ticket-article/__tests__/mocks/articleTranslation.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  mockTicketArticleTranslationTargetLocalesQuery,
  mockTicketArticleTranslationTargetLocalesQueryError,
  waitForTicketArticleTranslationTargetLocalesQueryCalls,
} from '#shared/entities/ticket-article/graphql/queries/ticketArticleTranslationTargetLocales.mocks.ts'
import { useArticleTranslationStore } from '#shared/entities/ticket-article/stores/articleTranslation.ts'
import { EnumTextDirection, EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import ArticleBubbleActionList from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleActionList.vue'

// The tab's translation state, as the bubble injects it.
let articleTranslation = createArticleTranslationMock()

beforeEach(() => {
  articleTranslation = createArticleTranslationMock()
})

const renderArticleBubbleActionList = (options?: {
  position?: 'left' | 'right'
  articleOverrides?: Parameters<typeof createDummyArticle>[0]
  provideOverrides?: Parameters<typeof provideTicketInformationMocks>[1]
  withGroupEmail?: boolean
  editable?: boolean
  ticketPolicy?: NonNullable<Parameters<typeof createDummyTicket>[0]>['defaultPolicy']
}) => {
  const {
    position = 'left',
    articleOverrides,
    provideOverrides,
    withGroupEmail = true,
    editable = true,
    ticketPolicy,
  } = options || {}

  return renderComponent(
    {
      components: {
        ArticleBubbleActionList,
      },
      setup() {
        const article = createDummyArticle({
          senderName: EnumTicketArticleSenderName.Agent,
          articleType: 'email',
          attachmentsWithoutInline: [
            {
              id: convertToGraphQLId('Store', 123),
              preferences: {
                'original-format': true,
              },
              internalId: 123,
              name: 'test.txt',
            },
          ],
          ...articleOverrides,
        })

        const ticket = createDummyTicket({
          defaultPolicy: ticketPolicy ?? {
            __typename: 'PolicyTicket',
            update: editable,
            agentReadAccess: true,
          },
          group: {
            emailAddress: withGroupEmail
              ? {
                  emailAddress: 'support@example.com',
                  name: 'Support',
                }
              : null,
          },
        })

        provideTicketInformationMocks(ticket, { articleTranslation, ...provideOverrides })

        return { position, article }
      },
      template: `<div class="relative"><ArticleBubbleActionList :position="position" :article="article"/> </div>`,
    },
    { router: true, store: true },
  )
}

describe('ArticleBubbleActionList', () => {
  it('shows top level actions without hover', () => {
    const wrapper = renderArticleBubbleActionList()

    expect(wrapper.getByTestId('top-level-article-action-container')).toBeVisible()
  })

  it('has reply action', async () => {
    const wrapper = renderArticleBubbleActionList()

    expect(wrapper.getByRole('button', { name: 'Follow up' })).toBeInTheDocument()
  })

  it('shows "Follow up" and not "Reply" for agent articles', () => {
    const wrapper = renderArticleBubbleActionList()

    expect(wrapper.getByRole('button', { name: 'Follow up' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Reply' })).not.toBeInTheDocument()
  })

  it('shows "Reply" and not "Follow up" for customer articles', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: { senderName: EnumTicketArticleSenderName.Customer },
    })

    expect(wrapper.getByRole('button', { name: 'Reply' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Follow up' })).not.toBeInTheDocument()
  })

  it('shows "Follow up to all" for agent articles with multiple recipients', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: {
        to: {
          raw: '',
          parsed: [
            { emailAddress: 'a@example.com', isSystemAddress: false },
            { emailAddress: 'b@example.com', isSystemAddress: false },
          ],
        },
      },
    })

    expect(wrapper.getByRole('button', { name: 'Follow up to all' })).toBeInTheDocument()
  })

  it('shows "Reply all" for customer articles with multiple recipients', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: {
        senderName: EnumTicketArticleSenderName.Customer,
        to: {
          raw: '',
          parsed: [
            { emailAddress: 'a@example.com', isSystemAddress: false },
            { emailAddress: 'b@example.com', isSystemAddress: false },
          ],
        },
      },
    })

    expect(wrapper.getByRole('button', { name: 'Reply all' })).toBeInTheDocument()
  })

  it('shows "Follow up" and not "Reply" for agent Facebook articles', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: {
        senderName: EnumTicketArticleSenderName.Agent,
        articleType: 'facebook feed comment',
      },
    })

    expect(wrapper.getByRole('button', { name: 'Follow up' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Reply' })).not.toBeInTheDocument()
  })

  it('shows "Reply" and not "Follow up" for customer Facebook articles', () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: {
        senderName: EnumTicketArticleSenderName.Customer,
        articleType: 'facebook feed comment',
      },
    })

    expect(wrapper.getByRole('button', { name: 'Reply' })).toBeInTheDocument()
    expect(wrapper.queryByRole('button', { name: 'Follow up' })).not.toBeInTheDocument()
  })

  it('shows all popover actions', async () => {
    const wrapper = renderArticleBubbleActionList()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Action menu button' }))

    const items = wrapper.getAllByRole('menuitem')
    expect(items.length).toBeGreaterThanOrEqual(3)
    expect(wrapper.getByRole('menuitem', { name: 'Forward' })).toBeInTheDocument()
    expect(wrapper.getByRole('menuitem', { name: 'Download original email' })).toBeInTheDocument()
    expect(wrapper.getByRole('menuitem', { name: 'Download raw email' })).toBeInTheDocument()
  })

  it('does not show reply all when single recipient', async () => {
    const wrapper = renderArticleBubbleActionList({})

    expect(wrapper.queryByRole('button', { name: 'Reply all' })).not.toBeInTheDocument()
  })

  it('shows two popover actions when original email unavailable', async () => {
    const wrapper = renderArticleBubbleActionList({
      articleOverrides: { attachmentsWithoutInline: [] },
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Action menu button' }))

    const items = wrapper.getAllByRole('menuitem')

    expect(items.length).toBeGreaterThanOrEqual(2)
    expect(wrapper.getByRole('menuitem', { name: 'Forward' })).toBeInTheDocument()
    expect(wrapper.getByRole('menuitem', { name: 'Download raw email' })).toBeInTheDocument()
    expect(
      wrapper.queryByRole('menuitem', { name: 'Download original email' }),
    ).not.toBeInTheDocument()
  })

  it('renders right-position actions with reversed order class', () => {
    const wrapper = renderArticleBubbleActionList({ position: 'right' })

    expect(wrapper.getByTestId('top-level-article-action-container')).toHaveClass('order-first')
  })

  it('keeps the read-only actions when the ticket is not editable', async () => {
    const wrapper = renderArticleBubbleActionList({
      editable: false,
      provideOverrides: { isTicketEditable: computed(() => false) },
    })

    expect(wrapper.queryByTestId('top-level-article-action-container')).not.toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Action menu button' }))

    expect(wrapper.getByRole('menuitem', { name: 'Copy article permalink' })).toBeInTheDocument()
    expect(wrapper.queryByRole('menuitem', { name: 'Set to internal' })).not.toBeInTheDocument()
  })

  describe('with article translation', () => {
    const enableTranslation = () => {
      mockApplicationConfig({
        content_translation_service: true,
        content_translation_ticket_article: true,
        locale_default: 'en-us',
      })

      mockTicketArticleTranslationTargetLocalesQuery({
        ticketArticleTranslationTargetLocales: [
          { locale: 'en-us', alias: 'en', name: 'English', dir: EnumTextDirection.Ltr },
        ],
      })

      const store = useArticleTranslationStore()

      // What the tab does on creation: asks the server whether it can translate.
      store.loadTargetLocales()

      return store
    }

    it('shows the translate control, and no menu entry', async () => {
      enableTranslation()

      const wrapper = renderArticleBubbleActionList({})

      const toggle = await wrapper.findByRole('button', { name: 'Translate article' })
      expect(toggle).toHaveAttribute('aria-pressed', 'false')

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Action menu button' }))

      expect(wrapper.queryByRole('menuitem', { name: /Translate/ })).not.toBeInTheDocument()
    })

    it('translates the article with the translate control', async () => {
      enableTranslation()

      const wrapper = renderArticleBubbleActionList({})

      await wrapper.events.click(await wrapper.findByRole('button', { name: 'Translate article' }))

      expect(articleTranslation.showTranslation).toHaveBeenCalledTimes(1)
    })

    // The article body names the running translation; the button only refuses it.
    it.each([
      ['on its way', { status: 'pending' } as const],
      [
        'regenerated for the shown one',
        { status: 'done', content: 'Hallo', translated: true, regenerating: true } as const,
      ],
    ])('is busy and refuses the press while a translation is %s', async (_, state) => {
      enableTranslation()
      articleTranslation.isTranslationActive = () => true
      articleTranslation.translationFor = () => state

      const wrapper = renderArticleBubbleActionList({})

      const toggle = await wrapper.findByRole('button', { name: 'Translate article' })

      expect(toggle).toHaveAttribute('aria-busy', 'true')
      expect(toggle).toHaveAttribute('aria-disabled', 'true')
      expect(toggle).toHaveAttribute('aria-pressed', 'false')
      expect(toggle).toHaveClass('text-[#8E9299]!')

      await wrapper.events.click(toggle)

      expect(articleTranslation.showOriginal).not.toHaveBeenCalled()
      expect(articleTranslation.showTranslation).not.toHaveBeenCalled()
    })

    it('keeps the translate control while the translation is shown, to switch back', async () => {
      enableTranslation()
      const active = ref(true)
      articleTranslation.isTranslationActive = () => active.value

      const wrapper = renderArticleBubbleActionList({})

      const toggle = await wrapper.findByRole('button', { name: 'Show original' })
      expect(toggle).toHaveAttribute('aria-pressed', 'true')

      await wrapper.events.click(toggle)
      expect(articleTranslation.showOriginal).toHaveBeenCalledTimes(1)

      active.value = false

      await waitFor(() =>
        expect(wrapper.getByRole('button', { name: 'Translate article' })).toHaveAttribute(
          'aria-pressed',
          'false',
        ),
      )
    })

    it('shows a failure, and puts it away on press', async () => {
      enableTranslation()
      articleTranslation.translationFor = () => ({ status: 'error', error: 'Provider down' })

      const wrapper = renderArticleBubbleActionList({})

      const toggle = await wrapper.findByRole('button', {
        name: 'Dismiss alert',
      })
      expect(toggle).toHaveAttribute('aria-pressed', 'false')
      expect(toggle).not.toHaveAttribute('aria-disabled')
      expect(toggle).toHaveClass('border-red-500!', 'text-red-500!')

      await wrapper.events.click(toggle)

      expect(articleTranslation.showOriginal).toHaveBeenCalledTimes(1)
      expect(articleTranslation.showTranslation).not.toHaveBeenCalled()
    })

    it('keeps the same button in every state', async () => {
      enableTranslation()
      const state = ref<ReturnType<typeof articleTranslation.translationFor>>()
      articleTranslation.translationFor = () => state.value
      articleTranslation.isTranslationActive = () =>
        state.value?.status === 'pending' || state.value?.status === 'done'

      const wrapper = renderArticleBubbleActionList({})
      const toggle = await wrapper.findByRole('button', { name: 'Translate article' })

      const expectState = async (next: typeof state.value, name: string) => {
        state.value = next
        await waitFor(() => expect(wrapper.getByRole('button', { name })).toBe(toggle))
        expect(toggle.querySelector('.icon-translate')).toBeInTheDocument()
      }

      await expectState({ status: 'pending' }, 'Translate article')
      await expectState({ status: 'done', content: 'Hallo', translated: true }, 'Show original')
      await expectState({ status: 'error', error: 'Provider down' }, 'Dismiss alert')
      await expectState(undefined, 'Translate article')
    })

    it('offers the translate control to read-only agents', async () => {
      enableTranslation()

      const wrapper = renderArticleBubbleActionList({
        editable: false,
        provideOverrides: { isTicketEditable: computed(() => false) },
      })

      expect(await wrapper.findByRole('button', { name: 'Translate article' })).toBeInTheDocument()
    })

    it('offers nothing to customers', async () => {
      const store = enableTranslation()

      const wrapper = renderArticleBubbleActionList({
        // A ticket the agent has no agent access to is shown in the customer view.
        ticketPolicy: { __typename: 'PolicyTicket', update: false, agentReadAccess: false },
        editable: false,
      })

      await waitFor(() => expect(store.isAvailable).toBe(true))

      expect(wrapper.queryByRole('button', { name: 'Translate article' })).not.toBeInTheDocument()
    })

    it('offers nothing while the service cannot translate', async () => {
      mockApplicationConfig({
        content_translation_service: true,
        content_translation_ticket_article: true,
      })
      mockTicketArticleTranslationTargetLocalesQueryError('AI provider is not configured.', {
        type: GraphQLErrorTypes.UnknownError,
      })
      useArticleTranslationStore().loadTargetLocales()

      const wrapper = renderArticleBubbleActionList({})

      await waitForTicketArticleTranslationTargetLocalesQueryCalls()

      expect(wrapper.queryByRole('button', { name: 'Translate article' })).not.toBeInTheDocument()
    })

    it('offers nothing while the feature is off', () => {
      mockApplicationConfig({
        content_translation_service: false,
        content_translation_ticket_article: false,
      })

      const wrapper = renderArticleBubbleActionList({})

      expect(wrapper.queryByRole('button', { name: 'Translate article' })).not.toBeInTheDocument()
    })
  })
})
