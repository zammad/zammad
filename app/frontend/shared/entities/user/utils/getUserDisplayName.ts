// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { isEmpty } from 'lodash-es'

import type { User } from '#shared/graphql/types.ts'

export const userDisplayName = (user: Partial<User>): string => {
  const { fullname, email, phone, login } = user

  return (
    [fullname, email, phone, login].find((elem) => elem && !isEmpty(elem)) ||
    '-'
  )
}
