// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import getUuid from '#shared/utils/getUuid.ts'

import CommonInputCopyToClipboard from '../CommonInputCopyToClipboard.vue'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async () => ({
  useCopyToClipboard: () => ({ copyToClipboard: copyToClipboardMock }),
}))

const renderCopyToClipboard = (props: Record<string, unknown> = {}, options: any = {}) => {
  return renderComponent(CommonInputCopyToClipboard, {
    props,
    ...options,
    form: true,
  })
}

const uuidValue = getUuid()

describe('CommonInputCopyToClipboard.vue', () => {
  it('show disabled input field with value and copy button', async () => {
    const view = renderCopyToClipboard({
      value: uuidValue,
      label: 'A label',
    })

    const input = view.getByLabelText('A label')

    expect(input).toHaveValue(uuidValue)
    expect(input).toHaveAttribute('readonly')
    expect(view.getByRole('button', { name: 'Copy text' })).toBeInTheDocument()
  })

  // Used while the value is known to be outdated, e.g. a token being rotated.
  it('blocks copying while disabled', async () => {
    const view = renderCopyToClipboard({
      value: uuidValue,
      label: 'A label',
      disabled: true,
    })

    const copyButton = view.getByRole('button', { name: 'Copy text' })

    expect(copyButton).toBeDisabled()

    await view.events.click(copyButton)

    expect(copyToClipboardMock).not.toHaveBeenCalled()
  })

  it('click copy button with a custom copy label', async () => {
    const view = renderCopyToClipboard({
      value: uuidValue,
      label: 'A label',
      copyButtonText: 'Copy token',
    })

    await view.events.click(view.getByRole('button', { name: 'Copy token' }))

    expect(copyToClipboardMock).toHaveBeenCalledWith(uuidValue)
  })
})
