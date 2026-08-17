// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useTopBarHeader } from '../useTopBarHeader.ts'

import type { TopBarHeaderProps } from '../types.ts'

const copyToClipboardMock = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/composables/useCopyToClipboard.ts')>()),
  useCopyToClipboard: () => ({
    copyToClipboard: copyToClipboardMock,
  }),
}))

describe('useTopBarHeader', () => {
  beforeEach(() => {
    copyToClipboardMock.mockReset()
  })

  it('copies markup in the title as literal text', () => {
    const title = 'Billing </a><strong>urgent</strong><a>'
    const { copyKnowledgeBaseNameToClipboard } = useTopBarHeader(
      ref({ title } as TopBarHeaderProps),
    )

    copyKnowledgeBaseNameToClipboard()

    const [{ data }] = copyToClipboardMock.mock.calls[0][0]
    const container = document.createElement('div')
    container.innerHTML = data['text/html']

    expect(container.children).toHaveLength(1)
    expect(container.firstElementChild).toHaveProperty('tagName', 'A')
    expect(container.querySelector('a')).toHaveTextContent(title)
    expect(container.querySelector('strong')).not.toBeInTheDocument()
    expect(container.querySelector('a')?.getAttribute('href')).toBe(document.URL)
  })
})
