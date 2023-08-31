// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { confirmationOptions } from '#shared/utils/confirmation.ts'
import {
  renderComponent,
  type ExtendedRenderResult,
} from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import CommonConfirmation from '../CommonConfirmation.vue'

let wrapper: ExtendedRenderResult

beforeEach(() => {
  confirmationOptions.value = undefined

  wrapper = renderComponent(CommonConfirmation, { shallow: false })
})

describe('popup confirm behaviour', () => {
  it('renders confirmation dialog with default values', async () => {
    const confirmCallbackSpy = vi.fn()

    confirmationOptions.value = {
      heading: 'Test heading',
      confirmCallback: confirmCallbackSpy,
    }

    await waitForNextTick()

    expect(wrapper.getByText('Test heading')).toBeInTheDocument()
    expect(wrapper.getByText('OK')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByText('OK'))
    expect(confirmCallbackSpy).toHaveBeenCalledTimes(1)
  })

  it('renders confirmation dialog with custom values', async () => {
    const confirmCallbackSpy = vi.fn()

    confirmationOptions.value = {
      heading: 'Test heading',
      buttonTitle: 'Custom button title',
      buttonVariant: 'danger',
      confirmCallback: confirmCallbackSpy,
    }

    await waitForNextTick()

    expect(wrapper.getByText('Custom button title')).toBeInTheDocument()
    expect(wrapper.getByText('Custom button title')).toHaveClass(
      'text-red-bright',
    )
  })

  it('closes the confirmation dialog by using cancel', async () => {
    const confirmCallbackSpy = vi.fn()
    const cancelCallbackSpy = vi.fn()

    confirmationOptions.value = {
      heading: 'Test heading',
      confirmCallback: confirmCallbackSpy,
      cancelCallback: cancelCallbackSpy,
    }

    await waitForNextTick()

    await wrapper.events.click(wrapper.getByText('Cancel'))
    expect(wrapper.queryByText('Test heading')).not.toBeInTheDocument()
    expect(cancelCallbackSpy).toHaveBeenCalledTimes(1)
  })
})
