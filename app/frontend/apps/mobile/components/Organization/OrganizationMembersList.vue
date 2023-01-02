<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { OrganizationQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { computed } from 'vue'
import CommonSectionMenu from '../CommonSectionMenu/CommonSectionMenu.vue'
import CommonShowMoreButton from '../CommonShowMoreButton/CommonShowMoreButton.vue'
import CommonUsersList from '../CommonUsersList/CommonUsersList.vue'

interface Props {
  organization: ConfidentTake<OrganizationQuery, 'organization'>
  disableShowMore?: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'load-more'): void
}>()

const members = computed(() => {
  return props.organization.members?.edges.map(({ node }) => node) || []
})
</script>

<template>
  <CommonSectionMenu v-if="members.length" :header-label="__('Members')">
    <CommonUsersList :users="members" />
    <CommonShowMoreButton
      :entities="members"
      :total-count="organization.members?.totalCount || 0"
      :disabled="disableShowMore"
      @click="emit('load-more')"
    />
  </CommonSectionMenu>
</template>
