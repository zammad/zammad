// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

describe('testing out of office a11y view', async () => {
  beforeEach(() => {
    mockUserCurrent({
      firstname: 'John',
      lastname: 'Doe',
      outOfOffice: true,
      preferences: { out_of_office_text: 'OOF holiday' },
      outOfOfficeStartAt: '2024-03-01',
      outOfOfficeEndAt: '2024-04-01',
      outOfOfficeReplacement: {
        id: convertToGraphQLId('User', 256),
        internalId: 256,
        fullname: 'Example Agent',
      },
    })
  })

  it('has no accessibility violations', async () => {
    const view = await visitView('/personal-setting/out-of-office')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
