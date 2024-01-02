// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils.ts'

describe('displays footer information', () => {
  it("doesn't display footer by default", () => {
    mountEditor()

    cy.findByTestId('editor-footer').should('not.exist')
  })

  it("doesn't display footer, if footer if disabled", () => {
    mountEditor({
      contentType: 'text/plain',
      meta: {
        footer: {
          disabled: true,
          text: '/AB',
        },
      },
    })

    // doesn't exist before async editor initialization
    cy.findByTestId('editor-footer').should('not.exist')
    cy.findByText('/AB').should('not.exist')

    // doesn't exist after async editor initialization
    cy.findByRole('textbox').then(() => {
      cy.findByTestId('editor-footer').should('not.exist')
      cy.findByText('/AB').should('not.exist')
    })
  })

  it('displays footer, if footer text is provided', () => {
    mountEditor({
      contentType: 'text/plain',
      meta: {
        footer: {
          text: '/AB',
        },
      },
    })

    // exists before async editor initialization
    cy.findByTestId('editor-footer').should('exist')
    cy.findByText('/AB').should('exist')

    // exists after async editor initialization
    cy.findByRole('textbox').then(() => {
      cy.findByTestId('editor-footer').should('exist')
      cy.findByText('/AB').should('exist')
    })
  })

  it('renders counter that decrements', () => {
    mountEditor({
      contentType: 'text/plain',
      meta: {
        footer: {
          text: '/AB',
          maxlength: 10,
          warningLength: 5,
        },
      },
    })

    cy.findByTestId('editor-footer').should('exist')
    cy.findByText('/AB').should('exist')
    cy.findByTitle('Available characters').should('have.text', '10')

    cy.findByRole('textbox').then(() => {
      cy.findByTestId('editor-footer').should('exist')
      cy.findByText('/AB').should('exist')
      cy.findByTitle('Available characters').should('have.text', '10')
    })

    cy.findByRole('textbox')
      .type('123456789')
      .then(() => {
        cy.findByTitle('Available characters')
          .should('have.text', '1')
          .and('have.class', 'text-orange')
      })
    cy.findByRole('textbox')
      .type('\n\n\n4567')
      .then(() => {
        cy.findByTitle('Available characters')
          .should('have.text', '-6')
          .and('have.class', 'text-red')
      })
  })
})
