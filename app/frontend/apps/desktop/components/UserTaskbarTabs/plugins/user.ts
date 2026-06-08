// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { UserTaskbarTabAttributesFragmentDoc } from '#shared/entities/user/graphql/fragments/userTaskbarTabAttributes.api.ts'
import { EnumTaskbarEntity, type User as UserType } from '#shared/graphql/types.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'

import User from '../User/User.vue'

const entityType = 'User'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.UserProfile,
  component: User,
  entityType,
  entityDocument: UserTaskbarTabAttributesFragmentDoc,
  buildEntityTabKey: (route) => `${entityType}-${route.params.internalId}`,
  buildTaskbarTabEntityId: (route) => route.params.internalId,
  buildTaskbarTabParams: (route) => ({ user_id: route.params.internalId }),
  buildTaskbarTabLink: (entity?: UserType, entityKey?: string) => {
    if (!entity?.internalId) {
      if (!entityKey) return
      return `/users/${entityKey.split('-')[1]}`
    }

    return `/users/${entity.internalId}`
  },
  confirmTabRemove: true,
  touchExistingTab: true,
}
