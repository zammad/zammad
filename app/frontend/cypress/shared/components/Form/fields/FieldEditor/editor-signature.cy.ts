// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import type { FieldEditorContext } from '@shared/components/Form/fields/FieldEditor/types'
import { mountEditor } from './utils'

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
  it('add signature when there is a full quote there', () => {
    const quote = '<blockquote data-full="true"><p>Some Quote</p></blockquote>'
    mountEditor({
      value: `<p></p>${quote}`,
    })

    cy.findByRole('textbox')
      .then(resolveContext)
      .then((context) => {
        context.addSignature({
          body: SIGNATURE,
          id: 3,
        })
        cy.findByRole('textbox')
          .should(
            'have.html',
            `${BREAK_HTML}${WRAPPED_SIGNATURE(
              '3',
              `${PARSED_SIGNATURE}${BREAK_HTML}`,
            )}${quote}`,
          )
          .type('new')
          .should('include.html', `<p>new</p><div data-signature`) // cursor didn't move
          .then(() => {
            context.removeSignature()
            cy.findByRole('textbox')
              .should('include.html', `<p>new</p>`)
              .and('include.html', quote)
          })
      })
  })
})
