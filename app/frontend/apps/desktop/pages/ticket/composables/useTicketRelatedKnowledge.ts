// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef, type ComputedRef } from 'vue'

import type { MentionKnowledgeBaseRelatedAnswers } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { useAiSuggestedAnswersAvailability } from '../components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/composables/useAiSuggestedAnswersAvailability.ts'
import { useKnowledgeBaseAiSuggestedAnswers } from '../components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/composables/useKnowledgeBaseAiSuggestedAnswers.ts'
import { useKnowledgeBaseLinkList } from '../components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/composables/useKnowledgeBaseLinkList.ts'
import { excludeLinkedAnswers } from '../components/TicketSidebar/TicketSidebarInformation/TicketSidebarInformationContent/TicketRelatedKnowledge/utils.ts'

// The knowledge base answers linked to and suggested for a ticket, loaded once per ticket tab. The
//   information sidebar and the reply editor both show them, and the sidebar is not mounted while
//   another sidebar is active or the sidebar is collapsed.
export const useTicketRelatedKnowledge = (
  ticket: ComputedRef<TicketById | undefined>,
  ticketId: ComputedRef<ID>,
) => {
  const config = toRef(useApplicationStore(), 'config')

  const { isTicketAgent } = useTicketView(ticket)

  // Agent read access is a per-ticket matter: an agent who is the customer of a ticket in a group
  //   they cannot access sees it in the customer view, where the knowledge base is not theirs to work
  //   with — and where the server would deny both the link list and the suggestions search.
  const isKbActive = computed(() => Boolean(config.value.kb_active) && isTicketAgent.value)

  const {
    linkedAnswerIds,
    linkedAnswers,
    targetType,
    isLoading: isLinkListLoading,
  } = useKnowledgeBaseLinkList(ticketId, {
    enabled: isKbActive,
  })

  const { showAiSuggestedAnswers, showRelevanceScore } =
    useAiSuggestedAnswersAvailability(isTicketAgent)

  // Searches without drafts, archived and linked answers: the sidebar shows this result as it is and
  //   lists the linked answers on its own.
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

  // Suggestions are left out of the `??` list until they are ready, instead of reporting their state.
  const editorSuggestedAnswers = computed(() => {
    if (
      !showAiSuggestedAnswers.value ||
      hasAiSuggestedAnswersError.value ||
      isAiSuggestedAnswersLoading.value ||
      isAiSuggestedAnswersPending.value
    )
      return []

    return excludeLinkedAnswers(aiSuggestedAnswers.value, linkedAnswers.value).map(
      ({ translation }) => translation,
    )
  })

  const editorRelatedAnswers = (): MentionKnowledgeBaseRelatedAnswers => ({
    linked: linkedAnswers.value,
    suggested: editorSuggestedAnswers.value,
  })

  return {
    isKbActive,
    linkedAnswers,
    linkedAnswerIds,
    targetType,
    isLinkListLoading,
    showAiSuggestedAnswers,
    showRelevanceScore,
    aiSuggestedAnswers,
    isAiSuggestedAnswersLoading,
    isAiSuggestedAnswersPending,
    hasAiSuggestedAnswersError,
    aiSuggestedAnswersErrorDetail,
    retryAiSuggestedAnswersSearch,
    refreshAiSuggestedAnswers,
    editorRelatedAnswers,
  }
}

export type TicketRelatedKnowledge = ReturnType<typeof useTicketRelatedKnowledge>
