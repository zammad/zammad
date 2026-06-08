// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

export default {
  type: EntityType.Organization,
  component: () =>
    import('#desktop/components/CommonSimpleEntityList/entity/OrganizationEntity.vue'),
  emptyMessage: __('No organizations found'),
}
