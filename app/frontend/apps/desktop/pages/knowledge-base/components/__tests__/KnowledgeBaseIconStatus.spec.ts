// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import KnowledgeBaseIconStatus from '../KnowledgeBaseIconStatus.vue'

const renderStatus = (props = {}) =>
  renderComponent(KnowledgeBaseIconStatus, {
    props: {
      name: 'folder',
      ...props,
    },
  })

const statuses = [
  { status: 'public', icon: 'unlock-fill', color: 'text-green-400!' },
  { status: 'draft', icon: 'pencil-fill', color: 'text-stone-200! dark:text-neutral-500!' },
] as const

describe('KnowledgeBaseIconStatus', () => {
  it('renders the base icon with the given name', () => {
    const view = renderStatus({ name: 'folder' })

    expect(view.getByIconName('folder')).toBeInTheDocument()
  })

  it('does not render a status marker without a status', () => {
    const view = renderStatus()

    statuses.forEach(({ icon }) => {
      expect(view.queryByIconName(icon)).not.toBeInTheDocument()
    })
  })

  it.each(statuses)(
    'marks the $status status with its icon and color',
    ({ status, icon, color }) => {
      const view = renderStatus({ status })

      // The status marker uses the mapped icon, and both icons share the color.
      expect(view.getByIconName(icon)).toHaveClass(color)
      expect(view.getByIconName('folder')).toHaveClass(color)
    },
  )

  it.each([
    { status: 'public', label: 'Public' },
    { status: 'internal', label: 'Internal' },
    { status: 'draft', label: 'Draft' },
  ] as const)('exposes the $status status as a tooltip label', ({ status, label }) => {
    const view = renderStatus({ status })

    expect(view.getByLabelText(label)).toBeInTheDocument()
  })
})
