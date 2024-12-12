// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  renderComponent,
  type ExtendedRenderResult,
} from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'

import CommonConfirmation from '../CommonConfirmation.vue'

let wrapper: ExtendedRenderResult

const { confirmationOptions } = useConfirmation()

beforeEach(() => {
  confirmationOptions.value.delete('confirmation')

  wrapper = renderComponent(CommonConfirmation, { shallow: false })
})

describe('popup confirm behaviour', () => {
  it('renders confirmation dialog with default values', async () => {
    const confirmCallbackSpy = vi.fn()

    confirmationOptions.value.set('confirmation', {
      text: 'Test heading',
      confirmCallback: confirmCallbackSpy,
      cancelCallback: vi.fn(),
      closeCallback: vi.fn(),
    })

    await waitForNextTick()

    expect(wrapper.getByText('Test heading')).toBeInTheDocument()
    expect(wrapper.getByText('OK')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByText('OK'))
    expect(confirmCallbackSpy).toHaveBeenCalledTimes(1)
  })

  it('renders confirmation dialog with custom values', async () => {
    const confirmCallbackSpy = vi.fn()

    confirmationOptions.value.set('confirmation', {
      text: 'Test heading',
      buttonLabel: 'Custom button title',
      buttonVariant: 'danger',
      confirmCallback: confirmCallbackSpy,
      cancelCallback: vi.fn(),
      closeCallback: vi.fn(),
    })

    await waitForNextTick()

    const button = wrapper.getByRole('button', { name: 'Custom button title' })

    expect(button).toBeInTheDocument()
    expect(button).toHaveClass('text-red-bright')
  })

  it('closes the confirmation dialog by using cancel', async () => {
    const confirmCallbackSpy = vi.fn()
    const cancelCallbackSpy = vi.fn()

    confirmationOptions.value.set('confirmation', {
      text: 'Test heading',
      confirmCallback: confirmCallbackSpy,
      cancelCallback: cancelCallbackSpy,
      closeCallback: vi.fn(),
    })

    await waitForNextTick()

    await wrapper.events.click(wrapper.getByText('Cancel'))
    expect(wrapper.queryByText('Test heading')).not.toBeInTheDocument()
    expect(cancelCallbackSpy).toHaveBeenCalledTimes(1)
  })
})
