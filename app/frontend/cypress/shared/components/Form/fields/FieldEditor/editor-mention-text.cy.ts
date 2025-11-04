// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { TextModuleSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditor } from './utils.ts'

describe('Testing "text" popup: "::" command', { retries: 2 }, () => {
  it('inserts a text', () => {
    const client = mockApolloClient()
    client.setRequestHandler(TextModuleSuggestionsDocument, async () => ({
      data: {
        textModuleSuggestions: [
          {
            __typename: 'TextModule',
            id: convertToGraphQLId('TextModule', '1'),
            name: 'ass - Anliegen sichten',
            keywords: null,
            renderedContent:
              '<p>Vielen Dank für Ihre Anfrage.</p><p>Wir werden Ihr Anliegen sichten und uns schnellstmöglich mit Ihnen in Verbindung setzen.</p>',
          },
        ],
      },
    }))

    mountEditor({}, ['ticket.agent'])

    cy.findByRole('textbox').type('::ass')

    cy.findByTestId('mention-text')
      .should('exist')
      .and('contain.text', 'Anliegen sichten')
      .findByText(/Anliegen sichten/)
      .click()

    cy.findByRole('textbox').shouldContainNormalizedHtml('Vielen Dank für Ihre Anfrage')
    cy.findByRole('textbox').type('{backspace}{backspace}123')
    cy.findByRole('textbox').shouldContainNormalizedHtml('Verbindung setze123')
    cy.findByRole('textbox').shouldContainNormalizedHtml(
      '<p>Vielen Dank für Ihre Anfrage.</p><p>Wir werden Ihr Anliegen sichten und uns schnellstmöglich mit Ihnen in Verbindung setze123</p>',
    )
  })
})
