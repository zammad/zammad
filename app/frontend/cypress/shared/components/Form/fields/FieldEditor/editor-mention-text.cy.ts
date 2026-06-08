// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { TextModuleSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditor } from './utils.ts'

describe('Testing "text" popup: "::" command', () => {
  it('inserts a text', () => {
    const client = mockApolloClient()
    const mock = cy.spy(async () => ({
      data: {
        textModuleSuggestions: [
          {
            __typename: 'TextModule',
            id: convertToGraphQLId('TextModule', '1'),
            name: 'ass - Anliegen sichten',
            keywords: null,
            renderedContent:
              '<p dir="auto">Vielen Dank für Ihre Anfrage.</p><p dir="auto">Wir werden Ihr Anliegen sichten und uns schnellstmöglich mit Ihnen in Verbindung setzen.</p>',
          },
        ],
      },
    }))

    client.setRequestHandler(TextModuleSuggestionsDocument, mock)

    mountEditor({}, ['ticket.agent'], { fqdn: 'example.zammad.com', http_type: 'http' })

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
      '<p dir="auto">Vielen Dank für Ihre Anfrage.</p><p dir="auto">Wir werden Ihr Anliegen sichten und uns schnellstmöglich mit Ihnen in Verbindung setze123</p>',
    )

    // asserting with `calledWith` is stricter than needed and can fail on unrelated payload expansion.
    // Prefer `calledWithMatch` to lock only the relevant fields.
    cy.wrap(mock).should('have.been.calledWithMatch', { query: 'ass' })
  })
})
