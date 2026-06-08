<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { User } from '#shared/graphql/types.ts'

import CommonSectionMenu from '../CommonSectionMenu/CommonSectionMenu.vue'
import CommonShowMoreButton from '../CommonShowMoreButton/CommonShowMoreButton.vue'
import CommonUsersList from '../CommonUsersList/CommonUsersList.vue'

interface Props {
  members: {
    array: User[]
    totalCount: number | null
  }
  disableShowMore?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'load-more': []
}>()

const totalCount = computed(() => {
  const count = props.members.totalCount || 0
  const loaded = props.members.array.length

  // We only fetch maximum of 100 member per batch
  return loaded + Math.min(count - loaded, 100)
})
</script>

<template>
  <CommonSectionMenu v-if="members?.array" :header-label="__('Members')">
    <CommonUsersList :users="members.array" />
    <CommonShowMoreButton
      :entities="members.array"
      :total-count="totalCount"
      :disabled="disableShowMore"
      @click="emit('load-more')"
    />
  </CommonSectionMenu>
</template>
