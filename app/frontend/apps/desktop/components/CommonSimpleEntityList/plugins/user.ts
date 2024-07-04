// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import UserEntity from '#desktop/components/CommonSimpleEntityList/entity/UserEntity.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

export default {
  type: EntityType.User,
  component: UserEntity,
  emptyMessage: __('No members found'),
}
