// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  renderComponent,
  type ExtendedRenderResult,
} from '@tests/support/components'
import { waitForNextTick } from '@tests/support/utils'

import useConfirmationDialog from '../composable'
import CommonConfirmation from '../CommonConfirmation.vue'

let wrapper: ExtendedRenderResult

beforeEach(() => {
  const { confirmationDialog } = useConfirmationDialog()
  confirmationDialog.value = undefined

  wrapper = renderComponent(CommonConfirmation, { shallow: false })
})

describe('popup confirm behaviour', () => {
  it('renders confirmation dialog with default values', async () => {
    const { showConfirmation } = useConfirmationDialog()

    const confirmCallbackSpy = vi.fn()

    showConfirmation({
      heading: 'Test heading',
      confirmCallback: confirmCallbackSpy,
    })

    await waitForNextTick()

    expect(wrapper.getByText('Test heading')).toBeInTheDocument()
    expect(wrapper.getByText('OK')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByText('OK'))
    expect(confirmCallbackSpy).toHaveBeenCalledTimes(1)
  })

  it('renders confirmation dialog with custom values', async () => {
    const { showConfirmation } = useConfirmationDialog()

    const confirmCallbackSpy = vi.fn()

    showConfirmation({
      heading: 'Test heading',
      buttonTitle: 'Custom button title',
      buttonTextColorClass: 'text-red',
      confirmCallback: confirmCallbackSpy,
    })

    await waitForNextTick()

    expect(wrapper.getByText('Custom button title')).toBeInTheDocument()
    expect(wrapper.getByText('Custom button title')).toHaveClass('text-red')
  })

  it('closes the confirmation dialog by using cancel', async () => {
    const { showConfirmation } = useConfirmationDialog()

    const confirmCallbackSpy = vi.fn()
    const cancelCallbackSpy = vi.fn()

    showConfirmation({
      heading: 'Test heading',
      confirmCallback: confirmCallbackSpy,
      cancelCallback: cancelCallbackSpy,
    })

    await waitForNextTick()

    await wrapper.events.click(wrapper.getByText('Cancel'))
    expect(wrapper.queryByText('Test heading')).not.toBeInTheDocument()
    expect(cancelCallbackSpy).toHaveBeenCalledTimes(1)
  })
})
