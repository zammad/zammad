<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import {
  EnumTicketExternalReferencesIssueTrackerItemState,
  type TicketExternalReferencesIssueTrackerItem,
} from '#shared/graphql/types.ts'

import IssueTrackerBadgeList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalIssueTracker/IssueTrackerList/IssueTrackerItem/IssueTrackerBadgeList.vue'
import IssueTrackerContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalIssueTracker/IssueTrackerList/IssueTrackerItem/IssueTrackerContent.vue'
import IssueTrackerLink from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalIssueTracker/IssueTrackerList/IssueTrackerItem/IssueTrackerLink.vue'

interface Props {
  issue: TicketExternalReferencesIssueTrackerItem
  isEditable: boolean
}

const props = defineProps<Props>()

defineEmits<{
  unlink: [TicketExternalReferencesIssueTrackerItem]
}>()

const issueStateColor = computed(() => {
  if (
    props.issue.state === EnumTicketExternalReferencesIssueTrackerItemState.Open
  ) {
    return 'text-yellow-500'
  }

  // Closed
  return 'text-green-400'
})

const issueStateName = computed(() => {
  switch (props.issue.state) {
    case EnumTicketExternalReferencesIssueTrackerItemState.Closed:
      return 'check-circle-outline'
    case EnumTicketExternalReferencesIssueTrackerItemState.Open:
    default:
      return 'check-circle-no'
  }
})
</script>

<template>
  <div class="group flex gap-2">
    <CommonIcon
      role="status"
      class="flex-shrink-0"
      :class="issueStateColor"
      :label="__('Issue status')"
      :aria-roledescription="$t('issue status: %s', $t(issue.state))"
      :name="issueStateName"
      size="small"
    />

    <div class="grow space-y-2.5">
      <IssueTrackerLink
        :is-editable="isEditable"
        :issue="issue"
        @unlink="$emit('unlink', $event)"
      />

      <IssueTrackerContent
        v-if="issue.milestone"
        :label="$t('Milestone')"
        :values="[issue.milestone]"
      />

      <IssueTrackerContent
        v-if="issue.assignees?.length"
        :label="issue.assignees.length > 1 ? $t('Assignees') : $t('Assignee')"
        :values="issue.assignees"
      />

      <IssueTrackerContent v-if="issue.labels?.length" :label="$t('Labels')">
        <IssueTrackerBadgeList :badges="issue.labels" />
      </IssueTrackerContent>
    </div>
  </div>
</template>
