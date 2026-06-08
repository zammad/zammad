// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'

import { mountEditor } from './utils.ts'

const html = String.raw

const getContext = () => getNode('editor')?.context as FieldEditorContext | undefined

const resolveContext = () => {
  return new Promise<Required<FieldEditorContext>>((resolve, reject) => {
    const start = Date.now()
    const max = start + 1000
    const interval = setInterval(() => {
      const context = getContext()
      if (context && '_loaded' in context) {
        resolve(context as any)
        clearInterval(interval)
      }
      if (max < Date.now()) {
        clearInterval(interval)
        reject(new Error('timeout'))
      }
    }, 50)
  })
}

const BREAK_HTML = '<p dir="auto"><br class="ProseMirror-trailingBreak"></p>'
const ORIGINAL_TEXT = 'Some Original Text'

const SIGNATURE =
  '<strong>Signature</strong><div>Context</div><br>---<br><em>Phone: +1234556778</em>'

const PARSED_SIGNATURE =
  '<p dir="auto"><strong>Signature</strong></p><p dir="auto">Context</p><p dir="auto"><br dir="auto">---<em>Phone: +1234556778</em></p>'

const WRAPPED_SIGNATURE = (id: string, str: string) => {
  return `<div data-signature="true" dir="auto" class="signature" data-signature-id="${id}">${str}</div>`
}

const resolveEditor = (props: any = {}) => {
  return mountEditor(props).then(() => resolveContext())
}

describe('correctly adds signature', { retries: 2 }, () => {
  it('add signature into an empty editor', () => {
    resolveEditor().then((context) => {
      cy.findByRole('textbox')
        .shouldHaveNormalizedHtml(`${BREAK_HTML}`)
        .then(() => {
          context.addSignature({
            renderedBody: SIGNATURE,
            internalId: 1,
          })
          cy.findByRole('textbox')
            .shouldHaveNormalizedHtml(
              `${BREAK_HTML}${WRAPPED_SIGNATURE('1', PARSED_SIGNATURE)}${BREAK_HTML}`,
            )
            .then(() => {
              context.removeSignature()
              cy.findByRole('textbox').shouldContainNormalizedHtml(`${BREAK_HTML}`)
            })
        })
    })
  })

  it('add bottom signature when content is already there', () => {
    mountEditor()

    cy.findByRole('textbox').type(ORIGINAL_TEXT)

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.addSignature({
          renderedBody: SIGNATURE,
          internalId: 2,
        })
        cy.findByRole('textbox').shouldContainNormalizedHtml(
          `<p dir="auto">${ORIGINAL_TEXT}</p>${BREAK_HTML}${WRAPPED_SIGNATURE(
            '2',
            `${PARSED_SIGNATURE}`,
          )}${BREAK_HTML}`,
        )
        cy.findByRole('textbox').type('new')

        cy.findByRole('textbox')
          .shouldContainNormalizedHtml(`<p dir="auto">${ORIGINAL_TEXT}new</p>`) // cursor didn't move
          .then(() => {
            context.removeSignature()
            cy.findByRole('textbox').shouldContainNormalizedHtml(
              `<p dir="auto">${ORIGINAL_TEXT}new</p>${BREAK_HTML}`,
            )
          })
      })
  })

  it('does not add extra blank line on remove+re-add cycle', () => {
    mountEditor()

    cy.findByRole('textbox').type(ORIGINAL_TEXT)

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        // First add
        context.addSignature({ renderedBody: SIGNATURE, internalId: 4 })

        cy.findByRole('textbox')
          .shouldHaveNormalizedHtml(
            `<p dir="auto">${ORIGINAL_TEXT}</p>${BREAK_HTML}${WRAPPED_SIGNATURE('4', PARSED_SIGNATURE)}${BREAK_HTML}`,
          )
          .then(() => {
            // Remove (simulates switching to a group without a signature)
            context.removeSignature()

            // Re-add (simulates switching back to a group with a signature)
            context.addSignature({ renderedBody: SIGNATURE, internalId: 4 })

            // Must be identical to the first-add result — no extra blank line
            cy.findByRole('textbox').shouldHaveNormalizedHtml(
              `<p dir="auto">${ORIGINAL_TEXT}</p>${BREAK_HTML}${WRAPPED_SIGNATURE('4', PARSED_SIGNATURE)}${BREAK_HTML}`,
            )
          })
      })
  })

  it('add signature before marker', () => {
    const originalBody = html`
      <p dir="auto" data-marker="signature-before"></p>
      <blockquote type="cite">
        <p dir="auto">Subject: Welcome to Zammad!</p>
      </blockquote>
    `

    mountEditor({
      value: originalBody,
    })

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.addSignature({
          renderedBody: SIGNATURE,
          internalId: 3,
        })
      })

    cy.findByRole('textbox').shouldContainNormalizedHtml(`${BREAK_HTML}<div data-signature=`)
    cy.findByRole('textbox').shouldContainNormalizedHtml(
      '<p dir="auto" data-marker="signature-before"><br class="ProseMirror-trailingBreak"></p><blockquote dir="auto" ',
    )
    cy.findByRole('textbox').type('{moveToStart}text')

    cy.findByRole('textbox').shouldContainNormalizedHtml(
      '<p dir="auto">text</p><div data-signature',
    )
    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.removeSignature()
      })

    cy.findByRole('textbox').shouldContainNormalizedHtml(
      `<p dir="auto">text</p><p dir="auto" data-marker=`,
    )
  })

  it('respects explicit position when upserting existing signature', () => {
    mountEditor()

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.addSignature({ renderedBody: SIGNATURE, internalId: 5 })
      })

    cy.findByRole('textbox').click().type('{moveToEnd}')

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.addSignature({ renderedBody: SIGNATURE, internalId: 5, position: 1 })
      })

    cy.findByRole('textbox').type('typed')

    cy.findByRole('textbox').shouldContainNormalizedHtml(
      '<p dir="auto">typed</p><div data-signature',
    )
  })

  it('adds new top-level signature when quoted content already contains a signature', () => {
    // Simulate replying to an email that already contains a signature in its quoted content.
    // The signature inside the blockquote must NOT prevent the new signature from being added.
    const originalBody = html`
      <p dir="auto" data-marker="signature-before"></p>
      <blockquote type="cite">
        <p dir="auto">Previous email content</p>
        <div data-signature="true" data-signature-id="1">Old Signature In Quote</div>
      </blockquote>
    `

    mountEditor({
      value: originalBody,
    })

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.addSignature({
          renderedBody: SIGNATURE,
          internalId: 1,
        })
      })

    // New signature should be added at the top level (before blockquote)
    cy.findByRole('textbox').shouldContainNormalizedHtml(`${BREAK_HTML}<div data-signature=`)

    // Quoted content (including old signature inside) should be unchanged
    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">Previous email content</p>')

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.removeSignature()
      })

    // After removeSignature, only the top-level signature is removed; blockquote content remains
    cy.findByRole('textbox').shouldContainNormalizedHtml(
      '<p dir="auto" data-marker="signature-before">',
    )
    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">Previous email content</p>')
  })
})
