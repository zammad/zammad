// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '@cy/utils'
import { KnowledgeBaseAnswerSuggestionContentTransformDocument } from '@shared/components/Form/fields/FieldEditor/graphql/mutations/knowledgeBase/suggestion/content/transform.api'
import { KnowledgeBaseAnswerSuggestionsDocument } from '@shared/components/Form/fields/FieldEditor/graphql/queries/knowledgeBase/answerSuggestions.api'
import { mountEditor } from './utils'

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
            // TODO separate test, when added
            attachments: [],
            errors: null,
          },
        },
      }),
    )

    mountEditor()

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
  })
})
