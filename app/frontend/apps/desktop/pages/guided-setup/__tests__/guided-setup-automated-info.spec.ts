// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { EnumSystemSetupInfoStatus } from '#shared/graphql/types.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

describe('guided setup automated info', () => {
  describe('when system is not ready', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: false,
      })

      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.Automated,
          type: null,
        },
      })
    })

    it('shows info screen', async () => {
      const view = await visitView('/guided-setup/automated')

      expect(view.getByText('Automated setup')).toBeInTheDocument()
      expect(view.queryByIconName('spinner')).not.toBeInTheDocument()

      expect(view.getByText('This system is configured for automated setup.')).toBeInTheDocument()

      expect(view.getByText('Please use the provided URL.')).toBeInTheDocument()
    })

    it('redirects to info screen first', async () => {
      const view = await visitView('/guided-setup')

      await waitFor(() => {
        expect(view, 'correctly redirects to guided setup automated info screen').toHaveCurrentUrl(
          '/guided-setup/automated',
        )
      })
    })
  })

  describe('when system is ready', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
      })
      mockAuthentication(true)
    })

    it('redirects to home screen', async () => {
      const view = await visitView('/guided-setup/automated')

      await waitFor(() => {
        expect(view, 'correctly redirects to home screen').toHaveCurrentUrl('/')
      })
    })
  })
})
