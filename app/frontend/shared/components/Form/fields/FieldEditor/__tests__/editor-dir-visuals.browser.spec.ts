// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { findEditor, mountEditor } from './browser-utils.ts'

const rtlWord = 'مرحبا'
const ltrWord = 'hello'

const setDefaultDir = (dir: 'ltr' | 'rtl') => {
  document.documentElement.setAttribute('dir', dir)
}

const typeWord = async (word: string) => {
  const view = await mountEditor()
  const editor = await findEditor()

  await userEvent.type(editor, word)

  return {
    editor: editor.element() as HTMLElement,
    field: page.elementLocator(view.container.querySelector('.formkit-outer')!),
  }
}

describe('editor handles dir automatically', () => {
  afterEach(() => setDefaultDir('ltr'))

  describe('when ltr is default', () => {
    beforeEach(() => setDefaultDir('ltr'))

    it('text is ltr', async () => {
      const { editor, field } = await typeWord(ltrWord)

      await expect.element(page.getByText(ltrWord)).toHaveAttribute('dir')
      // lose focus to hide the text cursor
      editor.blur()

      await expect.element(field).toMatchScreenshot('ltr-default-ltr-text')
    })

    it('text is rtl', async () => {
      const { editor, field } = await typeWord(rtlWord)

      await expect.element(page.getByText(rtlWord)).toHaveAttribute('dir', 'auto')
      // lose focus to hide the text cursor
      editor.blur()

      await expect.element(field).toMatchScreenshot('ltr-default-rtl-text')
    })
  })

  describe('when rtl is default', () => {
    beforeEach(() => setDefaultDir('rtl'))

    it('text is ltr', async () => {
      const { editor, field } = await typeWord(ltrWord)

      await expect.element(page.getByText(ltrWord)).toHaveAttribute('dir', 'auto')
      // lose focus to hide the text cursor
      editor.blur()

      await expect.element(field).toMatchScreenshot('rtl-default-ltr-text')
    })

    it('text is rtl', async () => {
      const { editor, field } = await typeWord(rtlWord)

      await expect.element(page.getByText(rtlWord)).toHaveAttribute('dir')
      // lose focus to hide the text cursor
      editor.blur()

      await expect.element(field).toMatchScreenshot('rtl-default-rtl-text')
    })
  })
})
