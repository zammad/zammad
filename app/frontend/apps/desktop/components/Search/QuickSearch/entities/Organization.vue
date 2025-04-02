<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { QuickSearchPluginProps } from '../../types.ts'

const props = defineProps<QuickSearchPluginProps>()

const isOrganizationInactive = computed(() => !props.item.active)
</script>

<template>
  <CommonLink
    class="group/item flex grow gap-2 rounded-md px-2 py-3 text-neutral-400 hover:bg-blue-900 hover:no-underline!"
    :link="`/organizations/${item.internalId}`"
    :aria-description="
      isOrganizationInactive ? $t('Organization is inactive.') : undefined
    "
    internal
  >
    <CommonIcon
      class="shrink-0 text-neutral-500"
      :name="isOrganizationInactive ? 'buildings-slash' : 'buildings'"
      size="small"
      decorative
    />
    <CommonLabel
      class="block! truncate group-hover/item:text-white"
      :class="{
        'text-neutral-500! group-hover/item:text-white!':
          isOrganizationInactive,
      }"
    >
      {{ item.name }}
    </CommonLabel>
  </CommonLink>
</template>
