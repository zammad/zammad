// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import '#tests/graphql/builders/mocks.ts'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockAuthentication } from '#tests/support/mock-authentication.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import {
  EnumFormUpdaterId,
  EnumSystemSetupInfoStatus,
  EnumSystemSetupInfoType,
} from '#shared/graphql/types.ts'

import { mockChannelEmailSetNotificationConfigurationMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailSetNotificationConfiguration.mocks.ts'
import { mockChannelEmailValidateConfigurationOutboundMutation } from '#desktop/entities/channel-email/graphql/mutations/channelEmailValidateConfigurationOutbound.mocks.ts'
import { mockEmailAddressesQuery } from '#desktop/entities/email-addresses/graphql/queries/emailAddresses.mocks.ts'

import { mockSystemImportStartMutation } from '../graphql/mutations/systemImportStart.mocks.ts'
import { mockSystemImportStateQuery } from '../graphql/queries/systemImportState.mocks.ts'
import { mockSystemSetupInfoQuery } from '../graphql/queries/systemSetupInfo.mocks.ts'

import { mockSystemSetupInfo } from './mocks/mock-systemSetupInfo.ts'

describe('testing admin password request a11y', () => {
  beforeEach(() => {
    mockApplicationConfig({
      system_init_done: false,
    })
  })

  it('has no accessibility violations in the info screen', async () => {
    mockSystemSetupInfoQuery({
      systemSetupInfo: {
        status: EnumSystemSetupInfoStatus.New,
        type: null,
      },
    })

    const view = await visitView('/guided-setup')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the import selection screen', async () => {
    mockSystemSetupInfoQuery({
      systemSetupInfo: {
        status: EnumSystemSetupInfoStatus.InProgress,
        type: EnumSystemSetupInfoType.Import,
      },
    })

    const view = await visitView('/guided-setup/import')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the import source screen', async () => {
    mockSystemSetupInfo({
      status: EnumSystemSetupInfoStatus.InProgress,
      type: EnumSystemSetupInfoType.Import,
      lockValue: 'random-uuid-lock',
      importSource: 'freshdesk',
    })

    const view = await visitView('/guided-setup/import/freshdesk')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  beforeEach(() => {
    mockApplicationConfig({
      system_init_done: false,
      import_mode: false,
      import_backend: 'freshdesk',
    })
  })

  it('has no accessibility violations in the import source start screen', async () => {
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

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the import source status screen', async () => {
    mockSystemImportStateQuery({
      systemImportState: {
        result: null,
        finishedAt: null,
        startedAt: null,
      },
    })

    const view = await visitView('/guided-setup/import/freshdesk/status')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the admin screen', async () => {
    mockSystemSetupInfoQuery({
      systemSetupInfo: {
        status: EnumSystemSetupInfoStatus.New,
        type: null,
      },
    })

    const view = await visitView('/guided-setup/manual/admin')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the system information screen', async () => {
    mockApplicationConfig({
      system_init_done: true,
    })
    mockPermissions(['admin'])
    mockAuthentication(true)

    const view = await visitView('/guided-setup/manual/system-information')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the email notification screen', async () => {
    mockApplicationConfig({
      system_init_done: true,
    })
    mockPermissions(['admin'])
    mockAuthentication(true)

    mockFormUpdaterQuery({
      formUpdater: {
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
    })

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

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the channels screen', async () => {
    mockApplicationConfig({
      system_init_done: true,
    })
    mockPermissions(['admin'])
    mockAuthentication(true)

    const view = await visitView('/guided-setup/manual/channels')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the email channel screen', async () => {
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
              adapter: {
                initialValue: 'smtp',
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
            },
          }

        case EnumFormUpdaterId.FormUpdaterUpdaterGuidedSetupEmailInbound:
        default:
          return {
            formUpdater: {
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
          }
      }
    })

    const view = await visitView('/guided-setup/manual/channels/email')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the pre-configured email address screen', async () => {
    mockApplicationConfig({
      system_init_done: true,
      system_online_service: true,
    })

    mockPermissions(['admin'])
    mockAuthentication(true)

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

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the invite screen', async () => {
    mockApplicationConfig({
      system_init_done: true,
    })
    mockPermissions(['admin'])
    mockAuthentication(true)

    mockFormUpdaterQuery({
      formUpdater: {
        role_ids: {
          initialValue: [2],
          options: [
            {
              value: 1,
              label: 'Admin',
              description: 'To configure your system.',
            },
            {
              value: 2,
              label: 'Agent',
              description: 'To work on Tickets.',
            },
            {
              value: 3,
              label: 'Customer',
              description: 'People who create Tickets ask for help.',
            },
          ],
        },
        group_ids: {
          options: [
            {
              value: 1,
              label: 'Users',
            },
            {
              value: 2,
              label: 'some group1',
            },
          ],
        },
      },
    })

    const view = await visitView('/guided-setup/manual/invite')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in the finish screen', async () => {
    mockApplicationConfig({
      system_init_done: true,
    })
    mockPermissions(['admin'])
    mockAuthentication(true)

    const view = await visitView('/guided-setup/manual/finish')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
