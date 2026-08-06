<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, useTemplateRef } from 'vue'

import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { type TicketSidebarContentProps } from '#desktop/pages/ticket/types/sidebar.ts'

import {
  TICKET_HISTORY_FLYOUT_NAME,
  useTicketHistory,
} from '../../TicketDetailView/actions/useTicketHistory.ts'
import TicketSidebarContent from '../TicketSidebarContent.vue'

import { useAiSuggestedAnswersAvailability } from './TicketSidebarInformationContent/composables/useAiSuggestedAnswersAvailability.ts'
import { useKnowledgeBaseAiSuggestedAnswers } from './TicketSidebarInformationContent/composables/useKnowledgeBaseAiSuggestedAnswers.ts'
import { useKnowledgeBaseLinkList } from './TicketSidebarInformationContent/composables/useKnowledgeBaseLinkList.ts'
import TicketAccountedTime from './TicketSidebarInformationContent/TicketAccountedTime.vue'
import TicketLinks from './TicketSidebarInformationContent/TicketLinks.vue'
import TicketRelatedKnowledge from './TicketSidebarInformationContent/TicketRelatedKnowledge.vue'
import TicketSubscribers from './TicketSidebarInformationContent/TicketSubscribers.vue'
import TicketTags from './TicketSidebarInformationContent/TicketTags.vue'

const props = defineProps<TicketSidebarContentProps>()

const persistentStates = defineModel<ObjectLike>({ required: true })

const { ticket, ticketId } = useTicketInformation()

const config = toRef(useApplicationStore(), 'config')

const ticketLinksInstance = useTemplateRef('ticket-links')

const { isTicketAgent, isTicketEditable } = useTicketView(ticket)

const ticketMergeFlyoutName = 'ticket-merge'
const ticketChangeCustomerFlyoutName = 'ticket-change-customer'

const { openTicketHistoryFlyout } = useTicketHistory()

const { open: openTicketMergeFlyout } = useFlyout({
  name: ticketMergeFlyoutName,
  component: () =>
    import('#desktop/pages/ticket/components/TicketDetailView/actions/TicketMerge/TicketMergeFlyout.vue'),
})

const { open: openChangeCustomerFlyout } = useFlyout({
  name: ticketChangeCustomerFlyoutName,
  component: () =>
    import('#desktop/pages/ticket/components/TicketDetailView/actions/TicketChangeCustomer/TicketChangeCustomerFlyout.vue'),
})

// :TODO find a way to provide the ticket via prop
const actions = computed<MenuItem[]>(() => [
  {
    key: TICKET_HISTORY_FLYOUT_NAME,
    label: __('History'),
    icon: 'clock-history',
    show: () => isTicketAgent.value,
    onClick: () => openTicketHistoryFlyout(ticket.value!.id),
  },
  {
    key: ticketMergeFlyoutName,
    label: __('Merge'),
    icon: 'merge',
    show: () => isTicketAgent.value && isTicketEditable.value,
    onClick: () =>
      openTicketMergeFlyout({
        ticket,
        currentTaskbarTabId: props.context.currentTaskbarTabId,
      }),
  },
  {
    key: ticketChangeCustomerFlyoutName,
    label: __('Change customer'),
    icon: 'user',
    show: () => isTicketAgent.value && isTicketEditable.value,
    onClick: () =>
      openChangeCustomerFlyout({
        ticket,
      }),
  },
])

// Agent read access is a per-ticket matter: an agent who is the customer of a ticket in a group
//   they cannot access sees it in the customer view, where the knowledge base is not theirs to work
//   with — and where the server would deny both the link list and the suggestions search.
const isKbActive = computed(() => config.value.kb_active && isTicketAgent.value)

const {
  linkedAnswerIds,
  linkedAnswers,
  targetType,
  isLoading: isKnowledgeBaseLinkListLoading,
} = useKnowledgeBaseLinkList(ticketId, {
  enabled: isKbActive,
})

const { showAiSuggestedAnswers, showRelevanceScore } =
  useAiSuggestedAnswersAvailability(isTicketAgent)

const {
  answers: aiSuggestedAnswers,
  loading: isAiSuggestedAnswersLoading,
  pending: isAiSuggestedAnswersPending,
  hasError: hasAiSuggestedAnswersError,
  errorDetail: aiSuggestedAnswersErrorDetail,
  retrySearch: retryAiSuggestedAnswersSearch,
  refreshKeepingAnswers: refreshAiSuggestedAnswers,
} = useKnowledgeBaseAiSuggestedAnswers(ticketId, {
  queryEnabled: showAiSuggestedAnswers,
  subscriptionEnabled: showAiSuggestedAnswers,
  articleCount: () => ticket.value?.articleCount,
})
</script>

<template>
  <TicketSidebarContent
    v-model="persistentStates.scrollPosition"
    :title="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :actions="actions"
  >
    <CommonSectionCollapse
      id="ticket-attributes"
      v-model="persistentStates.collapseAttributes"
      :title="__('Attributes')"
    >
      <div id="ticketEditAttributeForm" data-test-id="ticket-edit-attribute-form" />
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="isTicketAgent && (isTicketEditable || ticket?.tags?.length)"
      id="ticket-tags"
      v-model="persistentStates.collapseTags"
      :title="__('Tags')"
    >
      <TicketTags :ticket="ticket" :is-ticket-editable="isTicketEditable" />
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="isTicketAgent"
      v-show="isTicketEditable || ticketLinksInstance?.hasLinks"
      id="ticket-links"
      v-model="persistentStates.collapseLinks"
      :title="__('Related tickets')"
    >
      <TicketLinks ref="ticket-links" :ticket="ticket" :is-ticket-editable="isTicketEditable" />
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="isKbActive && (isTicketEditable || linkedAnswers.length || aiSuggestedAnswers.length)"
      id="ticket-ai-knowledge-base-answers"
      v-model="persistentStates.collapseKnowledgeBase"
      :title="__('Related knowledge')"
    >
      <TicketRelatedKnowledge
        :linked-answers="linkedAnswers"
        :linked-answer-ids="linkedAnswerIds"
        :target-type="targetType"
        :is-link-list-loading="isKnowledgeBaseLinkListLoading"
        :show-ai-suggested-answers="showAiSuggestedAnswers"
        :ai-suggested-answers="aiSuggestedAnswers"
        :show-relevance-score="showRelevanceScore"
        :is-ai-suggested-answers-loading="isAiSuggestedAnswersLoading"
        :is-ai-suggested-answers-pending="isAiSuggestedAnswersPending"
        :has-ai-suggested-answers-error="hasAiSuggestedAnswersError"
        :ai-suggested-answers-error-detail="aiSuggestedAnswersErrorDetail"
        @retry-ai-suggested-answers-search="retryAiSuggestedAnswersSearch"
        @refresh-ai-suggested-answers="refreshAiSuggestedAnswers"
      />
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="ticket?.timeUnit && isTicketAgent"
      id="ticket-time-accounting"
      v-model="persistentStates.collapseTimeAccounting"
      :title="__('Accounted time')"
    >
      <TicketAccountedTime :ticket="ticket!" />
    </CommonSectionCollapse>

    <CommonSectionCollapse
      v-if="isTicketAgent"
      id="ticket-subscribers"
      v-model="persistentStates.collapseSubscribers"
      :title="__('Subscribers')"
    >
      <TicketSubscribers :ticket="ticket" />
    </CommonSectionCollapse>
  </TicketSidebarContent>
</template>
