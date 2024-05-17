// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { mockUserCurrent } from '#tests/support/mock-userCurrent.ts'

import { UserCurrentAvatarActiveDocument } from '../graphql/queries/userCurrentAvatarActive.api.ts'

const mockAvatarImage =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='

const getAvatarObject = (deletable: boolean) => {
  return {
    id: 'Z2lkOi8vemFtbWFkL0F2YXRhci8yNA',
    default: true,
    deletable,
    initial: false,
    imageFull: mockAvatarImage,
    imageResize: mockAvatarImage,
    createdAt: '2022-07-12T06:54:45Z',
    updatedAt: '2022-07-12T06:54:45Z',
  }
}

const mockActiveAvatar = async (deletable = true) => {
  mockGraphQLApi(UserCurrentAvatarActiveDocument).willResolve({
    userCurrentAvatarActive: getAvatarObject(deletable),
  })
}

describe('testing account a11y', () => {
  beforeEach(() => {
    mockUserCurrent({
      lastname: 'Doe',
      firstname: 'John',
    })
  })

  test('account overview has no accessibility violations', async () => {
    const view = await visitView('/account')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })

  test('avatar editor has no accessibility violations', async () => {
    mockActiveAvatar()
    const view = await visitView('/user/current/avatar')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
