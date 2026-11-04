// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { describe, expect, it } from 'vitest'

import { editorHtml, findEditor, mountEditor } from './browser-utils.ts'

const html = String.raw

const SIGNATURE_BODY = '<strong>Test Signature</strong>'

const signature = (internalId: number, renderedBody = SIGNATURE_BODY) => ({
  renderedBody,
  internalId,
})

const QUOTE_BODY = html`<blockquote type="cite" data-marker="signature-before">
  <p>Quoted message</p>
</blockquote>`

// Negative expectations would pass before the asynchronously loaded editor even exists.
const mountEditorAndWait = async (props: Record<string, unknown>) => {
  await mountEditor(props)
  await findEditor()
}

describe('editor signature reconciliation', () => {
  it('applies an already present signature on mount', async () => {
    // The editor may mount after the article form is already set up (async import,
    // late dialog rendering) - the signature props are then present at mount time.
    await mountEditorAndWait({ signatureEnabled: true, signature: signature(1) })

    await expect.poll(editorHtml).toContain('data-signature-id="1"')
  })

  it('applies a late arriving signature', async () => {
    await mountEditorAndWait({ signatureEnabled: true })

    await expect.poll(editorHtml).not.toContain('data-signature')

    getNode('editor')!.props.signature = signature(1)

    await expect.poll(editorHtml).toContain('data-signature-id="1"')
  })

  it('adds and removes the signature when the article type flag flips', async () => {
    await mountEditorAndWait({ signatureEnabled: false, signature: signature(1) })

    await expect.poll(editorHtml).not.toContain('data-signature')

    getNode('editor')!.props.signatureEnabled = true

    await expect.poll(editorHtml).toContain('data-signature-id="1"')

    getNode('editor')!.props.signatureEnabled = false

    await expect.poll(editorHtml).not.toContain('data-signature')
  })

  it('applies the signature again after an external content write replaced the document', async () => {
    await mountEditorAndWait({ signatureEnabled: true, signature: signature(1) })

    await expect.poll(editorHtml).toContain('data-signature-id="1"')

    // Simulates the reply/forward quote write, which replaces the whole document
    // and thereby destroys an already applied signature.
    getNode('editor')!.input(QUOTE_BODY, false)

    await expect.poll(editorHtml).toContain('Quoted message')
    await expect.poll(editorHtml).toContain('data-signature-id="1"')

    // The signature must sit before the full quote.
    await expect
      .poll(() => {
        const content = editorHtml()

        return content.indexOf('data-signature-id="1"') < content.indexOf('Quoted message')
      })
      .toBe(true)
  })

  it('applies the signature again after an external write cleared the document', async () => {
    // With the full quote disabled the reply form has no quote to write, so it writes an
    // empty body after the form settled - which used to wipe the applied signature (#733).
    await mountEditorAndWait({ signatureEnabled: true, signature: signature(1) })

    await expect.poll(editorHtml).toContain('data-signature-id="1"')

    getNode('editor')!.input('', false)

    await expect.poll(editorHtml).toContain('data-signature-id="1"')
  })

  it('does not re-apply the signature on a cleared document when the handling is disabled', async () => {
    // Article discard clears the article type before it resets the field values, so the
    // reset must not bring the signature back (which would leave the form dirty).
    await mountEditorAndWait({ signatureEnabled: true, signature: signature(1) })

    getNode('editor')!.props.signatureEnabled = false

    await expect.poll(editorHtml).not.toContain('data-signature')

    getNode('editor')!.input('', false)

    await expect.poll(editorHtml).not.toContain('data-signature')
  })

  it('never touches present signature nodes when the handling is not engaged', async () => {
    // E.g. article edit or note editors: content can contain a previously sent
    // signature, but without a declared signatureEnabled prop nothing is wired up.
    const contentWithSignature = html`<p>Some article content</p>
      <div data-signature="true" data-signature-id="9"><p>Sent signature</p></div>`

    await mountEditorAndWait({ value: contentWithSignature })

    await expect.poll(editorHtml).toContain('data-signature-id="9"')

    getNode('editor')!.input(`<p>Edited</p>${contentWithSignature}`, false)

    await expect.poll(editorHtml).toContain('<p dir="auto">Edited</p>')
    await expect.poll(editorHtml).toContain('data-signature-id="9"')
  })
})
