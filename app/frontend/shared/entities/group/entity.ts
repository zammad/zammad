// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { EnumObjectManagerObjects, type Group } from '#shared/graphql/types.ts'

import type { EntityPlugin } from '../useEntity.ts'

// TODO: add Entity-Data types instead of direct usage from GQL

const groupEntity: EntityPlugin<Group> = {
  name: EnumObjectManagerObjects.Group,
  display: (object) => (object.name || '').replace(/::/g, ' › '),
}

export default groupEntity
