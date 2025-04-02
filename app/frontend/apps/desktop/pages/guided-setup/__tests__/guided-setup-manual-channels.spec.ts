// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EnumSystemSetupInfoStatus } from '#shared/graphql/types.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

describe('guided setup manual channels', () => {
  describe('when system is not ready', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: false,
      })
    })

    it('redirects to guided setup start', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.New,
          type: null,
        },
      })

      const view = await visitView('/guided-setup/manual/channels')

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup start screen',
        ).toHaveCurrentUrl('/guided-setup')
      })
      view.getByText('Set up a new system')
    })
  })

  describe('when system is ready for optional steps', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
      })
      mockPermissions(['admin'])
      mockAuthentication(true)
    })

    it('can redirect to email channel step', async () => {
      const view = await visitView('/guided-setup/manual/channels')

      expect(view.getByText('Connect Channels')).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Skip' })).toBeInTheDocument()

      const emailChannelButton = view.getByRole('button', {
        name: 'Email Channel',
      })

      await view.events.click(emailChannelButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup email channel step',
        ).toHaveCurrentUrl('/guided-setup/manual/channels/email')
      })
    })

    it('can go back to email notification step', async () => {
      const view = await visitView('/guided-setup/manual/channels')

      const goBackButton = view.getByRole('button', { name: 'Go Back' })

      await view.events.click(goBackButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to email notification step',
        ).toHaveCurrentUrl('/guided-setup/manual/email-notification')
      })
    })

    it('can skip to the last step', async () => {
      const view = await visitView('/guided-setup/manual/channels')

      const skipButton = view.getByRole('button', { name: 'Skip' })

      await view.events.click(skipButton)

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to the last step').toHaveCurrentUrl(
          '/guided-setup/manual/finish',
        )
      })
    })
  })
})
