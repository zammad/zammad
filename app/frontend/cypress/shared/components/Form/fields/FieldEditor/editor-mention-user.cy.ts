// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '@cy/utils'
import { useNotifications } from '@shared/components/CommonNotifications'
import { MentionSuggestionsDocument } from '@shared/components/Form/fields/FieldEditor/graphql/queries/mention/mentionSuggestions.api'
import { convertToGraphQLId } from '@shared/graphql/utils'

import { mountEditor } from './utils'

describe('Testing "user mention" popup: "@@" command', { retries: 2 }, () => {
  it('shows notification when no group is provided', () => {
    const { notifications } = useNotifications()
    mountEditor()

    cy.findByRole('textbox')
      .type('@@t')
      .then(() => {
        expect(notifications.value).to.have.length(1)
        expect(notifications.value[0].message).to.equal(
          'Before you mention a user, please select a group.',
        )
      })
  })

  it('inserts found text', () => {
    const client = mockApolloClient()
    const mock = cy.spy(async () => ({
      data: {
        mentionSuggestions: [
          {
            id: btoa('Bob Wance'),
            internalId: 3,
            fullname: 'Bob Wance',
            email: 'bob@mail.com',
          },
          {
            id: btoa('John Doe'),
            internalId: 4,
            fullname: 'John Doe',
            email: 'john@mail.com',
          },
        ],
      },
    }))
    client.setRequestHandler(MentionSuggestionsDocument, mock)

    mountEditor({ groupId: '1' })

    cy.findByRole('textbox').type('@@Jo')

    cy.findByTestId('mention-user')
      .should('exist')
      .and('contain.text', 'Bob Wance')
      .findByText(/Bob Wance/)
      .click()

    cy.findByRole('textbox')
      .should('have.text', 'Bob Wance')
      .type('{backspace}{backspace}{leftArrow}ndyke{rightArrow}{backspace}')
      .should('have.text', 'Bob Wandyke') // can rename user
      .then(($el) => {
        const link = $el.find('a')
        expect(link).to.have.text('Bob Wandyke')
        expect(link).to.have.attr('data-mention-user-id', '3')
        expect(link).to.have.attr(
          'href',
          `${window.location.origin}/#user/profile/3`,
        )
      })

    cy.wrap(mock).should('have.been.calledWith', {
      query: 'Jo',
      group: convertToGraphQLId('Group', '1'),
    })
  })
})
