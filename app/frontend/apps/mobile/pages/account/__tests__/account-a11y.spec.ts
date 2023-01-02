// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { axe } from 'vitest-axe'
import { visitView } from '@tests/support/components/visitView'
import { mockAccount } from '@tests/support/mock-account'
import { mockGraphQLApi } from '@tests/support/mock-graphql-api'
import { AccountAvatarActiveDocument } from '../avatar/graphql/queries/active.api'

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
  mockGraphQLApi(AccountAvatarActiveDocument).willResolve({
    accountAvatarActive: getAvatarObject(deletable),
  })
}

describe('testing account a11y', () => {
  beforeEach(() => {
    mockAccount({
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
    const view = await visitView('/account/avatar')
    const results = await axe(view.html())
    expect(results).toHaveNoViolations()
  })
})
