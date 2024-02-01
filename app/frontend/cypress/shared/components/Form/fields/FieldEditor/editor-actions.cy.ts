// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils.ts'

const testAction = (
  action: string,
  expected: (text: string) => string,
  typeText = 'Something',
  hint = ' ',
) => {
  describe(`testing action - ${action}`, { retries: 2 }, () => {
    it(`${action}${hint} - enabled, text after is affected`, () => {
      mountEditor()
      cy.findByRole('textbox').click()
      cy.findByTestId('action-bar').findByLabelText(action).click()

      // It is unsafe to chain further commands that rely on the subject after `.type()`.
      //   https://docs.cypress.io/api/commands/type
      cy.findByRole('textbox').type(typeText)
      cy.findByRole('textbox').should('contain.html', expected(typeText))
    })

    it(`${action}${hint} - toggle text`, () => {
      mountEditor()

      cy.findByRole('textbox').type(`${typeText}{selectall}`)
      cy.findByTestId('action-bar').findByLabelText(action).click()
      cy.findByRole('textbox').should('contain.html', expected(typeText))
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

  testAction(
    'Add ordered list',
    () => `<ol><li><p>Something1</p></li><li><p>Something2</p></li></ol>`,
    'Something1{enter}Something2',
    ' (multiline)',
  )
  testAction(
    'Add bullet list',
    () => `<ul><li><p>Something1</p></li><li><p>Something2</p></li></ul>`,
    'Something1{enter}Something2',
    ' (multiline)',
  )

  describe('testing action - remove formatting', () => {
    it('removes formatting', () => {
      mountEditor()

      cy.findByRole('textbox').click()
      cy.findByTestId('action-bar').findByLabelText('Format as bold').click()
      cy.findByRole('textbox').type('Text')

      cy.findByRole('textbox').should(
        'have.html',
        '<p><strong>Text</strong></p>',
      )

      cy.findByRole('textbox').type('{selectall}')
      cy.findByTestId('action-bar').findByLabelText('Remove formatting').click()
      cy.findByRole('textbox').type('Text')
      cy.findByRole('textbox').should('have.html', '<p>Text</p>')
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
