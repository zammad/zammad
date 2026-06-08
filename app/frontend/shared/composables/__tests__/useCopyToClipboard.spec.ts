// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { waitForNextTick } from '#tests/support/utils.ts'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'

const clipboardCopyMock = vi.fn()
const clipboardCopiedMock = ref(false)

vi.mock('@vueuse/core', async () => {
  const mod = await vi.importActual<typeof import('@vueuse/core')>('@vueuse/core')

  return {
    ...mod,
    useClipboardItems: () => ({
      copy: clipboardCopyMock,
      copied: clipboardCopiedMock,
    }),
  }
})

const notifyMock = vi.fn()

vi.mock('#shared/components/CommonNotifications/useNotifications.ts', async () => ({
  useNotifications: () => ({
    notify: notifyMock,
  }),
}))

describe('useCopyToClipboard', () => {
  it('supports copying text to clipboard', () => {
    const { copyToClipboard } = useCopyToClipboard()

    copyToClipboard('foobar')

    expect(clipboardCopyMock).toHaveBeenCalledWith([
      {
        data: {
          'text/plain': 'foobar',
        },
        options: {
          presentationStyle: 'unspecified',
        },
      },
    ])
  })

  it('supports copying content of different MIME types to clipboard', () => {
    const { copyToClipboard } = useCopyToClipboard()

    copyToClipboard([
      new ClipboardItem({
        'text/plain': 'foobar',
        'text/html': '<b>foobar</b>',
      }),
    ])

    expect(clipboardCopyMock).toHaveBeenCalledWith([
      {
        data: {
          'text/html': '<b>foobar</b>',
          'text/plain': 'foobar',
        },
        options: {
          presentationStyle: 'unspecified',
        },
      },
    ])
  })

  it('shows a notification on success', async () => {
    const { copyToClipboard } = useCopyToClipboard()

    copyToClipboard('foobar')

    clipboardCopiedMock.value = true

    await waitForNextTick()

    expect(notifyMock).toHaveBeenCalledWith(expect.objectContaining({ message: 'Copied.' }))
  })

  it('does not copy undefined nor null values to clipboard', () => {
    const { copyToClipboard } = useCopyToClipboard()

    copyToClipboard(undefined)

    expect(clipboardCopyMock).not.toHaveBeenCalled()

    copyToClipboard(null)

    expect(clipboardCopyMock).not.toHaveBeenCalled()
  })
})
