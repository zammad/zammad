// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import SplitButton, { type Props } from '../SplitButton.vue'

const renderSplitButton = (
  props?: Partial<Props>,
  slots?: typeof SplitButton.slots,
) => {
  const wrapper = renderComponent(SplitButton, {
    props,
    slots,
  })

  return wrapper
}

describe('SplitButton.vue', () => {
  it('renders as two separate buttons', () => {
    const wrapper = renderSplitButton(
      {},
      {
        default: 'Click me',
      },
    )

    expect(
      wrapper.getByRole('button', { name: 'Click me' }),
    ).toBeInTheDocument()

    const addonButton = wrapper.getByRole('button', { name: 'Context menu' })

    expect(getByIconName(addonButton, 'chevron-up')).toBeInTheDocument()
  })

  it('supports passthrough of button props for main button', () => {
    const wrapper = renderSplitButton(
      {
        type: 'submit',
        disabled: true,
      },
      {
        default: 'Update',
      },
    )

    const button = wrapper.getByRole('button', { name: 'Update' })

    expect(button).toHaveAttribute('type', 'submit')
    expect(button).toBeDisabled()

    const addonButton = wrapper.getByRole('button', { name: 'Context menu' })

    expect(addonButton).toHaveAttribute('type', 'button')
    expect(addonButton).not.toBeDisabled()
  })

  it('toggles popover when addon button is clicked', async () => {
    const wrapper = renderSplitButton()

    expect(wrapper.queryByRole('region')).not.toBeInTheDocument()

    const addonButton = wrapper.getByRole('button', { name: 'Context menu' })

    await wrapper.events.click(addonButton)

    const popover = wrapper.getByRole('region')

    expect(popover).toBeInTheDocument()

    await wrapper.events.click(addonButton)

    expect(popover).not.toBeInTheDocument()
  })

  it('supports disabling just the addon button', () => {
    const wrapper = renderSplitButton(
      {
        addonDisabled: true,
      },
      {
        default: 'Click me',
      },
    )

    expect(wrapper.getByRole('button', { name: 'Click me' })).not.toBeDisabled()

    expect(wrapper.getByRole('button', { name: 'Context menu' })).toBeDisabled()
  })

  it('renders popover menu items when passed', async () => {
    const wrapper = renderSplitButton({
      items: [
        {
          label: 'foo',
          icon: 'floppy',
          key: 'foo-bar',
        },
      ],
    })

    const addonButton = wrapper.getByRole('button', { name: 'Context menu' })

    await wrapper.events.click(addonButton)

    const popover = wrapper.getByRole('region')

    const item = within(popover).getByRole('button', { name: 'foo' })

    expect(getByIconName(item, 'floppy')).toBeInTheDocument()
  })

  it('supports popover content slot', async () => {
    const wrapper = renderSplitButton(
      {},
      {
        'popover-content': 'Popover content',
      },
    )

    expect(wrapper.queryByText('Popover content')).not.toBeInTheDocument()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Context menu' }),
    )

    expect(wrapper.getByText('Popover content')).toBeInTheDocument()
  })

  it('supports alternative addon button label', () => {
    const wrapper = renderSplitButton({
      addonLabel: 'Macro menu',
    })

    expect(
      wrapper.getByRole('button', { name: 'Macro menu' }),
    ).toBeInTheDocument()
  })
})
