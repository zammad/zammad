// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { mockUserCurrentOverviewListQuery } from '../graphql/queries/userCurrentOverviewList.mocks.ts'

const userCurrentOverviewList = [
  {
    id: convertToGraphQLId('Overview', 1),
    name: 'Open Tickets',
  },
  {
    id: convertToGraphQLId('Overview', 2),
    name: 'My Tickets',
  },
  {
    id: convertToGraphQLId('Overview', 3),
    name: 'All Tickets',
  },
]

describe('personal settings for token access', () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
    })
    mockPermissions(['user_preferences.overview_sorting'])
  })

  it('has no accessibility violations', async () => {
    mockUserCurrentOverviewListQuery({ userCurrentOverviewList })

    const view = await visitView('/personal-setting/ticket-overviews')

    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
