// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { OrganizationTaskbarTabAttributesFragmentDoc } from '#shared/entities/organization/graphql/fragments/organizationTaskbarTabAttributes.api.ts'
import { EnumTaskbarEntity, type Organization as OrganizationType } from '#shared/graphql/types.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'

import Organization from '../Organization/Organization.vue'

const entityType = 'Organization'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.OrganizationProfile,
  component: Organization,
  entityType,
  entityDocument: OrganizationTaskbarTabAttributesFragmentDoc,
  buildEntityTabKey: (route) => `${entityType}-${route.params.internalId}`,
  buildTaskbarTabEntityId: (route) => route.params.internalId,
  buildTaskbarTabParams: (route) => ({ organization_id: route.params.internalId }),
  buildTaskbarTabLink: (entity?: OrganizationType, entityKey?: string) => {
    if (!entity?.internalId) {
      if (!entityKey) return
      return `/organizations/${entityKey.split('-')[1]}`
    }

    return `/organizations/${entity.internalId}`
  },
  confirmTabRemove: true,
  touchExistingTab: true,
}
