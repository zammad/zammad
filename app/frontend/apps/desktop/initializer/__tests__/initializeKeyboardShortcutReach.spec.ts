// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, ref, type Ref } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { CommonPopoverInternalInstance } from '#desktop/components/CommonPopover/types.ts'
import { usePopoverInstances } from '#desktop/components/CommonPopover/usePopoverInstances.ts'
import { closeKeyboardShortcutsDialog } from '#desktop/components/KeyboardShortcutsDialog/useKeyboardShortcutsDialog.ts'
import { useCoveringOverlay } from '#desktop/composables/useOverlayCoverage.ts'

import { keyboardShortcutReachGuard } from '../initializeKeyboardShortcutReach.ts'

vi.mock('#desktop/components/KeyboardShortcutsDialog/useKeyboardShortcutsDialog.ts', () => ({
  KEYBOARD_SHORTCUTS_DIALOG_NAME: 'keyboard-shortcuts',
  closeKeyboardShortcutsDialog: vi.fn(),
}))

const { isReachable, beforeRun } = keyboardShortcutReachGuard

interface OverlayOptions {
  id?: string
  coversApplication?: boolean
  isShown?: boolean | Ref<boolean>
}

const renderOverlay = ({
  id = 'dialog-some',
  coversApplication = false,
  isShown = true,
}: OverlayOptions = {}) => {
  const wrapper = renderComponent({
    template: '<div ref="element"><button>Inside {{ id }}</button></div>',
    setup: () => {
      const element = ref<HTMLElement>()

      useCoveringOverlay({ id, element, isShown, coversApplication })

      return { element, id }
    },
  })

  return { inside: wrapper.getByRole('button', { name: `Inside ${id}` }) }
}

describe('keyboardShortcutReachGuard', () => {
  describe('isReachable', () => {
    it('reaches everything while nothing covers the screen', () => {
      expect(isReachable('application')).toBe(true)
      expect(isReachable('page')).toBe(true)
      expect(isReachable('focus')).toBe(true)
      expect(isReachable('anywhere')).toBe(true)
    })

    it('leaves the navigation reachable while the page is covered', () => {
      renderOverlay()

      expect(isReachable('application')).toBe(true)
      expect(isReachable('page')).toBe(false)
      expect(isReachable('anywhere')).toBe(true)
    })

    it('reaches only what cannot be covered while the whole application is covered', () => {
      renderOverlay({ coversApplication: true })

      expect(isReachable('application')).toBe(false)
      expect(isReachable('page')).toBe(false)
      expect(isReachable('anywhere')).toBe(true)
    })

    it('ignores the overlays of a page in the background', () => {
      renderOverlay({ coversApplication: true, isShown: false })

      expect(isReachable('application')).toBe(true)
      expect(isReachable('page')).toBe(true)
    })

    it('lets the navigation reach past the list of shortcuts, but not the page', () => {
      renderOverlay({ id: 'dialog-keyboard-shortcuts', coversApplication: true })

      expect(isReachable('application')).toBe(true)
      expect(isReachable('page')).toBe(false)
    })

    it('puts an overlay shown later on top of one mounted after it', async () => {
      const isViewerShown = ref(false)

      const viewer = renderOverlay({ id: 'image-viewer', isShown: isViewerShown })
      const sidePanel = renderOverlay({ id: 'flyout-some' })

      isViewerShown.value = true
      await nextTick()

      sidePanel.inside.focus()
      expect(isReachable('focus')).toBe(false)

      viewer.inside.focus()
      expect(isReachable('focus')).toBe(true)
    })

    it('reaches the focus only inside the overlay on top', () => {
      const lower = renderOverlay({ id: 'flyout-lower' })
      const upper = renderOverlay({ id: 'dialog-upper' })

      const outside = document.createElement('button')
      document.body.append(outside)

      upper.inside.focus()
      expect(isReachable('focus')).toBe(true)

      lower.inside.focus()
      expect(isReachable('focus')).toBe(false)

      outside.focus()
      expect(isReachable('focus')).toBe(false)

      outside.remove()
    })
  })

  describe('beforeRun', () => {
    const popover = (isOpen: boolean) =>
      ({
        isOpen: ref(isOpen),
        closePopover: vi.fn(),
      }) as unknown as CommonPopoverInternalInstance

    const { instances } = usePopoverInstances()

    afterEach(() => {
      instances.value.clear()
      vi.mocked(closeKeyboardShortcutsDialog).mockClear()
    })

    it('closes the list of shortcuts and the open popovers before a navigation', () => {
      const open = popover(true)
      const closed = popover(false)
      instances.value.add(open)
      instances.value.add(closed)

      beforeRun('overviews', 'application')

      expect(closeKeyboardShortcutsDialog).toHaveBeenCalledOnce()
      expect(open.closePopover).toHaveBeenCalledOnce()
      expect(closed.closePopover).not.toHaveBeenCalled()
    })

    it('closes the open popovers before a shortcut of the page', () => {
      const open = popover(true)
      instances.value.add(open)

      beforeRun('update-as-closed', 'page')

      expect(open.closePopover).toHaveBeenCalledOnce()
      expect(closeKeyboardShortcutsDialog).not.toHaveBeenCalled()
    })

    it('leaves the list of shortcuts to its own toggle', () => {
      beforeRun('list-of-shortcuts', 'application')

      expect(closeKeyboardShortcutsDialog).not.toHaveBeenCalled()
    })

    it('leaves the popovers to the shortcuts that toggle one', () => {
      const open = popover(true)
      instances.value.add(open)

      beforeRun('user-menu', 'application')
      beforeRun('notifications', 'application')

      expect(open.closePopover).not.toHaveBeenCalled()
    })

    it.each([
      ['submit-form', 'focus'],
      ['toggle-dark-mode', 'anywhere'],
    ] as const)('leaves everything open for %s, a %s shortcut', (key, reach) => {
      const open = popover(true)
      instances.value.add(open)

      beforeRun(key, reach)

      expect(open.closePopover).not.toHaveBeenCalled()
      expect(closeKeyboardShortcutsDialog).not.toHaveBeenCalled()
    })
  })
})
