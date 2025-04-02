// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects, type User } from '#shared/graphql/types.ts'

import type { EntityPlugin } from '../useEntity.ts'

// TODO: add Entity-Data types instead of direct usage from GQL

const userEntity: EntityPlugin<User> = {
  name: EnumObjectManagerObjects.User,
  display: (object) => object.fullname || '',
}

export default userEntity
