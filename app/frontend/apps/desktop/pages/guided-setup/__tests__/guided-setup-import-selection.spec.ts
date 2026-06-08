// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumSystemSetupInfoStatus, EnumSystemSetupInfoType } from '#shared/graphql/types.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

describe('guided setup import selection', () => {
  describe('when system initialization is done', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
      })
    })

    it('redirects to login window', async () => {
      const view = await visitView('/guided-setup/import')

      // Check that we ware on the login page
      expect(view.getByText('Username / Email')).toBeInTheDocument()
      expect(view.getByText('Password')).toBeInTheDocument()
      expect(view.getByText('Sign in')).toBeInTheDocument()
    })
  })

  describe('when system is not initialized', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: false,
      })
    })

    it('shows the selection and click on freshdesk', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.InProgress,
          type: EnumSystemSetupInfoType.Import,
        },
      })

      const view = await visitView('/guided-setup/import')

      expect(view.getByRole('button', { name: 'FreshdeskBeta' })).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'KayakoBeta' })).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'OTRSBeta' })).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'ZendeskBeta' })).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Go back' })).toBeInTheDocument()

      const importSourceButton = view.getByRole('button', {
        name: 'FreshdeskBeta',
      })

      await view.events.click(importSourceButton)

      await waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup import source freshdesk',
        ).toHaveCurrentUrl('/guided-setup/import/freshdesk')
      })
    })
  })
})
