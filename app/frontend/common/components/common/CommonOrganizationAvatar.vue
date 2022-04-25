<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonAvatar from '@common/components/common/CommonAvatar.vue'
import type { AvatarSize, AvatarOrganization } from '@common/types/avatar'
import { computed } from 'vue'

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
  <CommonAvatar v-bind:size="size" v-bind:icon="icon" />
</template>
