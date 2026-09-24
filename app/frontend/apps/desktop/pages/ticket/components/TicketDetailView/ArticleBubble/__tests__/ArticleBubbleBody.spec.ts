// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { defineComponent, nextTick, reactive, ref } from 'vue'

import { getGraphQLMockCalls } from '#tests/graphql/builders/mocks.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { createArticleTranslationMock } from '#shared/entities/ticket-article/__tests__/mocks/articleTranslation.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { ArticleTranslation } from '#shared/entities/ticket-article/stores/types.ts'
import { AiAnalyticsUsageDocument } from '#shared/graphql/mutations/aiAnalyticsUsage.api.ts'
import { waitForAiAnalyticsUsageMutationCalls } from '#shared/graphql/mutations/aiAnalyticsUsage.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { i18n } from '#shared/i18n.ts'

import { provideTicketInformationMocks } from '#desktop/entities/ticket/__tests__/mocks/provideTicketInformationMocks.ts'
import type { TicketInformation } from '#desktop/entities/ticket/types.ts'
import { TicketArticleHighlightedTextUpsertDocument } from '#desktop/entities/ticket-article/graphql/mutations/highlightedTextUpsert.api.ts'
import {
  mockTicketArticleHighlightedTextUpsertMutation,
  waitForTicketArticleHighlightedTextUpsertMutationCalls,
} from '#desktop/entities/ticket-article/graphql/mutations/highlightedTextUpsert.mocks.ts'
import ArticleBubbleBody from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleBody.vue'
import { items as highlightMenuItems } from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/composables/useHighlightMenuState.ts'

// The tab's translation state, as the bubble injects it.
let articleTranslation = createArticleTranslationMock()

beforeEach(() => {
  articleTranslation = createArticleTranslationMock()
})

const renderBody = (
  article: ReturnType<typeof createDummyArticle>,
  showMetaInformation: boolean,
  ticketInformation: Partial<TicketInformation> = {},
) => {
  return renderComponent(
    {
      components: { ArticleBubbleBody },

      setup: () => {
        const dummyTicket = createDummyTicket()

        provideTicketInformationMocks(dummyTicket, { articleTranslation, ...ticketInformation })

        return {
          article,
          showMetaInformation,
        }
      },
      template:
        '<ArticleBubbleBody :article="article" :showMetaInformation="showMetaInformation" position="left" :inlineImages="[]"/>',
    },
    {
      router: true,
      store: true,
      // CommonAIFeedback holds a FormKit comment field, which Vue resolves even while it is hidden.
      form: true,
    },
  )
}

describe('ArticleBubbleBody', () => {
  afterEach(() => {
    i18n.setTranslationMap(new Map())
  })

  it('displays html article body with meta information display active', async () => {
    const article = createDummyArticle({
      bodyWithUrls: 'test &amp; body',
      contentType: 'text/html',
    })

    const wrapper = renderBody(article, true)
    expect(await wrapper.findByText('test & body')).toBeInTheDocument()
    expect(await wrapper.queryByText(article.author.fullname!)).not.toBeInTheDocument()
  })

  it('displays text article body with meta information display inactive', async () => {
    const article = createDummyArticle({
      bodyWithUrls: 'test &amp; body',
      contentType: 'text/plain',
    })

    const wrapper = renderBody(article, false)
    expect(await wrapper.findByText('test &amp; body')).toBeInTheDocument()
    expect(await wrapper.queryByText(article.author.fullname!)).to.toBeInTheDocument()
  })

  it('does not display system message name on article body', async () => {
    const article = createDummyArticle({
      bodyWithUrls: 'test &amp; body',
      contentType: 'text/plain',
      internal: true,
      author: {
        id: convertToGraphQLId('User', 1), // System message user id
        fullname: '-',
        firstname: '-',
        lastname: '',
        email: '',
        active: false,
        image: null,
        vip: false,
        outOfOffice: false,
        outOfOfficeStartAt: null,
        outOfOfficeEndAt: null,
        authorizations: [],
      },
    })

    const wrapper = renderBody(article, false)

    expect(
      wrapper.queryByRole('group', {
        description: 'Author name and article creation date',
      }),
    ).not.toBeInTheDocument()
  })

  describe('bodyRenderingError', () => {
    const errorMsg =
      'This message cannot be displayed due to HTML processing issues. Download the raw message below and open it via an Email client if you still wish to view it.'

    it('displays the error message when bodyRenderingError is true', async () => {
      const article = createDummyArticle({
        bodyWithUrls: errorMsg,
        contentType: 'text/html',
        bodyRenderingError: true,
      })

      const wrapper = renderBody(article, false)
      expect(await wrapper.findByText(errorMsg)).toBeInTheDocument()
    })

    it('translates the error message according to the active locale', async () => {
      i18n.setTranslationMap(
        new Map([
          [
            errorMsg,
            'Diese Nachricht kann aufgrund von HTML-Verarbeitungsproblemen nicht angezeigt werden.',
          ],
        ]),
      )

      const article = createDummyArticle({
        bodyWithUrls: errorMsg,
        contentType: 'text/html',
        bodyRenderingError: true,
      })

      const wrapper = renderBody(article, false)
      expect(
        await wrapper.findByText(
          'Diese Nachricht kann aufgrund von HTML-Verarbeitungsproblemen nicht angezeigt werden.',
        ),
      ).toBeInTheDocument()
    })

    it('escapes HTML in the body instead of rendering it', () => {
      const article = createDummyArticle({
        bodyWithUrls: '<img src=x onerror="globalThis.__xss=1">',
        contentType: 'text/html',
        bodyRenderingError: true,
      })

      const wrapper = renderBody(article, false)
      const body = wrapper.container.querySelector('.inner-article-body')

      expect(body?.querySelector('img')).toBeNull()
      expect(body?.textContent).toContain('<img src=x onerror="globalThis.__xss=1">')
    })
  })

  describe('highlight a11y (aria-details)', () => {
    it('adds no aria-details when the article has no highlights', async () => {
      const article = createDummyArticle({
        bodyWithUrls: 'Hello world',
        contentType: 'text/html',
      })

      const wrapper = renderBody(article, false)
      await nextTick()

      expect(
        wrapper.getByTestId('article-content').querySelector('.inner-article-body'),
      ).not.toHaveAttribute('aria-details')
    })

    it('adds aria-details pointing to a hidden description when highlights are present', async () => {
      const article = {
        ...createDummyArticle({
          bodyWithUrls: 'Hello world',
          contentType: 'text/html',
        }),
        highlightedTexts: [
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 0,
            endIndex: 5,
            colorClass: 'highlight-yellow',
          },
        ],
      }

      const wrapper = renderBody(article, false)
      await nextTick()

      const articleBody = wrapper
        .getByTestId('article-content')
        .querySelector('.inner-article-body')!
      const descriptionId = articleBody.getAttribute('aria-details')

      expect(descriptionId).toBeTruthy()

      const descriptionEl = wrapper.container.querySelector(`#${descriptionId}`)
      expect(descriptionEl).toBeInTheDocument()
      expect(descriptionEl).toHaveClass('sr-only')
      expect(descriptionEl?.textContent?.trim()).toContain('Highlighted text')
      expect(descriptionEl?.textContent?.trim()).toContain('Yellow')
      expect(descriptionEl?.textContent?.trim()).toContain('"Hello"')
    })

    it('groups multiple highlights by color in the description', async () => {
      const article = {
        ...createDummyArticle({
          bodyWithUrls: 'Hello world foo',
          contentType: 'text/html',
        }),
        highlightedTexts: [
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 0,
            endIndex: 5,
            colorClass: 'highlight-yellow',
          },
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 6,
            endIndex: 11,
            colorClass: 'highlight-green',
          },
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 12,
            endIndex: 15,
            colorClass: 'highlight-yellow',
          },
        ],
      }

      const wrapper = renderBody(article, false)
      await nextTick()

      const articleBody = wrapper
        .getByTestId('article-content')
        .querySelector('.inner-article-body')!
      const descriptionId = articleBody.getAttribute('aria-details')!
      const descriptionEl = wrapper.container.querySelector(`#${descriptionId}`)!
      const text = descriptionEl.textContent?.trim() ?? ''

      expect(text).toContain('Yellow')
      expect(text).toContain('"Hello"')
      expect(text).toContain('"foo"')
      expect(text).toContain('Green')
      expect(text).toContain('"world"')
    })

    it('removes aria-details and description when all highlights are cleared', async () => {
      const baseArticle = createDummyArticle({
        bodyWithUrls: 'Hello world',
        contentType: 'text/html',
      })

      const article = {
        ...baseArticle,
        highlightedTexts: [
          {
            __typename: 'TicketArticleHighlightedText' as const,
            startIndex: 0,
            endIndex: 5,
            colorClass: 'highlight-yellow',
          },
        ],
      }

      const wrapper = renderBody(article, false)
      await nextTick()

      // Confirm description is present initially.
      const articleBody = wrapper
        .getByTestId('article-content')
        .querySelector('.inner-article-body')!
      expect(articleBody).toHaveAttribute('aria-details')

      // Clear highlights by re-rendering with null.
      await wrapper.rerender({ article: { ...baseArticle, highlightedTexts: null } })
      await nextTick()

      expect(articleBody).not.toHaveAttribute('aria-details')
      expect(
        wrapper.container.querySelector('[id^="article-highlight-description-"]'),
      ).not.toBeInTheDocument()
    })
  })

  describe('with a translation', () => {
    const mockTranslation = (translation?: ArticleTranslation) => {
      articleTranslation.translationFor = () => translation
    }

    it('shows the translated HTML instead of the original, with the AI attribution', async () => {
      mockTranslation({
        status: 'done',
        content: '<p>Hallo <strong>Welt</strong></p>',
        backend: 'ai',
        translated: true,
      })

      const article = createDummyArticle({
        bodyWithUrls: '<p>Hello <strong>world</strong></p>',
        contentType: 'text/html',
      })

      const wrapper = renderBody(article, false)

      expect(await wrapper.findByText('Welt')).toBeInTheDocument()
      expect(wrapper.queryByText('world')).not.toBeInTheDocument()
      expect(wrapper.getByTestId('article-translation-attribution')).toHaveTextContent(
        'Translated by AI, some formatting may be lost.',
      )
    })

    it('renders a plain text translation as text and names any other producer', async () => {
      mockTranslation({
        status: 'done',
        content: 'Hallo <Welt>',
        backend: 'deepl',
        translated: true,
      })

      const article = createDummyArticle({
        bodyWithUrls: 'Hello <world>',
        contentType: 'text/plain',
      })

      const wrapper = renderBody(article, false)

      expect(await wrapper.findByText('Hallo <Welt>')).toBeInTheDocument()
      expect(wrapper.getByTestId('article-translation-attribution')).toHaveTextContent(
        'Machine-translated, some formatting may be lost.',
      )
    })

    // The waiting is shown on the translate button, not in place of the article.
    it('keeps the original body while translating', async () => {
      mockTranslation({ status: 'pending' })

      const wrapper = renderBody(
        createDummyArticle({ bodyWithUrls: 'Hello', contentType: 'text/plain' }),
        false,
      )

      expect(await wrapper.findByText('Hello')).toBeInTheDocument()
      expect(wrapper.getByTestId('article-content')).toBeVisible()
    })

    it('swaps between original and translation as the state changes', async () => {
      const translation = ref<ArticleTranslation | undefined>(undefined)
      articleTranslation.translationFor = () => translation.value

      const article = createDummyArticle({ bodyWithUrls: 'Hello', contentType: 'text/plain' })

      const wrapper = renderBody(article, false)

      expect(wrapper.getByText('Hello')).toBeInTheDocument()

      translation.value = { status: 'done', content: 'Hallo', backend: 'ai', translated: true }

      expect(await wrapper.findByText('Hallo')).toBeInTheDocument()
      expect(wrapper.queryByText('Hello')).not.toBeInTheDocument()

      translation.value = undefined

      expect(await wrapper.findByText('Hello')).toBeInTheDocument()
      expect(wrapper.queryByTestId('article-translation-attribution')).not.toBeInTheDocument()
    })

    it('keeps the original when the translation failed', async () => {
      const translation = ref<ArticleTranslation | undefined>({ status: 'pending' })
      articleTranslation.translationFor = () => translation.value

      const article = createDummyArticle({ bodyWithUrls: 'Hello', contentType: 'text/plain' })

      const wrapper = renderBody(article, false)

      expect(await wrapper.findByText('Hello')).toBeInTheDocument()

      translation.value = { status: 'error', error: 'Provider down' }
      await nextTick()

      expect(wrapper.getByTestId('article-content')).toBeVisible()
      expect(wrapper.getByText('Hello')).toBeInTheDocument()
      expect(wrapper.queryByTestId('article-translation-attribution')).not.toBeInTheDocument()
    })

    it('shows the original when the original is asked for', () => {
      mockTranslation(undefined)

      const article = createDummyArticle({ bodyWithUrls: 'Hello', contentType: 'text/plain' })

      const wrapper = renderBody(article, false)

      expect(wrapper.getByText('Hello')).toBeInTheDocument()
      expect(wrapper.queryByTestId('article-translation-attribution')).not.toBeInTheDocument()
    })

    // Highlights are offsets into the original text; measured in a translation they would land
    // anywhere in the original, and replace what was highlighted there.
    it('warns instead of saving a highlight while the translation is shown', async () => {
      const translation = ref<ArticleTranslation | undefined>({
        status: 'done',
        content: '<p>Hallo Welt</p>',
        backend: 'ai',
        translated: true,
      })
      articleTranslation.translationFor = () => translation.value
      mockTicketArticleHighlightedTextUpsertMutation({
        ticketArticleHighlightedTextUpsert: { success: true, errors: null },
      })

      const article = createDummyArticle({
        bodyWithUrls: '<p>Hello world</p>',
        contentType: 'text/html',
      })

      const wrapper = renderBody(article, false, {
        highlightMenu: reactive({
          activeMenuItem: highlightMenuItems[0],
          isActive: true,
          isEraserActive: false,
        }),
      })

      const selectFirstWord = () => {
        const text = wrapper.getByTestId('article-content').querySelector('p')!.firstChild!
        const range = document.createRange()
        range.setStart(text, 0)
        range.setEnd(text, 5)
        const selection = window.getSelection()!
        selection.removeAllRanges()
        selection.addRange(range)
        document.dispatchEvent(new Event('pointerup'))
      }

      expect(await wrapper.findByText('Hallo Welt')).toBeInTheDocument()
      selectFirstWord()
      await waitForNextTick(true)

      expect(getGraphQLMockCalls(TicketArticleHighlightedTextUpsertDocument)).toHaveLength(0)

      const { notifications } = useNotifications()

      expect(notifications.value.at(-1)).toMatchObject({
        type: 'warn',
        message: 'Switch back to the original article to use highlighting.',
      })

      // The same gesture on the original is saved, so the guard is what kept the translation out.
      translation.value = undefined
      expect(await wrapper.findByText('Hello world')).toBeInTheDocument()
      selectFirstWord()

      const calls = await waitForTicketArticleHighlightedTextUpsertMutationCalls()
      expect(calls[0].variables).toMatchObject({
        articleId: article.id,
        highlight: [{ startIndex: 0, endIndex: 5 }],
      })
    })

    // A swapped body brings its own height, so it is measured again - a translation long enough
    // to be collapsed gets its own "See more".
    it('measures the translated body that replaced the original', async () => {
      vi.spyOn(Element.prototype, 'scrollHeight', 'get').mockReturnValue(800)

      const translation = ref<ArticleTranslation | undefined>(undefined)
      articleTranslation.translationFor = () => translation.value

      const article = createDummyArticle({ bodyWithUrls: 'Hello', contentType: 'text/plain' })
      const wrapper = renderBody(article, false)

      translation.value = { status: 'done', content: 'Hallo', backend: 'ai', translated: true }

      expect(await wrapper.findByText('Hallo')).toBeInTheDocument()
      expect(wrapper.getByTestId('article-content')).toBeVisible()
      expect(await wrapper.findByRole('button', { name: 'See more' })).toBeInTheDocument()
    })
    // A hidden tab is detached from the document, where nothing has a height.
    it('measures a translation that arrived while the tab was hidden once it is shown again', async () => {
      // The browser's measurements: a long text, nothing while detached.
      vi.spyOn(Element.prototype, 'scrollHeight', 'get').mockImplementation(function (
        this: Element,
      ) {
        return this.isConnected ? 800 : 0
      })

      const translation = ref<ArticleTranslation | undefined>(undefined)
      articleTranslation.translationFor = () => translation.value

      const article = createDummyArticle({ bodyWithUrls: 'Hello', contentType: 'text/plain' })
      const shown = ref(true)

      const wrapper = renderComponent(
        {
          components: { ArticleBubbleBody },
          setup: () => {
            provideTicketInformationMocks(createDummyTicket(), { articleTranslation })

            return { article, shown }
          },
          template:
            '<KeepAlive><ArticleBubbleBody v-if="shown" :article="article" :showMetaInformation="false" position="left" :inlineImages="[]" /></KeepAlive>',
        },
        { router: true, store: true },
      )

      expect(await wrapper.findByRole('button', { name: 'See more' })).toBeInTheDocument()

      shown.value = false
      await nextTick()

      translation.value = { status: 'done', content: 'Hallo', backend: 'ai', translated: true }
      // Long enough for a measurement to run while detached: images, then an animation frame.
      await new Promise((resolve) => {
        setTimeout(resolve, 50)
      })

      shown.value = true

      expect(await wrapper.findByText('Hallo')).toBeInTheDocument()
      expect(await wrapper.findByRole('button', { name: 'See more' })).toBeInTheDocument()
    })
    // The same for an article that arrives while the tab is hidden: its bubble mounts detached.
    it('measures an article that arrived while the tab was hidden once it is shown again', async () => {
      vi.spyOn(Element.prototype, 'scrollHeight', 'get').mockImplementation(function (
        this: Element,
      ) {
        return this.isConnected ? 800 : 0
      })

      const articles = ref([
        createDummyArticle({ bodyWithUrls: 'Hello', contentType: 'text/plain' }),
      ])
      const shown = ref(true)

      // KeepAlive keeps a component alive, so the list is one.
      const Tab = defineComponent({
        components: { ArticleBubbleBody },
        setup: () => ({ articles }),
        template: `<div>
          <ArticleBubbleBody v-for="article in articles" :key="article.id" :article="article" :showMetaInformation="false" position="left" :inlineImages="[]" />
        </div>`,
      })

      const wrapper = renderComponent(
        {
          components: { Tab },
          setup: () => {
            provideTicketInformationMocks(createDummyTicket(), { articleTranslation })

            return { shown }
          },
          template: '<KeepAlive><Tab v-if="shown" /></KeepAlive>',
        },
        { router: true, store: true },
      )

      expect(await wrapper.findAllByRole('button', { name: 'See more' })).toHaveLength(1)

      shown.value = false
      await nextTick()

      articles.value = [
        ...articles.value,
        createDummyArticle({
          articleId: 2,
          bodyWithUrls: 'Later',
          contentType: 'text/plain',
        }),
      ]
      await new Promise((resolve) => {
        setTimeout(resolve, 50)
      })

      shown.value = true

      expect(await wrapper.findByText('Later')).toBeInTheDocument()
      await waitFor(() =>
        expect(wrapper.getAllByRole('button', { name: 'See more' })).toHaveLength(2),
      )
    })

    // A rating attaches to the analytics run behind the translation, whichever service produced it;
    // a translation stored before runs were recorded leaves nothing to attach it to.
    describe('feedback', () => {
      const runId = convertToGraphQLId('AIAnalyticsRun', 1)

      const rateable = (
        userHasProvidedFeedback = false,
        backend = 'ai',
        regenerating = false,
      ): ArticleTranslation => ({
        status: 'done',
        content: 'Hallo',
        backend,
        translated: true,
        analytics: { run: { id: runId }, usage: { userHasProvidedFeedback } },
        regenerating,
      })

      const translatedArticle = () =>
        createDummyArticle({ bodyWithUrls: 'Hello', contentType: 'text/plain' })

      // Like the composable: the rating lands on the stored translation, and showing the original
      // only hides that entry.
      const mockRateableTranslation = () => {
        const rated = ref(false)
        const shown = ref(true)

        articleTranslation.translationFor = () => (shown.value ? rateable(rated.value) : undefined)
        articleTranslation.markTranslationRated = vi.fn(() => {
          rated.value = true
        })

        return shown
      }

      it('offers a rating for a translation that carries a run', async () => {
        mockTranslation(rateable())

        const wrapper = renderBody(translatedArticle(), false)

        expect(await wrapper.findByLabelText('Positive feedback')).toBeInTheDocument()
        expect(wrapper.getByLabelText('Negative feedback')).toBeInTheDocument()
      })

      it('offers a rating for a machine translation that carries a run, without the AI styling', async () => {
        mockTranslation(rateable(false, 'deepl'))

        const wrapper = renderBody(translatedArticle(), false)

        expect(await wrapper.findByLabelText('Positive feedback')).toBeInTheDocument()
        expect(wrapper.getByLabelText('Negative feedback')).toBeInTheDocument()
        expect(wrapper.getByLabelText('Regenerate')).not.toHaveClass('ai-stripe')
      })

      it('shows the AI styling on the regeneration of an AI translation', async () => {
        mockTranslation(rateable())

        const wrapper = renderBody(translatedArticle(), false)

        expect(await wrapper.findByLabelText('Regenerate')).toHaveClass('ai-stripe')
      })

      it('offers no rating for a translation without a run', async () => {
        mockTranslation({
          status: 'done',
          content: 'Hallo',
          backend: 'libretranslate',
          translated: true,
        })

        const wrapper = renderBody(translatedArticle(), false)

        expect(await wrapper.findByText('Hallo')).toBeInTheDocument()
        expect(wrapper.queryByLabelText('Positive feedback')).not.toBeInTheDocument()
      })

      it('offers no rating while the original is shown', async () => {
        mockTranslation(undefined)

        const wrapper = renderBody(translatedArticle(), false)

        expect(await wrapper.findByText('Hello')).toBeInTheDocument()
        expect(wrapper.queryByLabelText('Positive feedback')).not.toBeInTheDocument()
      })

      it('spans the toolbar only while the comment field is open', async () => {
        mockRateableTranslation()

        const wrapper = renderBody(translatedArticle(), false)

        const feedback = await wrapper.findByTestId('article-translation-feedback')
        expect(feedback).not.toHaveClass('w-full')

        await wrapper.events.click(wrapper.getByLabelText('Negative feedback'))

        await waitFor(() => expect(feedback).toHaveClass('w-full'))

        await wrapper.events.click(wrapper.getByRole('button', { name: 'No comment' }))

        await waitFor(() => expect(feedback).not.toHaveClass('w-full'))
      })

      it('regenerates the translation on request', async () => {
        mockTranslation(rateable())

        const article = translatedArticle()
        const wrapper = renderBody(article, false)

        await wrapper.events.click(await wrapper.findByLabelText('Regenerate'))

        expect(articleTranslation.regenerateTranslation).toHaveBeenCalledWith(article.id)
      })

      it('keeps the translation and refuses another regeneration while one is on its way', async () => {
        mockTranslation(rateable(false, 'ai', true))

        const wrapper = renderBody(translatedArticle(), false)

        const regenerate = await wrapper.findByLabelText('Regenerate')
        expect(regenerate).toHaveAttribute('aria-disabled', 'true')
        expect(regenerate).toHaveAttribute('aria-busy', 'true')
        expect(wrapper.getByTestId('article-translation-attribution')).toBeInTheDocument()
      })

      it('offers no regeneration for a translation without a run', async () => {
        mockTranslation({
          status: 'done',
          content: 'Hallo',
          backend: 'libretranslate',
          translated: true,
        })

        const wrapper = renderBody(translatedArticle(), false)

        expect(await wrapper.findByText('Hallo')).toBeInTheDocument()
        expect(wrapper.queryByLabelText('Regenerate')).not.toBeInTheDocument()
      })

      // One control per article: recording every displayed translation on render would mean one
      // mutation per translated article of the ticket.
      it('records nothing before the agent rates', async () => {
        mockTranslation(rateable())

        const wrapper = renderBody(translatedArticle(), false)

        expect(await wrapper.findByLabelText('Positive feedback')).toBeInTheDocument()
        await waitForNextTick(true)

        expect(getGraphQLMockCalls(AiAnalyticsUsageDocument)).toHaveLength(0)
      })

      it('records the rating against the run and stops asking', async () => {
        mockRateableTranslation()

        const article = translatedArticle()
        const wrapper = renderBody(article, false)

        await wrapper.events.click(await wrapper.findByLabelText('Positive feedback'))

        const calls = await waitForAiAnalyticsUsageMutationCalls()
        expect(calls.at(-1)?.variables).toEqual({
          aiAnalyticsRunId: runId,
          input: { rating: true },
        })

        expect(articleTranslation.markTranslationRated).toHaveBeenCalledWith(article.id)

        expect(wrapper.queryByLabelText('Positive feedback')).not.toBeInTheDocument()
      })

      // The control unmounts with the translation, so a rating kept on it alone would be lost.
      it('offers no rating again after the original was shown in between', async () => {
        const shown = mockRateableTranslation()

        const wrapper = renderBody(translatedArticle(), false)

        await wrapper.events.click(await wrapper.findByLabelText('Positive feedback'))
        await waitForAiAnalyticsUsageMutationCalls()

        shown.value = false
        await waitForNextTick(true)

        shown.value = true
        await waitForNextTick(true)

        expect(await wrapper.findByText('Hallo')).toBeInTheDocument()
        expect(wrapper.queryByLabelText('Positive feedback')).not.toBeInTheDocument()
      })

      // A rating is final, so a translation rated in an earlier visit offers no control again.
      it('offers no rating for a translation the agent already rated', async () => {
        mockTranslation(rateable(true))

        const wrapper = renderBody(translatedArticle(), false)

        expect(await wrapper.findByText('Hallo')).toBeInTheDocument()
        expect(wrapper.queryByLabelText('Positive feedback')).not.toBeInTheDocument()
      })
    })
  })
})
