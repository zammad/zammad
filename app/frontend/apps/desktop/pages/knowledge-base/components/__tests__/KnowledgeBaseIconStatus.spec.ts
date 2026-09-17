// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import KnowledgeBaseIconStatus from '../KnowledgeBaseIconStatus.vue'

const renderStatus = (props = {}) =>
  renderComponent(KnowledgeBaseIconStatus, {
    props: {
      name: 'f004',
      set: 'FontAwesome',
      ...props,
    },
  })

const statuses = [
  { status: 'published', icon: 'unlock-fill', color: 'text-green-400!' },
  { status: 'draft', icon: 'pencil-fill', color: 'text-stone-200! dark:text-neutral-500!' },
] as const

describe('KnowledgeBaseIconStatus', () => {
  it('renders the base icon with the given name', () => {
    const wrapper = renderStatus({ name: 'f115' })

    const svgElement = wrapper.container.querySelector('svg')!

    expect(svgElement.querySelector('use')?.getAttribute('href')).toContain(
      'FontAwesome.svg#icon-f115',
    )
  })

  it('does not render a status marker without a status', () => {
    const wrapper = renderStatus()

    statuses.forEach(({ icon }) => {
      expect(wrapper.queryByIconName(icon)).not.toBeInTheDocument()
    })
  })

  it.each(statuses)(
    'marks the $status status with its icon and color',
    ({ status, icon, color }) => {
      const wrapper = renderStatus({ status })

      // The status marker uses the mapped icon, and both icons share the color.
      expect(wrapper.getByIconName(icon)).toHaveClass(color)
      expect(wrapper.container.querySelector('svg.icon-f004')).toHaveClass(color)
    },
  )

  it.each([
    { status: 'published', label: 'Published' },
    { status: 'internal', label: 'Internal' },
    { status: 'draft', label: 'Draft' },
  ] as const)('exposes the $status status as a tooltip label', ({ status, label }) => {
    const wrapper = renderStatus({ status })

    expect(wrapper.getByLabelText(label)).toBeInTheDocument()
  })

  it('positions the status marker for the breadcrumb', () => {
    const wrapper = renderStatus({ status: 'published', breadcrumb: true })

    const marker = wrapper.getByIconName('unlock-fill').parentElement

    expect(marker).toHaveClass('translate-y-0.5', 'bg-neutral-50')
    expect(marker).not.toHaveClass('translate-y-2', 'bg-blue-200')
  })

  it('positions the status marker for the default context', () => {
    const wrapper = renderStatus({ status: 'published', breadcrumb: false })

    const marker = wrapper.getByIconName('unlock-fill').parentElement

    expect(marker).toHaveClass('translate-y-2', 'bg-blue-200')
    expect(marker).not.toHaveClass('translate-y-0.5', 'bg-neutral-50')
  })

  it.each([
    { size: 'small', dimension: '8' },
    { size: 'medium', dimension: '12' },
  ] as const)(
    'renders the status marker at $dimension px for the $size size',
    ({ size, dimension }) => {
      const wrapper = renderStatus({ status: 'published', size })

      const marker = wrapper.getByIconName('unlock-fill')

      expect(marker).toHaveAttribute('width', dimension)
      expect(marker).toHaveAttribute('height', dimension)
    },
  )
})
