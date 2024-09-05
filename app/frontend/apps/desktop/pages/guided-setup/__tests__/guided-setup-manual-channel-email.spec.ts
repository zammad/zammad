// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import {
  getByLabelText,
  getByRole,
  getByText,
  queryByText,
} from '@testing-library/vue'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import {
  EnumChannelEmailInboundAdapter,
  EnumChannelEmailOutboundAdapter,
  EnumChannelEmailSsl,
  EnumFormUpdaterId,
  EnumSystemSetupInfoStatus,
} from '#shared/graphql/types.ts'

import {
  mockChannelEmailAddMutation,
  waitForChannelEmailAddMutationCalls,
} from '#desktop/entities/channel-email/graphql/mutations/channelEmailAdd.mocks.ts'
import { mockChannelEmailGuessConfigurationMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailGuessConfiguration.mocks.ts'
import { mockChannelEmailValidateConfigurationInboundMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailValidateConfigurationInbound.mocks.ts'
import { mockChannelEmailValidateConfigurationOutboundMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailValidateConfigurationOutbound.mocks.ts'
import { mockChannelEmailValidateConfigurationRoundtripMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailValidateConfigurationRoundtrip.mocks.ts'

import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

const inboundConfiguration = {
  adapter: EnumChannelEmailInboundAdapter.Imap,
  host: 'mail.test.dc.zammad.com',
  port: 993,
  ssl: EnumChannelEmailSsl.Ssl,
  user: 'zammad@mail.test.dc.zammad.com',
  password: 'zammad',
  sslVerify: true,
  folder: 'INBOX',
}

const outboundConfiguration = {
  adapter: EnumChannelEmailOutboundAdapter.Smtp,
  host: 'mail.test.dc.zammad.com',
  port: 25,
  user: 'zammad@mail.test.dc.zammad.com',
  password: 'zammad',
  sslVerify: false,
}

const sslVerificationWarningText =
  'Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!'

describe('guided setup manual channel email', () => {
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

      const view = await visitView('/guided-setup/manual/channels/email')

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

      mockFormUpdaterQuery((variables) => {
        switch (variables.formUpdaterId) {
          case EnumFormUpdaterId.FormUpdaterUpdaterGuidedSetupEmailOutbound:
            return {
              formUpdater: {
                fields: {
                  adapter: {
                    initialValue: 'smtp',
                    options: [
                      {
                        value: 'smtp',
                        label:
                          'SMTP - configure your own outgoing SMTP settings',
                      },
                      {
                        value: 'sendmail',
                        label:
                          'Local MTA (Sendmail/Postfix/Exim/â\u0080¦) - use server setup',
                      },
                    ],
                  },
                },
              },
            }

          case EnumFormUpdaterId.FormUpdaterUpdaterGuidedSetupEmailInbound:
          default:
            return {
              formUpdater: {
                fields: {
                  adapter: {
                    initialValue: 'imap',
                    options: [
                      {
                        value: 'imap',
                        label: 'IMAP',
                      },
                      {
                        value: 'pop3',
                        label: 'POP3',
                      },
                    ],
                  },
                },
              },
            }
        }
      })
    })

    it('can redirect to invite step when guess is successful', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      expect(view.getByText('Email Account')).toBeInTheDocument()
      expect(view.getByRole('button', { name: 'Go Back' })).toBeInTheDocument()

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration,
            outboundConfiguration,
            mailboxStats: {
              contentMessages: 0,
              archivePossible: false,
              archiveWeekRange: 2,
            },
          },
        },
      })

      mockChannelEmailValidateConfigurationRoundtripMutation({
        channelEmailValidateConfigurationRoundtrip: {
          success: true,
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      await vi.waitFor(() => {
        expect(
          view,
          'correctly redirects to guided setup invite step',
        ).toHaveCurrentUrl('/guided-setup/manual/invite')
      })
    })

    it('can show inbound configuration form when guess is unsuccessful', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration: null,
            outboundConfiguration: null,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      expect(accountForm).not.toBeVisible()

      const inboundForm = view.getByTestId('channel-email-inbound')

      expect(inboundForm).toBeVisible()

      expect(getByRole(inboundForm, 'alert')).toHaveTextContent(
        'The server settings could not be automatically detected. Please configure them manually.',
      )

      expect(view.getByRole('button', { name: 'Continue' })).toBeInTheDocument()
    })

    it('can show inbound configuration form when roundtrip is unsuccessful', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration,
            outboundConfiguration,
            mailboxStats: {
              contentMessages: 0,
              archivePossible: false,
              archiveWeekRange: 2,
            },
          },
        },
      })

      mockChannelEmailValidateConfigurationRoundtripMutation({
        channelEmailValidateConfigurationRoundtrip: {
          success: false,
          errors: [
            {
              message: 'Something went wrong',
              field: 'inbound.adapter',
            },
          ],
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      expect(accountForm).not.toBeVisible()

      const inboundForm = view.getByTestId('channel-email-inbound')

      expect(inboundForm).toBeVisible()
      expect(getByText(inboundForm, 'Something went wrong')).toBeInTheDocument()
    })

    it('can show a form error when adding email channel is unsuccessful', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration,
            outboundConfiguration,
            mailboxStats: {
              contentMessages: 0,
              archivePossible: false,
              archiveWeekRange: 2,
            },
          },
        },
      })

      mockChannelEmailValidateConfigurationRoundtripMutation({
        channelEmailValidateConfigurationRoundtrip: {
          success: true,
        },
      })

      mockChannelEmailAddMutation({
        channelEmailAdd: {
          errors: [
            {
              message: 'The provided password is invalid.',
              field: 'password',
            },
          ],
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      expect(accountForm).toBeVisible()

      expect(
        getByText(accountForm, 'The provided password is invalid.'),
      ).toBeInTheDocument()
    })

    it('can show inbound messages form when some messages are detected', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration: null,
            outboundConfiguration: null,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      const inboundForm = view.getByTestId('channel-email-inbound')

      await view.events.type(
        getByLabelText(inboundForm, 'Host'),
        'mail.test.dc.zammad.com',
      )

      await getNode('channel-email-inbound')?.settled

      mockChannelEmailValidateConfigurationInboundMutation({
        channelEmailValidateConfigurationInbound: {
          success: true,
          mailboxStats: {
            contentMessages: 3,
            archivePossible: true,
            archivePossibleIsFallback: false,
            archiveWeekRange: 2,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Continue',
        }),
      )

      expect(inboundForm).not.toBeVisible()

      const inboundMessagesForm = view.getByTestId(
        'channel-email-inbound-messages',
      )

      expect(inboundMessagesForm).toBeVisible()

      expect(inboundMessagesForm).toHaveTextContent(
        '3 email(s) were found in your mailbox. They will all be moved from your mailbox into Zammad.',
      )

      expect(inboundMessagesForm).toHaveTextContent(
        'In addition, emails were found in your mailbox that are older than 2 weeks. You can import such emails as an "archive", which means that no notifications are sent and the tickets have the status "closed". However, you can find them in Zammad anytime using the search function.',
      )

      expect(
        getByLabelText(inboundMessagesForm, 'Email import mode'),
      ).toBeInTheDocument()

      expect(view.getByRole('button', { name: 'Continue' })).toBeInTheDocument()
    })

    it('can show inbound messages form when some messages are detected but imap sort failed', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration: null,
            outboundConfiguration: null,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      const inboundForm = view.getByTestId('channel-email-inbound')

      await view.events.type(
        getByLabelText(inboundForm, 'Host'),
        'mail.test.dc.zammad.com',
      )

      await getNode('channel-email-inbound')?.settled

      mockChannelEmailValidateConfigurationInboundMutation({
        channelEmailValidateConfigurationInbound: {
          success: true,
          mailboxStats: {
            contentMessages: 3,
            archivePossible: true,
            archivePossibleIsFallback: true,
            archiveWeekRange: 2,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Continue',
        }),
      )

      expect(inboundForm).not.toBeVisible()

      const inboundMessagesForm = view.getByTestId(
        'channel-email-inbound-messages',
      )

      expect(inboundMessagesForm).toBeVisible()

      expect(inboundMessagesForm).toHaveTextContent(
        '3 email(s) were found in your mailbox. They will all be moved from your mailbox into Zammad.',
      )

      expect(inboundMessagesForm).toHaveTextContent(
        'Since the mail server does not support sorting messages by date, it was not possible to detect if there is any mail older than 2 weeks in the connected mailbox. You can import such emails as an "archive", which means that no notifications are sent and the tickets have the status "closed". However, you can find them in Zammad anytime using the search function.',
      )

      expect(
        getByLabelText(inboundMessagesForm, 'Email import mode'),
      ).toBeInTheDocument()

      expect(view.getByRole('button', { name: 'Continue' })).toBeInTheDocument()
    })

    it('can show outbound configuration form when guess is unsuccessful', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration: null,
            outboundConfiguration: null,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      const inboundForm = view.getByTestId('channel-email-inbound')

      await view.events.type(
        getByLabelText(inboundForm, 'Host'),
        'mail.test.dc.zammad.com',
      )

      await getNode('channel-email-inbound')?.settled

      mockChannelEmailValidateConfigurationInboundMutation({
        channelEmailValidateConfigurationInbound: {
          success: true,
          mailboxStats: {
            contentMessages: 0,
            archivePossible: false,
            archiveWeekRange: 2,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Continue',
        }),
      )

      expect(inboundForm).not.toBeVisible()

      const outboundForm = view.getByTestId('channel-email-outbound')

      expect(outboundForm).toBeVisible()
      expect(
        view.getByRole('button', { name: 'Save and Continue' }),
      ).toBeInTheDocument()
    })

    it('can show outbound configuration form when roundtrip is unsuccessful', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration,
            outboundConfiguration,
            mailboxStats: {
              contentMessages: 0,
              archivePossible: false,
              archiveWeekRange: 2,
            },
          },
        },
      })

      mockChannelEmailValidateConfigurationRoundtripMutation({
        channelEmailValidateConfigurationRoundtrip: {
          success: false,
          errors: [
            {
              message: 'Something went wrong',
              field: 'outbound.adapter',
            },
          ],
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      expect(accountForm).not.toBeVisible()

      const outboundForm = view.getByTestId('channel-email-outbound')

      expect(outboundForm).toBeVisible()

      expect(
        getByText(outboundForm, 'Something went wrong'),
      ).toBeInTheDocument()
    })

    it('can add email channel and redirect to invite step', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration: null,
            outboundConfiguration: null,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      const inboundForm = view.getByTestId('channel-email-inbound')

      await view.events.type(
        getByLabelText(inboundForm, 'Host'),
        'mail.test.dc.zammad.com',
      )

      await getNode('channel-email-inbound')?.settled

      mockChannelEmailValidateConfigurationInboundMutation({
        channelEmailValidateConfigurationInbound: {
          success: true,
          mailboxStats: {
            contentMessages: 0,
            archivePossible: false,
            archiveWeekRange: 2,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Continue',
        }),
      )

      const outboundForm = view.getByTestId('channel-email-outbound')

      await view.events.type(getByLabelText(outboundForm, 'Port'), '25')

      mockChannelEmailValidateConfigurationOutboundMutation({
        channelEmailValidateConfigurationOutbound: {
          success: true,
        },
      })

      mockChannelEmailValidateConfigurationRoundtripMutation({
        channelEmailValidateConfigurationRoundtrip: {
          success: true,
        },
      })

      mockChannelEmailAddMutation({
        channelEmailAdd: {
          channel: {
            options: {},
            group: {
              id: 'gid://zammad/Group/1',
            },
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Save and Continue',
        }),
      )

      const calls = await waitForChannelEmailAddMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        input: {
          emailAddress: 'zammad@mail.test.dc.zammad.com',
          emailRealname: 'Zammad Helpdesk',
          inboundConfiguration: {
            adapter: 'imap',
            folder: '',
            host: 'mail.test.dc.zammad.com',
            keepOnServer: false,
            password: 'zammad',
            port: 993,
            ssl: 'ssl',
            sslVerify: true,
            user: 'zammad@mail.test.dc.zammad.com',
          },
          outboundConfiguration: {
            adapter: 'smtp',
            host: 'mail.test.dc.zammad.com',
            password: 'zammad',
            port: 25,
            sslVerify: false,
            user: 'zammad@mail.test.dc.zammad.com',
          },
        },
      })

      await vi.waitFor(() => {
        expect(view).toHaveCurrentUrl('/guided-setup/manual/invite')
      })
    })

    it('can show warning when SSL/STARTTLS is used and SSL verification is turned off in inbound form', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration: null,
            outboundConfiguration: null,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      const inboundForm = view.getByTestId('channel-email-inbound')

      let alert = queryByText(inboundForm, sslVerificationWarningText)

      expect(alert).not.toBeInTheDocument()

      await view.events.click(getByLabelText(inboundForm, 'SSL verification'))

      alert = getByText(inboundForm, sslVerificationWarningText)

      expect(alert?.role).toBe('alert')

      await view.events.click(getByLabelText(inboundForm, 'SSL verification'))

      expect(alert).not.toBeInTheDocument()

      await view.events.click(getByLabelText(inboundForm, 'SSL verification'))

      alert = getByText(inboundForm, sslVerificationWarningText)

      expect(alert).toBeInTheDocument()

      const sslField = view.getByLabelText('SSL/STARTTLS')

      await view.events.click(sslField)
      await view.events.click(view.getAllByRole('option')[0])

      expect(alert).not.toBeInTheDocument()

      await view.events.click(sslField)
      await view.events.click(view.getAllByRole('option')[2])

      alert = queryByText(inboundForm, sslVerificationWarningText)

      expect(alert).not.toBeInTheDocument()

      await view.events.click(getByLabelText(inboundForm, 'SSL verification'))

      alert = getByText(inboundForm, sslVerificationWarningText)
      expect(alert).toBeInTheDocument()
    })

    it('can show warning when secure port is used and SSL verification is turned off in outbound form', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const accountForm = view.getByTestId('channel-email-account')

      await view.events.type(
        getByLabelText(accountForm, 'Full name'),
        'Zammad Helpdesk',
      )

      await view.events.type(
        getByLabelText(accountForm, 'Email address'),
        'zammad@mail.test.dc.zammad.com',
      )

      await view.events.type(getByLabelText(accountForm, 'Password'), 'zammad')

      mockChannelEmailGuessConfigurationMutation({
        channelEmailGuessConfiguration: {
          result: {
            inboundConfiguration: null,
            outboundConfiguration: null,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Connect and Continue',
        }),
      )

      const inboundForm = view.getByTestId('channel-email-inbound')

      await view.events.type(
        getByLabelText(inboundForm, 'Host'),
        'mail.test.dc.zammad.com',
      )

      await getNode('channel-email-inbound')?.settled

      mockChannelEmailValidateConfigurationInboundMutation({
        channelEmailValidateConfigurationInbound: {
          success: true,
          mailboxStats: {
            contentMessages: 0,
            archivePossible: false,
            archiveWeekRange: 2,
          },
        },
      })

      await view.events.click(
        view.getByRole('button', {
          name: 'Continue',
        }),
      )

      const outboundForm = view.getByTestId('channel-email-outbound')

      let alert = queryByText(outboundForm, sslVerificationWarningText)

      expect(alert).not.toBeInTheDocument()

      expect(
        getByLabelText(outboundForm, 'SSL verification'),
      ).not.toBeDisabled()

      await view.events.click(getByLabelText(outboundForm, 'SSL verification'))

      alert = getByText(outboundForm, sslVerificationWarningText)

      expect(alert?.role).toBe('alert')

      await view.events.click(getByLabelText(outboundForm, 'SSL verification'))

      expect(alert).not.toBeInTheDocument()

      await view.events.click(getByLabelText(outboundForm, 'SSL verification'))

      alert = getByText(outboundForm, sslVerificationWarningText)

      expect(alert).toBeInTheDocument()

      await view.events.type(getByLabelText(outboundForm, 'Port'), '25')

      await vi.waitFor(() => {
        expect(alert).not.toBeInTheDocument()
        expect(getByLabelText(outboundForm, 'SSL verification')).toBeDisabled()
      })

      await view.events.clear(getByLabelText(outboundForm, 'Port'))

      await vi.waitFor(() => {
        expect(
          getByLabelText(outboundForm, 'SSL verification'),
        ).not.toBeDisabled()
      })

      await view.events.click(getByLabelText(outboundForm, 'SSL verification'))

      await vi.waitFor(() => {
        alert = getByText(outboundForm, sslVerificationWarningText)

        expect(alert).toBeInTheDocument()

        expect(
          getByLabelText(outboundForm, 'SSL verification'),
        ).not.toBeDisabled()
      })

      await view.events.type(getByLabelText(outboundForm, 'Port'), '465')

      await vi.waitFor(() => {
        expect(
          getByLabelText(outboundForm, 'SSL verification'),
        ).not.toBeDisabled()
      })

      await vi.waitFor(() => {
        alert = getByText(outboundForm, sslVerificationWarningText)

        expect(alert).toBeInTheDocument()

        expect(
          getByLabelText(outboundForm, 'SSL verification'),
        ).not.toBeDisabled()
      })

      await view.events.type(getByLabelText(outboundForm, 'Port'), '587')

      await vi.waitFor(() => {
        expect(
          getByLabelText(outboundForm, 'SSL verification'),
        ).not.toBeDisabled()
      })

      await vi.waitFor(() => {
        alert = getByText(outboundForm, sslVerificationWarningText)

        expect(alert).toBeInTheDocument()

        expect(
          getByLabelText(outboundForm, 'SSL verification'),
        ).not.toBeDisabled()
      })
    })

    it('can go back to channels step', async () => {
      const view = await visitView('/guided-setup/manual/channels/email')

      const goBackButton = view.getByRole('button', { name: 'Go Back' })

      await view.events.click(goBackButton)

      await vi.waitFor(() => {
        expect(view, 'correctly redirects to channels step').toHaveCurrentUrl(
          '/guided-setup/manual/channels',
        )
      })
    })
  })
})
