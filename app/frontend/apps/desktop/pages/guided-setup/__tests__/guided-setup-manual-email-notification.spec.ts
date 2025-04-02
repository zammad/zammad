// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { getByRole, queryByRole } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { EnumSystemSetupInfoStatus } from '#shared/graphql/types.ts'

import { mockChannelEmailSetNotificationConfigurationMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailSetNotificationConfiguration.mocks.ts'
import {
  mockChannelEmailValidateConfigurationOutboundMutation,
  waitForChannelEmailValidateConfigurationOutboundMutationCalls,
} from '#desktop/entities/channel-email/graphql/mutations/channelEmailValidateConfigurationOutbound.mocks.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

describe('guided setup manual email notification', () => {
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

      const view = await visitView('/guided-setup/manual/email-notification')

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

      mockFormUpdaterQuery({
        formUpdater: {
          fields: {
            adapter: {
              initialValue: 'sendmail',
              options: [
                {
                  value: 'smtp',
                  label: 'SMTP - configure your own outgoing SMTP settings',
                },
                {
                  value: 'sendmail',
                  label:
                    'Local MTA (Sendmail/Postfix/Exim/â\u0080¦) - use server setup',
                },
              ],
            },
            notification_sender: {
              initialValue: 'Zammad Helpdesk <noreply@zammad.example.com>',
            },
          },
        },
      })
    })

    it('can save and continue to channels step', async () => {
      mockChannelEmailValidateConfigurationOutboundMutation({
        channelEmailValidateConfigurationOutbound: {
          success: true,
          errors: null,
        },
      })

      mockChannelEmailSetNotificationConfigurationMutation({
        channelEmailSetNotificationConfiguration: {
          success: true,
        },
      })

      const view = await visitView('/guided-setup/manual/email-notification')

      await flushPromises()
      await getNode('email-notification-setup')?.settled

      expect(view.getByText('Email Notification')).toBeInTheDocument()
      expect(view.getByLabelText('Send mails via')).toBeInTheDocument()

      const continueButton = view.getByRole('button', {
        name: 'Save and Continue',
      })

      await view.events.click(continueButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup email channel step',
        ).toHaveCurrentUrl('/guided-setup/manual/channels')
      })
    })

    it('shows warning when SSL verification is turned off', async () => {
      const view = await visitView('/guided-setup/manual/email-notification')

      await flushPromises()
      await getNode('email-notification-setup')?.settled

      const form = view.getByTestId('email-notification-setup')

      expect(queryByRole(form, 'alert')).not.toBeInTheDocument()

      const adapterField = view.getByLabelText('Send mails via')

      await view.events.click(adapterField)
      await view.events.click(view.getAllByRole('option')[0])

      expect(queryByRole(form, 'alert')).not.toBeInTheDocument()

      await view.events.click(view.getByLabelText('SSL verification'))

      let alert = getByRole(form, 'alert')

      expect(alert).toHaveTextContent(
        'Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!',
      )

      await view.events.click(view.getByLabelText('SSL verification'))

      expect(alert).not.toBeInTheDocument()

      await view.events.click(view.getByLabelText('SSL verification'))

      alert = getByRole(form, 'alert')

      expect(alert).toBeInTheDocument()

      await view.events.click(adapterField)
      await view.events.click(view.getAllByRole('option')[1])

      expect(alert).not.toBeInTheDocument()
    })

    it('toggles SSL verification disabled state when a port number is provided', async () => {
      const view = await visitView('/guided-setup/manual/email-notification')

      await flushPromises()
      await getNode('email-notification-setup')?.settled

      const adapterField = view.getByLabelText('Send mails via')

      await view.events.click(adapterField)
      await view.events.click(view.getAllByRole('option')[0])

      expect(view.getByLabelText('SSL verification')).not.toBeDisabled()

      await view.events.type(view.getByLabelText('Port'), '25')

      await vi.waitFor(() => {
        expect(view.getByLabelText('SSL verification')).toBeDisabled()
      })

      await view.events.clear(view.getByLabelText('Port'))

      await vi.waitFor(() => {
        expect(view.getByLabelText('SSL verification')).not.toBeDisabled()
      })

      await view.events.type(view.getByLabelText('Port'), '465')

      await vi.waitFor(() => {
        expect(view.getByLabelText('SSL verification')).not.toBeDisabled()
      })

      await view.events.type(view.getByLabelText('Port'), '587')

      await vi.waitFor(() => {
        expect(view.getByLabelText('SSL verification')).not.toBeDisabled()
      })
    })

    it('submits `false` value when SSL verification is disabled', async () => {
      mockChannelEmailValidateConfigurationOutboundMutation({
        channelEmailValidateConfigurationOutbound: {
          success: true,
          errors: null,
        },
      })

      mockChannelEmailSetNotificationConfigurationMutation({
        channelEmailSetNotificationConfiguration: {
          success: true,
        },
      })

      const view = await visitView('/guided-setup/manual/email-notification')

      await flushPromises()
      await getNode('email-notification-setup')?.settled

      const adapterField = view.getByLabelText('Send mails via')

      await view.events.click(adapterField)
      await view.events.click(view.getAllByRole('option')[0])
      await view.events.type(view.getByLabelText('Host'), 'mail')

      await view.events.type(
        view.getByLabelText('User'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(view.getByLabelText('Password'), 'zammad')
      await view.events.type(view.getByLabelText('Port'), '25')

      expect(
        getNode('email-notification-setup')?.find('sslVerify')?.value,
      ).toBe(true)

      await view.events.click(
        view.getByRole('button', {
          name: 'Save and Continue',
        }),
      )

      const calls =
        await waitForChannelEmailValidateConfigurationOutboundMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          outboundConfiguration: expect.objectContaining({
            sslVerify: false,
          }),
        }),
      )
    })

    it('can go back to system information step', async () => {
      const view = await visitView('/guided-setup/manual/email-notification')

      const goBackButton = view.getByRole('button', { name: 'Go Back' })

      await view.events.click(goBackButton)

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to email notification step',
        ).toHaveCurrentUrl('/guided-setup/manual/system-information')
      })
    })

    it('can skip to channels step', async () => {
      const view = await visitView('/guided-setup/manual/email-notification')

      const skipButton = view.getByRole('button', { name: 'Skip' })

      await view.events.click(skipButton)

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to channels step').toHaveCurrentUrl(
          '/guided-setup/manual/channels',
        )
      })
    })
  })
})
