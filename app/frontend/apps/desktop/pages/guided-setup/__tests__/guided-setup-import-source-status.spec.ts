// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { getConfigUpdatesSubscriptionHandler } from '#shared/graphql/subscriptions/configUpdates.mocks.ts'
import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { mockSystemImportStateQuery } from '../graphql/queries/systemImportState.mocks.ts'
import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

import { mockSystemSetupInfo } from './mocks/mock-systemSetupInfo.ts'

describe('guided setup import source status', () => {
  describe('when import_mode is not set', () => {
    beforeEach(() => {
      mockApplicationConfig({
        import_backend: 'freshdesk',
        import_mode: false,
        system_init_done: false,
      })

      mockSystemSetupInfo({
        status: EnumSystemSetupInfoStatus.InProgress,
        type: EnumSystemSetupInfoType.Import,
        lockValue: 'random-uuid-lock',
        importSource: 'freshdesk',
      })

      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.InProgress,
          type: EnumSystemSetupInfoType.Import,
        },
      })
    })

    it('redirects to freshdesk configuration', async () => {
      const view = await visitView('/guided-setup/import/freshdesk/status')

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup import source freshdesk configuration',
        ).toHaveCurrentUrl('/guided-setup/import/freshdesk')
      })
    })
  })

  describe('when import is started', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: false,
        import_mode: true,
        import_backend: 'freshdesk',
      })
      mockSystemSetupInfo({
        status: EnumSystemSetupInfoStatus.InProgress,
        type: EnumSystemSetupInfoType.Import,
        lockValue: 'random-uuid-lock',
        importSource: 'freshdesk',
      })
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.InProgress,
          type: EnumSystemSetupInfoType.Import,
        },
      })

      vi.useFakeTimers()
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('shows the import starting message', async () => {
      const mockerImportState = mockSystemImportStateQuery({
        systemImportState: {
          result: null,
          finishedAt: null,
          startedAt: null,
        },
      })

      const view = await visitView('/guided-setup/import/freshdesk/status')

      const mockCalls = await mockerImportState.waitForCalls()
      expect(mockCalls).toHaveLength(1)

      expect(view.getByText('Freshdesk Import Status')).toBeInTheDocument()
      expect(view.getByText('Starting import…')).toBeInTheDocument()

      mockSystemImportStateQuery({
        systemImportState: {
          result: {},
          finishedAt: null,
          startedAt: new Date().toISOString(),
        },
      })

      vi.advanceTimersByTime(5000)
      expect(mockCalls).toHaveLength(2)

      await waitForNextTick()

      expect(view.queryByText('Starting import…')).not.toBeInTheDocument()

      expect(view.getByLabelText('Groups')).toBeInTheDocument()
      expect(view.getByLabelText('Organizations')).toBeInTheDocument()
      expect(view.getByLabelText('Users')).toBeInTheDocument()
      expect(view.getByLabelText('Tickets')).toBeInTheDocument()
    })

    it('shows the result and updated results', async () => {
      const startDate = new Date().toISOString()
      const mockerImportState = mockSystemImportStateQuery({
        systemImportState: {
          result: {},
          finishedAt: null,
          startedAt: startDate,
        },
      })

      const view = await visitView('/guided-setup/import/freshdesk/status')

      const mockCalls = await mockerImportState.waitForCalls()
      expect(mockCalls).toHaveLength(1)

      expect(view.getByLabelText('Groups')).toBeInTheDocument()
      expect(view.getByLabelText('Organizations')).toBeInTheDocument()
      expect(view.getByLabelText('Users')).toBeInTheDocument()
      expect(view.getByLabelText('Tickets')).toBeInTheDocument()

      mockSystemImportStateQuery({
        systemImportState: {
          result: {
            Groups: { sum: 5, total: 10 },
          },
          finishedAt: null,
          startedAt: startDate,
        },
      })

      await vi.advanceTimersByTimeAsync(5000)
      expect(mockCalls).toHaveLength(2)

      await waitForNextTick()

      const groupProgress = view.getByRole('progressbar', { name: 'Groups' })
      expect(groupProgress).toHaveAttribute('value', '5')
      expect(groupProgress).toHaveAttribute('max', '10')

      mockSystemImportStateQuery({
        systemImportState: {
          result: {
            Groups: { sum: 10, total: 10 },
            Organizations: { sum: 100, total: 100 },
            Users: { sum: 5000, total: 10000 },
          },
          finishedAt: null,
          startedAt: startDate,
        },
      })

      await vi.advanceTimersByTimeAsync(5000)
      expect(mockCalls).toHaveLength(3)

      await waitForNextTick()

      expect(groupProgress).toHaveAttribute('value', '10')
      expect(groupProgress).toHaveAttribute('max', '10')

      const organizationProgress = view.getByRole('progressbar', {
        name: 'Organizations',
      })
      expect(organizationProgress).toHaveAttribute('value', '100')
      expect(organizationProgress).toHaveAttribute('max', '100')

      const userProgress = view.getByRole('progressbar', {
        name: 'Users',
      })
      expect(userProgress).toHaveAttribute('value', '5000')
      expect(userProgress).toHaveAttribute('max', '10000')
    })

    it('shows directly the result and finish import with next refresh', async () => {
      const startDate = new Date().toISOString()
      const mockerImportState = mockSystemImportStateQuery({
        systemImportState: {
          result: {
            Groups: { sum: 10, total: 10 },
            Organizations: { sum: 100, total: 100 },
            Users: { sum: 10000, total: 10000 },
            Tickets: { sum: 80000, total: 100000 },
          },
          finishedAt: null,
          startedAt: startDate,
        },
      })

      const view = await visitView('/guided-setup/import/freshdesk/status')

      const application = useApplicationStore()
      application.initializeConfigUpdateSubscription()
      const configUpdateSubscription = getConfigUpdatesSubscriptionHandler()

      const mockCalls = await mockerImportState.waitForCalls()
      expect(mockCalls).toHaveLength(1)

      const ticketProgress = view.getByRole('progressbar', {
        name: 'Tickets',
      })
      expect(ticketProgress).toHaveAttribute('value', '80000')
      expect(ticketProgress).toHaveAttribute('max', '100000')

      mockSystemImportStateQuery({
        systemImportState: {
          result: {
            Groups: { sum: 10, total: 10 },
            Organizations: { sum: 100, total: 100 },
            Users: { sum: 10000, total: 10000 },
            Tickets: { sum: 100000, total: 100000 },
          },
          finishedAt: new Date().toISOString(),
          startedAt: startDate,
        },
      })

      await vi.advanceTimersByTimeAsync(5000)
      expect(mockCalls).toHaveLength(2)
      vi.useRealTimers()

      await configUpdateSubscription.trigger({
        configUpdates: {
          setting: {
            key: 'import_mode',
            value: false,
          },
        },
      })
      await configUpdateSubscription.trigger({
        configUpdates: {
          setting: {
            key: 'system_init_done',
            value: true,
          },
        },
      })

      await waitForNextTick()

      const successMessage = await view.findByText(
        'Import finished successfully!',
      )

      expect(successMessage.role).toBe('alert')
      expect(successMessage).toBeInTheDocument()

      const goToLoginButton = view.getByRole('button', {
        name: 'Go to Login',
      })
      await view.events.click(goToLoginButton)

      await flushPromises()

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to login page').toHaveCurrentUrl(
          '/login',
        )
      })
    })

    it('shows import could not be started message', async () => {
      const mockerImportState = mockSystemImportStateQuery({
        systemImportState: {
          result: null,
          finishedAt: null,
          startedAt: null,
        },
      })

      const view = await visitView('/guided-setup/import/freshdesk/status')

      const mockCalls = await mockerImportState.waitForCalls()
      expect(mockCalls).toHaveLength(1)

      await vi.advanceTimersByTimeAsync(90000)

      await waitForNextTick()

      const errorMessage = await view.findByText(
        'Background process did not start or has not finished! Please contact your support.',
      )
      expect(errorMessage.role).toBe('alert')
      expect(errorMessage).toBeInTheDocument()
    })

    it('shows server error after some status updates and hide it again', async () => {
      const startDate = new Date().toISOString()
      const mockerImportState = mockSystemImportStateQuery({
        systemImportState: {
          result: {
            Groups: { sum: 5, total: 10 },
          },
          finishedAt: null,
          startedAt: startDate,
        },
      })

      const view = await visitView('/guided-setup/import/freshdesk/status')

      const mockCalls = await mockerImportState.waitForCalls()
      expect(mockCalls).toHaveLength(1)

      mockSystemImportStateQuery({
        systemImportState: {
          result: {
            Groups: { sum: 8, total: 10 },
            error: 'An error occurred while importing data.',
          },
          finishedAt: null,
          startedAt: startDate,
        },
      })

      await vi.advanceTimersByTimeAsync(5000)
      expect(mockCalls).toHaveLength(2)

      await waitForNextTick()

      const errorMessage = await view.findByText(
        'An error occurred while importing data.',
      )
      expect(errorMessage.role).toBe('alert')
      expect(errorMessage).toBeInTheDocument()

      mockSystemImportStateQuery({
        systemImportState: {
          result: {
            Groups: { sum: 10, total: 10 },
            Organizations: { sum: 50, total: 100 },
          },
          finishedAt: null,
          startedAt: startDate,
        },
      })

      await vi.advanceTimersByTimeAsync(5000)
      expect(mockCalls).toHaveLength(3)

      await waitForNextTick()

      expect(errorMessage).not.toBeInTheDocument()
    })

    it('shows server error during the start (should hide start loading) and stop polling after some time', async () => {
      const mockerImportState = mockSystemImportStateQuery({
        systemImportState: {
          result: null,
          finishedAt: null,
          startedAt: null,
        },
      })

      const view = await visitView('/guided-setup/import/freshdesk/status')

      const mockCalls = await mockerImportState.waitForCalls()
      expect(mockCalls).toHaveLength(1)

      expect(view.getByText('Starting import…')).toBeInTheDocument()

      mockSystemImportStateQuery({
        systemImportState: {
          result: {
            error: 'An error occurred while importing data.',
          },
          finishedAt: null,
          startedAt: null,
        },
      })

      await vi.advanceTimersByTimeAsync(5000)
      expect(mockCalls).toHaveLength(2)

      await waitForNextTick()

      const errorMessage = await view.findByText(
        'An error occurred while importing data.',
      )
      expect(errorMessage.role).toBe('alert')
      expect(errorMessage).toBeInTheDocument()
      expect(view.queryByText('Starting import…')).not.toBeInTheDocument()

      // Stop polling after 90 seconds, so it should not be more then 19 calls.
      await vi.advanceTimersByTimeAsync(100000)
      expect(mockCalls).toHaveLength(19)
    })
  })
})
