// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import getUuid from '#shared/utils/getUuid.ts'

import CommonInputCopyToClipboard from '../CommonInputCopyToClipboard.vue'

const clipboardCopyMock = vi.fn()

vi.mock('@vueuse/core', async () => {
  const mod =
    await vi.importActual<typeof import('@vueuse/core')>('@vueuse/core')

  return {
    ...mod,
    useClipboard: () => ({
      copy: clipboardCopyMock,
      copied: vi.fn(),
    }),
  }
})

const renderCopyToClipboard = (
  props: Record<string, unknown> = {},
  options: any = {},
) => {
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
      label: 'A Label',
    })

    const input = view.getByLabelText('A Label')

    expect(input).toHaveValue(uuidValue)
    expect(input).toHaveAttribute('readonly')
    expect(view.getByRole('button', { name: 'Copy Text' })).toBeInTheDocument()
  })

  it('click copy button with a custom copy label', async () => {
    const view = renderCopyToClipboard({
      value: uuidValue,
      label: 'A Label',
      copyButtonText: 'Copy Token',
    })

    await view.events.click(view.getByRole('button', { name: 'Copy Token' }))

    expect(clipboardCopyMock).toHaveBeenCalledWith(uuidValue)
  })
})
