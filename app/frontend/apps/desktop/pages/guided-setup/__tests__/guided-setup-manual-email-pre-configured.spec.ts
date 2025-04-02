// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'

import { mockEmailAddressesQuery } from '#desktop/entities/email-addresses/graphql/queries/emailAddresses.mocks.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

describe('guided setup manual email notification', () => {
  describe('when system is ready for optional steps and system_online_service is false', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
        system_online_service: false,
      })

      mockPermissions(['admin'])
      mockAuthentication(true)
    })

    it('redirects to guided setup channels email step', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.InProgress,
          type: EnumSystemSetupInfoType.Manual,
        },
      })

      const view = await visitView(
        '/guided-setup/manual/channels/email-pre-configured',
      )

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup channels email screen',
        ).toHaveCurrentUrl('/guided-setup/manual/channels/email')
      })

      expect(view.getByText('Email Account')).toBeInTheDocument()
      expect(view.getByText('Email address')).toBeInTheDocument()
    })
  })

  describe('when system is ready for optional steps and system_online_service is true', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
        system_online_service: true,
      })

      mockPermissions(['admin'])
      mockAuthentication(true)
    })

    it('shows information about pre-configured email addresses', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.InProgress,
          type: EnumSystemSetupInfoType.Manual,
        },
      })

      mockEmailAddressesQuery({
        emailAddresses: [
          {
            name: 'Example Corporation',
            email: 'example@zammad.com',
          },
        ],
      })

      const view = await visitView(
        '/guided-setup/manual/channels/email-pre-configured',
      )

      await vi.waitFor(() => {
        expect(
          view,
          'correctly shows information about pre-configured email addresses',
        ).toHaveCurrentUrl('/guided-setup/manual/channels/email-pre-configured')
      })

      const labels = view.getAllByTestId('common-label')

      expect(labels[0]).toBeInTheDocument()
      expect(labels[0]).toHaveTextContent(
        'Your Zammad has the following email address',
      )

      expect(
        view.getByText('Example Corporation <example@zammad.com>'),
      ).toBeInTheDocument()

      expect(labels[1]).toBeInTheDocument()
      expect(labels[1]).toHaveTextContent(
        'If you want to use additional email addresses, you can configure them later',
      )
    })
  })
})
