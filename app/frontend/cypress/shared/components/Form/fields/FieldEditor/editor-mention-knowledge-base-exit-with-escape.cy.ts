// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { KnowledgeBaseAnswerSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditorWithAttachments } from './utils.ts'

describe('Testing "knowledge base" popup: "??" command', () => {
  before(() => {
    mountEditorWithAttachments(['ticket.agent'])
  })

  it('inserts a knowledge base mention > but exit on Esc > keyboard keys should still work', () => {
    const client = mockApolloClient()
    const mock = cy.spy(async () => ({
      data: {
        knowledgeBaseAnswerSuggestions: [
          {
            __typename: 'KnowledgeBaseAnswer',
            id: convertToGraphQLId('KnowledgeBaseAnswer', '1'),
            title: 'How to create a ticket?',
            categoryTreeTranslation: [
              {
                __typename: 'KnowledgeBaseCategoryTranslation',
                id: convertToGraphQLId('KnowledgeBaseCategory', '1'),
                title: 'Category 1',
              },
            ],
          },
        ],
      },
    }))

    client.setRequestHandler(KnowledgeBaseAnswerSuggestionsDocument, mock)

    cy.findByRole('textbox').type('??How to c')
    cy.findByTestId('mention-knowledge-base').should('exist') // verify that the suggestion UI opened
    cy.findByRole('textbox').type('{esc}')
    cy.findByTestId('mention-knowledge-base').should('not.exist') // verify that the suggestion UI closed

    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">??How to c</p>')
    cy.findByRole('textbox').type('{backspace}{backspace}123')
    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">??How to123</p>')
    cy.findByRole('textbox').type('{leftArrow}{leftArrow}654')
    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">??How to165423</p>')

    // asserting with `calledWith` is stricter than needed and can fail on unrelated payload expansion.
    // Prefer `calledWithMatch` to lock only the relevant fields.
    cy.wrap(mock).should('have.been.calledWithMatch', {
      query: 'How to c',
    })
  })
})
