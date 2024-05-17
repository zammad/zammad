// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'

import type { AddressesField } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<AddressesField> => {
  const email = faker.internet.email()
  const name = faker.person.fullName()
  const raw = `${name} <${email}>`
  return {
    parsed: [
      {
        __typename: 'EmailAddressParsed',
        emailAddress: email,
        isSystemAddress: false,
        name,
      },
    ],
    raw,
  }
}
