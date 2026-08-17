// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import FloatingToolbar from '../FloatingToolbar.vue'

const renderToolbar = () => renderComponent(FloatingToolbar)

describe('FloatingToolbar', () => {
  it('renders all image actions', () => {
    const wrapper = renderToolbar()

    expect(wrapper.getByRole('toolbar', { name: 'Image actions' })).toBeVisible()

    ;['Zoom in', 'Zoom out', 'Fit to screen', 'Rotate left', 'Rotate right'].forEach((name) => {
      expect(wrapper.getByRole('button', { name })).toBeVisible()
    })
  })

  it.each([
    ['Zoom in', 'zoom-in'],
    ['Zoom out', 'zoom-out'],
    ['Fit to screen', 'resize'],
    ['Rotate left', 'rotate-left'],
    ['Rotate right', 'rotate-right'],
  ])('emits %s action', async (name, event) => {
    const wrapper = renderToolbar()

    await wrapper.events.click(wrapper.getByRole('button', { name }))

    expect(wrapper.emitted(event)).toHaveLength(1)
  })
})
