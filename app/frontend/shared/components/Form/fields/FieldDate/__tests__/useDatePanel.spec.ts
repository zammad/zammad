// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { nextTick, ref } from 'vue'

import testFlags from '#shared/utils/testFlags.ts'

import { useDatePanel } from '../useDatePanel.ts'

const setup = (disabled = false) => {
  const input = ref(document.createElement('input'))
  document.body.append(input.value)

  const hooks = { onOpen: vi.fn(), onOpened: vi.fn(), onClose: vi.fn() }

  const panel = useDatePanel({ input, disabled: () => disabled, ...hooks })

  return { input, hooks, panel }
}

describe('useDatePanel', () => {
  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('opens and closes the panel, with the test flags once it has rendered or gone', async () => {
    const { hooks, panel } = setup()

    panel.open()

    expect(panel.isOpen.value).toBe(true)
    expect(hooks.onOpen).toHaveBeenCalledOnce()
    expect(hooks.onOpened).not.toHaveBeenCalled()

    await flushPromises()

    expect(hooks.onOpened).toHaveBeenCalledOnce()
    expect(testFlags.get('field-date.opened')).toBe(true)

    panel.open()

    expect(hooks.onOpen).toHaveBeenCalledOnce()

    panel.close()
    await flushPromises()

    expect(panel.isOpen.value).toBe(false)
    expect(hooks.onClose).toHaveBeenCalledOnce()
    expect(testFlags.get('field-date.closed')).toBe(true)
  })

  it('does not open while disabled', () => {
    const { hooks, panel } = setup(true)

    panel.open()

    expect(panel.isOpen.value).toBe(false)
    expect(hooks.onOpen).not.toHaveBeenCalled()
  })

  it('moves the focus back to the input only when asked', async () => {
    const { input, panel } = setup()

    panel.open()
    panel.close()
    await nextTick()

    expect(input.value).not.toHaveFocus()

    panel.open()
    panel.close({ refocus: true })
    await nextTick()

    expect(input.value).toHaveFocus()
  })
})
