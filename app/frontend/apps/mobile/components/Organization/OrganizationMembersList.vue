<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { OrganizationQuery } from '@shared/graphql/types'
import type { ConfidentTake } from '@shared/types/utils'
import { computed } from 'vue'
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
  <CommonUsersList
    :label="__('Members')"
    :users="members"
    :total-count="organization.members?.totalCount || 0"
    :disable-show-more="disableShowMore"
    @show-more="emit('load-more')"
  />
</template>
