// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mountEditor } from './utils.ts'

const testAction = (
  action: string,
  expected: (text: string) => string,
  submenu?: string,
  typeText = 'Something',
  hint = ' ',
) => {
  describe(`testing action - ${action}`, { retries: 2 }, () => {
    it(`${action}${hint} - enabled, text after is affected`, () => {
      mountEditor()

      cy.findByRole('textbox').click()

      if (submenu) {
        cy.findByLabelText(submenu).click()
        cy.findByLabelText(action).click()
      } else {
        cy.findByTestId('action-bar').findByLabelText(action).click()
      }

      // It is unsafe to chain further commands that rely on the subject after `.type()`.
      //   https://docs.cypress.io/api/commands/type
      cy.findByRole('textbox').type(typeText)
      cy.findByRole('textbox').should('contain.html', expected(typeText))
    })

    it(`${action}${hint} - toggle text`, () => {
      mountEditor()

      cy.findByRole('textbox').type(`${typeText}{selectall}`)

      if (submenu) {
        cy.findByLabelText(submenu).click()
        cy.findByLabelText(action).click()
      } else {
        cy.findByTestId('action-bar').findByLabelText(action).click()
      }

      cy.findByRole('textbox').should('contain.html', expected(typeText))
    })
  })
}

const testTableAction = (
  actionLabel: string,
  {
    trCount,
    tdCount,
    thCount,
  }: { trCount: number; tdCount: number; thCount?: number },
) => {
  it(`table action - ${actionLabel}`, () => {
    mountEditor()

    cy.findByRole('textbox').click()

    cy.findByTestId('action-bar').findByLabelText('Insert table').click()

    cy.findByRole('table').find('td').first().click()
    cy.findByRole('table').find('td').first().click()

    cy.findByRole('region').should('exist')

    if (actionLabel === 'Merge cells') {
      cy.findByRole('table').find('td').selectText('left', 2)
    }

    if (actionLabel === 'Split cells') {
      cy.findByRole('table').find('td').selectText('left', 2)
      cy.findByLabelText('Merge cells').click({ force: true }) // can be out of viewport scrollable
    }

    cy.findByLabelText(actionLabel).click({ force: true }) // can be out of viewport scrollable

    cy.findByRole('table').find('td').should('have.length', tdCount)
    cy.findByRole('table').find('tr').should('have.length', trCount)

    if (thCount) {
      cy.findByRole('table').find('th').should('have.length', thCount)
    }
  })
}

// Some test examples in this suite may be flaky due to asynchronous nature of the editor typing mechanism.
//   Configure run mode to retry several times before giving up.
describe('testing actions', { retries: { runMode: 2 } }, () => {
  testAction('Format as underlined', (text) => `<u>${text}</u>`)
  testAction('Format as bold', (text) => `<strong>${text}</strong>`)
  testAction('Format as italic', (text) => `<em>${text}</em>`)
  testAction('Format as strikethrough', (text) => `<s>${text}</s>`)
  testAction(
    'Add first level heading',
    (text) => `<h1>${text}</h1>`,
    'Add heading',
  )
  testAction(
    'Add second level heading',
    (text) => `<h2>${text}</h2>`,
    'Add heading',
  )
  testAction(
    'Add third level heading',
    (text) => `<h3>${text}</h3>`,
    'Add heading',
  )
  testAction('Add ordered list', (text) => `<ol><li><p>${text}</p></li></ol>`)
  testAction('Add bullet list', (text) => `<ul><li><p>${text}</p></li></ul>`)

  testAction(
    'Add ordered list',
    () => `<ol><li><p>Something1</p></li><li><p>Something2</p></li></ol>`,
    undefined,
    'Something1{enter}Something2',
    ' (multiline)',
  )
  testAction(
    'Add bullet list',
    () => `<ul><li><p>Something1</p></li><li><p>Something2</p></li></ul>`,
    undefined,
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

  describe('table', () => {
    it('inserts a table', () => {
      mountEditor()

      cy.findByRole('textbox').click()
      cy.findByTestId('action-bar').findByLabelText('Insert table').click()

      cy.findByRole('table').should('exist')

      cy.findByRole('table').children().should('have.length', 2)

      cy.findByRole('table').find('td').first().type('Table text')

      cy.findByText('Table text').should('exist')

      cy.findByRole('table').find('tr').should('have.length', 3)
    })

    describe.only('actions', () => {
      testTableAction('Insert row above', { trCount: 4, tdCount: 9 })
      testTableAction('Insert row below', { trCount: 4, tdCount: 9 })
      testTableAction('Delete row', { trCount: 2, tdCount: 3 })
      testTableAction('Insert column before', { trCount: 3, tdCount: 8 })
      testTableAction('Insert column after', { trCount: 3, tdCount: 8 })
      testTableAction('Delete column', { trCount: 3, tdCount: 4 })

      testTableAction('Merge cells', { trCount: 3, tdCount: 6, th: 2 })
      testTableAction('Split cells', { trCount: 3, tdCount: 6, th: 3 })

      testTableAction('Toggle header row', { trCount: 3, tdCount: 9 })
      testTableAction('Toggle header column', {
        trCount: 3,
        tdCount: 4,
        thCount: 5,
      })
      testTableAction('Toggle header cell', {
        trCount: 3,
        tdCount: 5,
        thCount: 4,
      })

      it('table action - delete table', () => {
        mountEditor()

        cy.findByRole('textbox').click()
        cy.findByTestId('action-bar').findByLabelText('Insert table').click()

        cy.findByRole('table').should('exist')

        cy.findByRole('table').find('td').first().click()
        cy.findByRole('table').find('td').first().click()

        cy.findByRole('region').should('exist')

        cy.findByLabelText('Delete table').click({ force: true }) // can be out of viewport scrollable

        cy.findByRole('table').should('not.exist')
      })
    })
  })

  it('should insert code block', () => {
    mountEditor()

    cy.findByRole('textbox').click()
    cy.findByTestId('action-bar').findByLabelText('Insert code block').click()

    cy.findByRole('textbox').type('const vue = "awesome"')

    cy.findByRole('textbox').should(
      'have.html',
      '<pre><code>const <span class="hljs-attr">vue</span> = <span class="hljs-string">"awesome"</span></code></pre>',
    )
  })

  it('indents list item', () => {
    mountEditor()

    cy.findByRole('textbox').click()
    cy.findByTestId('action-bar').findByLabelText('Add bullet list').click()

    cy.findByRole('textbox').type('First{enter}Second{enter}Third')

    cy.findByLabelText('Indent text').click()

    cy.findByRole('textbox').should(
      'contain.html',
      '<li style="margin-left: 1rem"><p>Third</p></li>',
    )

    cy.findByLabelText('Indent text').click()
    cy.findByRole('textbox').should(
      'contain.html',
      '<li style="margin-left: 2rem"><p>Third</p></li>',
    )
  })

  it('outdents list item', () => {
    mountEditor()

    cy.findByRole('textbox').click()
    cy.findByTestId('action-bar').findByLabelText('Add bullet list').click()

    cy.findByRole('textbox').type('First{enter}Second{enter}Third')

    cy.findByLabelText('Indent text').click()

    cy.findByRole('textbox').should(
      'contain.html',
      '<li style="margin-left: 1rem"><p>Third</p></li>',
    )

    cy.findByLabelText('Outdent text').click()
    cy.findByRole('textbox').should('contain.html', '<li><p>Third</p></li>')
  })

  it('changes text color of item', () => {
    mountEditor()

    cy.findByRole('textbox').type('world')
    cy.findByRole('textbox').selectText('left', 5)

    cy.findByTestId('action-bar').findByLabelText('Change text color').click()

    cy.findByLabelText('Monza').click()
    cy.findByRole('textbox').should(
      'contain.html',
      '<span style="color: #B00020">world</span>',
    )
  })
})
