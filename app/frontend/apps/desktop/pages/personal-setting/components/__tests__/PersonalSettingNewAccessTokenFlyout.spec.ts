// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getByRole, within } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import {
  mockUserCurrentAccessTokenAddMutation,
  waitForUserCurrentAccessTokenAddMutationCalls,
} from '#shared/entities/user/current/graphql/mutations/userCurrentAccessTokenAdd.mocks.ts'

import PersonalSettingNewAccessTokenFlyout from '../PersonalSettingNewAccessTokenFlyout.vue'

const renderNewAccessTokenFlyout = (
  props: Record<string, unknown> = {},
  options: any = {},
) => {
  return renderComponent(PersonalSettingNewAccessTokenFlyout, {
    props,
    ...options,
    store: true,
    form: true,
    router: true,
    global: {
      stubs: {
        teleport: true,
      },
    },
  })
}

describe('PersonalSettingNewAccessTokenFlyout - create new access token', () => {
  beforeEach(() => {
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
  })

  it('show create access token flyout', async () => {
    const view = renderNewAccessTokenFlyout()

    await view.findByRole('complementary', {
      name: 'New Personal Access Token',
    })

    expect(await view.findByLabelText('Name')).toBeInTheDocument()
    expect(view.getByLabelText('Expiration date')).toBeInTheDocument()
    expect(view.getByLabelText('Permissions')).toBeInTheDocument()
  })

  it('use flyout to create a access token', async () => {
    const view = renderNewAccessTokenFlyout()

    const name = await view.findByLabelText('Name')
    await view.events.type(name, 'A new token')

    const permissionsField = within(view.getByLabelText('Permissions'))
    const permissions = permissionsField.getAllByRole('treeitem')

    const toggleSwitch = getByRole(permissions[0], 'switch')
    await view.events.click(toggleSwitch)

    mockUserCurrentAccessTokenAddMutation({
      userCurrentAccessTokenAdd: {
        tokenValue: 'new-token-1234',
      },
    })

    await view.events.click(view.getByText('Create'))

    const calls = await waitForUserCurrentAccessTokenAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual(
      expect.objectContaining({
        input: expect.objectContaining({
          name: 'A new token',
          permission: ['report'],
        }),
      }),
    )

    expect(view.getByLabelText('Your Personal Access Token')).toHaveValue(
      'new-token-1234',
    )
  })
})
