// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { getByRole, queryByRole } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import {
  mockFormUpdaterQuery,
  waitForFormUpdaterQueryCalls,
} from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { EnumSystemSetupInfoStatus } from '#shared/graphql/types.ts'

import {
  mockChannelEmailSetNotificationConfigurationMutation,
  waitForChannelEmailSetNotificationConfigurationMutationCalls,
} from '#desktop/entities/channel-email/graphql/mutations/channelEmailSetNotificationConfiguration.mocks.ts'

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

      await waitFor(() => {
        expect(view, 'correctly redirects to guided setup start screen').toHaveCurrentUrl(
          '/guided-setup',
        )
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
                  label: 'Local MTA (Sendmail/Postfix/Exim/â\u0080¦) - use server setup',
                },
              ],
            },
          },
        },
      })
    })

    it('can save and continue to channels step', async () => {
      mockChannelEmailSetNotificationConfigurationMutation({
        channelEmailSetNotificationConfiguration: {
          success: true,
          refused: false,
        },
      })

      const view = await visitView('/guided-setup/manual/email-notification')

      await flushPromises()
      await getNode('email-notification-setup')?.settled

      expect(view.getByText('Email notification')).toBeInTheDocument()
      expect(view.getByLabelText('Send mails via')).toBeInTheDocument()

      const continueButton = view.getByRole('button', {
        name: 'Save and continue',
      })

      await view.events.click(continueButton)

      await waitFor(() => {
        expect(view, 'correctly redirects to guided setup email channel step').toHaveCurrentUrl(
          '/guided-setup/manual/channels',
        )
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

      await waitFor(() => {
        expect(view.getByLabelText('SSL verification')).toBeDisabled()
      })

      await view.events.clear(view.getByLabelText('Port'))

      await waitFor(() => {
        expect(view.getByLabelText('SSL verification')).not.toBeDisabled()
      })

      await view.events.type(view.getByLabelText('Port'), '465')

      await waitFor(() => {
        expect(view.getByLabelText('SSL verification')).not.toBeDisabled()
      })

      await view.events.type(view.getByLabelText('Port'), '587')

      await waitFor(() => {
        expect(view.getByLabelText('SSL verification')).not.toBeDisabled()
      })
    })

    it('submits `false` value when SSL verification is disabled', async () => {
      mockChannelEmailSetNotificationConfigurationMutation({
        channelEmailSetNotificationConfiguration: {
          success: true,
          refused: false,
        },
      })

      const view = await visitView('/guided-setup/manual/email-notification')

      await flushPromises()
      await getNode('email-notification-setup')?.settled

      const adapterField = view.getByLabelText('Send mails via')

      await view.events.click(adapterField)
      await view.events.click(view.getAllByRole('option')[0])
      await view.events.type(view.getByLabelText('Host'), 'mail')

      await view.events.type(view.getByLabelText('User'), 'zammad@mail.test.dc.zammad.com')

      await view.events.type(view.getByLabelText('Password'), 'zammad')
      await view.events.type(view.getByLabelText('Port'), '25')

      expect(getNode('email-notification-setup')?.find('sslVerify')?.value).toBe(true)

      await view.events.click(
        view.getByRole('button', {
          name: 'Save and continue',
        }),
      )

      const calls = await waitForChannelEmailSetNotificationConfigurationMutationCalls()

      expect(calls.at(-1)?.variables).toEqual(
        expect.objectContaining({
          outboundConfiguration: expect.objectContaining({
            sslVerify: false,
          }),
        }),
      )
    })

    describe('when the server refuses the test email', () => {
      const refusal = {
        message: 'smtp.example.com: 554 5.7.1 Relay access denied',
        field: null,
      }

      const question = 'Does this email server only deliver to internal recipients?'

      const note =
        'Please note that an internal-only email server may fail to deliver password reset, new device and similar system emails to recipients outside the organization.'

      const submitSmtpConfiguration = async () => {
        mockUserCurrent({ email: 'admin@example.com' })
        mockPermissions(['admin'])

        const view = await visitView('/guided-setup/manual/email-notification')

        await flushPromises()
        await getNode('email-notification-setup')?.settled

        await view.events.click(view.getByLabelText('Send mails via'))
        await view.events.click(view.getAllByRole('option')[0])
        await view.events.type(view.getByLabelText('Host'), 'smtp.example.com')
        await view.events.type(view.getByLabelText('User'), 'zammad')
        await view.events.type(view.getByLabelText('Password'), 'zammad')
        await view.events.type(view.getByLabelText('Port'), '587')

        expect(view.queryByLabelText('Custom verification email')).not.toBeInTheDocument()

        await view.events.click(view.getByRole('button', { name: 'Save and continue' }))

        return view
      }

      it('asks about an internal-only server and saves with the test address', async () => {
        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: true,
            errors: [refusal],
          },
        })

        const view = await submitSmtpConfiguration()

        expect(await view.findByText(refusal.message)).toBeInTheDocument()
        expect(view.getByText(question)).toBeInTheDocument()
        expect(view.queryByLabelText('Custom verification email')).not.toBeInTheDocument()
        expect(view, 'stays on the step').toHaveCurrentUrl(
          '/guided-setup/manual/email-notification',
        )

        const firstCalls = await waitForChannelEmailSetNotificationConfigurationMutationCalls()

        expect(firstCalls.at(-1)?.variables.testAddress).toBeUndefined()

        await view.events.click(view.getByRole('button', { name: 'Yes' }))

        const testAddress = await view.findByLabelText('Custom verification email')

        expect(testAddress).toHaveValue('admin@example.com')

        await waitFor(() => {
          expect(testAddress).toHaveFocus()
        })

        expect(view.getByText(note)).toBeInTheDocument()
        expect(view.queryByText(question)).not.toBeInTheDocument()
        expect(view.queryByText(refusal.message)).not.toBeInTheDocument()

        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: true,
            refused: false,
            errors: null,
          },
        })

        await view.events.clear(testAddress)
        await view.events.type(testAddress, 'internal@example.com')
        await view.events.click(view.getByRole('button', { name: 'Save and continue' }))

        await waitFor(() => {
          expect(view, 'continues to the channels step').toHaveCurrentUrl(
            '/guided-setup/manual/channels',
          )
        })

        const secondCalls = await waitForChannelEmailSetNotificationConfigurationMutationCalls()

        expect(secondCalls.at(-1)?.variables).toEqual(
          expect.objectContaining({
            outboundConfiguration: expect.objectContaining({ host: 'smtp.example.com' }),
            testAddress: 'internal@example.com',
          }),
        )
      })

      it('sends a test address on a host without a domain', async () => {
        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: true,
            errors: [refusal],
          },
        })

        const view = await submitSmtpConfiguration()

        await view.events.click(await view.findByRole('button', { name: 'Yes' }))

        const testAddress = await view.findByLabelText('Custom verification email')

        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: true,
            refused: false,
            errors: null,
          },
        })

        await view.events.clear(testAddress)
        await view.events.type(testAddress, 'helpdesk@mailhost')
        await view.events.click(view.getByRole('button', { name: 'Save and continue' }))

        await waitFor(() => {
          expect(view, 'continues to the channels step').toHaveCurrentUrl(
            '/guided-setup/manual/channels',
          )
        })

        const calls = await waitForChannelEmailSetNotificationConfigurationMutationCalls()

        expect(calls.at(-1)?.variables.testAddress).toBe('helpdesk@mailhost')
      })

      it('sends no form updater query for the test address', async () => {
        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: true,
            errors: [refusal],
          },
        })

        const view = await submitSmtpConfiguration()

        await view.events.click(await view.findByRole('button', { name: 'Yes' }))

        const testAddress = await view.findByLabelText('Custom verification email')

        await getNode('email-notification-setup')?.settled

        const calls = (await waitForFormUpdaterQueryCalls()).length

        await view.events.type(testAddress, '.org')

        await getNode('email-notification-setup')?.settled
        await flushPromises()

        expect(await waitForFormUpdaterQueryCalls()).toHaveLength(calls)
      })

      it('shows a refusal of the test address without the question', async () => {
        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: true,
            errors: [refusal],
          },
        })

        const view = await submitSmtpConfiguration()

        await view.events.click(await view.findByRole('button', { name: 'Yes' }))

        await view.findByLabelText('Custom verification email')

        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: false,
            errors: [refusal],
          },
        })

        await view.events.click(view.getByRole('button', { name: 'Save and continue' }))

        expect(await view.findByText(refusal.message)).toBeInTheDocument()
        expect(view.queryByText(question)).not.toBeInTheDocument()
        expect(view.getByText(note)).toBeInTheDocument()
        expect(view.getByLabelText('Custom verification email')).toBeInTheDocument()
      })

      it('shows a failure for the test address at the field', async () => {
        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: true,
            errors: [refusal],
          },
        })

        const view = await submitSmtpConfiguration()

        await view.events.click(await view.findByRole('button', { name: 'Yes' }))

        const testAddress = await view.findByLabelText('Custom verification email')

        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: false,
            errors: [
              {
                message: 'Please enter a valid email address.',
                field: 'outbound.testAddress',
                exception: null,
              },
            ],
          },
        })

        await view.events.click(view.getByRole('button', { name: 'Save and continue' }))

        await waitFor(() => {
          expect(testAddress).toBeDescribedBy('Please enter a valid email address.')
        })

        expect(view.queryByText(question)).not.toBeInTheDocument()
        expect(view.getByText(note)).toBeInTheDocument()
      })

      it('returns to the usual check when the adapter changes', async () => {
        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: true,
            errors: [refusal],
          },
        })

        const view = await submitSmtpConfiguration()

        await view.events.click(await view.findByRole('button', { name: 'Yes' }))

        await view.findByLabelText('Custom verification email')

        await view.events.click(view.getByLabelText('Send mails via'))
        await view.events.click(view.getAllByRole('option')[1])

        await waitFor(() => {
          expect(view.queryByText(note)).not.toBeInTheDocument()
        })

        await view.events.click(view.getByLabelText('Send mails via'))
        await view.events.click(view.getAllByRole('option')[0])

        const host = await view.findByLabelText('Host')

        expect(view.queryByLabelText('Custom verification email')).not.toBeInTheDocument()
        expect(view.queryByText(note)).not.toBeInTheDocument()

        await view.events.clear(host)
        await view.events.type(host, 'smtp.example.com')
        await view.events.clear(view.getByLabelText('User'))
        await view.events.type(view.getByLabelText('User'), 'zammad')
        await view.events.clear(view.getByLabelText('Password'))
        await view.events.type(view.getByLabelText('Password'), 'zammad')
        await view.events.clear(view.getByLabelText('Port'))
        await view.events.type(view.getByLabelText('Port'), '587')

        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: true,
            refused: false,
            errors: null,
          },
        })

        await view.events.click(view.getByRole('button', { name: 'Save and continue' }))

        await waitFor(() => {
          expect(view, 'continues to the channels step').toHaveCurrentUrl(
            '/guided-setup/manual/channels',
          )
        })

        const calls = await waitForChannelEmailSetNotificationConfigurationMutationCalls()

        expect(calls.at(-1)?.variables.testAddress).toBeUndefined()
      })

      it.each(['Host', 'Port', 'User', 'Password'])(
        'returns to the usual check when the %s changes',
        async (label) => {
          mockChannelEmailSetNotificationConfigurationMutation({
            channelEmailSetNotificationConfiguration: {
              success: false,
              refused: true,
              errors: [refusal],
            },
          })

          const view = await submitSmtpConfiguration()

          await view.events.click(await view.findByRole('button', { name: 'Yes' }))

          await view.findByLabelText('Custom verification email')

          await view.events.type(view.getByLabelText(label), '1')

          await waitFor(() => {
            expect(view.queryByLabelText('Custom verification email')).not.toBeInTheDocument()
          })

          expect(view.queryByText(note)).not.toBeInTheDocument()

          mockChannelEmailSetNotificationConfigurationMutation({
            channelEmailSetNotificationConfiguration: {
              success: true,
              refused: false,
              errors: null,
            },
          })

          await view.events.click(view.getByRole('button', { name: 'Save and continue' }))

          await waitFor(() => {
            expect(view, 'continues to the channels step').toHaveCurrentUrl(
              '/guided-setup/manual/channels',
            )
          })

          const calls = await waitForChannelEmailSetNotificationConfigurationMutationCalls()

          expect(calls.at(-1)?.variables.testAddress).toBeUndefined()
        },
      )

      it('takes the question back when the host changes', async () => {
        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: true,
            errors: [refusal],
          },
        })

        const view = await submitSmtpConfiguration()

        expect(await view.findByText(question)).toBeInTheDocument()

        await view.events.type(view.getByLabelText('Host'), '.org')

        await waitFor(() => {
          expect(view.queryByText(question)).not.toBeInTheDocument()
        })
      })

      it('shows another failure without the question', async () => {
        mockChannelEmailSetNotificationConfigurationMutation({
          channelEmailSetNotificationConfiguration: {
            success: false,
            refused: false,
            errors: [
              {
                message: 'The hostname could not be found.',
                field: 'outbound.host',
                exception: null,
              },
            ],
          },
        })

        const view = await submitSmtpConfiguration()

        expect(await view.findByText('The hostname could not be found.')).toBeInTheDocument()
        expect(view.queryByText(question)).not.toBeInTheDocument()
        expect(view.queryByRole('button', { name: 'Yes' })).not.toBeInTheDocument()
      })
    })

    it('can go back to system information step', async () => {
      const view = await visitView('/guided-setup/manual/email-notification')

      const goBackButton = view.getByRole('button', { name: 'Go back' })

      await view.events.click(goBackButton)

      await waitFor(() => {
        expect(view, 'correctly redirects to email notification step').toHaveCurrentUrl(
          '/guided-setup/manual/system-information',
        )
      })
    })

    it('can skip to channels step', async () => {
      const view = await visitView('/guided-setup/manual/email-notification')

      const skipButton = view.getByRole('button', { name: 'Skip' })

      await view.events.click(skipButton)

      await waitFor(() => {
        expect(view, 'correctly redirects to channels step').toHaveCurrentUrl(
          '/guided-setup/manual/channels',
        )
      })
    })
  })
})
