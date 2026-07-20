// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'

import TopBarHeaderCompact from '../TopBarHeaderCompact.vue'

const copyKnowledgeBaseNameToClipboard = vi.fn()

vi.mock('../useTopBarHeader.ts', () => ({
  useTopBarHeader: () => ({
    copyKnowledgeBaseNameToClipboard,
  }),
}))

const breadcrumbs: BreadcrumbItem[] = [
  { label: 'Support', icon: 'book', route: '/' },
  { label: 'Some Category' },
]

const locales: DropdownItem[] = [
  { key: '1', label: 'English' },
  { key: '2', label: 'Deutsch' },
]

const renderHeader = (props = {}) =>
  renderComponent(TopBarHeaderCompact, {
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

describe('TopBarHeaderCompact', () => {
  beforeEach(() => {
    copyKnowledgeBaseNameToClipboard.mockReset()
  })

  it('renders the breadcrumb items', () => {
    const view = renderHeader()

    expect(view.getByRole('link', { name: /Support/ })).toBeInTheDocument()
    expect(view.getByText('Some Category')).toBeInTheDocument()
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
})
