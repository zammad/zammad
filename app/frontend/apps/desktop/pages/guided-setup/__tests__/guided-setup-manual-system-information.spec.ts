// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { dataURItoBlob } from '#tests/support/utils.ts'

import { EnumSystemSetupInfoStatus } from '#shared/graphql/types.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

describe('guided setup system information', () => {
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

      const view = await visitView('/guided-setup/manual/system-information')

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

    it('can configure system information', async () => {
      const view = await visitView('/guided-setup/manual/system-information')

      expect(view.getByText('System Information')).toBeInTheDocument()

      expect(
        view.queryByRole('button', { name: 'Go Back' }),
      ).not.toBeInTheDocument()

      const organizationField = view.getByLabelText('Organization name')
      const urlField = view.getByLabelText('System URL')
      const logoField = view.getByLabelText('Organization logo')

      expect(organizationField).toBeInTheDocument()
      expect(urlField).toBeInTheDocument()
      expect(logoField).toBeInTheDocument()

      expect(urlField).toHaveValue('http://localhost:3000')

      await view.events.type(organizationField, "Don't be Evil Inc")
      await view.events.clear(urlField)
      await view.events.type(urlField, 'https://example.com')

      const testValue =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVQYV2NgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII='

      const testFile = new File([dataURItoBlob(testValue)], 'foo.png', {
        type: 'image/png',
      })

      await view.events.upload(logoField, testFile)

      const continueButton = view.getByRole('button', {
        name: 'Save and Continue',
      })

      await view.events.click(continueButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup email notification setp',
        ).toHaveCurrentUrl('/guided-setup/manual/email-notification')
      })
    })
  })
})
