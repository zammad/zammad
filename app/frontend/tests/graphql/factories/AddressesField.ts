// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { AddressesField } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'
import { faker } from '@faker-js/faker'

export default (): DeepPartial<AddressesField> => {
  const email = faker.internet.email()
  const name = faker.person.fullName()
  const raw = `${name} <${email}>`
  return {
    parsed: [
      {
        __typename: 'EmailAddress',
        emailAddress: email,
        isSystemAddress: false,
        name,
      },
    ],
    raw,
  }
}
