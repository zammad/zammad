// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { TextModuleSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/textModule/textModuleSuggestions.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditor } from './utils.ts'

describe('Testing "text" popup: "::" command', () => {
  before(() => {
    mountEditor({}, ['ticket.agent'])
  })

  it('inserts a text > allows spaces in search but exit on Esc', () => {
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

    client.setRequestHandler(TextModuleSuggestionsDocument, mock) // supports space
    cy.findByRole('textbox').type('::weitere fragen')
    cy.findByTestId('mention-text').should('exist') // verify that the suggestion UI opened
    cy.findByRole('textbox').type('{esc}')
    cy.findByTestId('mention-text').should('not.exist') // verify that the suggestion UI closed

    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">::weitere fragen</p>')
    cy.findByRole('textbox').type('{backspace}{backspace}123')
    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">::weitere frag123</p>')
    cy.findByRole('textbox').type('{leftArrow}{leftArrow}654')
    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">::weitere frag165423</p>')

    // asserting with `calledWith` is stricter than needed and can fail on unrelated payload expansion.
    // Prefer `calledWithMatch` to lock only the relevant fields.
    cy.wrap(mock).should('have.been.calledWithMatch', { query: 'weitere fragen' })
  })
})
