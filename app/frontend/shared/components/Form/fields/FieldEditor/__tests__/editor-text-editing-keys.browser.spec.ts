// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { userEvent } from 'vitest/browser'

import { findEditor, mountEditor } from './browser-utils.ts'

// The browser runs on Linux, where the old editor's block and clean-up keys use ctrl+shift.
const hotkey = (key: string) => `{Control>}{Shift>}${key}{/Shift}{/Control}`

const SELECT_ALL = '{Control>}a{/Control}'

const typeInEditor = async (keys: string, props: Record<string, unknown> = {}) => {
  await mountEditor(props)

  const editor = await findEditor()
  await editor.click()
  await userEvent.keyboard(keys)

  return editor
}

describe('editor text editing keys of the old desktop view', () => {
  it.each([
    ['bold', '{Control>}b{/Control}', 'strong'],
    ['italic', '{Control>}i{/Control}', 'em'],
    ['underlined', '{Control>}u{/Control}', 'u'],
    ['struck through', '{Control>}s{/Control}', 's'],
  ])('formats the selection as %s', async (_, keys, element) => {
    const editor = await typeInEditor(`Text${SELECT_ALL}${keys}`)

    await expect.element(editor.getByText('Text')).toBeInTheDocument()
    expect(editor.element().querySelector(element)).toHaveTextContent('Text')
  })

  it('keeps ctrl+s from the browser', async () => {
    await mountEditor()

    const editor = await findEditor()
    await editor.click()

    const handled: boolean[] = []
    const recordSave = (event: KeyboardEvent) => {
      if (event.key === 's' && event.ctrlKey) handled.push(event.defaultPrevented)
    }

    window.addEventListener('keydown', recordSave)
    await userEvent.keyboard('Text{Control>}s{/Control}')
    window.removeEventListener('keydown', recordSave)

    expect(handled).toEqual([true])
  })

  it.each([
    ['h1', hotkey('1')],
    ['h2', hotkey('2')],
    ['h3', hotkey('3')],
    ['ul', hotkey('l')],
    ['ol', hotkey('k')],
  ])('turns the line into %s', async (element, keys) => {
    const editor = await typeInEditor(`Text${keys}`)

    expect(editor.element().querySelector(element)).toHaveTextContent('Text')
  })

  it('inserts a horizontal rule, ahead of redo', async () => {
    const editor = await typeInEditor(`Text${hotkey('z')}`)

    expect(editor.element().querySelector('hr')).toBeInTheDocument()
    await expect.element(editor).toHaveTextContent('Text')
  })

  it('removes the formatting of the selection', async () => {
    const editor = await typeInEditor(`Text${SELECT_ALL}{Control>}b{/Control}${hotkey('f')}`)

    expect(editor.element().querySelector('strong')).not.toBeInTheDocument()
    await expect.element(editor).toHaveTextContent('Text')
  })

  it('removes the formatting of the whole text', async () => {
    const editor = await typeInEditor(hotkey('y'), {
      value: '<h1>Title</h1><p><strong>Bold</strong> and <em>italic</em></p>',
    })

    expect(editor.element().querySelector('h1, strong, em')).not.toBeInTheDocument()
    await expect.element(editor).toHaveTextContent('TitleBold and italic')
  })

  it('removes the hyperlink around the cursor', async () => {
    await mountEditor({ value: '<p><a href="https://zammad.org">Zammad</a></p>' })

    const editor = await findEditor()
    await editor.getByText('Zammad').click()
    await userEvent.keyboard(hotkey('x'))

    expect(editor.element().querySelector('a')).not.toBeInTheDocument()
    await expect.element(editor).toHaveTextContent('Zammad')
  })

  it('keeps ctrl+s from the browser also in code, where nothing can be struck through', async () => {
    await mountEditor({ value: '<pre><code>code</code></pre>' })

    const editor = await findEditor()
    await editor.getByText('code').click()

    const handled: boolean[] = []
    const recordSave = (event: KeyboardEvent) => {
      if (event.key === 's' && event.ctrlKey) handled.push(event.defaultPrevented)
    }

    window.addEventListener('keydown', recordSave)
    await userEvent.keyboard('{Control>}s{/Control}')
    window.removeEventListener('keydown', recordSave)

    expect(handled).toEqual([true])
  })

  it.each([
    ['ul', hotkey('l')],
    ['ol', hotkey('k')],
  ])('turns %s back into a paragraph', async (element, keys) => {
    const editor = await typeInEditor(`Text${keys}${keys}`)

    expect(editor.element().querySelector(element)).not.toBeInTheDocument()
    await expect.element(editor).toHaveTextContent('Text')
  })

  it('keeps the cursor in its text when removing the formatting of the whole text', async () => {
    await mountEditor({
      value: '<ul><li><p>One</p></li><li><p>Two</p></li></ul><p>Three</p>',
    })

    const editor = await findEditor()
    await editor.getByText('Two').click()
    await expect.poll(() => window.getSelection()?.anchorNode?.textContent).toBe('Two')

    await userEvent.keyboard(`${hotkey('y')}X`)

    const typedInto = Array.from(editor.element().querySelectorAll('p')).find((paragraph) =>
      paragraph.textContent?.includes('X'),
    )

    expect(editor.element().querySelector('ul')).not.toBeInTheDocument()
    expect(typedInto?.textContent?.replace('X', '')).toBe('Two')
  })
})
