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

  it('inserts a user mention  > allows spaces in search', () => {
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

    // But select Bob
    cy.findByTestId('mention-user')
      .should('exist')
      .and('contain.text', 'John Doe')
      .and('contain.text', 'Bob Wance')
      .findByText(/Bob Wance/)
      .click()

    cy.findByRole('textbox')
      .should('contain.text', 'Bob Wance')
      .type('{backspace}{backspace}{leftArrow}ndyke{rightArrow}{backspace}')
      .should('contain.text', 'Bob Wandyke') // can rename user
      .then(($el) => {
        const link = $el.find('a')
        expect(link).to.contain.text('Bob Wandyke')
        expect(link).to.have.attr('data-mention-user-id', '3')
        expect(link).to.have.attr('href', `http://example.zammad.com/#user/profile/3`)
      })

    // asserting with `calledWith` is stricter than needed and can fail on unrelated payload expansion.
    // Prefer `calledWithMatch` to lock only the relevant fields.
    cy.wrap(mock).should('have.been.calledWithMatch', {
      query: 'Jo mail.com',
      groupId: convertToGraphQLId('Group', '1'),
    })
  })
})
