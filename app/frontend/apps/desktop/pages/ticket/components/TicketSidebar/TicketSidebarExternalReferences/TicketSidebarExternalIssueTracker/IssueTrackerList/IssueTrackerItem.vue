<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import {
  EnumTicketExternalReferencesIssueTrackerItemState,
  type TicketExternalReferencesIssueTrackerItem,
} from '#shared/graphql/types.ts'

import ExternalReferenceContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceContent.vue'
import ExternalReferenceLink from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceLink.vue'
import IssueTrackerBadgeList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/IssueTrackerList/IssueTrackerItem/IssueTrackerBadgeList.vue'

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
      <ExternalReferenceLink
        :id="issue.issueId"
        :is-editable="isEditable"
        :link="issue.url"
        show-id
        :title="issue.title"
        :tooltip="$t('Unlink issue')"
        @remove="$emit('unlink', issue)"
      />

      <ExternalReferenceContent
        v-if="issue.milestone"
        :label="$t('Milestone')"
        :values="[issue.milestone]"
      />

      <ExternalReferenceContent
        v-if="issue.assignees?.length"
        :label="issue.assignees.length > 1 ? $t('Assignees') : $t('Assignee')"
        :values="issue.assignees"
      />

      <ExternalReferenceContent
        v-if="issue.labels?.length"
        :label="$t('Labels')"
      >
        <IssueTrackerBadgeList :badges="issue.labels" />
      </ExternalReferenceContent>
    </div>
  </div>
</template>
