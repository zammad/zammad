// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'

import { EnumSystemSetupInfoStatus } from '#shared/graphql/types.ts'

import {
  mockSystemSetupRunAutoWizardMutation,
  waitForSystemSetupRunAutoWizardMutationCalls,
} from '#desktop/pages/guided-setup/graphql/mutations/systemSetupRunAutoWizard.mocks.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

describe('guided setup automated run', () => {
  describe('when system is not ready', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: false,
      })

      mockAuthentication(false)

      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.Automated,
          type: null,
        },
      })
    })

    it('redirects to home screen after successful setup', async () => {
      vi.useFakeTimers()

      const view = await visitView('/guided-setup/automated/run')

      expect(view.getByText('Automated Setup')).toBeInTheDocument()
      expect(view.getByIconName('spinner')).toBeInTheDocument()

      expect(
        view.getByText(
          'The system was configured successfully. You are being redirected.',
        ),
      ).toBeInTheDocument()

      await vi.runAllTimersAsync()
      vi.useRealTimers()

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to home screen').toHaveCurrentUrl('/')
      })
    })

    it('shows an alert message and hides spinner on errors', async () => {
      mockSystemSetupRunAutoWizardMutation({
        systemSetupRunAutoWizard: {
          errors: [
            {
              message: 'An unexpected error occurred during system setup.',
              field: null,
            },
          ],
        },
      })

      const view = await visitView('/guided-setup/automated/run')
      await flushPromises()

      expect(view.getByText('Automated Setup')).toBeInTheDocument()
      expect(view.queryByIconName('spinner')).not.toBeInTheDocument()

      expect(
        view.getByText('An unexpected error occurred during system setup.'),
      ).toBeInTheDocument()
    })

    it('supports optional token parameter', async () => {
      await visitView('/guided-setup/automated/run/s3cr3t-t0k3n')
      await flushPromises()

      const calls = await waitForSystemSetupRunAutoWizardMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          token: 's3cr3t-t0k3n',
        }),
      )
    })
  })

  describe('when system is ready', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
      })
    })

    it('redirects to home screen', async () => {
      mockAuthentication(true)

      const view = await visitView('/guided-setup/automated/run')

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to home screen').toHaveCurrentUrl('/')
      })
    })

    it('redirects to login screen', async () => {
      mockAuthentication(false)

      const view = await visitView('/guided-setup/automated/run')

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to login screen').toHaveCurrentUrl(
          '/login',
        )
      })
    })
  })
})
