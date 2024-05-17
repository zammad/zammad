// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

describe('testing password a11y view', async () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',

      preferences: {
        notification_sound: {
          enabled: true,
          file: 'Xylo.mp3',
        },
        notification_config: {
          group_ids: ['1', '2'],
          matrix: {
            create: {
              criteria: {
                owned_by_me: true,
                owned_by_nobody: true,
                subscribed: true,
                no: false,
              },
              channel: { email: true, online: true },
            },
            update: {
              criteria: {
                owned_by_me: true,
                owned_by_nobody: true,
                subscribed: true,
                no: false,
              },
              channel: { email: true, online: true },
            },
            reminder_reached: {
              criteria: {
                owned_by_me: true,
                owned_by_nobody: false,
                subscribed: false,
                no: false,
              },
              channel: { email: true, online: true },
            },
            escalation: {
              criteria: {
                owned_by_me: true,
                owned_by_nobody: false,
                subscribed: false,
                no: false,
              },
              channel: { email: true, online: true },
            },
          },
        },
      },
    })

    mockPermissions(['user_preferences.notifications'])
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/notifications')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
