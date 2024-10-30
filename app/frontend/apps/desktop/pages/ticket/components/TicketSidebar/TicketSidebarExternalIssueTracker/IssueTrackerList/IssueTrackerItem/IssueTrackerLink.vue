<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import type { TicketExternalReferencesIssueTrackerItem } from '#shared/graphql/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  issue: TicketExternalReferencesIssueTrackerItem
  isEditable: boolean
}

defineProps<Props>()

defineEmits<{
  unlink: [TicketExternalReferencesIssueTrackerItem]
}>()

const { isTouchDevice } = useTouchDevice()
</script>

<template>
  <div class="flex gap-2">
    <CommonLink
      class="grow"
      size="medium"
      external
      open-in-new-tab
      :link="issue.url"
    >
      {{ `#${issue.issueId} ${issue.title}` }}
    </CommonLink>
    <CommonButton
      v-if="isEditable"
      v-tooltip="$t('Unlink issue')"
      icon="x-lg"
      size="small"
      variant="danger"
      :class="{ 'invisible group-hover:visible': !isTouchDevice }"
      @click="$emit('unlink', issue)"
    />
  </div>
</template>
