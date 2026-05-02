// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { MentionSuggestionsDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/mention/mentionSuggestions.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditor } from './utils.ts'

describe('Testing "user mention" popup: "@@" command', () => {
  before(() => {
    mountEditor({ groupId: '1' }, ['ticket.agent'], {
      fqdn: 'example.zammad.com',
      http_type: 'http',
    })
  })

  it('inserts a user mention > allows spaces in search but exit on Esc', () => {
    const client = mockApolloClient()
    const mock = cy.spy(async () => ({
      data: {
        mentionSuggestions: [
          {
            __typename: 'User',
            id: convertToGraphQLId('User', '3'),
            internalId: 3,
            fullname: 'Bob Wance',
            email: 'bob@example.com',
          },
          {
            __typename: 'User',
            id: convertToGraphQLId('User', '4'),
            internalId: 4,
            fullname: 'John Doe',
            email: 'john@mail.com',
          },
        ],
      },
    }))
    client.setRequestHandler(MentionSuggestionsDocument, mock)

    // Search for John
    cy.findByRole('textbox').type('@@Jo mail.com') // supports space
    cy.findByTestId('mention-user').should('exist') // verify that the suggestion UI opened
    cy.findByRole('textbox').type('{esc}')
    cy.findByTestId('mention-user').should('not.exist') // verify that the suggestion UI closed

    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">@@Jo mail.com</p>')
    cy.findByRole('textbox').type('{backspace}{backspace}123')
    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">@@Jo mail.c123</p>')
    cy.findByRole('textbox').type('{leftArrow}{leftArrow}654')
    cy.findByRole('textbox').shouldContainNormalizedHtml('<p dir="auto">@@Jo mail.c165423</p>')

    // asserting with `calledWith` is stricter than needed and can fail on unrelated payload expansion.
    // Prefer `calledWithMatch` to lock only the relevant fields.
    cy.wrap(mock).should('have.been.calledWithMatch', {
      query: 'Jo mail.com',
      groupId: convertToGraphQLId('Group', '1'),
    })
  })
})
