// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import {
  checkSimpleTableContent,
  checkSimpleTableHeader,
} from '#tests/support/components/checkSimpleTableContent.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockUserCurrentAccessTokenAddMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAccessTokenAdd.mocks.ts'
import { mockUserCurrentAccessTokenDeleteMutation } from '#shared/entities/user/current/graphql/mutations/userCurrentAccessTokenDelete.mocks.ts'
import { mockUserCurrentAccessTokenListQuery } from '#shared/entities/user/current/graphql/queries/userCurrentAcessTokenList.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { getUserCurrentAccessTokenUpdatesSubscriptionHandler } from '../graphql/subscriptions/userCurrentAccessTokenUpdates.mocks.ts'

vi.hoisted(() => {
  vi.setSystemTime(new Date('2024-04-25T10:00:00Z'))
})

const userCurrentAccessTokenList = [
  {
    id: convertToGraphQLId('Token', 1),
    name: 'Example Token',
    preferences: {
      permission: ['user_preferences.access_token'],
    },
    createdAt: '2020-12-18T17:26:00Z',
    expiresAt: null,
    lastUsedAt: '2024-02-01T17:00:00Z',
  },
  {
    id: convertToGraphQLId('Token', 2),
    name: 'Ticket Handling',
    preferences: {
      permission: ['admin.user', 'admin.organization'],
    },
    createdAt: '2022-01-31T12:00:00Z',
    expiresAt: '2024-06-01T10:00:00Z',
    lastUsedAt: null,
  },
]

const rowContents = [
  [
    'Example Token',
    'user_preferences.access_token',
    ['2020-12-18 17:26', '3 years ago'],
    '-',
    ['2024-02-01 17:00', '2 months ago'],
  ],
  [
    'Ticket Handling',
    'admin.user, admin.organization',
    ['2022-01-31 12:00', '2 years ago'],
    ['2024-06-01 10:00', 'in 1 month'],
    '-',
  ],
]

describe('personal settings for token access', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })
    mockPermissions(['user_preferences.access_token'])

    mockApplicationConfig({
      api_token_access: true,
    })
  })

  afterAll(() => {
    vi.useRealTimers()
  })

  it('show initial message when no token exists yet', async () => {
    mockUserCurrentAccessTokenListQuery({ userCurrentAccessTokenList: [] })

    const view = await visitView('/personal-setting/token-access')

    expect(
      view.getByText(
        'You can generate a personal access token for each application you use that needs access to the Zammad API.',
      ),
    ).toBeInTheDocument()

    expect(
      view.getByText(
        "Pick a name for the application, and we'll give you a unique token.",
      ),
    ).toBeInTheDocument()
  })

  it('redirects to the error page when api token access is disabled', async () => {
    mockApplicationConfig({
      api_token_access: false,
    })

    const view = await visitView('/personal-setting/token-access')

    await vi.waitFor(() => {
      expect(view, 'correctly redirects to error page').toHaveCurrentUrl(
        '/error-tab',
      )
    })
  })

  it('show existing personal access token', async () => {
    mockUserCurrentAccessTokenListQuery({ userCurrentAccessTokenList })

    const view = await visitView('/personal-setting/token-access')

    const tableLabel = 'Personal Access Tokens'

    const tableHeaders = [
      'Name',
      'Permissions',
      'Created',
      'Expires',
      'Last Used',
      'Actions',
    ]

    checkSimpleTableHeader(view, tableHeaders, tableLabel)
    checkSimpleTableContent(view, rowContents, tableLabel)

    const table = within(view.getByRole('table', { name: tableLabel }))
    expect(
      table.getAllByRole('button', { name: 'Delete this access token' }),
    ).toHaveLength(2)
  })

  it('can delete an personal access token', async () => {
    mockUserCurrentAccessTokenListQuery({ userCurrentAccessTokenList })

    const view = await visitView('/personal-setting/token-access')

    const table = within(view.getByRole('table'))

    const deleteButton = within(table.getAllByRole('row')[1]).getByRole(
      'button',
      {
        name: 'Delete this access token',
      },
    )

    mockUserCurrentAccessTokenDeleteMutation({
      userCurrentAccessTokenDelete: {
        success: true,
      },
    })

    await view.events.click(deleteButton)

    await waitForNextTick()

    expect(
      await view.findByRole('dialog', { name: 'Delete Object' }),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Delete Object' }))

    checkSimpleTableContent(view, [rowContents[1]])
  })

  it('updates the personal access token list when a new access token is added', async () => {
    mockUserCurrentAccessTokenListQuery({ userCurrentAccessTokenList })

    const view = await visitView('/personal-setting/token-access')

    const accessTokenUpdateSubscription =
      getUserCurrentAccessTokenUpdatesSubscriptionHandler()

    accessTokenUpdateSubscription.trigger({
      userCurrentAccessTokenUpdates: {
        tokens: [
          ...userCurrentAccessTokenList,
          {
            id: convertToGraphQLId('Token', 3),
            name: 'New Token',
            preferences: {
              permission: ['ticket.agent'],
            },
            createdAt: '2024-04-25T09:59:59Z',
            expiresAt: null,
            lastUsedAt: null,
          },
        ],
      },
    })

    await waitForNextTick()

    const newAccessTokenRowContents = [
      'New Token',
      'ticket.agent',
      ['2024-04-25 09:59', 'just now'],
    ]

    checkSimpleTableContent(view, [...rowContents, newAccessTokenRowContents])
  })

  it('create new personal access token', async () => {
    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          permissions: {
            options: [
              {
                value: 'report',
                label: 'Report (%s)',
                description: 'To access the report interface.',
              },
              {
                value: 'ticket',
                label: 'Ticket (%s)',
                description: 'To access the ticket interface.',
                disabled: true,
                children: [
                  {
                    value: 'ticket.agent',
                    label: 'Agent Tickets (%s)',
                    description:
                      'To access the agent tickets based on group access.',
                  },
                ],
              },
            ],
          },
        },
      },
    })
    mockUserCurrentAccessTokenListQuery({ userCurrentAccessTokenList })

    const view = await visitView('/personal-setting/token-access')

    const newAccessTokenButton = view.getByRole('button', {
      name: 'New Personal Access Token',
    })

    await view.events.click(newAccessTokenButton)

    const flyout = await view.findByRole('complementary', {
      name: 'New Personal Access Token',
    })
    expect(flyout).toBeInTheDocument()

    const name = await view.findByLabelText('Name')
    await view.events.type(name, 'A new token')

    const input = view.getByLabelText('Expiration date')
    await view.events.type(input, '2024-12-31{Enter}')

    const permissionsField = within(view.getByLabelText('Permissions'))
    const permissions = permissionsField.getAllByRole('treeitem')

    const toggleSwitch = within(permissions[0]).getByRole('switch')
    await view.events.click(toggleSwitch)

    mockUserCurrentAccessTokenAddMutation({
      userCurrentAccessTokenAdd: {
        tokenValue: 'new-token-1234',
        token: {
          id: convertToGraphQLId('Token', 3),
          name: 'A new token',
          preferences: {
            permission: ['report'],
          },
          createdAt: '2024-04-25T09:59:59Z',
          expiresAt: '2024-12-31T00:00:00Z',
          lastUsedAt: null,
          user: {
            id: '123',
          },
        },
        errors: null,
      },
    })

    await view.events.click(view.getByRole('button', { name: 'Create' }))

    expect(
      await view.findByLabelText('Your Personal Access Token'),
    ).toHaveValue('new-token-1234')

    await view.events.click(
      view.getByRole('button', {
        name: 'OK, I have copied my token',
      }),
    )

    expect(flyout).not.toBeInTheDocument()

    checkSimpleTableContent(view, [
      [
        'A new token',
        'report',
        ['2024-04-25 09:59', 'just now'],
        ['2024-12-31 00:00', 'in 8 months'],
        '-',
      ],
      ...rowContents,
    ])
  })
})
