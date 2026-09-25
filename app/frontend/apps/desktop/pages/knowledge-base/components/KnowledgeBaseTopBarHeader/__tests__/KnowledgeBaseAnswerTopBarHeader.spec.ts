// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { within } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseAnswerTopBarHeader from '../KnowledgeBaseAnswerTopBarHeader.vue'

import type { KnowledgeBaseAnswerCachedHeader, KnowledgeBaseAnswerHeader } from '../../../types.ts'

const ANSWER_ID = convertToGraphQLId('KnowledgeBase::Answer', 5)
const ROOT_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 1)
const CHILD_CATEGORY_ID = convertToGraphQLId('KnowledgeBase::Category', 2)

const routerRoutes = [
  { name: 'Dashboard', path: '/', component: { template: '<div />' } },
  {
    name: 'KnowledgeBaseBrowse',
    path: '/knowledge-base/locale/:localeCode?',
    component: { template: '<div />' },
  },
  {
    name: 'KnowledgeBaseCategory',
    path: '/knowledge-base/locale/:localeCode/category/:categoryInternalId(\\d+)',
    component: { template: '<div />' },
  },
  {
    name: 'KnowledgeBaseAnswer',
    path: '/knowledge-base/locale/:localeCode/answer/:answerInternalId(\\d+)',
    component: { template: '<div />' },
  },
  // The public preview link points at a REST endpoint outside the app. `CommonLink` resolves
  //   every href against the router all the same, so without something to match it the real
  //   app's catch-all stands in for, it warns once per rendered header.
  { name: 'CatchAll', path: '/:pathMatch(.*)*', component: { template: '<div />' } },
]

const breadcrumb = [
  {
    id: ROOT_CATEGORY_ID,
    translation: {
      id: convertToGraphQLId('KnowledgeBase::Category::Translation', 1),
      title: 'Root Category',
    },
    categoryIcon: 'folder',
    iconSet: 'FontAwesome',
    visibility: EnumKnowledgeBaseVisibility.Published,
  },
  {
    id: CHILD_CATEGORY_ID,
    translation: {
      id: convertToGraphQLId('KnowledgeBase::Category::Translation', 2),
      title: 'Child Category',
    },
    categoryIcon: 'folder',
    visibility: EnumKnowledgeBaseVisibility.Published,
    iconSet: 'FontAwesome',
  },
] as KnowledgeBaseAnswerCachedHeader['breadcrumb']

// What the two listing queries of the browse page leave behind for this header: the path, the
//   title in the browsed locale, and the state its public preview link is gated on.
const cachedHeader: KnowledgeBaseAnswerCachedHeader = {
  id: ANSWER_ID,
  visibility: EnumKnowledgeBaseVisibility.Published,
  translation: {
    __typename: 'KnowledgeBaseAnswerTranslation',
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
    title: 'Cached Answer Title',
    kbLocale: {
      __typename: 'KnowledgeBaseLocale',
      id: convertToGraphQLId('KnowledgeBase::Locale', 1),
      systemLocale: { __typename: 'Locale', locale: 'en-us' },
    },
  },
  breadcrumb,
}

// The same entry, but written under another locale than the one being browsed - what the cache
//   holds for an answer that has no translation of its own and was served a fallback.
const cachedHeaderInLocale = (locale: string): KnowledgeBaseAnswerCachedHeader => ({
  ...cachedHeader,
  translation: {
    ...cachedHeader.translation!,
    kbLocale: {
      __typename: 'KnowledgeBaseLocale',
      id: convertToGraphQLId('KnowledgeBase::Locale', 2),
      systemLocale: { __typename: 'Locale', locale },
    },
  },
})

// Only what this header reads off the loaded record; the rest is the sidebar's and the body's.
const loadedAnswer = {
  id: ANSWER_ID,
  visibility: EnumKnowledgeBaseVisibility.Published,
  visibilitySchedules: [],
  internalAt: null,
  publishedAt: '2026-08-01T10:00:00Z',
  archivedAt: null,
  translation: {
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
    title: 'Loaded Answer Title',
    editedAt: '2026-08-03T10:00:00Z',
    editedBy: null,
    kbLocale: {
      id: convertToGraphQLId('KnowledgeBase::Locale', 1),
      systemLocale: { locale: 'en-us' },
    },
  },
  category: { id: CHILD_CATEGORY_ID, breadcrumb },
} as unknown as KnowledgeBaseAnswerHeader

const renderHeader = async (props = {}) => {
  const view = renderComponent(KnowledgeBaseAnswerTopBarHeader, {
    props: { contentContainerElement: null, ...props },
    router: true,
    routerRoutes,
    store: true,
  })

  await getTestRouter().replace(`/knowledge-base/locale/en-us/answer/5`)
  await flushPromises()

  return view
}

// Both header variants are rendered at once (the compact one is positioned over the full one), so
//   every query has to say which of the two it means - and scoped to this render's own container,
//   since the examples of a file are not cleaned up between runs.
const fullHeader = (view: Awaited<ReturnType<typeof renderHeader>>) =>
  within(within(view.container as HTMLElement).getByTestId('knowledge-base-header-full'))

describe('KnowledgeBaseAnswerTopBarHeader', () => {
  beforeEach(() => {
    mockPermissions(['knowledge_base.reader'])
  })

  // The point of the cached pre-info: opening an answer from the category that lists it shows the
  //   real header at once, instead of skeletoning the top bar for a round trip and resizing it.
  describe('while the answer is still loading', () => {
    it('renders the path and the title from the cached pre-info', async () => {
      const view = fullHeader(await renderHeader({ cachedHeader }))

      expect(view.getByRole('link', { name: /Root Category/ })).toBeInTheDocument()
      expect(view.getByRole('link', { name: /Child Category/ })).toBeInTheDocument()
      // Twice, and both on purpose: the breadcrumb closes on the opened answer as the page
      //   heading, and the title row below repeats it as the header's own title.
      expect(
        view.getByRole('heading', { level: 1, name: 'Cached Answer Title' }),
      ).toBeInTheDocument()
      expect(
        view.getByRole('heading', { level: 2, name: 'Cached Answer Title' }),
      ).toBeInTheDocument()
    })

    // Gated on the answer's visibility, which the pre-info carries - so the button does not pop in
    //   a round trip after the header it sits in.
    it('offers the public preview link from the cached pre-info', async () => {
      const view = fullHeader(await renderHeader({ cachedHeader }))

      expect(view.getByRole('link', { name: 'View public knowledge base' })).toHaveAttribute(
        'href',
        '/api/v1/knowledge_bases/preview/KnowledgeBaseAnswer/5/en-us',
      )
    })

    // The one row the pre-info cannot fill. It has to hold its place all the same, or the header
    //   would grow a row the moment the answer lands.
    it('skeletons the details row in place', async () => {
      const view = fullHeader(await renderHeader({ cachedHeader }))

      expect(view.getAllByRole('progressbar').length).toBeGreaterThan(0)
    })

    // The alert docks a row under the header, so it has to be decided from the cached pre-info
    //   too - arriving with the answer would grow the header exactly the way this branch is here
    //   to stop. That is the only reason `knowledgeBaseAnswerPreInfo` carries `kbLocale`, and
    //   dropping it would not silence the alert but raise it for *every* cache-opened answer:
    //   `isTranslationMissing` reads an unknown locale as missing.
    it('warns from the cached pre-info when the title is a fallback from another locale', async () => {
      const view = fullHeader(await renderHeader({ cachedHeader: cachedHeaderInLocale('de-de') }))

      expect(
        view.getByText('No translation available for this locale'),
        'the en-us route is served a de-de title',
      ).toBeInTheDocument()
    })

    it('does not warn when the cached title belongs to the browsed locale', async () => {
      const view = fullHeader(await renderHeader({ cachedHeader }))

      expect(view.queryByText('No translation available for this locale')).not.toBeInTheDocument()
    })
  })

  describe('once the answer has arrived', () => {
    it('prefers the loaded answer over the cached pre-info', async () => {
      const view = fullHeader(await renderHeader({ cachedHeader, answer: loadedAnswer }))

      expect(
        view.getByRole('heading', { level: 2, name: 'Loaded Answer Title' }),
      ).toBeInTheDocument()
      expect(
        view.queryByRole('heading', { level: 2, name: 'Cached Answer Title' }),
      ).not.toBeInTheDocument()
    })

    it('replaces the details skeleton with the answer details', async () => {
      const view = fullHeader(await renderHeader({ cachedHeader, answer: loadedAnswer }))

      expect(view.queryByRole('progressbar')).not.toBeInTheDocument()
      expect(view.getByText(/edited /)).toBeInTheDocument()
    })
  })

  // Nothing listed it, so there is nothing to open from - the header skeletons as a whole, which
  //   is the page's call (`headerLoading` in useKnowledgeBaseAnswer).
  it('skeletons the whole header without a cached pre-info', async () => {
    const view = await renderHeader({ loading: true })

    expect(
      within(view.container as HTMLElement).queryByTestId('knowledge-base-header-full'),
    ).not.toBeInTheDocument()
    expect(
      within(view.container as HTMLElement).getAllByRole('progressbar').length,
    ).toBeGreaterThan(0)
  })
})
