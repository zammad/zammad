// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { useApplicationStore } from '#shared/stores/application.ts'

import { REPEATED_PRESS_WINDOW, useKeyboardShortcut } from '../useKeyboardShortcut.ts'
import { KEYBOARD_SHORTCUTS_STORAGE_KEY } from '../useKeyboardShortcutsEnabled.ts'

import { changeStoredFlag } from './support/changeStoredFlag.ts'

import type {
  KeyboardShortcutHandler,
  KeyboardShortcutOptions,
  RegistryKeyboardShortcutKey,
} from '../types.ts'

const { platform } = vi.hoisted(() => ({ platform: { isMac: false } }))

vi.mock('#shared/utils/browser.ts', async (importOriginal) => ({
  ...(await importOriginal<typeof import('#shared/utils/browser.ts')>()),
  isMac: () => platform.isMac,
}))

const mountShortcut = (
  key: RegistryKeyboardShortcutKey,
  handler: KeyboardShortcutHandler,
  options?: KeyboardShortcutOptions,
) =>
  renderComponent(
    {
      template: `
        <input aria-label="Input" />
        <textarea aria-label="Textarea"></textarea>
        <select aria-label="Select"><option>One</option></select>
        <div aria-label="Editor" contenteditable="true" tabindex="0"></div>
        <p>Selectable text</p>
      `,
      setup: () => {
        useKeyboardShortcut(key, handler, options)
      },
    },
    { store: true },
  )

describe('useKeyboardShortcut', () => {
  beforeEach(async () => {
    platform.isMac = false
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ dashboard: true })
    await changeStoredFlag(null)
  })

  it('runs the handler with the event and a press count', async () => {
    const handler = vi.fn()
    const wrapper = mountShortcut('dashboard', handler)

    await wrapper.events.keyboard('h')

    expect(handler).toHaveBeenCalledWith({
      event: expect.any(KeyboardEvent),
      count: 1,
    })
  })

  describe('catalogue entry', () => {
    it('registers every combination of the entry', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('navigate-articles', handler)

      await wrapper.events.keyboard('{ArrowRight}{ArrowLeft}')

      expect(handler).toHaveBeenCalledTimes(2)
    })

    it.each([
      ['macOS', true, 2],
      ['Windows and Linux', false, 1],
    ])('registers the combinations the entry has on %s', async (_, isMac, presses) => {
      platform.isMac = isMac

      const handler = vi.fn()
      const wrapper = mountShortcut('submit-form', handler)

      await wrapper.events.keyboard('{Control>}{Enter}{/Control}')
      await wrapper.events.keyboard('{Meta>}{Enter}{/Meta}')

      expect(handler).toHaveBeenCalledTimes(presses)
    })

    it('does not register a key the catalogue does not list', () => {
      expect(() => useKeyboardShortcut('unknown' as RegistryKeyboardShortcutKey, vi.fn())).toThrow(
        'Unknown keyboard shortcut: "unknown"',
      )
    })
  })

  describe('shortcut switch of the old desktop view', () => {
    it('is on while the key is absent and never writes it', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler)

      await wrapper.events.keyboard('h')

      expect(handler).toHaveBeenCalledTimes(1)
      expect(localStorage.getItem(KEYBOARD_SHORTCUTS_STORAGE_KEY)).toBeNull()
    })

    it('is off while the key holds false and picks up changes from another tab', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler)

      await changeStoredFlag('false')
      await wrapper.events.keyboard('h')

      expect(handler).not.toHaveBeenCalled()

      await changeStoredFlag(null)
      await wrapper.events.keyboard('h')

      expect(handler).toHaveBeenCalledTimes(1)
    })

    it('reads a value already stored when the shortcut registers', async () => {
      await changeStoredFlag('false')

      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler)

      await wrapper.events.keyboard('h')

      expect(handler).not.toHaveBeenCalled()
    })
  })

  describe('who may use it, from the catalogue entry', () => {
    it('runs for a user with the permission of the entry', async () => {
      mockPermissions(['user_preferences.appearance'])

      const handler = vi.fn()
      const wrapper = mountShortcut('toggle-dark-mode', handler)

      await wrapper.events.keyboard('d')

      expect(handler).toHaveBeenCalledTimes(1)
    })

    it('leaves the key alone for a user without the permission and follows a change of it', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('toggle-dark-mode', handler)

      await wrapper.events.type(wrapper.getByLabelText('Input'), 'd')

      expect(handler).not.toHaveBeenCalled()
      expect(wrapper.getByLabelText('Input')).toHaveValue('d')

      mockPermissions(['user_preferences.appearance'])
      await wrapper.events.keyboard('d')

      expect(handler).toHaveBeenCalledTimes(1)
    })

    it('leaves the key alone while the session condition of the entry fails', async () => {
      mockPermissions(['ticket.customer'])
      mockApplicationConfig({ customer_ticket_create: false })

      const handler = vi.fn()
      const wrapper = mountShortcut('new-ticket', handler)

      await wrapper.events.type(wrapper.getByLabelText('Input'), 'n')

      expect(handler).not.toHaveBeenCalled()
      expect(wrapper.getByLabelText('Input')).toHaveValue('n')

      useApplicationStore().config.customer_ticket_create = true
      await wrapper.events.keyboard('n')

      expect(handler).toHaveBeenCalledTimes(1)
    })
  })

  describe('setting', () => {
    it('runs while the setting is on', async () => {
      mockApplicationConfig({ dashboard: true })

      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler)

      await wrapper.events.keyboard('h')

      expect(handler).toHaveBeenCalledTimes(1)
    })

    it('leaves the key alone while the setting is off and follows a change of it', async () => {
      mockApplicationConfig({ dashboard: false })

      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler)

      await wrapper.events.type(wrapper.getByLabelText('Input'), 'h')

      expect(handler).not.toHaveBeenCalled()
      expect(wrapper.getByLabelText('Input')).toHaveValue('h')

      useApplicationStore().config.dashboard = true
      await wrapper.events.keyboard('h')

      expect(handler).toHaveBeenCalledTimes(1)
    })
  })

  describe('enabled', () => {
    it('leaves the key alone while disabled and follows a change', async () => {
      const enabled = ref(false)
      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler, { enabled })

      await wrapper.events.type(wrapper.getByLabelText('Input'), 'h')

      expect(handler).not.toHaveBeenCalled()
      expect(wrapper.getByLabelText('Input')).toHaveValue('h')

      enabled.value = true
      await wrapper.events.keyboard('h')

      expect(handler).toHaveBeenCalledTimes(1)
    })

    it('takes a getter', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler, { enabled: () => false })

      await wrapper.events.keyboard('h')

      expect(handler).not.toHaveBeenCalled()
    })
  })

  describe('text entry guard', () => {
    it.each(['Input', 'Textarea', 'Select', 'Editor'])(
      'does not fire while %s has the focus',
      async (label) => {
        const handler = vi.fn()
        const wrapper = mountShortcut('dashboard', handler, { onlyOutsideInputs: true })

        wrapper.getByLabelText(label).focus()
        await wrapper.events.keyboard('h')

        expect(handler).not.toHaveBeenCalled()
      },
    )

    it('lets the typed character through', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler, { onlyOutsideInputs: true })

      await wrapper.events.type(wrapper.getByLabelText('Input'), 'h')

      expect(wrapper.getByLabelText('Input')).toHaveValue('h')
    })

    it('fires in a text field without the guard', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('submit-form', handler)

      wrapper.getByLabelText('Textarea').focus()
      await wrapper.events.keyboard('{Control>}{Enter}{/Control}')

      expect(handler).toHaveBeenCalledTimes(1)
    })
  })

  describe('selection guard', () => {
    const selectText = (wrapper: ReturnType<typeof mountShortcut>) => {
      const range = document.createRange()
      range.selectNodeContents(wrapper.getByText('Selectable text'))
      window.getSelection()?.removeAllRanges()
      window.getSelection()?.addRange(range)
    }

    afterEach(() => {
      window.getSelection()?.removeAllRanges()
    })

    it('does not fire while text is selected', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('dashboard', handler, { onlyWithoutSelection: true })

      selectText(wrapper)
      await wrapper.events.keyboard('h')

      expect(handler).not.toHaveBeenCalled()

      window.getSelection()?.removeAllRanges()
      await wrapper.events.keyboard('h')

      expect(handler).toHaveBeenCalledTimes(1)
    })

    it('keeps counting a selection that existed when shift went down', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('update-as-closed', handler, { onlyWithoutSelection: true })

      selectText(wrapper)
      await wrapper.events.keyboard('{Shift>}')
      window.getSelection()?.removeAllRanges()
      await wrapper.events.keyboard('c{/Shift}')

      expect(handler).not.toHaveBeenCalled()

      await wrapper.events.keyboard('{Shift>}c{/Shift}')

      expect(handler).toHaveBeenCalledTimes(1)
    })

    it('forgets that selection when the window loses the focus while shift is held', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('update-as-closed', handler, { onlyWithoutSelection: true })

      selectText(wrapper)

      // Shift goes down here, and is released in another window.
      window.dispatchEvent(new KeyboardEvent('keydown', { key: 'Shift', shiftKey: true }))
      window.dispatchEvent(new Event('blur'))
      window.getSelection()?.removeAllRanges()

      await wrapper.events.keyboard('{Shift>}c{/Shift}')

      expect(handler).toHaveBeenCalledTimes(1)
    })
  })

  describe('press count', () => {
    beforeEach(() => {
      vi.useFakeTimers({ toFake: ['Date'] })

      // The count is global, like the old view's: forget the presses of earlier examples.
      window.dispatchEvent(new KeyboardEvent('keyup', { key: 'Escape' }))
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    const counts = (handler: ReturnType<typeof vi.fn>) =>
      handler.mock.calls.map(([press]) => press.count)

    it('counts repeated presses within the window', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('copy-object-number', handler)

      await wrapper.events.keyboard('.')
      vi.advanceTimersByTime(REPEATED_PRESS_WINDOW - 1)
      await wrapper.events.keyboard('.')
      vi.advanceTimersByTime(REPEATED_PRESS_WINDOW - 1)
      await wrapper.events.keyboard('.')

      expect(counts(handler)).toEqual([1, 2, 3])
    })

    it('starts over after the window', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('copy-object-number', handler)

      await wrapper.events.keyboard('.')
      vi.advanceTimersByTime(REPEATED_PRESS_WINDOW)
      await wrapper.events.keyboard('.')

      expect(counts(handler)).toEqual([1, 1])
    })

    it('starts over after another shortcut or escape', async () => {
      const handler = vi.fn()
      const wrapper = mountShortcut('copy-object-number', handler)

      renderComponent({
        template: '<div/>',
        setup: () => useKeyboardShortcut('dashboard', vi.fn()),
      })

      await wrapper.events.keyboard('.')
      await wrapper.events.keyboard('h')
      await wrapper.events.keyboard('.')
      await wrapper.events.keyboard('{Escape}')
      await wrapper.events.keyboard('.')

      expect(counts(handler)).toEqual([1, 1, 1])
    })
  })
})
