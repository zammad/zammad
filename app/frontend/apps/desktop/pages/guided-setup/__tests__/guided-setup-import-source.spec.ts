// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'

import { mockSystemImportConfigurationMutation } from '../graphql/mutations/systemImportConfiguration.mocks.ts'
import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

import { mockSystemSetupInfo } from './mocks/mock-systemSetupInfo.ts'

describe('guided setup import source', () => {
  describe('when system initialization is done', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
      })
    })

    it('redirects to login window', async () => {
      const view = await visitView('/guided-setup/import/freshdesk')

      // Check that we ware on the login page
      expect(view.getByText('Username / Email')).toBeInTheDocument()
      expect(view.getByText('Password')).toBeInTheDocument()
      expect(view.getByText('Sign in')).toBeInTheDocument()
    })
  })

  describe('when system is not ready', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: false,
      })

      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.InProgress,
          type: EnumSystemSetupInfoType.Import,
        },
      })
    })

    it('shows the form to verify the import configuration + continues with a view to start the import', async () => {
      mockSystemSetupInfo({
        status: EnumSystemSetupInfoStatus.InProgress,
        type: EnumSystemSetupInfoType.Import,
        lockValue: 'random-uuid-lock',
        importSource: 'freshdesk',
      })

      const view = await visitView('/guided-setup/import/freshdesk')

      expect(view.getByText('URL')).toBeInTheDocument()
      expect(view.getByText('API token')).toBeInTheDocument()

      expect(view.getByRole('button', { name: 'Go Back' })).toBeInTheDocument()
      expect(
        view.getByRole('button', { name: 'Save and Continue' }),
      ).toBeInTheDocument()

      mockSystemImportConfigurationMutation({
        systemImportConfiguration: {
          success: false,
          errors: [
            {
              message: 'The hostname could not be found.',
              field: 'url',
            },
          ],
        },
      })

      const urlField = view.getByLabelText('URL')
      await view.events.type(urlField, 'https://zammad.freshdesk.com')

      const apiTokenField = view.getByLabelText('API token')
      await view.events.type(apiTokenField, 'random-api-token')

      const saveAndContinueButton = view.getByRole('button', {
        name: 'Save and Continue',
      })
      await view.events.click(saveAndContinueButton)

      expect(
        await view.findByText('The hostname could not be found.'),
      ).toBeInTheDocument()

      mockSystemImportConfigurationMutation({
        systemImportConfiguration: {
          success: true,
          errors: null,
        },
      })

      await view.events.click(saveAndContinueButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup import source freshdesk',
        ).toHaveCurrentUrl('/guided-setup/import/freshdesk/start')
      })

      expect(
        view.getByRole('button', { name: 'Start Import' }),
      ).toBeInTheDocument()
    })

    describe('when otrs import is used', () => {
      it('disable ssl verify for http urls', async () => {
        mockSystemSetupInfo({
          status: EnumSystemSetupInfoStatus.InProgress,
          type: EnumSystemSetupInfoType.Import,
          lockValue: 'random-uuid-lock',
          importSource: 'otrs',
        })

        const view = await visitView('/guided-setup/import/otrs')

        const continueButton = await view.findByRole('button', {
          name: 'Continue',
        })
        await view.events.click(continueButton)

        const sslField = await view.findByLabelText('SSL verification')

        expect(sslField).toBeChecked()

        const urlField = view.getByLabelText('URL')
        await view.events.type(urlField, 'http://otrs.example.com/...')

        expect(sslField).not.toBeChecked()
        expect(sslField).toBeDisabled()
      })
    })
  })
})
