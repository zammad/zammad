// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils'

describe('FieldEditor basic functionality', { retries: 2 }, () => {
  it('typing works, text becomes bold, when "B" is clicked', () => {
    mountEditor()

    cy.findByRole('textbox')
      .click()
      .then(() => {
        cy.findByTestId('action-bar').should('be.visible')
      })
      .type('Hello, World!{selectall}')
      .then(() => {
        cy.findByLabelText('Format as bold')
          .click()
          .should('have.class', '!bg-gray-300')
          .then(() => {
            cy.findByTestId('action-bar').should('be.visible') // should not dissapear on click
          })

        cy.findByRole('textbox').within((editor) => {
          expect(editor.find('strong')).to.have.text('Hello, World!')
        })
      })
      .then(() => {
        cy.findByTestId('action-bar').should('be.visible')
        cy.get('body').click(400, 400, { force: true })
        cy.findByTestId('action-bar').should('not.be.visible')
      })
  })

  it('text is italic (or any other style) from the start', () => {
    mountEditor()

    cy.findByRole('textbox').click()
    cy.findByTestId('action-bar').findByLabelText('Format as italic').click()
    cy.findByRole('textbox')
      .type('Hello, World!')
      .within((editor) => {
        expect(editor.find('em')).to.have.text('Hello, World!')
      })
      .selectText('left', 2)
      .findByLabelText('Format as italic')
      .click()
      .then(() => {
        cy.findByRole('textbox').within((editor) => {
          expect(editor.find('em')).to.have.text('Hello, Worl')
        })
      })
  })

  it('has content when it is provided', () => {
    mountEditor({
      value: '<strong>Hello, World!</strong>',
    })

    cy.findByRole('textbox')
      .should('have.text', 'Hello, World!')
      .and('have.html', '<p><strong>Hello, World!</strong></p>')
  })

  it('pasting images inlines them', () => {
    mountEditor()

    cy.findByRole('textbox')
      .type('He')
      .selectText('left', 2)
      .then(() => {
        cy.findByTestId('action-bar')
          .findByLabelText('Format as italic')
          .click()
      })

    cy.findByRole('textbox')
      .type('{rightarrow}') // removing selection from realPress
      .paste({
        files: [new File(['0', '1'], 'name.jpeg', { type: 'image/jpeg' })],
      })
      .find('img')
      .should('have.attr', 'src', 'data:image/jpeg;base64,MDE=')
  })
})
