// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

export default {
  type: EntityType.User,
  component: () => import('#desktop/components/CommonSimpleEntityList/entity/UserEntity.vue'),
  emptyMessage: __('No members found'),
}
