// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApolloClient } from '#cy/utils.ts'

import { AiAssistanceTextToolsListDocument } from '#shared/components/Form/fields/FieldEditor/graphql/queries/aiAssistanceTextTools/aiAssistanceTextToolsList.api.ts'
import { AiAssistanceTextToolsRunDocument } from '#shared/graphql/mutations/aiAssistanceTextToolsRun.api.ts'
import { AiTextToolUpdatesDocument } from '#shared/graphql/subscriptions/aiTextToolUpdates.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mountEditor } from './utils.ts'

describe('Testing AI text tools', { retries: 2 }, () => {
  it('inserts a text', () => {
    const client = mockApolloClient()
    client.setRequestHandler(AiTextToolUpdatesDocument, async () => ({
      data: {
        aiTextToolUpdates: null,
      },
    }))
    client.setRequestHandler(AiAssistanceTextToolsListDocument, async () => ({
      data: {
        aiAssistanceTextToolsList: [
          {
            __typename: 'AiAssistanceTextTool',
            id: convertToGraphQLId('AiAssistanceTextTool', '1'),
            name: 'Text Tool 1',
            active: true,
          },
        ],
      },
    }))
    client.setRequestHandler(AiAssistanceTextToolsRunDocument, async () => ({
      data: {
        aiAssistanceTextToolsRun: {
          output: 'Some new text returned.',
        },
      },
    }))

    mountEditor({}, ['ticket.agent'], {
      ai_assistance_text_tools: true,
      ai_provider: true,
    })

    cy.findByRole('textbox').type('Some text which should be checked.{selectall}')

    cy.findByLabelText('AI writing assistant tools').click()
    cy.findByRole('button', { name: 'Text Tool 1' }).click()

    cy.findByRole('textbox').should('have.text', 'Some new text returned.')
  })
})
