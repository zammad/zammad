// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { getClipboardItemData } from '#tests/support/mocks/clipboardItem.ts'

import { type ObjectReference, useObjectReferenceShortcut } from '../useObjectReferenceShortcut.ts'

const copyToClipboard = vi.fn()

vi.mock('#shared/composables/useCopyToClipboard.ts', () => ({
  useCopyToClipboard: () => ({ copyToClipboard }),
}))

const URL_BASE = 'https://zammad.example.com/desktop'

const mountShortcut = (reference?: ObjectReference, enabled = ref(true)) =>
  renderComponent(
    {
      template: '<input aria-label="Input" />',
      setup: () => {
        useObjectReferenceShortcut(() => reference, { enabled })
      },
    },
    { store: true },
  )

const copiedItem = (call: number) => getClipboardItemData(copyToClipboard.mock.calls[call][0][0])

describe('useObjectReferenceShortcut', () => {
  beforeEach(async () => {
    mockApplicationConfig({ http_type: 'https', fqdn: 'zammad.example.com' })
    copyToClipboard.mockClear()
  })

  // The press count is shared by all shortcuts, Escape starts it over.
  afterEach(async () => {
    const wrapper = renderComponent({ template: '<div />' })

    await wrapper.events.keyboard('{Escape}')
  })

  it('copies the number, then with the title, then with the link', async () => {
    const view = mountShortcut({
      number: 'Ticket#31001',
      title: 'Printer on fire',
      path: '/tickets/1',
    })

    await view.events.keyboard('...')

    expect(copyToClipboard).toHaveBeenNthCalledWith(1, 'Ticket#31001')
    expect(copyToClipboard).toHaveBeenNthCalledWith(2, 'Ticket#31001: Printer on fire')
    expect(copiedItem(2)).toEqual({
      'text/plain': `Ticket#31001: Printer on fire\n${URL_BASE}/tickets/1`,
      'text/html': `<a href="${URL_BASE}/tickets/1">Ticket#31001</a>: Printer on fire`,
    })
  })

  it('references an object without a number by its title', async () => {
    const view = mountShortcut({ title: 'Nicole Braun', path: '/users/2' })

    await view.events.keyboard('...')

    expect(copyToClipboard).toHaveBeenCalledTimes(2)
    expect(copyToClipboard).toHaveBeenNthCalledWith(1, 'Nicole Braun')
    expect(copiedItem(1)).toEqual({
      'text/plain': `Nicole Braun\n${URL_BASE}/users/2`,
      'text/html': `<a href="${URL_BASE}/users/2">Nicole Braun</a>`,
    })
  })

  it('escapes the values in the link', async () => {
    const view = mountShortcut({ title: 'Smith & <Sons>', path: '/organizations/1' })

    await view.events.keyboard('...')

    expect(copiedItem(1)['text/html']).toBe(
      `<a href="${URL_BASE}/organizations/1">Smith &amp; &lt;Sons&gt;</a>`,
    )
  })

  it('copies no link without a path', async () => {
    const view = mountShortcut({ number: 'Ticket#31001', title: 'Printer on fire' })

    await view.events.keyboard('...')

    expect(copyToClipboard).toHaveBeenCalledTimes(2)
  })

  it('copies nothing without a number or a title', async () => {
    const view = mountShortcut({ title: '', path: '/search' })

    await view.events.keyboard('...')

    expect(copyToClipboard).not.toHaveBeenCalled()
  })

  it('copies nothing without a reference', async () => {
    const view = mountShortcut()

    await view.events.keyboard('...')

    expect(copyToClipboard).not.toHaveBeenCalled()
  })

  it('copies nothing on further presses', async () => {
    const view = mountShortcut({
      number: 'Ticket#31001',
      title: 'Printer on fire',
      path: '/tickets/1',
    })

    await view.events.keyboard('....')

    expect(copyToClipboard).toHaveBeenCalledTimes(3)
  })

  it('copies nothing while disabled', async () => {
    const view = mountShortcut({ title: 'Nicole Braun', path: '/users/2' }, ref(false))

    await view.events.keyboard('...')

    expect(copyToClipboard).not.toHaveBeenCalled()
  })

  it('copies nothing from an input', async () => {
    const view = mountShortcut({
      number: 'Ticket#31001',
      title: 'Printer on fire',
      path: '/tickets/1',
    })

    await view.events.click(view.getByLabelText('Input'))
    await view.events.keyboard('...')

    expect(copyToClipboard).not.toHaveBeenCalled()
  })
})
