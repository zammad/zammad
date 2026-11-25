// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { userEvent } from 'vitest/browser'

import { findEditor, mountEditor } from './browser-utils.ts'

// ProseMirror keeps a trailing break of its own in an empty last line.
const LINE_BREAK = 'br:not(.ProseMirror-trailingBreak)'

// Stands in for the page's submit shortcut: takes the presses handed on to it.
const takeHandedOnPresses = () => {
  const presses: KeyboardEvent[] = []

  const takePress = (event: KeyboardEvent) => {
    if (event.key !== 'Enter' || !event.ctrlKey || event.defaultPrevented) return

    presses.push(event)
    event.preventDefault()
  }

  window.addEventListener('keydown', takePress)

  return { presses, stop: () => window.removeEventListener('keydown', takePress) }
}

describe('editor submit keys', () => {
  it.each([
    ['plain', { contentType: 'text/plain' }],
    ['rich', {}],
    ['basic', { extensionSet: 'basic' }],
    ['reduced', { extensionSet: 'reduced' }],
  ])('hands ctrl+enter on to the page from the %s editor', async (_, props) => {
    await mountEditor(props)

    const editor = await findEditor()
    await editor.click()

    const { presses, stop } = takeHandedOnPresses()

    await userEvent.keyboard('One{Control>}{Enter}{/Control}Two')

    stop()

    expect(presses.map((press) => press.repeat)).toEqual([false])
    expect(editor.element().querySelectorAll(LINE_BREAK)).toHaveLength(0)
    await expect.element(editor).toHaveTextContent('OneTwo')
  })

  it('marks the presses of a held ctrl+enter as repeated', async () => {
    await mountEditor()

    const editor = await findEditor()
    await editor.click()

    const { presses, stop } = takeHandedOnPresses()

    await userEvent.keyboard('{Control>}{Enter>3}{/Enter}{/Control}')

    stop()

    expect(presses.map((press) => press.repeat)).toEqual([false, true, true])
  })

  it('leaves ctrl+enter to the editor while the page does not take it', async () => {
    await mountEditor()

    const editor = await findEditor()
    await editor.click()

    await userEvent.keyboard('One{Control>}{Enter}{/Control}Two')

    expect(editor.element().querySelectorAll(LINE_BREAK)).toHaveLength(1)
  })

  it('still breaks the line with shift+enter', async () => {
    await mountEditor()

    const editor = await findEditor()
    await editor.click()

    await userEvent.keyboard('One{Shift>}{Enter}{/Shift}Two')

    expect(editor.element().querySelectorAll(LINE_BREAK)).toHaveLength(1)
  })
})
