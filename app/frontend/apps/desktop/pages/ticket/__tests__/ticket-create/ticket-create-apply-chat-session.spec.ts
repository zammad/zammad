// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { waitForFormUpdaterQueryCalls } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { handleMockFormUpdaterQuery } from '#desktop/pages/ticket/__tests__/support/ticket-create-helpers.ts'

describe('ticket create view - turning a chat session into a ticket', () => {
  const sessionId = convertToGraphQLId('Chat::Session', 1)

  beforeEach(() => {
    mockApplicationConfig({
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
    })
    mockPermissions(['ticket.agent', 'chat.agent'])
  })

  it('hands the session to the form updater and shows what it prefilled', async () => {
    handleMockFormUpdaterQuery({
      title: { value: 'Chat from 03/04/2026 2:05 pm' },
    })

    const view = await visitView(`/ticket/create?chatSessionId=${sessionId}`)

    const formUpdaterCalls = await waitForFormUpdaterQueryCalls()

    expect(formUpdaterCalls.at(-1)?.variables).toEqual(
      expect.objectContaining({
        meta: expect.objectContaining({
          additionalData: expect.objectContaining({ chatSessionId: sessionId }),
        }),
      }),
    )

    await waitForNextTick()

    expect(view.getByLabelText('Title')).toHaveValue('Chat from 03/04/2026 2:05 pm')
  })
})
