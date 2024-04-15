// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'

import CommonConfirmationDialog from '../CommonConfirmationDialog.vue'

const { confirmationOptions } = useConfirmation()

beforeAll(() => {
  const main = document.createElement('main')
  main.id = 'page-main-content'
  document.body.appendChild(main)
})

afterAll(() => {
  document.body.innerHTML = ''
})

describe('dialog confirm behaviour', () => {
  beforeEach(() => {
    confirmationOptions.value = undefined
  })

  it('renders confirmation dialog with default values', async () => {
    const confirmCallbackSpy = vi.fn()

    const wrapper = renderComponent(CommonConfirmationDialog)

    confirmationOptions.value = {
      text: 'Test heading',
      confirmCallback: confirmCallbackSpy,
      cancelCallback: vi.fn(),
    }

    await waitForNextTick()

    expect(wrapper.getByText('Test heading')).toBeInTheDocument()
    expect(wrapper.getByText('OK')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'OK' }))
    expect(confirmCallbackSpy).toHaveBeenCalledTimes(1)
  })

  it('renders confirmation dialog with custom values', async () => {
    const confirmCallbackSpy = vi.fn()

    const wrapper = renderComponent(CommonConfirmationDialog)

    confirmationOptions.value = {
      text: 'Test heading',
      buttonLabel: 'Custom button title',
      buttonVariant: 'danger',
      confirmCallback: confirmCallbackSpy,
      cancelCallback: vi.fn(),
    }

    await waitForNextTick()

    expect(
      wrapper.getByRole('button', { name: 'Custom button title' }),
    ).toBeInTheDocument()
    expect(
      wrapper.getByRole('button', { name: 'Custom button title' }),
    ).toHaveClass('btn-error')
  })

  it('closes the confirmation dialog by using cancel', async () => {
    const confirmCallbackSpy = vi.fn()
    const cancelCallbackSpy = vi.fn()

    const wrapper = renderComponent(CommonConfirmationDialog)

    confirmationOptions.value = {
      text: 'Test heading',
      confirmCallback: confirmCallbackSpy,
      cancelCallback: cancelCallbackSpy,
    }

    await waitForNextTick()

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Cancel & Go Back' }),
    )

    expect(cancelCallbackSpy).toHaveBeenCalledTimes(1)
  })
})
