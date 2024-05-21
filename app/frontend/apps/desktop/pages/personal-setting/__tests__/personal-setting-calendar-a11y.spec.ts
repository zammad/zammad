// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockUserCurrentCalendarSubscriptionList } from '../graphql/queries/userCurrentCalendarSubscriptionList.mocks.ts'

describe('testing password a11y view', async () => {
  beforeEach(() => {
    mockPermissions(['user_preferences.notifications'])

    mockUserCurrentCalendarSubscriptionList({
      userCurrentCalendarSubscriptionList: {
        combinedUrl: 'https://zammad.example.com/ical/tickets',
        globalOptions: {
          alarm: false,
        },
        escalation: {
          url: 'https://zammad.example.com/ical/tickets/escalation',
          options: {
            own: true,
            notAssigned: false,
          },
        },
        newOpen: {
          url: 'https://zammad.example.com/ical/tickets/new_open',
          options: {
            own: false,
            notAssigned: true,
          },
        },
        pending: {
          url: 'https://zammad.example.com/ical/tickets/pending',
          options: {
            own: false,
            notAssigned: false,
          },
        },
      },
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/calendar-subscriptions')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
