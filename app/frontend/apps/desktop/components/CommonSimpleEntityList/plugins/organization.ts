// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import OrganizationEntity from '#desktop/components/CommonSimpleEntityList/entity/OrganizationEntity.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

export default {
  type: EntityType.Organization,
  component: OrganizationEntity,
  emptyMessage: __('No organizations found'),
}
