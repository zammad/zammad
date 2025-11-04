// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils.ts'

describe('changes private value depending on content type', () => {
  it('has html content type by default', () => {
    mountEditor()

    cy.findByRole('textbox').type('some kind of text')

    cy.findByRole('textbox').shouldHaveNormalizedHtml('<p>some kind of text</p>')
  })

  it('has html content type, if prop is provided', () => {
    mountEditor({
      contentType: 'text/html',
    })

    cy.findByRole('textbox').type('some kind of text')
    cy.findByRole('textbox').shouldHaveNormalizedHtml('<p>some kind of text</p>')
  })

  it('has text content type, if prop is provided', () => {
    mountEditor({
      contentType: 'text/plain',
    })

    cy.findByRole('textbox').type('some kind of text')

    cy.findByRole('textbox').shouldHaveNormalizedHtml('<p>some kind of text</p>')
  })
})
