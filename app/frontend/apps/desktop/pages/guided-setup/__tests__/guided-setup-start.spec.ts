// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getTestRouter } from '#tests/support/components/renderComponent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'

import { mockSystemSetupLockMutation } from '../graphql/mutations/systemSetupLock.mocks.ts'
import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'
import { useSystemSetupInfoStore } from '../stores/systemSetupInfo.ts'

import { mockSystemSetupInfo } from './mocks/mock-systemSetupInfo.ts'

describe('guided setup start', () => {
  describe('when system initialization is done', () => {
    beforeEach(() => {
      mockApplicationConfig({
        system_init_done: true,
      })
    })

    it('redirects to login window', async () => {
      const view = await visitView('/guided-setup')

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

    it('shows guided setup screen and opens manual setup on click', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.New,
          type: null,
        },
      })

      mockSystemSetupLockMutation({
        systemSetupLock: {
          resource: 'Zammad::System::Setup',
          value: 'random-uuid',
        },
      })

      const view = await visitView('/guided-setup')

      const manualSetupButton = view.getByText('Set up a new system')

      expect(manualSetupButton).toBeInTheDocument()
      expect(
        view.getByText('Or migrate from another system'),
      ).toBeInTheDocument()

      await view.events.click(manualSetupButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup manual',
        ).toHaveCurrentUrl('/guided-setup/manual')
      })

      expect(view.getByRole('button', { name: 'Go Back' })).toBeInTheDocument()
      expect(view.getByText('Create Administrator Account')).toBeInTheDocument()
    })

    it('shows guided setup screen and opens import setup on click', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.New,
          type: null,
        },
      })

      mockSystemSetupLockMutation({
        systemSetupLock: {
          resource: 'Zammad::System::Setup',
          value: 'random-uuid',
        },
      })

      const view = await visitView('/guided-setup')

      const importSetupButton = view.getByText('Or migrate from another system')
      expect(importSetupButton).toBeInTheDocument()

      await view.events.click(importSetupButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup import',
        ).toHaveCurrentUrl('/guided-setup/import')
      })

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
    })

    it('shows guided setup manual screen when lock exists', async () => {
      mockSystemSetupInfo({
        status: EnumSystemSetupInfoStatus.InProgress,
        type: EnumSystemSetupInfoType.Manual,
        lockValue: 'random-uuid-lock',
      })

      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.InProgress,
          type: EnumSystemSetupInfoType.Manual,
        },
      })

      const view = await visitView('/guided-setup')

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup manual',
        ).toHaveCurrentUrl('/guided-setup/manual')
      })

      expect(view.getByRole('button', { name: 'Go Back' })).toBeInTheDocument()
      expect(view.getByText('Create Administrator Account')).toBeInTheDocument()
    })

    it('redirects to home screen on back navigation, if the setup was completed', async () => {
      mockSystemSetupInfoQuery({
        systemSetupInfo: {
          status: EnumSystemSetupInfoStatus.New,
          type: null,
        },
      })

      const view = await visitView('/guided-setup')

      await view.events.click(view.getByText('Set up a new system'))

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup manual',
        ).toHaveCurrentUrl('/guided-setup/manual')
      })

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
