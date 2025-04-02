// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'

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

      expect(
        view.getByRole('button', { name: 'Freshdesk Beta' }),
      ).toBeInTheDocument()
      expect(
        view.getByRole('button', { name: 'Kayako Beta' }),
      ).toBeInTheDocument()
      expect(
        view.getByRole('button', { name: 'OTRS Beta' }),
      ).toBeInTheDocument()
      expect(
        view.getByRole('button', { name: 'Zendesk Beta' }),
      ).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Go Back' })).toBeInTheDocument()

      const importSourceButton = view.getByRole('button', {
        name: 'Freshdesk Beta',
      })

      await view.events.click(importSourceButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup import source freshdesk',
        ).toHaveCurrentUrl('/guided-setup/import/freshdesk')
      })
    })
  })
})
