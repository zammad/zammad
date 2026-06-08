<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useOrganizationEntity } from '#shared/entities/organization/composables/useOrganizationEntity.ts'
import type { Organization } from '#shared/graphql/types.ts'

import OrganizationPopoverWithTrigger from '#desktop/components/Organization/OrganizationPopoverWithTrigger.vue'

import type { QuickSearchPluginProps } from '../../types.ts'

const props = defineProps<QuickSearchPluginProps>()

const { organizationDisplayName, isOrganizationInactive } = useOrganizationEntity(
  toRef(props, 'item'),
)
</script>

<template>
  <OrganizationPopoverWithTrigger
    :popover-config="{ orientation: 'right' }"
    z-index="52"
    class="group/item flex grow items-center gap-2 rounded-md px-2 py-3 text-neutral-400 hover:bg-blue-900 hover:no-underline!"
    trigger-link-active-class="outline-2! outline-offset-1! outline-blue-800! hover:outline-blue-800!"
    :organization="item as Organization"
    :aria-description="isOrganizationInactive ? $t('Organization is inactive.') : undefined"
  >
    <CommonIcon
      class="shrink-0 text-neutral-500"
      :name="isOrganizationInactive ? 'buildings-slash' : 'buildings'"
      size="tiny"
      decorative
    />
    <CommonLabel
      class="block! truncate group-hover/item:text-white"
      :class="{
        'text-neutral-500! group-hover/item:text-white!': isOrganizationInactive,
      }"
    >
      {{ organizationDisplayName }}
    </CommonLabel>
  </OrganizationPopoverWithTrigger>
</template>
