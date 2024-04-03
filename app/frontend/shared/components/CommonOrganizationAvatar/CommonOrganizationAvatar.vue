<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getOrganizationAvatarClasses } from '#shared/initializer/initializeOrganizationAvatarClasses.ts'

import CommonAvatar from '../CommonAvatar/CommonAvatar.vue'
import type { AvatarSize } from '../CommonAvatar/index.ts'
import type { AvatarOrganization } from './types.ts'

export interface Props {
  entity: AvatarOrganization
  size?: AvatarSize
}

const props = defineProps<Props>()

const icon = computed(() => {
  return props.entity.active ? 'organization' : 'inactive-organization'
})

const { backgroundColor } = getOrganizationAvatarClasses()
</script>

<template>
  <CommonAvatar
    :class="backgroundColor"
    :size="size"
    :icon="icon"
    :aria-label="`Avatar (${entity.name})`"
    :vip-icon="entity.vip ? 'vip-organization' : undefined"
  />
</template>
