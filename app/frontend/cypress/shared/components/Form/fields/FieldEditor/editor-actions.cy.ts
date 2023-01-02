// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils'

const testAction = (action: string, expected: (text: string) => string) => {
  describe(`testing action - ${action}`, { retries: 2 }, () => {
    it(`${action} - enabled, text after is affected`, () => {
      mountEditor()
      cy.findByRole('textbox').click()
      cy.findByTestId('action-bar').findByLabelText(action).click()
      cy.findByRole('textbox')
        .type('Something')
        .should('contain.html', expected('Something'))
    })

    it(`${action} - toggle text`, () => {
      mountEditor()
      cy.findByRole('textbox')
        .type('Something{selectall}')
        .should('have.html', '<p>Something</p>')
      cy.findByTestId('action-bar').findByLabelText(action).click()
      cy.findByRole('textbox').should('contain.html', expected('Something'))
    })
  })
}

describe('testing actions', () => {
  testAction('Format as underlined', (text) => `<u>${text}</u>`)
  testAction('Format as bold', (text) => `<strong>${text}</strong>`)
  testAction('Format as italic', (text) => `<em>${text}</em>`)
  testAction('Format as strikethrough', (text) => `<s>${text}</s>`)
  testAction('Add first level heading', (text) => `<h1>${text}</h1>`)
  testAction('Add second level heading', (text) => `<h2>${text}</h2>`)
  testAction('Add third level heading', (text) => `<h3>${text}</h3>`)
  testAction('Add ordered list', (text) => `<ol><li><p>${text}</p></li></ol>`)
  testAction('Add bullet list', (text) => `<ul><li><p>${text}</p></li></ul>`)

  describe('testing action - remove formatting', () => {
    it('removes formatting', () => {
      mountEditor()
      cy.findByRole('textbox').click()
      cy.findByTestId('action-bar').findByLabelText('Format as bold').click()
      cy.findByRole('textbox')
        .type('Text')
        .should('have.html', '<p><strong>Text</strong></p>')
        .type('{selectall}')
      cy.findByTestId('action-bar').findByLabelText('Remove formatting').click()
      cy.findByRole('textbox').type('Text').should('have.html', '<p>Text</p>')
    })
  })

  it('adds a link', () => {
    cy.window().then((win) => {
      cy.stub(win, 'prompt').returns('https://example.com')
      mountEditor()
      cy.findByRole('textbox').click()
      cy.findByTestId('action-bar').findByLabelText('Add link').click()
      cy.findByRole('textbox')
        .find('a')
        .should('have.attr', 'href', 'https://example.com')
        .should('have.text', 'https://example.com')
    })
  })

  it('makes text into a link', () => {
    cy.window().then((win) => {
      cy.stub(win, 'prompt').returns('https://example.com')
      mountEditor()
      cy.findByRole('textbox').click().type('Text{selectAll}')
      cy.findByTestId('action-bar').findByLabelText('Add link').click()
      cy.findByRole('textbox')
        .find('a')
        .should('have.attr', 'href', 'https://example.com')
        .should('have.text', 'Text')
    })
  })

  it('inline image', () => {
    mountEditor()

    const imageBuffer = Cypress.Buffer.from('some image')

    cy.findByRole('textbox').click()
    cy.findByTestId('action-bar')
      .findByLabelText('Add image')
      .click() // click inserts input into DOM
      .then(() => {
        cy.findByTestId('editor-image-input').selectFile(
          {
            contents: imageBuffer,
            fileName: 'file.png',
            mimeType: 'image/png',
            lastModified: Date.now(),
          },
          { force: true },
        )
      })

    cy.findByRole('textbox')
      .find('img')
      .should(
        'have.attr',
        'src',
        `data:image/png;base64,${btoa(imageBuffer.toString())}`,
      )
  })
})
