<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar'
import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import ObjectAttributes from '#shared/components/ObjectAttributes/ObjectAttributes.vue'
import type { ObjectAttribute } from '#shared/entities/object-attributes/types/store.ts'
import type { OrganizationQuery, User } from '#shared/graphql/types.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import type { TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarContent from '../TicketSidebarContent.vue'

interface Props extends TicketSidebarContentProps {
  organization: OrganizationQuery['organization']
  organizationMembers: ReturnType<typeof normalizeEdges<Partial<User>>>
  objectAttributes: ObjectAttribute[]
}

defineProps<Props>()

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
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :entity="organization"
    :actions="actions"
  >
    <CommonLink
      :link="`/organizations/${organization.internalId}`"
      class="flex gap-2"
    >
      <CommonOrganizationAvatar
        class="p-3.5"
        :entity="organization as AvatarOrganization"
        size="normal"
      />
      <CommonLabel size="large" class="dark:text-white"
        >{{ organization.name }}
      </CommonLabel>
    </CommonLink>

    <ObjectAttributes
      :object="organization"
      :attributes="objectAttributes"
      :skip-attributes="['name', 'vip', 'active']"
    />

    <CommonSimpleEntityList
      id="organization-members"
      :type="EntityType.User"
      :label="__('Members')"
      :entity="organizationMembers"
      @load-more="$emit('load-more-members')"
    />
  </TicketSidebarContent>
</template>
