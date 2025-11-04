<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { Organization, User } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import OrganizationInfo from '#desktop/components/Organization/OrganizationInfo.vue'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

interface Props extends TicketSidebarContentProps {
  organization: Organization
  organizationMembers: ReturnType<typeof normalizeEdges<Partial<User>>>
  objectAttributes: ObjectAttribute[]
}

defineProps<Props>()

const persistentStates = defineModel<ObjectLike>({ required: true })

defineEmits<{
  'load-more-members': []
}>()

const actions: MenuItem[] = [
  {
    key: 'edit-organization',
    label: __('Edit Organization'),
    icon: 'organization-edit',
    show: (entity) => entity?.policy.update,
    onClick: (id) => {
      console.log(id, 'Edit organization')
    },
  },
]
</script>

<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :entity="organization"
    :actions="actions"
  >
    <OrganizationInfo :organization="organization" />

    <ObjectAttributes
      :object="organization"
      :attributes="objectAttributes"
      :skip-attributes="['name', 'vip', 'active']"
    />

    <CommonSimpleEntityList
      id="organization-members"
      v-model="persistentStates.collapseMembers"
      :type="EntityType.User"
      :label="__('Members')"
      :entity="organizationMembers"
      has-popover
      @load-more="$emit('load-more-members')"
    />
  </TicketSidebarContent>
</template>
