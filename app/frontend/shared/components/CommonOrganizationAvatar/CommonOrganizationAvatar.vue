<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
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
</script>

<template>
  <CommonAvatar
    class="bg-gray-200"
    :size="size"
    :icon="icon"
    :aria-label="`Avatar (${entity.name})`"
    :vip-icon="entity.vip ? 'vip-organization' : undefined"
  />
</template>
