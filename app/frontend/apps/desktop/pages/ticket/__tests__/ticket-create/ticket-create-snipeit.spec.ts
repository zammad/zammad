// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import getUuid from '#shared/utils/getUuid.ts'

describe('Ticket create Snipe-IT links', () => {
  it('displays Snipe-IT integration', async () => {
    mockApplicationConfig({
      snipeit_integration: true,
    })
    mockPermissions(['ticket.agent'])

    const uid = getUuid()
    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(within(sidebar).getByRole('button', { name: 'Snipe-IT' })).toBeInTheDocument()
  })

  it('hides Snipe-IT integration when not available', async () => {
    mockPermissions(['ticket.agent'])

    mockApplicationConfig({
      snipeit_integration: false,
    })

    const uid = getUuid()
    const view = await visitView(`/ticket/create/${uid}`)

    const sidebar = view.getByLabelText('Content sidebar')

    expect(within(sidebar).queryByRole('button', { name: 'Snipe-IT' })).not.toBeInTheDocument()
  })
})
