// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import { mountEditor } from './utils.ts'

const html = String.raw

const SIGNATURE_BODY = '<strong>Test Signature</strong>'

const signature = (internalId: number, renderedBody = SIGNATURE_BODY) => ({
  renderedBody,
  internalId,
})

const QUOTE_BODY = html`<blockquote type="cite" data-marker="signature-before">
  <p>Quoted message</p>
</blockquote>`

describe('editor signature reconciliation', { retries: 2 }, () => {
  it('applies an already present signature on mount', () => {
    // The editor may mount after the article form is already set up (async import,
    // late dialog rendering) - the signature props are then present at mount time.
    mountEditor({ signatureEnabled: true, signature: signature(1) })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('data-signature-id="1"')
    })
  })

  it('applies a late arriving signature', () => {
    mountEditor({ signatureEnabled: true })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).not.to.include('data-signature')
    })

    cy.then(() => {
      getNode('editor')!.props.signature = signature(1)
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('data-signature-id="1"')
    })
  })

  it('adds and removes the signature when the article type flag flips', () => {
    mountEditor({ signatureEnabled: false, signature: signature(1) })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).not.to.include('data-signature')
    })

    cy.then(() => {
      getNode('editor')!.props.signatureEnabled = true
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('data-signature-id="1"')
    })

    cy.then(() => {
      getNode('editor')!.props.signatureEnabled = false
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).not.to.include('data-signature')
    })
  })

  it('applies the signature again after an external content write replaced the document', () => {
    mountEditor({ signatureEnabled: true, signature: signature(1) })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('data-signature-id="1"')
    })

    // Simulates the reply/forward quote write, which replaces the whole document
    // and thereby destroys an already applied signature.
    cy.then(() => {
      getNode('editor')!.input(QUOTE_BODY, false)
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('Quoted message')
      expect($el.html()).to.include('data-signature-id="1"')
    })

    // The signature must sit before the full quote.
    cy.findByRole('textbox').should(($el) => {
      const content = $el.html()
      expect(content.indexOf('data-signature-id="1"')).to.be.lessThan(
        content.indexOf('Quoted message'),
      )
    })
  })

  it('applies the signature again after an external write cleared the document', () => {
    // With the full quote disabled the reply form has no quote to write, so it writes an
    // empty body after the form settled - which used to wipe the applied signature (#733).
    mountEditor({ signatureEnabled: true, signature: signature(1) })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('data-signature-id="1"')
    })

    cy.then(() => {
      getNode('editor')!.input('', false)
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('data-signature-id="1"')
    })
  })

  it('does not re-apply the signature on a cleared document when the handling is disabled', () => {
    // Article discard clears the article type before it resets the field values, so the
    // reset must not bring the signature back (which would leave the form dirty).
    mountEditor({ signatureEnabled: true, signature: signature(1) })

    cy.then(() => {
      getNode('editor')!.props.signatureEnabled = false
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).not.to.include('data-signature')
    })

    cy.then(() => {
      getNode('editor')!.input('', false)
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).not.to.include('data-signature')
    })
  })

  it('never touches present signature nodes when the handling is not engaged', () => {
    // E.g. article edit or note editors: content can contain a previously sent
    // signature, but without a declared signatureEnabled prop nothing is wired up.
    const contentWithSignature = html`<p>Some article content</p>
      <div data-signature="true" data-signature-id="9"><p>Sent signature</p></div>`

    mountEditor({ value: contentWithSignature })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('data-signature-id="9"')
    })

    cy.then(() => {
      getNode('editor')!.input(`<p>Edited</p>${contentWithSignature}`, false)
    })

    cy.findByRole('textbox').should(($el) => {
      expect($el.html()).to.include('<p dir="auto">Edited</p>')
      expect($el.html()).to.include('data-signature-id="9"')
    })
  })
})
