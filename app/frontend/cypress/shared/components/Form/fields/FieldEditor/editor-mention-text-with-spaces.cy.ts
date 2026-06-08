// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { TextModuleSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditor } from './utils.ts'

describe('Testing "text" popup: "::" command', () => {
  before(() => {
    mountEditor({}, ['ticket.agent'])
  })

  it('inserts a text > allows spaces in search', () => {
    const client = mockApolloClient()
    const mock = cy.spy(async () => ({
      data: {
        textModuleSuggestions: [
          {
            __typename: 'TextModule',
            id: convertToGraphQLId('TextModule', '2'),
            name: 'fwf - Für weitere Fragen stehe ich...',
            keywords: null,
            renderedContent: 'Für weitere Fragen stehe ich gerne zur Verfügung!',
          },
        ],
      },
    }))
    client.setRequestHandler(TextModuleSuggestionsDocument, mock)

    cy.findByRole('textbox').type('::weitere fragen') // supports space

    cy.findByTestId('mention-text')
      .should('exist')
      .and('contain.text', 'Für weitere Fragen')
      .findByText(/Für weitere Fragen/)
      .click()

    cy.findByRole('textbox').shouldContainNormalizedHtml(
      'Für weitere Fragen stehe ich gerne zur Verfügung!',
    )
    cy.findByRole('textbox').type('{backspace}{backspace}123')
    cy.findByRole('textbox').shouldContainNormalizedHtml(
      '<p dir="auto">Für weitere Fragen stehe ich gerne zur Verfügun123</p>',
    )

    // asserting with `calledWith` is stricter than needed and can fail on unrelated payload expansion.
    // Prefer `calledWithMatch` to lock only the relevant fields.
    cy.wrap(mock).should('have.been.calledWithMatch', { query: 'weitere fragen' })
  })
})
