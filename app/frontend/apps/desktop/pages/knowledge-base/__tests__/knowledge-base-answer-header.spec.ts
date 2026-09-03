// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import type { KnowledgeBaseAnswerQuery } from '#shared/graphql/types.ts'
import { convertToGraphQLId, getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import { mockKnowledgeBaseQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBase.mocks.ts'
import { mockKnowledgeBaseAnswerQuery } from '#desktop/entities/knowledge-base/graphql/queries/knowledgeBaseAnswer.mocks.ts'

const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 5)
const PREVIOUS_ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 4)
const NEXT_ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 6)
const ROOT_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

const ANSWER_PATH = `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(ANSWER_ID)}`

type Answer = NonNullable<KnowledgeBaseAnswerQuery['knowledgeBaseAnswer']>

type AnswerOverrides = Omit<Partial<Answer>, 'translation'> & {
  translation?: Partial<NonNullable<Answer['translation']>> | null
}

const mockAnswer = ({ translation, ...overrides }: AnswerOverrides = {}) =>
  mockKnowledgeBaseAnswerQuery({
    knowledgeBaseAnswer: {
      id: ANSWER_ID,
      visibility: EnumKnowledgeBaseVisibility.Published,
      internalAt: null,
      publishedAt: '2026-08-01T10:00:00Z',
      archivedAt: null,
      // Spread apart from the rest, so an example states only the part of the translation it is
      //   about - the locale it belongs to, say, which is what the header warns about.
      translation:
        translation === null
          ? null
          : {
              id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
              title: 'Some Knowledge Base Answer',
              editedAt: '2026-08-03T10:00:00Z',
              editedBy: {
                id: convertToGraphQLId('User', 3),
                firstname: 'Erika',
                lastname: 'Mustermann',
                fullname: 'Erika Mustermann',
                organization: null,
              },
              navigation: {
                __typename: 'KnowledgeBaseAnswerNavigation',
                index: 2,
                totalCount: 3,
                previousAnswer: {
                  __typename: 'KnowledgeBaseAnswer',
                  id: PREVIOUS_ANSWER_ID,
                  translation: {
                    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 4),
                    title: 'Previous Knowledge Base Answer',
                  },
                },
                nextAnswer: {
                  __typename: 'KnowledgeBaseAnswer',
                  id: NEXT_ANSWER_ID,
                  translation: {
                    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 6),
                    title: 'Next Knowledge Base Answer',
                  },
                },
              },
              ...translation,
            },
      category: {
        id: CHILD_CATEGORY_ID,
        breadcrumb: [
          {
            id: ROOT_CATEGORY_ID,
            translation: { title: 'Root Category' },
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
          },
          {
            id: CHILD_CATEGORY_ID,
            translation: { title: 'Child Category' },
            categoryIcon: 'folder',
            visibility: EnumKnowledgeBaseVisibility.Published,
          },
        ],
      },
      ...overrides,
    },
  } as KnowledgeBaseAnswerQuery)

// `showFeedIcon` is pinned rather than left to the automocker: it decides whether the header's
//   action menu has an entry besides the edit one, and an auto-generated boolean differs between
//   an isolated and a whole-file run - which made a test about that menu pass or fail by luck.
const mockKnowledgeBase = (showFeedIcon = false) =>
  mockKnowledgeBaseQuery({
    knowledgeBase: {
      id: convertToGraphQLId('KnowledgeBase', 1),
      translation: { title: 'My Knowledge Base' },
      iconset: 'default',
      isPubliclyAvailable: true,
      isVisiblePublicly: true,
      showFeedIcon,
      kbLocales: [
        {
          id: convertToGraphQLId('KnowledgeBase::Locale', 1),
          primary: true,
          systemLocale: { id: '1', locale: 'en-us', name: 'English (United States)' },
        },
        {
          id: convertToGraphQLId('KnowledgeBase::Locale', 2),
          primary: false,
          systemLocale: { id: '2', locale: 'de-de', name: 'Deutsch' },
        },
      ],
      currentLocale: {
        id: convertToGraphQLId('KnowledgeBase::Locale', 1),
        systemLocale: { id: '1', locale: 'en-us' },
      },
    },
  })

describe('knowledge base answer header', () => {
  beforeEach(() => {
    mockApplicationConfig({ kb_active_publicly: true })
    mockPermissions(['knowledge_base.reader'])

    mockKnowledgeBase()

    mockAnswer()
  })

  it('shows the full category path and the answer as the opened node', async () => {
    const view = await visitView(ANSWER_PATH)

    const breadcrumb = (
      await view.findAllByRole('navigation', { name: 'Knowledge base navigation' })
    ).at(-1)!

    // Each link carries its category icon, which contributes to the accessible name.
    expect(within(breadcrumb).getByRole('link', { name: /Root Category/ })).toBeInTheDocument()
    expect(within(breadcrumb).getByRole('link', { name: /Child Category/ })).toBeInTheDocument()
    expect(
      within(breadcrumb).getByRole('heading', { name: 'Some Knowledge Base Answer' }),
      'the opened answer is the page heading',
    ).toBeInTheDocument()
  })

  it('shows the answer title, its publication state and its edit metadata', async () => {
    const view = await visitView(ANSWER_PATH)

    expect(await view.findAllByText('Published')).not.toHaveLength(0)
    expect(view.getByText(/edited .* by Erika Mustermann/)).toBeInTheDocument()
  })

  it('links the search button to the knowledge base root of the browsed locale, focusing its search field', async () => {
    const view = await visitView(ANSWER_PATH)

    // Once per header variant (full and compact).
    const links = await view.findAllByRole('link', { name: 'Search the knowledge base' })

    expect(links.length).toBeGreaterThan(0)
    links.forEach((link) => {
      expect(link).toHaveAttribute('href', '/desktop/knowledge-base/locale/en-us?focus=search')
    })
  })

  // The way into the edit view - without it the view is only reachable by typing a URL.
  describe('the edit action', () => {
    // Per record, never on the global `knowledge_base.editor` permission: a granular setup can make
    //   the same user editor of one subtree and reader of the next, so the global permission would
    //   offer a button the mutation then refuses.
    it('is offered to a user who may update the answer', async () => {
      mockAnswer({ policy: { __typename: 'PolicyDefault', update: true, destroy: true } })

      const view = await visitView(ANSWER_PATH)

      expect((await view.findAllByRole('button', { name: 'Edit answer' }))[1]).toBeInTheDocument()
    })

    it('is not offered to a user who may only read it', async () => {
      mockPermissions(['knowledge_base.editor'])
      mockAnswer({ policy: { __typename: 'PolicyDefault', update: false, destroy: false } })

      const view = await visitView(ANSWER_PATH)

      // Awaited through something else the header renders, so the absence is asserted on a
      //   settled view rather than on one that has not got there yet.
      await view.findAllByText('Published')

      expect(view.queryByRole('button', { name: 'Edit answer' })).not.toBeInTheDocument()
    })

    // Editing continues in the locale being read: the edit route carries one, and its taskbar tab
    //   is per answer *and* locale.
    it('opens the edit view for the locale being read', async () => {
      mockAnswer({ policy: { __typename: 'PolicyDefault', update: true, destroy: true } })

      const view = await visitView(ANSWER_PATH)

      await view.events.click((await view.findAllByRole('button', { name: 'Edit answer' }))[0])

      const router = getTestRouter()

      await waitFor(() => {
        expect(router.currentRoute.value.name).toBe('KnowledgeBaseAnswerEdit')
      })

      expect(router.currentRoute.value.params).toMatchObject({
        localeCode: 'en-us',
        answerInternalId: String(getIdFromGraphQLId(ANSWER_ID)),
      })
    })
  })

  it('links the public knowledge base button to the answer preview endpoint', async () => {
    const view = await visitView(ANSWER_PATH)

    const links = await view.findAllByRole('link', { name: 'View public knowledge base' })

    expect(links.length).toBeGreaterThan(0)
    links.forEach((link) => {
      expect(link).toHaveAttribute(
        'href',
        `/api/v1/knowledge_bases/preview/KnowledgeBaseAnswer/${getIdFromGraphQLId(ANSWER_ID)}/en-us`,
      )
    })
  })

  it('hides the public knowledge base button for an unpublished answer without editor permission', async () => {
    mockAnswer({
      visibility: EnumKnowledgeBaseVisibility.Internal,
      publishedAt: null,
      internalAt: '2026-08-01T10:00:00Z',
    })

    const view = await visitView(ANSWER_PATH)

    // The header rendered, so the button is hidden by visibility, not by an empty page.
    expect(await view.findAllByText('Internal')).not.toHaveLength(0)
    expect(view.queryByRole('link', { name: 'View public knowledge base' })).not.toBeInTheDocument()
  })

  it('stays on the answer when switching language', async () => {
    const view = await visitView(ANSWER_PATH)

    // Both the full and the (scrolled) compact header carry a language selector;
    //   at the top only the full header is active, so target the last one.
    const languageButtons = await view.findAllByRole('button', { name: 'Change language' })
    await view.events.click(languageButtons.at(-1) as HTMLElement)

    await view.events.click(await view.findByText('Deutsch'))

    await waitFor(() => {
      expect(view, 'stayed on the answer in the selected locale').toHaveCurrentUrl(
        `/knowledge-base/locale/de-de/answer/${getIdFromGraphQLId(ANSWER_ID)}`,
      )
    })
  })

  // Reading the same answer in two locales and coming back: the answer is one record, and a client
  //   caching by object identity would hold one translation for both locales unless the field
  //   carries the locale it was asked for (Gql::Types::KnowledgeBase::AnswerType#translation). The
  //   way back is what shows it - the second locale looks right either way, it is the return that
  //   reads the other's title.
  it('keeps each locale reading its own title', async () => {
    mockKnowledgeBaseAnswerQuery(({ locale }) => {
      const german = locale === 'de-de'

      return {
        knowledgeBaseAnswer: {
          id: ANSWER_ID,
          translation: {
            id: convertToGraphQLId('KnowledgeBase::Answer::Translation', german ? 2 : 1),
            title: german ? 'Titel auf Deutsch' : 'Some Knowledge Base Answer',
            navigation: null,
            kbLocale: {
              __typename: 'KnowledgeBaseLocale' as const,
              id: convertToGraphQLId('KnowledgeBase::Locale', german ? 2 : 1),
              systemLocale: { __typename: 'Locale' as const, locale: locale ?? 'en-us' },
            },
          },
          category: {
            id: ROOT_CATEGORY_ID,
            breadcrumb: [{ id: ROOT_CATEGORY_ID, translation: { title: 'Root Category' } }],
          },
        },
      }
    })

    const view = await visitView(ANSWER_PATH)

    expect(
      await view.findAllByRole('heading', { name: 'Some Knowledge Base Answer' }),
    ).not.toHaveLength(0)

    const router = getTestRouter()

    await router.push(`/knowledge-base/locale/de-de/answer/${getIdFromGraphQLId(ANSWER_ID)}`)

    expect(await view.findAllByRole('heading', { name: 'Titel auf Deutsch' })).not.toHaveLength(0)

    await router.push(ANSWER_PATH)

    await waitFor(() => {
      expect(
        view.getAllByRole('heading', { name: 'Some Knowledge Base Answer' }),
        'back in the first locale, with its own title',
      ).not.toHaveLength(0)
    })
  })

  it('navigates to the next answer in the route locale', async () => {
    const view = await visitView(ANSWER_PATH)

    const nextLinks = await view.findAllByRole('link', {
      name: 'Next answer: Next Knowledge Base Answer',
    })
    await view.events.click(nextLinks.at(-1) as HTMLElement)

    await waitFor(() => {
      expect(view).toHaveCurrentUrl(
        `/knowledge-base/locale/en-us/answer/${getIdFromGraphQLId(NEXT_ANSWER_ID)}`,
      )
    })
  })

  it('warns when the answer has no translation in the browsed locale', async () => {
    mockAnswer({
      translation: {
        id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 2),
        kbLocale: {
          __typename: 'KnowledgeBaseLocale' as const,
          id: convertToGraphQLId('KnowledgeBase::Locale', 2),
          systemLocale: { __typename: 'Locale', locale: 'de-de' },
        },
      },
    })

    const view = await visitView(ANSWER_PATH)

    // One alert per header, so the warning survives the scroll swap.
    await waitFor(() => {
      expect(view.getAllByText('No translation available for this locale')).toHaveLength(2)
    })
  })

  it('does not warn about a missing translation for a translated answer', async () => {
    const view = await visitView(ANSWER_PATH)

    // Both headers are mounted, so the answer title appears more than once.
    expect(await view.findAllByText('Some Knowledge Base Answer')).not.toHaveLength(0)
    expect(view.queryAllByText('No translation available for this locale')).toHaveLength(0)
  })
})
