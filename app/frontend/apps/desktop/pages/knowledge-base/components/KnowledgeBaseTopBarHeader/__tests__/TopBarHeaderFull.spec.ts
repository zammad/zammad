// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

const renderHeader = (props = {}) =>
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
})
