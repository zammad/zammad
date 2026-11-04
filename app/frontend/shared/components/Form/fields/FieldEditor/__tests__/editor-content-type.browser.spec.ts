// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { userEvent } from 'vitest/browser'

import { editorHtml, findEditor, mountEditor } from './browser-utils.ts'

describe('changes private value depending on content type', () => {
  it('has html content type by default', async () => {
    await mountEditor()

    await userEvent.type(await findEditor(), 'some kind of text')

    await expect.poll(editorHtml).toBe('<p dir="auto">some kind of text</p>')
  })

  it('has html content type, if prop is provided', async () => {
    await mountEditor({
      contentType: 'text/html',
    })

    await userEvent.type(await findEditor(), 'some kind of text')

    await expect.poll(editorHtml).toBe('<p dir="auto">some kind of text</p>')
  })

  it('has text content type, if prop is provided', async () => {
    await mountEditor({
      contentType: 'text/plain',
    })

    await userEvent.type(await findEditor(), 'some kind of text')

    await expect.poll(editorHtml).toBe('<p dir="auto">some kind of text</p>')
  })
})
