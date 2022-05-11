// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils'

describe('Testing "knowledge base" popup: "??" command', () => {
  // TODO change when api calls will be added
  it('inserts a text', () => {
    mountEditor()

    cy.findByRole('textbox').type('??')

    cy.findByTestId('mention-knowledge-base')
      .should('exist')
      .and('contain.text', 'Title1')
      .findByText('Title1')
      .click()

    cy.findByRole('textbox')
      .should('have.text', 'CONTENT')
      .type('{backspace}{backspace}')
      .should('have.text', 'CONTE')
  })

  it.skip('filters knowledge base by query')
})
