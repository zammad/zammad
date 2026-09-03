// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import '#tests/graphql/builders/mocks.ts'

import { flushPromises } from '@vue/test-utils'

import renderComponent, { getTestRouter } from '#tests/support/components/renderComponent.ts'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import KnowledgeBaseSearchResultItem from '../KnowledgeBaseSearchResultItem.vue'

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
]

const pathSegment = (id: number, title: string) => ({
  id: convertToGraphQLId('KnowledgeBase::Category', id),
  title,
})

const answerResult = (overrides = {}) => ({
  item: {
    __typename: 'KnowledgeBaseAnswer',
    id: convertToGraphQLId('KnowledgeBase::Answer', 42),
    visibility: EnumKnowledgeBaseVisibility.Published,
    translation: {
      __typename: 'KnowledgeBaseAnswerTranslation',
      id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 42),
      title: 'Printer setup',
    },
  },
  titlePreview: [
    { text: 'Printer', highlight: true },
    { text: ' setup', highlight: false },
  ],
  bodyPreview: [
    { text: 'Connect the ', highlight: false },
    { text: 'printer', highlight: true },
    { text: ' via USB.', highlight: false },
  ],
  categoryPath: [pathSegment(1, 'Hardware'), pathSegment(2, 'Peripherals')],
  ...overrides,
})

const categoryResult = (overrides = {}) => ({
  item: {
    __typename: 'KnowledgeBaseCategory',
    id: convertToGraphQLId('KnowledgeBase::Category', 7),
    title: 'Printers',
    categoryIcon: 'f02f',
    iconSet: 'FontAwesome',
    visibility: EnumKnowledgeBaseVisibility.Internal,
  },
  titlePreview: [{ text: 'Printers', highlight: true }],
  bodyPreview: [],
  categoryPath: [pathSegment(1, 'Hardware')],
  ...overrides,
})

// The item takes the locale from the browsed URL; the test router only exists
//   after the first render, so the route is set afterwards.
const renderItem = async (
  result: object,
  path = '/knowledge-base/locale/en-us',
  props: object = {},
) => {
  const view = renderComponent(KnowledgeBaseSearchResultItem, {
    router: true,
    routerRoutes,
    props: { result, query: 'printer', ...props },
  })

  await getTestRouter().push(path)
  await flushPromises()

  return view
}

const markedTexts = (view: ReturnType<typeof renderComponent>) =>
  Array.from(view.container.querySelectorAll('mark')).map((mark) => mark.textContent)

describe('KnowledgeBaseSearchResultItem', () => {
  describe('answer hit', () => {
    it('shows the state icon, highlighted title, body preview and category path', async () => {
      const view = await renderItem(answerResult())

      expect(view.getByIconName('kb-published')).toBeInTheDocument()
      // The highlighted runs split the texts over several nodes, so match on the whole content.
      expect(view.container).toHaveTextContent('Printer setup')
      expect(view.container).toHaveTextContent('Connect the printer via USB.')
      // Each segment is its own node, separated by a chevron icon (so it can truncate
      //   independently), hence checking the segments and separator individually.
      expect(view.getByText('Hardware')).toBeInTheDocument()
      expect(view.getByText('Peripherals')).toBeInTheDocument()
      expect(view.getByIconName('chevron-right')).toBeInTheDocument()

      expect(markedTexts(view)).toEqual(['Printer', 'printer'])
    })

    it('links to the answer of the browsed locale, carrying the search it was found in', async () => {
      const view = await renderItem(answerResult())

      expect(view.getByRole('link')).toHaveAttribute(
        'href',
        '/desktop/knowledge-base/locale/en-us/answer/42?query=printer',
      )
    })

    it('carries the searched category along, so the way back keeps the category', async () => {
      const view = await renderItem(answerResult(), '/knowledge-base/locale/en-us/category/7', {
        categoryId: convertToGraphQLId('KnowledgeBase::Category', 7),
      })

      expect(view.getByRole('link')).toHaveAttribute(
        'href',
        '/desktop/knowledge-base/locale/en-us/answer/42?query=printer&category=7',
      )
    })

    it('falls back to the plain title without a title preview', async () => {
      const view = await renderItem(answerResult({ titlePreview: [] }))

      expect(view.getByText('Printer setup')).toBeInTheDocument()
      // Only the body preview carries a highlight now.
      expect(markedTexts(view)).toEqual(['printer'])
    })
  })

  describe('category hit', () => {
    it('shows the category icon with its state, the highlighted title and no body preview', async () => {
      const view = await renderItem(categoryResult())

      // The category icon carries its state as a small badge (KnowledgeBaseIconStatus).
      expect(view.getByIconName('lock-fill')).toBeInTheDocument()
      expect(view.getByText('Printers')).toBeInTheDocument()
      expect(view.getByText('Hardware')).toBeInTheDocument()
      expect(view.container).not.toHaveTextContent('Connect the printer via USB.')

      expect(markedTexts(view)).toEqual(['Printers'])
    })

    // Opening a category starts a new search scope, so the term stays behind with it.
    it('links to the category of the browsed locale, without the search', async () => {
      const view = await renderItem(categoryResult())

      expect(view.getByRole('link')).toHaveAttribute(
        'href',
        '/desktop/knowledge-base/locale/en-us/category/7',
      )
    })
  })

  describe('category path', () => {
    it('shows nothing for a hit at the top level', async () => {
      const view = await renderItem(answerResult({ categoryPath: [] }))

      expect(view.queryByText('Hardware')).not.toBeInTheDocument()
      expect(view.queryAllByIconName('chevron-right')).toHaveLength(0)
    })

    it('renders every segment of a long path, each able to truncate on its own', async () => {
      const view = await renderItem(
        answerResult({
          categoryPath: [
            pathSegment(1, 'Hardware'),
            pathSegment(2, 'Peripherals'),
            pathSegment(3, 'Office'),
            pathSegment(4, 'Printers'),
          ],
        }),
      )

      expect(view.getByText('Hardware')).toBeInTheDocument()
      expect(view.getByText('Peripherals')).toBeInTheDocument()
      expect(view.getByText('Office')).toBeInTheDocument()
      expect(view.getByText('Printers')).toBeInTheDocument()
      expect(view.getAllByIconName('chevron-right')).toHaveLength(3)
    })

    // The segment only line-clamps rather than hard-cutting, so its full title is still
    //   reachable — as a tooltip, shown once the segment is actually truncated.
    it('offers a truncated segment as a tooltip', async () => {
      const view = await renderItem(answerResult())

      expect(view.getByText('Hardware')).toHaveAttribute('data-tooltip', 'truncate')
      expect(view.getByText('Hardware')).toHaveAttribute('aria-description', 'Hardware')
    })
  })

  it('renders no link without a browsed locale', async () => {
    const view = await renderItem(answerResult(), '/')

    expect(view.queryByRole('link')).not.toBeInTheDocument()
    expect(view.container).toHaveTextContent('Printer setup')
  })
})
