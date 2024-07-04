<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { OrganizationQuery } from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

import CommonSectionMenu from '../CommonSectionMenu/CommonSectionMenu.vue'
import CommonShowMoreButton from '../CommonShowMoreButton/CommonShowMoreButton.vue'
import CommonUsersList from '../CommonUsersList/CommonUsersList.vue'

interface Props {
  organization: ConfidentTake<OrganizationQuery, 'organization'>
  disableShowMore?: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'load-more': []
}>()

const members = computed(() => {
  return props.organization.allMembers?.edges.map(({ node }) => node) || []
})
</script>

<template>
  <CommonSectionMenu v-if="members.length" :header-label="__('Members')">
    <CommonUsersList :users="members" />
    <CommonShowMoreButton
      :entities="members"
      :total-count="organization.allMembers?.totalCount || 0"
      :disabled="disableShowMore"
      @click="emit('load-more')"
    />
  </CommonSectionMenu>
</template>
