// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { KnowledgeBaseAnswerSuggestionContentTransformDocument } from '#shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.api.ts'
import { KnowledgeBaseAnswerSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.api.ts'

import { mountEditorWithAttachments } from './utils.ts'

describe('Testing "knowledge base" popup: "??" command', { retries: 2 }, () => {
  it('inserts a text', () => {
    const client = mockApolloClient()
    client.setRequestHandler(
      KnowledgeBaseAnswerSuggestionsDocument,
      async () => ({
        data: {
          knowledgeBaseAnswerSuggestions: [
            {
              __typename: 'KnowledgeBaseAnswer',
              id: btoa('How to create a ticket?'),
              title: 'How to create a ticket?',
              categoryTreeTranslation: [
                {
                  __typename: 'KnowledgeBaseCategoryTranslation',
                  id: btoa('Category 1'),
                  title: 'Category 1',
                },
              ],
            },
          ],
        },
      }),
    )
    client.setRequestHandler(
      KnowledgeBaseAnswerSuggestionContentTransformDocument,
      async () => ({
        data: {
          knowledgeBaseAnswerSuggestionContentTransform: {
            __typename: 'KnowledgeBaseAnswerSuggestionContentTransform',
            body: 'knowledge base answer body',
            attachments: [
              {
                id: 'gid://zammad/Store/2062',
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
      }),
    )

    mountEditorWithAttachments()

    cy.findByRole('textbox').type('??How to c') // supports space

    cy.findByTestId('mention-knowledge-base')
      .should('exist')
      .and('contain.text', 'How to create a ticket?')
      .findByText('How to create a ticket?')
      .click()

    cy.findByRole('textbox')
      .should('have.text', 'knowledge base answer body')
      .type('{backspace}{backspace}r')
      .should('have.text', 'knowledge base answer bor')

    cy.findByText('Zammad.png').should('exist')
    cy.findByText('923 KB').should('exist')
  })
})
