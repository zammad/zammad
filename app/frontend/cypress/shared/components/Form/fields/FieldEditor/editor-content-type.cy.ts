// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { mountEditor } from './utils'

describe('changes private value depending on content type', () => {
  it('has html content type by default', () => {
    mountEditor()

    cy.findByRole('textbox')
      .type('some kind of text')
      .then(() => {
        expect(getNode('editor')?._value).to.equal('<p>some kind of text</p>')
      })
  })

  it('has html content type, if prop is provided', () => {
    mountEditor({
      contentType: 'text/html',
    })

    cy.findByRole('textbox')
      .type('some kind of text')
      .then(() => {
        expect(getNode('editor')?._value).to.equal('<p>some kind of text</p>')
      })
  })

  it('has text content type, if prop is provided', () => {
    mountEditor({
      contentType: 'text/plain',
    })

    cy.findByRole('textbox')
      .type('some kind of text')
      .then(() => {
        expect(getNode('editor')?._value).to.equal('some kind of text')
      })
  })
})
