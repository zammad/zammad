// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils'

describe('Testing "text" popup: "::" command', () => {
  // TODO change when api calls will be added
  it('inserts a text', () => {
    mountEditor()

    cy.findByRole('textbox').type('::')

    cy.findByTestId('mention-text')
      .should('exist')
      .and('contain.text', 'MySnap')
      .findByText('MySnap')
      .click()

    cy.findByRole('textbox')
      .should('have.text', 'Hello Mrs. name - query ""')
      .type('{backspace}{backspace}')
      .should('have.text', 'Hello Mrs. name - query ')
  })

  it.skip('filters text by query')
})
