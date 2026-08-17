// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { getClipboardItemData } from '#tests/support/mocks/clipboardItem.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import {
  createLinkClipboardItem,
  useCopyToClipboard,
} from '#shared/composables/useCopyToClipboard.ts'

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

describe('createLinkClipboardItem', () => {
  it('copies markup in the label as literal text', () => {
    const href = 'https://zammad.example.com/desktop/users/2'
    const label = 'Nicole </a><strong>Braun</strong><a>'

    const data = getClipboardItemData(createLinkClipboardItem(href, label))

    expect(data['text/plain']).toBe(label)

    const container = document.createElement('div')
    container.innerHTML = data['text/html']

    expect(container.children).toHaveLength(1)
    expect(container.firstElementChild).toHaveProperty('tagName', 'A')
    expect(container.querySelector('a')).toHaveTextContent(label)
    expect(container.querySelector('strong')).not.toBeInTheDocument()
    expect(container.querySelector('a')?.getAttribute('href')).toBe(href)
  })

  it.each([
    ['javascript:alert(1)'],
    ['data:text/html,<script>alert(1)</script>'],
    ['ftp://example.com/file'],
    ['http://'],
  ])('falls back to a plain-text item for unsafe href %s', (href) => {
    const label = 'Nicole Braun'

    expect(getClipboardItemData(createLinkClipboardItem(href, label))).toEqual({
      'text/plain': label,
    })
  })
})
