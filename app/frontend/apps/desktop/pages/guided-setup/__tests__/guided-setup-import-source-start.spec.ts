// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'

import { mockSystemImportStartMutation } from '../graphql/mutations/systemImportStart.mocks.ts'
import { mockSystemImportStateQuery } from '../graphql/queries/systemImportState.mocks.ts'
import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

import { mockSystemSetupInfo } from './mocks/mock-systemSetupInfo.ts'

describe('guided setup import source start', () => {
  describe('when import_backend is not present', () => {
    beforeEach(() => {
      mockApplicationConfig({
        import_backend: undefined,
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
      const view = await visitView('/guided-setup/import/freshdesk/start')

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup import source freshdesk configuration',
        ).toHaveCurrentUrl('/guided-setup/import/freshdesk')
      })
    })
  })

  describe('when system is not initialized and import not started', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: false,
        import_mode: false,
        import_backend: 'freshdesk',
      })
    })

    it('shows the start view for the import (freshdesk) and start', async () => {
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
      mockSystemImportStartMutation({
        systemImportStart: {
          success: true,
        },
      })
      mockSystemImportStateQuery({
        systemImportState: {
          finishedAt: null,
          startedAt: null,
        },
      })

      const view = await visitView('/guided-setup/import/freshdesk/start')

      expect(view.getByText('Start Import from Freshdesk')).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Go Back' })).toBeInTheDocument()

      const startButton = view.getByRole('button', { name: 'Start Import' })
      expect(startButton).toBeInTheDocument()

      await view.events.click(startButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup import source freshdesk status page',
        ).toHaveCurrentUrl('/guided-setup/import/freshdesk/status')
      })

      expect(view.getByText('Starting import…')).toBeInTheDocument()
    })

    it('shows the start view and go back', async () => {
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

      const view = await visitView('/guided-setup/import/freshdesk/start')

      const goBackButton = view.getByRole('button', { name: 'Go Back' })
      expect(goBackButton).toBeInTheDocument()

      await view.events.click(goBackButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup import source freshdesk configuration page',
        ).toHaveCurrentUrl('/guided-setup/import/freshdesk')
      })
    })
  })
})
