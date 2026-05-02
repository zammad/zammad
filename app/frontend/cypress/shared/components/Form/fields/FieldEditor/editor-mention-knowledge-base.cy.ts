// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { KnowledgeBaseAnswerSuggestionContentTransformDocument } from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.api.ts'
import { KnowledgeBaseAnswerSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditorWithAttachments } from './utils.ts'

describe('Testing "knowledge base" popup: "??" command', () => {
  it('inserts a knowledge base mention', () => {
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

    client.setRequestHandler(KnowledgeBaseAnswerSuggestionContentTransformDocument, async () => ({
      data: {
        knowledgeBaseAnswerSuggestionContentTransform: {
          __typename: 'KnowledgeBaseAnswerSuggestionContentTransform',
          body: 'knowledge base answer body',
          attachments: [
            {
              id: convertToGraphQLId('Store', 2062),
              name: 'Zammad.png',
              size: 945213,
              type: 'image/png',
              preferences: {
                'Content-Type': 'image/png',
                resizable: true,
                content_preview: true,
              },
              __typename: 'StoredFile',
            },
          ],
          errors: null,
        },
      },
    }))

    mountEditorWithAttachments(['ticket.agent'])

    cy.findByRole('textbox').type('??How to c') // supports space

    cy.findByTestId('mention-knowledge-base')
      .should('exist')
      .and('contain.text', 'How to create a ticket?')
      .findByText('How to create a ticket?')
      .click()

    cy.findByRole('textbox')
      .should('contain.text', 'knowledge base answer body')
      .type('{backspace}{backspace}r')
      .should('contain.text', 'knowledge base answer bor')

    cy.contains('Zammad.png').should('exist')
    cy.findByText('923 KB').should('exist')

    // asserting with `calledWith` is stricter than needed and can fail on unrelated payload expansion.
    // Prefer `calledWithMatch` to lock only the relevant fields.
    cy.wrap(mock).should('have.been.calledWithMatch', {
      query: 'How to c',
    })
  })
})
