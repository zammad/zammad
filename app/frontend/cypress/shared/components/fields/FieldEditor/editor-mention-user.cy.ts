// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils'

describe('Testing "user mention" popup: "@@" command', () => {
  // TODO change when api calls will be added
  it('inserts a text', () => {
    mountEditor()

    cy.findByRole('textbox').type('@@')

    cy.findByTestId('mention-user')
      .should('exist')
      .and('contain.text', 'Bob Wance')
      .findByText(/Bob Wance/)
      .click()

    cy.findByRole('textbox')
      .should('have.text', 'Bob Wance')
      .type('{backspace}{backspace}{leftArrow}ndyke{rightArrow}{backspace}')
      .should('have.text', 'Bob Wandyke') // can rename user
      .then(($el) => {
        const link = $el.find('a')
        expect(link).to.have.text('Bob Wandyke')
        expect(link).to.have.attr('data-mention-user-id', '3')
        expect(link).to.have.attr(
          'href',
          `${window.location.origin}/#user/profile/3`,
        )
      })
  })

  it.skip('filters knowledge base by query')
})
