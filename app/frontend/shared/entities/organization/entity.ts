// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumObjectManagerObjects,
  type Organization,
} from '#shared/graphql/types.ts'

import type { EntityPlugin } from '../useEntity.ts'

// TODO: add Entity-Data types instead of direct usage from GQL

const organizationEntity: EntityPlugin<Organization> = {
  name: EnumObjectManagerObjects.Organization,
  display: (object) => object.name || '',
}

export default organizationEntity
