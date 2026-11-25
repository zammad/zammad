// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

const TEXT_ENTRY_ELEMENTS = new Set(['INPUT', 'TEXTAREA', 'SELECT'])

const isContentEditable = (element: Element) => {
  if (element instanceof HTMLElement && element.isContentEditable) return true

  // jsdom does not implement `isContentEditable`.
  const attribute = element.getAttribute('contenteditable')

  return attribute !== null && attribute !== 'false'
}

export const isTextEntry = () => {
  const element = document.activeElement
  if (!element) return false

  return TEXT_ENTRY_ELEMENTS.has(element.nodeName) || isContentEditable(element)
}

let hasSelectionWhenShiftWasPressed = false

export const hasSelection = () => {
  if (hasSelectionWhenShiftWasPressed) return true

  return window.getSelection()?.type === 'Range'
}

// Also for a window that loses the focus while shift is held: the release goes to another one.
export const forgetSelectionOnShift = () => {
  hasSelectionWhenShiftWasPressed = false
}

// Mirrors the old view: a selection that existed when shift went down still counts while shift
//   is held, so extending or replacing it with shift held does not trigger a shortcut.
export const trackSelectionOnShift = (event: KeyboardEvent) => {
  if (event.key !== 'Shift') return

  if (event.type === 'keyup') {
    forgetSelectionOnShift()
    return
  }

  if (hasSelection()) hasSelectionWhenShiftWasPressed = true
}
