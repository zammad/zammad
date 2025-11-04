<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getOrganizationAvatarClasses } from '#shared/initializer/initializeOrganizationAvatarClasses.ts'

import CommonAvatar from '../CommonAvatar/CommonAvatar.vue'

import type { AvatarOrganization } from './types.ts'
import type { AvatarSize } from '../CommonAvatar/index.ts'

export interface Props {
  entity: AvatarOrganization
  size?: AvatarSize
}

const props = defineProps<Props>()

const icon = computed(() => {
  return props.entity.active ? 'organization' : 'inactive-organization'
})

const { base, inactive } = getOrganizationAvatarClasses()

const sizeClass = computed(() => {
  switch (props.size) {
    case 'xs':
      return 'p-0.5'
    case 'small':
      return 'p-2'
    case 'medium':
      return 'p-2.5'
    case 'large':
      return 'p-4'
    case 'xl':
      return 'p-6'
    default:
      return 'p-3.5'
  }
})
</script>

<template>
  <CommonAvatar
    :class="[
      base,
      sizeClass,
      {
        [inactive]: !entity.active,
      },
    ]"
    :size="size"
    :icon="icon"
    :aria-label="`Avatar (${entity.name})`"
    :vip-icon="entity.vip ? 'vip-organization' : undefined"
  />
</template>
