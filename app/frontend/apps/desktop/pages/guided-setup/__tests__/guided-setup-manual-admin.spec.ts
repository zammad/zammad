// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import { EnumSystemSetupInfoStatus } from '#shared/graphql/types.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'
import { useSystemSetupInfoStore } from '../stores/systemSetupInfo.ts'

describe('guided setup admin user creation', () => {
  describe('when system initialization is done', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
      })
    })

    it('redirects to login window', async () => {
      const view = await visitView('/guided-setup/manual')

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
    })

    afterEach(() => {
      vi.clearAllMocks()
    })

    it('shows guided setup screen and opens manual setup on click', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.New,
          type: null,
        },
      })

      const view = await visitView('/guided-setup')

      view.getByText('Set up a new system').click()

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup manual',
        ).toHaveCurrentUrl('/guided-setup/manual')
      })

      expect(view.getByText('Create Administrator Account')).toBeInTheDocument()

      const firstNameField = view.getByLabelText('First name')
      const lastNameField = view.getByLabelText('Last name')
      const emailField = view.getByLabelText('Email')
      const passwordField = view.getByLabelText('Password')
      const confirmPasswordField = view.getByLabelText('Confirm password')

      expect(firstNameField).toBeInTheDocument()
      expect(lastNameField).toBeInTheDocument()
      expect(emailField).toBeInTheDocument()
      expect(passwordField).toBeInTheDocument()
      expect(confirmPasswordField).toBeInTheDocument()

      await view.events.type(firstNameField, 'Bender')
      await view.events.type(lastNameField, 'Rodriguez')
      await view.events.type(emailField, 'bender.rodriguez@futurama.corp')
      await view.events.type(passwordField, 'planetexpress')
      await view.events.type(confirmPasswordField, 'planetexpress')

      const createUserCurrentButton = view.getByRole('button', {
        name: 'Create account',
      })

      await view.events.click(createUserCurrentButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup manual system information step',
        ).toHaveCurrentUrl('/guided-setup/manual/system-information')
      })

      expect(useAuthenticationStore().authenticated).toBe(true)

      // Redirects to home screen on back navigation, if the setup was completed.
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.Done,
          type: null,
        },
      })

      const { setSystemSetupInfo } = useSystemSetupInfoStore()

      await setSystemSetupInfo()

      const router = getTestRouter()

      router.back()

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to home screen').toHaveCurrentUrl('/')
      })
    })
  })
})
