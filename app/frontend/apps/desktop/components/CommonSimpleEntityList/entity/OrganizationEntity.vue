<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { AvatarOrganization } from '#shared/components/CommonOrganizationAvatar'
import CommonOrganizationAvatar from '#shared/components/CommonOrganizationAvatar/CommonOrganizationAvatar.vue'
import type { Organization } from '#shared/graphql/types.ts'

import OrganizationPopoverWithTrigger from '#desktop/components/Organization/OrganizationPopoverWithTrigger.vue'

import type { EntityType } from '../types.ts'

interface Props {
  entity: Organization
  context: {
    type: EntityType
    emptyMessage: string
    hasPopover?: boolean
  }
}
defineProps<Props>()
</script>

<template>
  <OrganizationPopoverWithTrigger
    v-if="context.hasPopover"
    :popover-config="{ orientation: 'left' }"
    :organization="entity"
    no-focus-styling
  >
    <template #default="slotProps">
      <div class="flex items-center gap-2">
        <CommonOrganizationAvatar
          class="rounded-full outline-1 outline-transparent group-hover:outline-blue-600 group-hover:dark:outline-blue-900 group-focus-visible:outline-blue-800"
          :class="{
            'outline-2! outline-blue-800!': slotProps?.isOpen && slotProps.hasOpenViaLongClick,
          }"
          :entity="entity"
          size="small"
        />
        <CommonLabel
          class="block truncate text-blue-800! group-hover:text-blue-850! group-hover:dark:text-blue-600! group-focus-visible:text-blue-800!"
        >
          {{ entity.name }}
        </CommonLabel>
      </div>
    </template>
  </OrganizationPopoverWithTrigger>
  <CommonLink
    v-else
    :link="`/organization/profile/${entity.internalId}`"
    class="group flex items-center gap-2 hover:no-underline!"
  >
    <CommonOrganizationAvatar :entity="entity as AvatarOrganization" size="small" />
    <CommonLabel
      class="block truncate text-blue-800! group-hover:text-blue-850! group-hover:dark:text-blue-600! group-focus-visible:text-blue-800!"
    >
      {{ entity.name }}
    </CommonLabel>
  </CommonLink>
</template>
