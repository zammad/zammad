<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonAvatar from '@shared/components/CommonAvatar/CommonAvatar.vue'
import type { AvatarSize } from '@shared/components/CommonAvatar'
import type { AvatarOrganization } from '@shared/components/CommonOrganizationAvatar/types'
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
