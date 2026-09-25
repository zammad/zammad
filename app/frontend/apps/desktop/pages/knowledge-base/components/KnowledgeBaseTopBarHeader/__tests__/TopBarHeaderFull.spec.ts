// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'

import TopBarHeaderFull from '../TopBarHeaderFull.vue'

import type { KnowledgeBaseBreadcrumbItem } from '../../../types.ts'

const copyKnowledgeBaseNameToClipboard = vi.fn()

vi.mock('../useTopBarHeader.ts', () => ({
  useTopBarHeader: () => ({
    copyKnowledgeBaseNameToClipboard,
  }),
}))

const breadcrumbs: KnowledgeBaseBreadcrumbItem[] = [
  { label: 'Support', icon: 'book', route: '/' },
  { label: 'Some Category' },
]

const locales: DropdownItem[] = [
  { key: '1', label: 'English' },
  { key: '2', label: 'Deutsch' },
]

const renderHeader = (props = {}, slots: Record<string, string> = {}) =>
  renderComponent(TopBarHeaderFull, {
    props: {
      breadcrumbs,
      locales,
      title: 'Knowledge Base Title',
      localeCode: 'EN',
      previewUrl: 'https://example.com/help',
      selectedLocale: locales[0],
      ...props,
    },
    slots,
    router: true,
  })

describe('TopBarHeaderFull', () => {
  beforeEach(() => {
    copyKnowledgeBaseNameToClipboard.mockReset()
  })

  it('renders the breadcrumb items', () => {
    const view = renderHeader()

    expect(view.getByRole('link', { name: /Support/ })).toBeInTheDocument()
    expect(view.getByText('Some Category')).toBeInTheDocument()
  })

  it('renders the title', () => {
    const view = renderHeader({ title: 'My Knowledge Base' })

    expect(view.getByText('My Knowledge Base')).toBeInTheDocument()
  })

  it('renders the locale code in the language selector', () => {
    const view = renderHeader({ localeCode: 'DE' })

    expect(view.getByRole('button', { name: 'Change language' })).toHaveTextContent('DE')
  })

  it('renders a link to the public knowledge base', () => {
    const view = renderHeader({ previewUrl: 'https://example.com/help' })

    expect(view.getByRole('link', { name: 'View public knowledge base' })).toHaveAttribute(
      'href',
      'https://example.com/help',
    )
  })

  it('offers a link to the knowledge base search ahead of the public knowledge base link', () => {
    const view = renderHeader({ searchLink: '/knowledge-base/locale/en-us' })

    const searchLink = view.getByRole('link', { name: 'Search the knowledge base' })
    const previewLink = view.getByRole('link', { name: 'View public knowledge base' })

    expect(searchLink).toHaveAttribute('href', '/desktop/knowledge-base/locale/en-us')
    expect(searchLink.compareDocumentPosition(previewLink)).toBe(Node.DOCUMENT_POSITION_FOLLOWING)
  })

  it('offers no search link without one', () => {
    const view = renderHeader()

    expect(view.queryByRole('link', { name: 'Search the knowledge base' })).not.toBeInTheDocument()
  })

  it('emits the selected locale when a language is chosen', async () => {
    const view = renderHeader()

    await view.events.click(view.getByRole('button', { name: 'Change language' }))
    await view.events.click(view.getByText('Deutsch'))

    expect(view.emitted('update:selectedLocale')).toEqual([[locales[1]]])
  })

  it('copies the knowledge base name to clipboard when the copy button is clicked', async () => {
    const view = renderHeader()

    await view.events.click(view.getByRole('button', { name: 'Copy knowledge base name' }))

    expect(copyKnowledgeBaseNameToClipboard).toHaveBeenCalled()
  })

  // While a node is being created the breadcrumb's last item is the heading, so the big title
  //   row must not take up space above it.
  // The reader's answer header opens from the cached pre-info, which carries the breadcrumb and
  //   the title but nothing the badges need. Without a loading state of its own the details row
  //   would be absent until the answer lands, and the header would grow a row on arrival.
  describe('the details row', () => {
    const details = { details: '<div data-test-id="details">details</div>' }

    // Scoped to this render's own container: the examples of a file are not cleaned up between
    //   runs, so a document-wide query would also find the details of the ones before it.
    const renderDetails = (props = {}) =>
      within(renderHeader(props, details).container as HTMLElement)

    it('holds its place while only the details are still loading', () => {
      const view = renderDetails({ loadingDetails: true })

      expect(view.queryByTestId('details')).not.toBeInTheDocument()
      expect(view.getAllByRole('progressbar').length).toBeGreaterThan(0)

      // The rest of the header is not loading, so it is there for real.
      expect(view.getByRole('link', { name: /Support/ })).toBeInTheDocument()
      expect(view.getByText('Knowledge Base Title')).toBeInTheDocument()
    })

    it('shows the details once they are there', () => {
      expect(renderDetails({ loadingDetails: false }).getByTestId('details')).toBeInTheDocument()
    })

    // A header that loads as a whole - the edit view's - says so once and means both.
    it('follows the header loading state when it is not told otherwise', () => {
      const view = renderDetails({ loading: true })

      expect(view.queryByTestId('details')).not.toBeInTheDocument()
      expect(view.getAllByRole('progressbar').length).toBeGreaterThan(0)
    })
  })

  it('renders no title row without a title', () => {
    const view = renderHeader({ title: undefined })

    expect(view.queryByText('Knowledge Base Title')).not.toBeInTheDocument()
  })

  // A node that is being created has no stored title to copy - its title is a form field.
  it('hides the copy button when asked to', () => {
    const view = renderHeader({ noCopyButton: true })

    expect(view.queryByRole('button', { name: 'Copy knowledge base name' })).not.toBeInTheDocument()
  })

  it('offers the given actions in the action menu', async () => {
    const view = renderHeader({
      actions: [{ key: 'knowledge-base-feed', label: 'Set up RSS feed', icon: 'rss' }],
    })

    await view.events.click(view.getByRole('button', { name: 'Additional actions' }))

    expect(view.getByRole('button', { name: 'Set up RSS feed' })).toBeInTheDocument()
  })

  it('hides the action menu without actions', () => {
    const view = renderHeader({ actions: [] })

    expect(view.queryByRole('button', { name: 'Additional actions' })).not.toBeInTheDocument()
  })

  // The title has to sit above the content it belongs to: the browse view's card
  //   grid is wide, the answer view's article body reads at the narrower measure.
  it('caps the title at the wide content width by default', () => {
    const view = renderHeader({ title: 'My Knowledge Base' })

    expect(view.getByText('My Knowledge Base')).toHaveClass(
      'max-w-[calc(var(--container-7xl)-2.750rem)]',
    )
  })

  it('caps the title at the article reading width when asked for it', () => {
    const view = renderHeader({ title: 'My Knowledge Base', contentWidth: 'reading' })

    const title = view.getByText('My Knowledge Base')

    // Same class the answer article's own reading column uses (KnowledgeBaseAnswer.vue),
    //   so the two stay aligned at any width.
    expect(title).toHaveClass('max-w-[calc(var(--container-3xl)+2.750rem)]', 'px-5.5')
    // Breaks out of the header's own px-5.5 first, so the px-5.5 above is the
    //   header's own padding, not stacked on top of it.
    expect(title.parentElement).toHaveClass('-mx-5.5')
  })

  // The create and edit views put their title field up here, above the form column it belongs
  //   to - so it is the field, not a title, that has to line up with the fields below it.
  it('caps the teleport target for the title field at the form column width', () => {
    const view = renderHeader({
      title: undefined,
      titleFieldTarget: 'knowledgeBaseAnswerTitleField',
      contentWidth: 'form',
    })

    const target = view.baseElement.querySelector('#knowledgeBaseAnswerTitleField')

    // Same class the create/edit form column uses, so the two stay aligned at any width.
    expect(target).toHaveClass('max-w-270', 'px-5.5')
    expect(target?.parentElement).toHaveClass('-mx-5.5')
  })

  // The edit header opens its breadcrumb from the cache while the form is still on its way, so the
  //   title field's placeholder must not go with the header's own loading state.
  describe('the title field placeholder', () => {
    const renderTitleField = (props = {}) => {
      const view = renderHeader({
        title: undefined,
        titleFieldTarget: 'knowledgeBaseAnswerTitleField',
        ...props,
      })

      return view.container.querySelector('#knowledgeBaseAnswerTitleField') as HTMLElement
    }

    it('stays while only the title field is still loading', () => {
      const target = renderTitleField({ loadingTitleField: true })

      expect(within(target).getByRole('progressbar')).toBeInTheDocument()
    })

    it('goes once the title field is there, keeping its container', () => {
      const target = renderTitleField({ loading: true, loadingTitleField: false })

      expect(target).toBeInTheDocument()
      expect(within(target).queryByRole('progressbar')).not.toBeInTheDocument()
    })

    it('follows the header loading state when it is not told otherwise', () => {
      const target = renderTitleField({ loading: true })

      expect(within(target).getByRole('progressbar')).toBeInTheDocument()
    })
  })
})
