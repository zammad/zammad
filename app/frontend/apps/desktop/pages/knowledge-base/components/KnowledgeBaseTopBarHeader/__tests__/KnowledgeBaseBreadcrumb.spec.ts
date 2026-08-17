// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumKnowledgeBaseVisibility, EnumTextDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'

import KnowledgeBaseBreadcrumb from '../KnowledgeBaseBreadcrumb.vue'

import type { KnowledgeBaseBreadcrumbItem } from '../../../types.ts'

const items: KnowledgeBaseBreadcrumbItem[] = [
  { label: 'Knowledge Base', route: '/' },
  { label: 'Some Category' },
]

const renderBreadcrumb = (props = {}) =>
  renderComponent(KnowledgeBaseBreadcrumb, {
    props: {
      items,
      ...props,
    },
    slots: {
      trailing: 'trailing slot',
    },
    router: true,
  })

// The category icons come from a sprite file per icon set, so they are plain
//   `<use>` references and cannot be found via `getByIconName`.
const getCategoryIcons = (container: Element) =>
  Array.from(container.querySelectorAll('use[href^="/assets/icon-fonts/"]')).map((use) =>
    use.getAttribute('href'),
  )

describe('KnowledgeBaseBreadcrumb', () => {
  it('renders the breadcrumb', () => {
    const view = renderBreadcrumb()

    const link = view.getByRole('link', { name: 'Knowledge Base' })

    expect(link).toHaveAttribute('href', '/desktop/')
    expect(link).not.toHaveAttribute('aria-label')
    expect(view.getByRole('heading', { name: 'Some Category', level: 1 })).toHaveAttribute(
      'aria-current',
      'page',
    )
    expect(view.getByText('trailing slot')).toBeInTheDocument()
  })

  it('translates the item labels unless asked not to', () => {
    i18n.setTranslationMap(
      new Map([
        ['Some Category', 'Irgendeine Kategorie'],
        ['Other Category', 'Andere Kategorie'],
      ]),
    )

    const view = renderBreadcrumb({
      items: [
        { label: 'Some Category' },
        { label: 'Other Category', noOptionLabelTranslation: true },
      ],
    })

    expect(view.getByText('Irgendeine Kategorie')).toBeInTheDocument()
    expect(view.getByText('Other Category')).toBeInTheDocument()
    expect(view.queryByText('Andere Kategorie')).not.toBeInTheDocument()

    i18n.setTranslationMap(new Map([]))
  })

  it('renders a count badge when a count is given', () => {
    const view = renderBreadcrumb({
      items: [
        { label: 'Knowledge Base', route: '/' },
        { label: 'Some Category', count: 0 },
      ],
    })

    expect(view.getByText('0')).toBeInTheDocument()
  })

  it('emphasizes the last item', () => {
    const view = renderBreadcrumb({ emphasizeLastItem: true })

    expect(view.getByText('Some Category').parentElement).toHaveClass(
      'last:dark:text-white last:text-black',
    )
  })

  it('supports different text sizes', async () => {
    const view = renderBreadcrumb()

    // Default size
    expect(view.getByLabelText('Breadcrumb navigation')).toHaveClass('text-base')

    await view.rerender({ items, size: 'small' })

    expect(view.getByLabelText('Breadcrumb navigation')).toHaveClass('text-xs')
  })

  it('supports a custom navigation label', () => {
    const view = renderBreadcrumb({ label: 'Category navigation' })

    expect(view.getByRole('navigation', { name: 'Category navigation' })).toBeInTheDocument()
  })

  it('supports setting an item to isActive', () => {
    const view = renderBreadcrumb({
      items: [
        { label: 'Knowledge Base', route: '/' },
        { label: 'Some Category', isActive: true },
      ],
    })

    expect(view.getByRole('heading', { name: 'Some Category', level: 1 })).toHaveClass(
      'text-black dark:text-white',
    )
  })

  it('renders a separator between the items only', () => {
    const view = renderBreadcrumb({
      items: [...items, { label: 'Some Answer' }],
    })

    expect(view.getAllByIconName('chevron-right')).toHaveLength(2)
  })

  it('reverses the separator in RTL locales', async () => {
    const view = renderBreadcrumb()
    const locale = useLocaleStore()

    expect(view.getByIconName('chevron-right')).toBeInTheDocument()

    locale.localeData = { dir: EnumTextDirection.Rtl } as never

    await waitFor(() => {
      expect(view.getByIconName('chevron-left')).toBeInTheDocument()
    })

    locale.localeData = null
  })

  describe('icons', () => {
    it('renders a common icon for an item without an icon set', () => {
      const view = renderBreadcrumb({
        items: [
          { label: 'Knowledge Base', route: '/', icon: 'book' },
          { label: 'Some Category', icon: 'folder' },
        ],
      })

      expect(view.getByIconName('book')).toBeInTheDocument()
      expect(view.getByIconName('folder')).toBeInTheDocument()
      expect(getCategoryIcons(view.container)).toEqual([])
    })

    it('renders the category icon from the given icon set', () => {
      const view = renderBreadcrumb({
        items: [
          { label: 'Knowledge Base', route: '/', icon: 'f115', iconSet: 'FontAwesome' },
          { label: 'Some Category', icon: 'f004', iconSet: 'FontAwesome' },
        ],
      })

      expect(getCategoryIcons(view.container)).toEqual([
        '/assets/icon-fonts/FontAwesome.svg#icon-f115',
        '/assets/icon-fonts/FontAwesome.svg#icon-f004',
      ])
    })

    it('renders the category icon for an icon only item', () => {
      const view = renderBreadcrumb({
        items: [
          {
            label: 'Knowledge Base',
            route: '/',
            icon: 'f115',
            iconSet: 'FontAwesome',
            iconOnly: true,
          },
          { label: 'Some Category' },
        ],
      })

      expect(getCategoryIcons(view.container)).toContain(
        '/assets/icon-fonts/FontAwesome.svg#icon-f115',
      )
      expect(view.getByRole('link')).toHaveAttribute('aria-label', 'Knowledge Base')
      expect(view.queryByText('Knowledge Base')).not.toBeInTheDocument()
    })

    it('shows the visibility status of the category icon', () => {
      const view = renderBreadcrumb({
        items: [
          {
            label: 'Knowledge Base',
            route: '/',
            icon: 'f115',
            iconSet: 'FontAwesome',
            visibility: EnumKnowledgeBaseVisibility.Internal,
          },
          {
            label: 'Some Category',
            icon: 'f004',
            iconSet: 'FontAwesome',
            visibility: EnumKnowledgeBaseVisibility.Draft,
          },
        ],
      })

      expect(view.getByLabelText('Internal')).toBeInTheDocument()
      expect(view.getByIconName('lock-fill')).toBeInTheDocument()
      expect(view.getByLabelText('Draft')).toBeInTheDocument()
      expect(view.getByIconName('pencil-fill')).toBeInTheDocument()
    })

    it('shows no visibility status without a visibility', () => {
      const view = renderBreadcrumb({
        items: [
          { label: 'Knowledge Base', route: '/', icon: 'f115', iconSet: 'FontAwesome' },
          { label: 'Some Category' },
        ],
      })

      expect(view.queryByIconName('lock-fill')).not.toBeInTheDocument()
      expect(view.queryByIconName('unlock-fill')).not.toBeInTheDocument()
      expect(view.queryByIconName('pencil-fill')).not.toBeInTheDocument()
    })

    it('supports passing a custom class to the icons', () => {
      const view = renderBreadcrumb({
        items: [
          { label: 'Knowledge Base', route: '/', icon: 'book', iconClass: 'text-red-500' },
          {
            label: 'Some Category',
            icon: 'f004',
            iconSet: 'FontAwesome',
            iconClass: 'text-blue-500',
          },
        ],
      })

      expect(view.getByIconName('book')).toHaveClass('text-red-500')
      // The custom class lands on the status wrapper, which colors the icon inside.
      expect(view.container.querySelector('svg.icon-f004')?.parentElement).toHaveClass(
        'text-blue-500',
      )
    })
  })
})
