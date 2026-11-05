// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, it } from 'vitest'
import { userEvent } from 'vitest/browser'

import {
  editorHtml,
  findEditor,
  getEditorContext,
  MOVE_TO_END,
  mountEditor,
  moveCursorToStart,
} from './browser-utils.ts'

const html = String.raw

const BREAK_HTML = '<p dir="auto"><br class="ProseMirror-trailingBreak"></p>'
const ORIGINAL_TEXT = 'Some Original Text'

const SIGNATURE =
  '<strong>Signature</strong><div>Context</div><br>---<br><em>Phone: +1234556778</em>'

const PARSED_SIGNATURE =
  '<p dir="auto"><strong>Signature</strong></p><p dir="auto">Context</p><p dir="auto"><img class="ProseMirror-separator" alt=""><br dir="auto">---<em>Phone: +1234556778</em></p>'

const WRAPPED_SIGNATURE = (id: string, str: string) => {
  return `<div data-signature="true" dir="auto" class="signature" data-signature-id="${id}">${str}</div>`
}

describe('correctly adds signature', () => {
  it('add signature into an empty editor', async () => {
    await mountEditor()

    await findEditor()
    const context = await getEditorContext()

    await expect.poll(editorHtml).toBe(BREAK_HTML)

    context.addSignature({
      renderedBody: SIGNATURE,
      internalId: 1,
    })

    await expect
      .poll(editorHtml)
      .toBe(`${BREAK_HTML}${WRAPPED_SIGNATURE('1', PARSED_SIGNATURE)}${BREAK_HTML}`)

    context.removeSignature()

    await expect.poll(editorHtml).toContain(BREAK_HTML)
  })

  it('add bottom signature when content is already there', async () => {
    await mountEditor()

    await userEvent.type(await findEditor(), ORIGINAL_TEXT)

    const context = await getEditorContext()

    context.addSignature({
      renderedBody: SIGNATURE,
      internalId: 2,
    })

    await expect
      .poll(editorHtml)
      .toContain(
        `<p dir="auto">${ORIGINAL_TEXT}</p>${BREAK_HTML}${WRAPPED_SIGNATURE('2', PARSED_SIGNATURE)}${BREAK_HTML}`,
      )

    await userEvent.keyboard('new')

    // cursor didn't move
    await expect.poll(editorHtml).toContain(`<p dir="auto">${ORIGINAL_TEXT}new</p>`)

    context.removeSignature()

    await expect.poll(editorHtml).toContain(`<p dir="auto">${ORIGINAL_TEXT}new</p>${BREAK_HTML}`)
  })

  it('does not add extra blank line on remove+re-add cycle', async () => {
    await mountEditor()

    await userEvent.type(await findEditor(), ORIGINAL_TEXT)

    const context = await getEditorContext()

    const expectedHtml = `<p dir="auto">${ORIGINAL_TEXT}</p>${BREAK_HTML}${WRAPPED_SIGNATURE('4', PARSED_SIGNATURE)}${BREAK_HTML}`

    // First add
    context.addSignature({ renderedBody: SIGNATURE, internalId: 4 })

    await expect.poll(editorHtml).toBe(expectedHtml)

    // Remove (simulates switching to a group without a signature)
    context.removeSignature()

    // Re-add (simulates switching back to a group with a signature)
    context.addSignature({ renderedBody: SIGNATURE, internalId: 4 })

    // Must be identical to the first-add result — no extra blank line
    await expect.poll(editorHtml).toBe(expectedHtml)
  })

  it('add signature before marker', async () => {
    const originalBody = html`
      <p dir="auto" data-marker="signature-before"></p>
      <blockquote type="cite">
        <p dir="auto">Subject: Welcome to Zammad!</p>
      </blockquote>
    `

    await mountEditor({
      value: originalBody,
    })

    const editor = await findEditor()
    const context = await getEditorContext()

    context.addSignature({
      renderedBody: SIGNATURE,
      internalId: 3,
    })

    await expect.poll(editorHtml).toContain(`${BREAK_HTML}<div data-signature=`)
    await expect
      .poll(editorHtml)
      .toContain(
        '<p dir="auto" data-marker="signature-before"><br class="ProseMirror-trailingBreak"></p><blockquote dir="auto" ',
      )

    await moveCursorToStart(editor)
    await userEvent.keyboard('text')

    await expect.poll(editorHtml).toContain('<p dir="auto">text</p><div data-signature')

    context.removeSignature()

    await expect.poll(editorHtml).toContain('<p dir="auto">text</p><p dir="auto" data-marker=')
  })

  it('respects explicit position when upserting existing signature', async () => {
    await mountEditor()

    const editor = await findEditor()
    const context = await getEditorContext()

    context.addSignature({ renderedBody: SIGNATURE, internalId: 5 })

    await editor.click()
    await userEvent.keyboard(MOVE_TO_END)

    context.addSignature({ renderedBody: SIGNATURE, internalId: 5, position: 1 })

    await userEvent.keyboard('typed')

    await expect.poll(editorHtml).toContain('<p dir="auto">typed</p><div data-signature')
  })

  it('adds new top-level signature when quoted content already contains a signature', async () => {
    // Simulate replying to an email that already contains a signature in its quoted content.
    // The signature inside the blockquote must NOT prevent the new signature from being added.
    const originalBody = html`
      <p dir="auto" data-marker="signature-before"></p>
      <blockquote type="cite">
        <p dir="auto">Previous email content</p>
        <div data-signature="true" data-signature-id="1">Old Signature In Quote</div>
      </blockquote>
    `

    await mountEditor({
      value: originalBody,
    })

    await findEditor()
    const context = await getEditorContext()

    context.addSignature({
      renderedBody: SIGNATURE,
      internalId: 1,
    })

    // New signature should be added at the top level (before blockquote)
    await expect.poll(editorHtml).toContain(`${BREAK_HTML}<div data-signature=`)

    // Quoted content (including old signature inside) should be unchanged
    await expect.poll(editorHtml).toContain('<p dir="auto">Previous email content</p>')

    context.removeSignature()

    // After removeSignature, only the top-level signature is removed; blockquote content remains
    await expect.poll(editorHtml).toContain('<p dir="auto" data-marker="signature-before">')
    await expect.poll(editorHtml).toContain('<p dir="auto">Previous email content</p>')
  })
})
