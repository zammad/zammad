// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { mockCurrentUserQuery } from '#shared/graphql/queries/currentUser.mocks.ts'
import {
  EnumFormUpdaterId,
  EnumNotificationSoundFile,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { waitForUserCurrentNotificationPreferencesResetMutationCalls } from '#desktop/pages/personal-setting/graphql/mutations/userCurrentNotificationPreferencesReset.mocks.ts'
import {
  mockUserCurrentNotificationPreferencesUpdateMutation,
  waitForUserCurrentNotificationPreferencesUpdateMutationCalls,
} from '#desktop/pages/personal-setting/graphql/mutations/userCurrentNotificationPreferencesUpdate.mocks.ts'

const mockPersonalSettings = (withGroups = true) => {
  return {
    personalSettings: {
      notificationConfig: {
        groupIds: withGroups ? [1, 2] : undefined,
        matrix: {
          create: {
            criteria: {
              ownedByMe: true,
              ownedByNobody: true,
              subscribed: true,
              no: false,
            },
            channel: { email: true, online: true },
          },
          update: {
            criteria: {
              ownedByMe: true,
              ownedByNobody: true,
              subscribed: true,
              no: false,
            },
            channel: { email: true, online: true },
          },
          reminderReached: {
            criteria: {
              ownedByMe: true,
              ownedByNobody: false,
              subscribed: false,
              no: false,
            },
            channel: { email: true, online: true },
          },
          escalation: {
            criteria: {
              ownedByMe: true,
              ownedByNobody: false,
              subscribed: false,
              no: false,
            },
            channel: { email: true, online: true },
          },
        },
      },
      notificationSound: {
        enabled: true,
        file: EnumNotificationSoundFile.Xylo,
      },
    },
  }
}

const mockUser = () => ({
  firstname: 'John',
  lastname: 'Doe',
})

describe('personal notifications settings', () => {
  beforeEach(() => {
    mockPermissions(['user_preferences.notifications'])

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          EnumFormUpdaterId:
            EnumFormUpdaterId.FormUpdaterUpdaterUserNotifications,
          group_ids: {
            options: [
              {
                label: 'Testers Group',
                value: 1,
              },
              {
                label: 'Developers Group',
                value: 2,
              },
            ],
          },
        },
      },
    })
  })

  it('renders view correctly', async () => {
    mockUserCurrent({
      ...mockUser(),
      ...mockPersonalSettings(),
    })

    await waitForNextTick()

    const view = await visitView('personal-setting/notifications')

    // TABLE
    expect(view.getByText('New ticket')).toBeInTheDocument()
    expect(view.getByText('Ticket update')).toBeInTheDocument()
    expect(view.getByText('Ticket reminder reached')).toBeInTheDocument()
    expect(view.getByText('Ticket escalation')).toBeInTheDocument()

    expect(view.getByText('Name')).toBeInTheDocument()
    expect(view.getByText('My tickets')).toBeInTheDocument()
    expect(view.getByText('Not assigned')).toBeInTheDocument()
    expect(view.getByText('All tickets')).toBeInTheDocument()
    expect(view.getByText('Also notify via email')).toBeInTheDocument()
    expect(view.getByText('Developers Group')).toBeInTheDocument()
    expect(view.getByText('Testers Group')).toBeInTheDocument()

    const checkboxes = view.getAllByRole('checkbox')
    expect(checkboxes).toHaveLength(20)

    // Fields
    expect(view.getByText('Notification sound')).toBeInTheDocument()

    expect(
      view.getByText('Limit notifications to specific groups'),
    ).toBeInTheDocument()

    expect(
      view.getByText('Play user interface sound effects'),
    ).toBeInTheDocument()
  })

  it("doesn't render user groups if groups are not provided", async () => {
    mockUserCurrent({
      ...mockUser(),
      ...mockPersonalSettings(false),
    })

    const view = await visitView('personal-setting/notifications')

    expect(view.queryByText('User groups')).not.toBeInTheDocument()
  })

  it('resets values to default', async () => {
    mockUserCurrent({
      ...mockUser(),
      ...mockPersonalSettings(),
    })

    const playSound = vi.fn()
    // Set up a mock for playing sound effects in a test environment
    // This is necessary because the audio API is not available in the test environment
    window.HTMLMediaElement.prototype.play = () => playSound()

    const view = await visitView('personal-setting/notifications')

    await view.events.click(view.getByLabelText('Notification sound'))

    await view.events.click(view.getByText('Plop'))

    const checkboxes = view.getAllByTestId('checkbox-label')

    await view.events.click(checkboxes.at(-1)!)

    expect(
      (view.getByLabelText('Notification sound') as HTMLInputElement).value,
    ).toEqual('Plop')

    await view.events.click(
      view.getByRole('button', { name: 'Reset to Default Settings' }),
    )

    expect(
      await view.findByRole('dialog', { name: 'Confirmation' }),
    ).toBeInTheDocument()

    expect(
      view.getByText(
        'Are you sure? Your notifications settings will be reset to default.',
      ),
    ).toBeInTheDocument()

    await view.events.click(view.getByRole('button', { name: 'Yes' }))

    const mocks =
      await waitForUserCurrentNotificationPreferencesResetMutationCalls()

    expect(mocks.at(-1)?.variables).toEqual({})

    mockCurrentUserQuery({
      currentUser: {
        ...mockUser(),
        ...mockPersonalSettings(),
      },
    })

    await waitForNextTick()

    expect(playSound).toHaveBeenCalled()
    expect(checkboxes.at(-1)).toBeEnabled()
  })

  it('submits notification form successfully', async () => {
    mockUserCurrent({
      ...mockUser(),
      ...mockPersonalSettings(),
    })

    const view = await visitView('personal-setting/notifications')

    const checkboxes = view.getAllByTestId('checkbox-label')

    await view.events.click(checkboxes.at(-1)!)

    mockUserCurrentNotificationPreferencesUpdateMutation({
      userCurrentNotificationPreferencesUpdate: {
        user: {
          ...mockUser(),
          ...mockPersonalSettings(),
        },
        errors: null,
      },
    })

    await view.events.click(
      view.getByRole('button', { name: 'Save Notifications' }),
    )

    const previousMockedData = mockPersonalSettings()

    // Convert group ids to GraphQL ids to match payload format
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-expect-error
    previousMockedData.personalSettings.notificationConfig.groupIds =
      previousMockedData.personalSettings.notificationConfig?.groupIds?.map(
        (id) => convertToGraphQLId('Group', id),
      )

    const mocks =
      await waitForUserCurrentNotificationPreferencesUpdateMutationCalls()

    // Last checkbox in table got updated
    expect(mocks.at(-1)?.variables).not.toEqual(previousMockedData)
  })
})
