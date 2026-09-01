// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils.ts'

const typeOrderedList = () => {
  mountEditor()

  cy.findByRole('textbox').click()
  cy.findByTestId('action-bar').findByLabelText('Add ordered list').click()

  cy.findByRole('listitem').type('First{enter}Middle{enter}Third{enter}Last')
}

// Turns the ordered list off for the item the cursor sits on, breaking the list in two.
const turnListOffFor = (item: string) => {
  cy.findByRole('textbox').contains(item).click()
  cy.findByTestId('action-bar').findByLabelText('Add ordered list').click()
}

describe('editor ordered list numbering', { retries: 2 }, () => {
  it('continues the numbering when the list is broken apart', () => {
    typeOrderedList()

    turnListOffFor('Third')

    // "First" and "Middle" keep 1 and 2, "Third" is no longer numbered, so "Last" becomes 3.
    cy.findByRole('textbox').find('ol').should('have.length', 2)
    cy.findByRole('textbox').find('ol').last().should('have.attr', 'start', '3')
    cy.findByRole('textbox').find('ol').first().should('not.have.attr', 'start')
  })

  it('restarts the numbering when the list is turned on again', () => {
    typeOrderedList()

    turnListOffFor('Third')
    cy.findByRole('textbox').find('ol').last().should('have.attr', 'start', '3')

    // Turning the list off and on again asks for a fresh count.
    turnListOffFor('Last')
    cy.findByRole('textbox').find('ol').should('have.length', 1)

    cy.findByRole('textbox').contains('Last').click()
    cy.findByTestId('action-bar').findByLabelText('Add ordered list').click()

    cy.findByRole('textbox').find('ol').should('have.length', 2)
    cy.findByRole('textbox').find('ol').last().should('not.have.attr', 'start')
  })
})
