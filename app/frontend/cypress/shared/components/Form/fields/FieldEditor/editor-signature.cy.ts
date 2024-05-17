// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'

import { mountEditor } from './utils.ts'

const html = String.raw

const getContext = () =>
  getNode('editor')?.context as FieldEditorContext | undefined

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

const BREAK_HTML = '<p><br class="ProseMirror-trailingBreak"></p>'
const ORIGINAL_TEXT = 'Some Original Text'

const SIGNATURE =
  '<strong>Signature</strong><div>Context</div><br>---<br><em>Phone: +1234556778</em>'

const PARSED_SIGNATURE =
  '<strong><p>Signature</p></strong><p>Context</p><p><br>---<br><em>Phone: +1234556778</em></p>'

const WRAPPED_SIGNATURE = (id: string, str: string) => {
  return `<div data-signature="true" class="signature" data-signature-id="${id}">${str}</div>`
}

const resolveEditor = (props: any = {}) => {
  return mountEditor(props).then(() => resolveContext())
}

describe('correctly adds signature', () => {
  it('add signature into an empty editor', () => {
    resolveEditor().then((context) => {
      context.addSignature({
        body: SIGNATURE,
        id: 1,
      })
      cy.findByRole('textbox')
        .should(
          'have.html',
          `${BREAK_HTML}${BREAK_HTML}${WRAPPED_SIGNATURE(
            '1',
            PARSED_SIGNATURE,
          )}`,
        )
        .then(() => {
          context.removeSignature()
          cy.findByRole('textbox').should('have.html', BREAK_HTML)
        })
    })
  })

  it('add bottom signature when content is already there', () => {
    mountEditor()

    cy.findByRole('textbox')
      .type(ORIGINAL_TEXT)
      .then(resolveContext)
      .then((context) => {
        context.addSignature({
          body: SIGNATURE,
          id: 2,
        })
        cy.findByRole('textbox')
          .should(
            'have.html',
            `<p>${ORIGINAL_TEXT}</p>${BREAK_HTML}${WRAPPED_SIGNATURE(
              '2',
              `${PARSED_SIGNATURE}`,
            )}`,
          )
          .type('new')
          .should('include.html', `<p>${ORIGINAL_TEXT}new</p>`) // cursor didn't move
          .then(() => {
            context.removeSignature()
            cy.findByRole('textbox').should(
              'have.html',
              `<p>${ORIGINAL_TEXT}new</p>`,
            )
          })
      })
  })

  it('add signature before marker', () => {
    const originalBody = html`<p data-marker="signature-before"></p>
      <blockquote type="cite">
        <p>Subject: Welcome to Zammad!</p>
      </blockquote>`

    mountEditor({
      value: originalBody,
    })

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.addSignature({
          body: SIGNATURE,
          id: 3,
        })
      })

    cy.findByRole('textbox')
      .should('contain.html', `${BREAK_HTML}<div data-signature=`)
      .should(
        'contain.html',
        '<p data-marker="signature-before"><br class="ProseMirror-trailingBreak"></p><blockquote ',
      )
      .type('{moveToStart}text')

    cy.findByRole('textbox')
      .should('contain.html', '<p>text</p><div data-signature')
      .then(resolveContext)
      .then((context) => {
        context.removeSignature()
      })

    cy.findByRole('textbox').should(
      'contain.html',
      `<p>text</p><p data-marker=`,
    )
  })
})
