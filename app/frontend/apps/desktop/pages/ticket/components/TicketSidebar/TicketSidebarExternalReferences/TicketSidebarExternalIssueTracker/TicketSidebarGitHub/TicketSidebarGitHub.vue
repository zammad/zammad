<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef, ref, toRef, watch, onMounted } from 'vue'

import { EnumTicketExternalReferencesIssueTrackerType } from '#shared/graphql/types.ts'

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import TicketSidebarContent from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarContent.vue'
import IssueTrackerList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/IssueTrackerList.vue'
import { useIssueTracker } from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/useIssueTracker.ts'
import { usePersistentStates } from '#desktop/pages/ticket/composables/usePersistentStates.ts'
import {
  TicketSidebarScreenType,
  type TicketSidebarEmits,
  type TicketSidebarProps,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarWrapper from '../../../TicketSidebarWrapper.vue'

const props = defineProps<TicketSidebarProps>()

const { persistentStates } = usePersistentStates()

const emit = defineEmits<TicketSidebarEmits>()

const { hideSidebar, issueLinks, isTicketEditable, openIssuesBadge } =
  useIssueTracker(
    EnumTicketExternalReferencesIssueTrackerType.Github,
    toRef(props, 'context'),
  )

const issueTrackerListInstance = useTemplateRef('issue-tracker-list')

const error = ref<string | null>(null)

const handleError = (message: string | null) => {
  error.value = message
}

const flyoutConfig = {
  name: 'link-github-issue',
  icon: props.sidebarPlugin.icon,
  label: __('GitHub: Link issue'),
  inputPlaceholder: 'https://github.com/organization/repository/issues/42',
}

if (props.context.screenType === TicketSidebarScreenType.TicketDetailView) {
  watch(
    hideSidebar,
    (value) => {
      if (value) {
        emit('hide')
      } else {
        emit('show')
      }
    },
    { immediate: true },
  )
} else {
  onMounted(() => {
    emit('show')
  })
}

const actions = computed((): MenuItem[] =>
  issueLinks.value?.length && !error.value
    ? [
        {
          key: 'link-github-issue',
          label: __('Link Issue'),
          show: () => isTicketEditable.value,
          onClick: () => issueTrackerListInstance.value?.openFlyout(),
          icon: 'link-45deg',
        },
      ]
    : [],
)
</script>

<template>
  <TicketSidebarWrapper
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="sidebarPlugin"
    :selected="selected"
    :badge="openIssuesBadge"
  >
    <TicketSidebarContent
      v-model="persistentStates.scrollPosition"
      :title="sidebarPlugin.title"
      :icon="sidebarPlugin.icon"
      :actions="actions"
    >
      <IssueTrackerList
        ref="issue-tracker-list"
        :screen-type="context.screenType"
        :is-ticket-editable="isTicketEditable"
        :form="context.form"
        :ticket-id="context.ticket?.value?.id"
        :issue-links="issueLinks"
        :tracker-type="EnumTicketExternalReferencesIssueTrackerType.Github"
        :flyout-config="flyoutConfig"
        @error="handleError"
      />
    </TicketSidebarContent>
  </TicketSidebarWrapper>
</template>
