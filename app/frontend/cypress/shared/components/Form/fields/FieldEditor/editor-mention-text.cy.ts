// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '@cy/utils'
import { TextModuleSuggestionsDocument } from '@shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.api'
import { mountEditor } from './utils'

describe('Testing "text" popup: "::" command', { retries: 2 }, () => {
  it('inserts a text', () => {
    const client = mockApolloClient()
    client.setRequestHandler(TextModuleSuggestionsDocument, async () => ({
      data: {
        textModuleSuggestions: [
          {
            __typename: 'TextModule',
            id: btoa('ass - Anliegen sichten'),
            name: 'ass - Anliegen sichten',
            keywords: null,
            renderedContent:
              '<p>Vielen Dank für Ihre Anfrage.</p><p>Wir werden Ihr Anliegen sichten und uns schnellstmöglich mit Ihnen in Verbindung setzen.</p>',
          },
        ],
      },
    }))

    mountEditor()

    cy.findByRole('textbox').type('::ass')

    cy.findByTestId('mention-text')
      .should('exist')
      .and('contain.text', 'Anliegen sichten')
      .findByText(/Anliegen sichten/)
      .click()

    cy.findByRole('textbox')
      .should('include.text', 'Vielen Dank für Ihre Anfrage')
      .type('{backspace}{backspace}123')
      .should('include.text', 'Verbindung setze123')
      .should(
        'include.html',
        '<p>Vielen Dank für Ihre Anfrage.</p><p>Wir werden Ihr Anliegen sichten und uns schnellstmöglich mit Ihnen in Verbindung setze123</p>',
      )
  })
})
